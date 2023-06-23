
use strict;

package SGN::Controller::AJAX::SpatialModel;

use Moose;
use Data::Dumper;
use File::Temp qw | tempfile |;
use File::Slurp;
use File::Spec qw | catfile|;
use File::Basename qw | basename |;
use File::Copy;
use List::Util qw | any |;
use CXGN::Dataset;
use CXGN::Dataset::File;
use CXGN::Tools::Run;
use CXGN::Page::UserPrefs;
use CXGN::Tools::List qw/distinct evens/;
use CXGN::Blast::Parse;
use CXGN::Blast::SeqQuery;
use SGN::Model::Cvterm;
use Cwd qw(cwd);
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON' },
    );


sub shared_phenotypes: Path('/ajax/spatial_model/shared_phenotypes') Args(0) {
    my $self = shift;
    my $c = shift;
    my $dataset_id = $c->req->param('dataset_id');
    my $people_schema = $c->dbic_schema("CXGN::People::Schema");
    my $schema = $c->dbic_schema("Bio::Chado::Schema", "sgn_chado");
    my $ds = CXGN::Dataset->new(people_schema => $people_schema, schema => $schema, sp_dataset_id => $dataset_id);
    my $traits = $ds->retrieve_traits();

    $c->tempfiles_subdir("spatial_model_files");
    my ($fh, $tempfile) = $c->tempfile(TEMPLATE=>"spatial_model_files/trait_XXXXX");
    my $temppath = $c->config->{basepath}."/".$tempfile;
    my $ds2 = CXGN::Dataset::File->new(people_schema => $people_schema, schema => $schema, sp_dataset_id => $dataset_id, file_name => $temppath, quotes => 0);
    my $phenotype_data_ref = $ds2->retrieve_phenotypes();

    print STDERR Dumper($traits);
    $c->stash->{rest} = {
        options => $traits,
        tempfile => $tempfile."_phenotype.txt",
#        tempfile => $file_response,
    };
}



sub extract_trait_data :Path('/ajax/spatial_model/getdata') Args(0) {
    my $self = shift;
    my $c = shift;

    my $file = $c->req->param("file");
    my $trait = $c->req->param("trait");

    $file = basename($file);
    my @data;

    my $temppath = File::Spec->catfile($c->config->{basepath}, "static/documents/tempfiles/spatial_model_files", $file);
    print STDERR Dumper($temppath);

    my $F;
    if (! open($F, "<", $temppath)) {
	$c->stash->{rest} = { error => "Can't find data." };
	return;
    }

    $c->stash->{rest} = { data => \@data, trait => $trait};
}


sub generate_results: Path('/ajax/spatial_model/generate_results') Args(1) {
    my $self = shift;
    my $c = shift;
    my $trial_id = shift;
    my $basenamesp = $c -> req -> param("basenamesp");

    print STDERR "TRIAL_ID: $trial_id\n";

    $c->tempfiles_subdir("spatial_model_files"); # set the tempfiles subdir to spatial model files
    my $spatial_model_tmp_output = $c->config->{cluster_shared_tempdir}."/spatial_model_files"; # get the spatial model temp output directory
    print STDERR "spatial_model_tmp_output: $spatial_model_tmp_output\n";
    mkdir $spatial_model_tmp_output if ! -d $spatial_model_tmp_output; # create the spatial model temp output directory if it doesn't exist
    my ($tmp_fh, $tempfile) = tempfile(
      "spatial_model_download_XXXXX",
      DIR=> $spatial_model_tmp_output,
    );
    print STDERR "tempfile: $tempfile\n";

    #my $temppath = $c->config->{basepath}."/".$tempfile;
    #print STDERR "temppath: $temppath\n";

    my $pheno_filepath = $tempfile . "_phenotype.txt"; # create the phenotype file path
    

    print STDERR "pheno_filepath: $pheno_filepath\n";

    my $people_schema = $c->dbic_schema("CXGN::People::Schema");
    my $schema = $c->dbic_schema("Bio::Chado::Schema", "sgn_chado");

    
    my $temppath =  $tempfile;
    my $ds = CXGN::Dataset::File->new(people_schema => $people_schema, schema => $schema,  file_name => $temppath, quotes=>0);
    $ds -> trials([$trial_id]);
    $ds -> retrieve_phenotypes($pheno_filepath);
    open(my $PF, "<", $pheno_filepath) || die "Can't open pheno file $pheno_filepath";
    open(my $CLEAN, ">", $pheno_filepath.".clean") || die "Can't open pheno_filepath clean for writing";

    my $header = <$PF>;
    chomp($header);

    my @fields = split /\t/, $header;

    my @file_traits = @fields[ 39 .. @fields-1 ];
    my @other_headers = @fields[ 0 .. 38 ];



    print STDERR "FIELDS: ".Dumper(\@file_traits);

    foreach my $t (@file_traits) {
	$t = make_R_trait_name($t);
    }

    my $si_traits = join(",", @file_traits);

    print STDERR "FILE TRAITS: ".Dumper(\@file_traits);

    my @new_header = (@other_headers, @file_traits);
    print $CLEAN join("\t", @new_header)."\n";

    my $last_index = scalar(@new_header)-1;


    while(<$PF>) {
	print $CLEAN $_;
    }

    close($PF);
    close($CLEAN);

    my $cmd = CXGN::Tools::Run->new({
	backend => $c->config->{backend},
	submit_host=>$c->config->{cluster_host},
	temp_base => $c->config->{cluster_shared_tempdir} . "/spatial_model_files",
	queue => $c->config->{'web_cluster_queue'},
	do_cleanup => 0,
	# don't block and wait if the cluster looks full
	max_cluster_jobs => 1_000_000_000,
    });


    $cmd->run_cluster(
	"Rscript ",
	#$c->config->{basepath} . "/R/spatial_modeling.R",
    $c->config->{basepath} . "/R/spatial_correlation_check.R",
	$pheno_filepath.".clean",
	"'".$si_traits."'",

	);

    while ($cmd->alive) {
	sleep(1);
    }
    #getting the spatial correlation results
    my @data;

    open(my $F, "<", $pheno_filepath.".clean.spatial_correlation_summary") || die "Can't open result file $pheno_filepath".".spatial_correlation_summary";
    my $header = <$F>;
    my @h = split(/\t/, $header);
    #my @h = split(',', $header);
    my @spl;
    foreach my $item (@h) {
    push  @spl, {title => $item};
  }
    print STDERR "Header: ".Dumper(\@spl);
    while (<$F>) {
	chomp;
	my @fields = split /\t/; #split /,/;
	foreach my $f (@fields) { $f =~ s/\"//g; }
	push @data, \@fields;
    }

    print STDERR "FORMATTED DATA: ".Dumper(\@data);

    my $basename = basename($pheno_filepath.".clean.spatial_correlation_summary");

    copy($pheno_filepath.".clean.blues", $c->config->{basepath}."/static/documents/tempfiles/spatial_model_files/".$basename);

    my $download_url = '/documents/tempfiles/spatial_model_files/'.$basename;
    my $download_link = "<a href=\"$download_url\">Download Results</a>";

####################################################################
#     #getting the blue results
#     my @data;

#     open(my $F, "<", $pheno_filepath.".clean.blues") || die "Can't open result file $pheno_filepath".".clean.blues";
#     my $header = <$F>;
#     my @h = split(/\s+/, $header);
#     #my @h = split(',', $header);
#     my @spl;
#     foreach my $item (@h) {
#     push  @spl, {title => $item};
#   }
#     print STDERR "Header: ".Dumper(\@spl);
#     while (<$F>) {
# 	chomp;
# 	my @fields = split /\s+/;
# 	foreach my $f (@fields) { $f =~ s/\"//g; }
# 	push @data, \@fields;
#     }

#     # print STDERR "FORMATTED DATA: ".Dumper(\@data);

#     my $basename = basename($pheno_filepath.".clean.blues");

#     copy($pheno_filepath.".clean.blues", $c->config->{basepath}."/static/documents/tempfiles/spatial_model_files/".$basename);

#     my $download_url = '/documents/tempfiles/spatial_model_files/'.$basename;
#     my $download_link = "<a href=\"$download_url\">Download Results</a>";



#     #############################################################
#     ##getting with fitted results
#     my @data_fitted;

#     open(my $F_fitted, "<", $pheno_filepath.".clean.fitted") || die "Can't open result file $pheno_filepath".".clean.fitted";
#     my $header_fitted = <$F_fitted>;
#     my @h_fitted = split(/\s+/, $header_fitted);
#     #my @h = split(',', $header);
#     my @spl_fitted;
#     foreach my $item_fitted (@h_fitted) {
#     push  @spl_fitted, {title => $item_fitted};
#   }
#     print STDERR "Header: ".Dumper(\@spl_fitted);
#     while (<$F_fitted>) {
# 	chomp;
# 	my @fields_fitted = split /\s+/;
# 	foreach my $f_fitted (@fields_fitted) { $f_fitted =~ s/\"//g; }
# 	push @data_fitted, \@fields_fitted;
#     }

#     # print STDERR "FORMATTED DATA: ".Dumper(\@data);

#     my $basename = basename($pheno_filepath.".clean.fitted");

#     copy($pheno_filepath.".clean.fitted", $c->config->{basepath}."/static/documents/tempfiles/spatial_model_files/".$basename);
#     my $fitted_hash;
#     ($fitted_hash) = $self->result_file_to_hash($c, $F_fitted);
#     my $download_url_fitted = '/documents/tempfiles/spatial_model_files/'.$basename;
#     my $download_link_fitted = "<a href=\"$download_url\">Download Fitted values</a>";
    ###############################################################
    #getting the AIC results
#     my @data_AIC;

#     open(my $F_AIC, "<", $pheno_filepath.".clean.AIC") || die "Can't open result file $pheno_filepath".".clean.AIC";
#     my $header_AIC = <$F_AIC>;
#     my @h_AIC = split(/\s+/, $header_AIC);
#     #my @h = split(',', $header);
#     my @spl_AIC;
#     foreach my $item_AIC (@h_AIC) {
#     push  @spl_AIC, {title => $item_AIC};
#   }
#     print STDERR "Header: ".Dumper(\@spl_AIC);
#     while (<$F_AIC>) {
# 	chomp;
# 	my @fields_AIC = split /\s+/;
# 	foreach my $f_AIC (@fields_AIC) { $f_AIC =~ s/\"//g; }
# 	push @data_AIC, \@fields_AIC;
#     }

#     my $basename = basename($pheno_filepath.".clean.AIC");

#     copy($pheno_filepath.".clean.AIC", $c->config->{basepath}."/static/documents/tempfiles/spatial_model_files/".$basename);

#     my $download_url_AIC = '/documents/tempfiles/spatial_model_files/'.$basename;
#     my $download_link_AIC = "<a href=\"$download_url_AIC\">Download Results</a>";
    ######################################################


    $c->stash->{rest} = {
	data => \@data,
    headers => \@spl,
	download_link => $download_link,
    pheno_filepath => $pheno_filepath,
    phenotype_file => $pheno_filepath.".clean",
    # data_fitted => \@data_fitted,
    # headers_fitted => \@spl_fitted,

    # download_link_fitted => $download_link_fitted,
    # data_AIC => \@data_AIC,
    # headers_AIC => \@spl_AIC,
    # download_link_AIC => $download_link_AIC,
    # input_file => $temppath,
    # fitted_hash => $fitted_hash,
    };
}
sub correct_spatial: Path('/ajax/spatial_model/correct_spatial') Args(1) {
    #my ($c) = @_; # $c is the catalyst object
     my ($self, $c) = @_;
    my $dataTableData = $c->req->param("dataTableData");
    print STDERR "DATA TABLE DATA: $dataTableData\n";
    # Convert the DataTable data back into an array
    my @dataTableArray = map { [split(/\t/, $_)] } split(/\n/, $dataTableData);

    # Get the data and other required variables from the stash
    # my $data = $c->stash->{rest}->{data};
    my $pheno_filepath = $c->req->param("pheno_filepath");
    my $headers = $c->req->param("headers");   
    my $phenotype_file = $c->req->param("phenotype_file");
    print STDERR "PHENOTYPE FILE: $phenotype_file\n";
    # Convert the data and headers to a format suitable for passing to the second R script
    my $data_string = join("\n", map { join("\t", @$_) } @$dataTableData);
    my $headers_string = join(",", map { $_->{title} } @$headers);
    # Create a temporary file to store the data
    my ($temp_fh, $temp_file) = tempfile();
    print $temp_fh $data_string;
    close($temp_fh);
    print STDERR "TEMP FILE: $temp_file\n";


    # Define the command to run the second R script
    my $cmd = CXGN::Tools::Run->new({
	backend => $c->config->{backend},
	submit_host=>$c->config->{cluster_host},
	temp_base => $c->config->{cluster_shared_tempdir} . "/spatial_model_files",
	queue => $c->config->{'web_cluster_queue'},
	do_cleanup => 0,
	# don't block and wait if the cluster looks full
	max_cluster_jobs => 1_000_000_000,
    });
    # my $command = "Rscript /R/Spatial_Correction.R $phenotype_file $temp_file \"$headers_string\" ";
      $cmd->run_cluster(
	"Rscript ",
	#$c->config->{basepath} . "/R/spatial_modeling.R",
    $c->config->{basepath} . "/R/Spatial_Correction.R",
    $phenotype_file,
    $temp_file, 
	"'".$headers_string."'",

	);

    while ($cmd->alive) {
	sleep(1);
    }

   #getting the spatial correlation results
    my @result;

    open(my $F, "<", $pheno_filepath.".blues") || die "Can't open result file $pheno_filepath".".blues";
    my $header = <$F>;
    my @h = split(/\t/, $header);
    #my @h = split(',', $header);
    my @spl;
    foreach my $item (@h) {
    push  @spl, {title => $item};
  }
    print STDERR "Header: ".Dumper(\@spl);
    while (<$F>) {
	chomp;
	my @fields = split /\t/; #split /,/;
	foreach my $f (@fields) { $f =~ s/\"//g; }
	push @result, \@fields;
    }

    print STDERR "FORMATTED DATA: ".Dumper(\@result);

    my $basename = basename($pheno_filepath.".clean.blues");

    copy($pheno_filepath.".clean.corrected", $c->config->{basepath}."/static/documents/tempfiles/spatial_model_files/".$basename);

    my $download_url = '/documents/tempfiles/spatial_model_files/'.$basename;
    my $download_link = "<a href=\"$download_url\">Download Results</a>";

    $c->stash->{rest} = {
	result => \@result,
    headers => \@spl,
	download_link => $download_link,

};
}
sub result_file_to_hash {
    my $self = shift;
    my $c = shift;
    my $file = shift;

    print STDERR "result_file_to_hash(): Processing file $file...\n";
    my @lines = read_file($file);
    chomp(@lines);

    my $header_line = shift(@lines);
    my ($accession_header, @value_cols) = split /\t/, $header_line;

    my $now = DateTime->now();
    my $timestamp = $now->ymd()."T".$now->hms();

    my $operator = $c->user()->get_object()->get_first_name()." ".$c->user()->get_object()->get_last_name();

    my @fields;
    my @accession_names;
    my %analysis_data;

    my $html = qq | <style> th, td {padding: 10px;} </style> \n <table cellpadding="20" cellspacing="20"> |;

    $html .= "<br><tr>";
    for (my $m=0; $m<@value_cols; $m++) {
      $html .= "<th scope=\"col\">".($value_cols[$m])."</th>";
    }
    $html .= "</tr><tr>";
    foreach my $line (@lines) {
	      my ($accession_name, @values) = split /\t/, $line;
	      push @accession_names, $accession_name;

        #$html .= "<tr><td>".join("</td><td>", $accession_name)."</td>";

        for (my $k=0; $k<@value_cols; $k++) { 
          #print STDERR "adding  $values[$k] to column $value_cols[$k]\n";
          $html .= "<td>".($values[$k])."</td>";
        }

	      for(my $n=0; $n<@values; $n++) {
	         #print STDERR "Building hash for trait $accession_name and value $value_cols[$n]\n";
	          $analysis_data{$accession_name}->{$value_cols[$n]} = [ $values[$n], $timestamp, $operator, "", "" ];



	      }
        $html .= "</tr>"

    }
    $html .= "</table>";

    #print STDERR "Analysis data formatted: ".Dumper(\%analysis_data);

    return (\%analysis_data);
}
sub make_R_trait_name {
    my $trait = shift;

    if ($trait =~ /^\d/) {
	$trait = "X".$trait;
    }
    $trait =~ s/\&/\_/g;
    $trait =~ s/\%//g;
    $trait =~ s/\s/\_/g;
    $trait =~ s/\//\_/g;
    $trait =~ tr/ /./;
    $trait =~ tr/\//./;
    $trait =~ s/\:/\_/g;
    $trait =~ s/\|/\_/g;
    $trait =~ s/\-/\_/g;

    return $trait;
}

1;
