package CXGN::Trial::Download::Plugin::ExcelBasic;

=head1 NAME

CXGN::Trial::Download::Plugin::ExcelBasic

=head1 SYNOPSIS

This plugin module is loaded from CXGN::Trial::Download

------------------------------------------------------------------

For downloading a trial's xls spreadsheet for collecting phenotypes (as used
from SGN::Controller::AJAX::PhenotypesDownload->create_phenotype_spreadsheet):

my $rel_file = $c->tempfile( TEMPLATE => 'download/downloadXXXXX');
my $tempfile = $c->config->{basepath}."/".$rel_file.".xls";
my $create_spreadsheet = CXGN::Trial::Download->new({
    bcs_schema => $schema,
    trial_list => \@trial_ids,
    trait_list => \@trait_list,
    filename => $tempfile,
    format => "ExcelBasic",
    data_level => $data_level,
    sample_number => $sample_number,
    predefined_columns => $predefined_columns,
    treatment_project_id => $treatment_project_id
});
$create_spreadsheet->download();
$c->stash->{rest} = { filename => $urlencode{$rel_file.".xls"} };


=head1 AUTHORS

=cut

use Moose::Role;
use JSON;
use Data::Dumper;

sub verify {
    my $self = shift;
    return 1;
}


sub download {
    my $self = shift;

    my $schema = $self->bcs_schema();
    my @trial_ids = @{$self->trial_list()};
    my @trait_list = @{$self->trait_list()};
    my $spreadsheet_metadata = $self->file_metadata();

    my $workbook = Spreadsheet::WriteExcel->new($self->filename());
    my $ws = $workbook->add_worksheet();

    # generate worksheet headers
    #
    my $bold = $workbook->add_format();
    $bold->set_bold();

    my %treatment_project_hash = $self->treatment_project_hash() ? %{$self->treatment_project_hash()} : undef;

    my @predefined_columns;
    my $submitted_predefined_columns;
    my $json = JSON->new();
    if ($self->predefined_columns) {
        $submitted_predefined_columns = $self->predefined_columns;
        foreach (@$submitted_predefined_columns) {
            foreach my $header_predef_col (keys %{$_}) {
                if ($_->{$header_predef_col}) {
                    push @predefined_columns, $header_predef_col;
                }
            }
        }
    }
    #print STDERR Dumper \@predefined_columns;
    my $predefined_columns_json = $json->encode(\@predefined_columns);

    my @trial_names;
    my @trial_design_types;
    my @trial_descriptions;
    my @trial_locations;
    my @trial_treatment_names;
    foreach (@trial_ids){
        my $trial = CXGN::Trial->new({bcs_schema => $schema, trial_id => $_} );
        my $treatment_id = $treatment_project_hash{$_};
        my $treatment_trial;
        my $treatment_name = "";
        if ($treatment_id){
            $treatment_trial = CXGN::Trial->new({bcs_schema => $schema, trial_id => $treatment_id});
            $treatment_name = $treatment_trial->get_name();
        }
        push @trial_names, $trial->get_name;
        push @trial_design_types, $trial->get_design_type;
        push @trial_descriptions, $trial->get_description;
        push @trial_locations, $trial->get_location()->[1];
        push @trial_treatment_names, $treatment_name;
    }

    $ws->write(0, 0, 'Spreadsheet ID'); $ws->write('0', '1', 'ID'.$$.time());
    $ws->write(0, 2, 'Spreadsheet format'); $ws->write(0, 3, "BasicExcel");
    $ws->write(1, 0, 'Trial name(s)'); $ws->write(1, 1, join(",", @trial_names), $bold);
    $ws->write(3, 2, 'Design Type(s)'); $ws->write(3, 3, join(",", @trial_design_types), $bold);
    $ws->write(2, 0, 'Description(s)'); $ws->write(2, 1, join(",", @trial_descriptions), $bold);
    $ws->write(3, 0, "Trial location(s)");  $ws->write(3, 1, join(",", @trial_locations), $bold);
    $ws->write(4, 0, "Predefined Columns");  $ws->write(4, 1, $predefined_columns_json, $bold);
    $ws->write(4, 2, "Treatment(s)"); $ws->write(4, 3, join(",", @trial_treatment_names));
    $ws->write(1, 2, 'Operator');       $ws->write(1, 3, "Enter operator here");
    $ws->write(2, 2, 'Date');           $ws->write(2, 3, "Enter date here");
    $ws->data_validation(2,3, { validate => "date", criteria => '>', value=>'1000-01-01' });

    my $num_col_before_traits;
    if ($self->data_level eq 'plots') {
        $num_col_before_traits = 6;
        @column_headers = ("plot_name", "accession_name", "plot_number", "block_number", "is_a_control", "rep_number", "treatment_name");
    } elsif ($self->data_level eq 'plants') {
        $num_col_before_traits = 7;
        @column_headers = ("plant_name", "plot_name", "accession_name", "plot_number", "block_number", "is_a_control", "rep_number", "treatment_name");
    } elsif ($self->data_level eq 'subplots') {
        $num_col_before_traits = 7;
        @column_headers = ("subplot_name", "plot_name", "accession_name", "plot_number", "block_number", "is_a_control", "rep_number", "treatment_name");
    } elsif ($self->data_level eq 'plants_subplots') {
        $num_col_before_traits = 8;
        @column_headers = ("plant_name", "subplot_name", "plot_name", "accession_name", "plot_number", "block_number", "is_a_control", "rep_number", "treatment_name");
    }

    my $num_col_b = $num_col_before_traits;
    if (scalar(@predefined_columns) > 0) {
        push (@column_headers, @predefined_columns);
        $num_col_before_traits += scalar(@predefined_columns);
    }
    for(my $n=0; $n<scalar(@column_headers); $n++) {
        $ws->write(6, $n, $column_headers[$n]);
    }

    my $line = 7;
    foreach (@trial_ids){
        my $trial = CXGN::Trial->new({bcs_schema => $schema, trial_id => $_} );
        my $trial_layout = CXGN::Trial::TrialLayout->new({schema => $schema, trial_id => $_} );
        my $design = $trial_layout->get_design();

        if (!$design) {
            return "No design found for trial: ".$trial->get_name;
        }
        my %design = %{$design};

        my $treatment_id = $treatment_project_hash{$_};
        my $selected_treatment_trial_name = "";
        my $treatment_trial;
        if ($treatment_id){
            $treatment_trial = CXGN::Trial->new({bcs_schema => $schema, trial_id => $treatment_id});
        }

        if ($self->data_level eq 'plots') {

            my %treatment_plot_hash;
            if ($treatment_trial){
                my $treatment_plots = $treatment_trial->get_plots();
                $selected_treatment_trial_name = $treatment_trial->get_name();
                foreach (@$treatment_plots){
                    $treatment_plot_hash{$_->[1]}++;
                }
            }

            my @ordered_plots = sort { $a <=> $b} keys(%design);
            for(my $n=0; $n<@ordered_plots; $n++) {
                my %design_info = %{$design{$ordered_plots[$n]}};

                $ws->write($line, 0, $design_info{plot_name});
                $ws->write($line, 1, $design_info{accession_name});
                $ws->write($line, 2, $design_info{plot_number});
                $ws->write($line, 3, $design_info{block_number});
                $ws->write($line, 4, $design_info{is_a_control});
                $ws->write($line, 5, $design_info{rep_number});

                if (exists($treatment_plot_hash{$design_info{plot_name}})){
                    $ws->write($line, $num_col_b-1, $selected_treatment_trial_name);
                }

                if (scalar(@predefined_columns) > 0) {
                    my $pre_col_ind = $num_col_b;
                    foreach (@$submitted_predefined_columns) {
                        foreach my $header_predef_col (keys %{$_}) {
                            if ($_->{$header_predef_col}) {
                                $ws->write($line, $pre_col_ind, $_->{$header_predef_col});
                                $pre_col_ind++;
                            }
                        }
                    }
                }

                $line++;
            }
        } elsif ($self->data_level eq 'plants') {

            my %treatment_plant_hash;
            if($treatment_trial){
                my $treatment_plants = $treatment_trial->get_plants();
                $selected_treatment_trial_name = $treatment_trial->get_name();
                foreach (@$treatment_plants){
                    $treatment_plant_hash{$_->[1]}++;
                }
            }

            my @ordered_plots = sort { $a <=> $b} keys(%design);
            for(my $n=0; $n<@ordered_plots; $n++) {
                my %design_info = %{$design{$ordered_plots[$n]}};
                my $plant_names = $design_info{plant_names};

                my $sampled_plant_names;
                if ($self->sample_number) {
                    my $sample_number = $self->sample_number;
                    foreach (@$plant_names) {
                        if ( $_ =~ m/_plant_(\d+)/) {
                            if ($1 <= $sample_number) {
                                push @$sampled_plant_names, $_;
                            }
                        }
                    }
                } else {
                    $sampled_plant_names = $plant_names;
                }

                foreach (@$sampled_plant_names) {
                    $ws->write($line, 0, $_);
                    $ws->write($line, 1, $design_info{plot_name});
                    $ws->write($line, 2, $design_info{accession_name});
                    $ws->write($line, 3, $design_info{plot_number});
                    $ws->write($line, 4, $design_info{block_number});
                    $ws->write($line, 5, $design_info{is_a_control});
                    $ws->write($line, 6, $design_info{rep_number});

                    if (exists($treatment_plant_hash{$_})){
                        $ws->write($line, $num_col_b-1, $selected_treatment_trial_name);
                    }

                    if (scalar(@predefined_columns) > 0) {
                        my $pre_col_ind = $num_col_b;
                        foreach (@$submitted_predefined_columns) {
                            foreach my $header_predef_col (keys %{$_}) {
                                if ($_->{$header_predef_col}) {
                                    $ws->write($line, $pre_col_ind, $_->{$header_predef_col});
                                    $pre_col_ind++;
                                }
                            }
                        }
                    }

                    $line++;
                }
            }
        } elsif ($self->data_level eq 'subplots') {

            my %treatment_subplot_hash;
            if($treatment_trial){
                my $treatment_subplots = $treatment_trial->get_subplots();
                $selected_treatment_trial_name = $treatment_trial->get_name();
                foreach (@$treatment_subplots){
                    $treatment_subplot_hash{$_->[1]}++;
                }
            }

            my @ordered_plots = sort { $a <=> $b} keys(%design);
            for(my $n=0; $n<@ordered_plots; $n++) {
                my %design_info = %{$design{$ordered_plots[$n]}};
                my $subplot_names = $design_info{subplot_names};

                my $sampled_subplot_names;
                if ($self->sample_number) {
                    my $sample_number = $self->sample_number;
                    foreach (@$subplot_names) {
                        if ( $_ =~ m/_subplot_(\d+)/) {
                            if ($1 <= $sample_number) {
                                push @$sampled_subplot_names, $_;
                            }
                        }
                    }
                } else {
                    $sampled_subplot_names = $subplot_names;
                }

                foreach (@$sampled_subplot_names) {
                    $ws->write($line, 0, $_);
                    $ws->write($line, 1, $design_info{plot_name});
                    $ws->write($line, 2, $design_info{accession_name});
                    $ws->write($line, 3, $design_info{plot_number});
                    $ws->write($line, 4, $design_info{block_number});
                    $ws->write($line, 5, $design_info{is_a_control});
                    $ws->write($line, 6, $design_info{rep_number});

                    if (exists($treatment_subplot_hash{$_})){
                        $ws->write($line, $num_col_b-1, $selected_treatment_trial_name);
                    }

                    if (scalar(@predefined_columns) > 0) {
                        my $pre_col_ind = $num_col_b;
                        foreach (@$submitted_predefined_columns) {
                            foreach my $header_predef_col (keys %{$_}) {
                                if ($_->{$header_predef_col}) {
                                    $ws->write($line, $pre_col_ind, $_->{$header_predef_col});
                                    $pre_col_ind++;
                                }
                            }
                        }
                    }

                    $line++;
                }
            }
        } elsif ($self->data_level eq 'plants_subplots') {
            my %treatment_plant_hash;
            if($treatment_trial){
                my $treatment_plants = $treatment_trial->get_plants();
                $selected_treatment_trial_name = $treatment_trial->get_name();
                foreach (@$treatment_plants){
                    $treatment_plant_hash{$_->[1]}++;
                }
            }

            my @ordered_plots = sort { $a <=> $b} keys(%design);
            for(my $n=0; $n<@ordered_plots; $n++) {
                my %design_info = %{$design{$ordered_plots[$n]}};
                my $subplot_plant_names = $design_info{subplots_plant_names};
                foreach my $s (sort keys %$subplot_plant_names){
                    my $plant_names = $subplot_plant_names->{$s};

                    foreach (sort @$plant_names) {
                        $ws->write($line, 0, $_);
                        $ws->write($line, 1, $s);
                        $ws->write($line, 2, $design_info{plot_name});
                        $ws->write($line, 3, $design_info{accession_name});
                        $ws->write($line, 4, $design_info{plot_number});
                        $ws->write($line, 5, $design_info{block_number});
                        $ws->write($line, 6, $design_info{is_a_control});
                        $ws->write($line, 7, $design_info{rep_number});

                        if (exists($treatment_plant_hash{$_})){
                            $ws->write($line, $num_col_b-1, $selected_treatment_trial_name);
                        }

                        if (scalar(@predefined_columns) > 0) {
                            my $pre_col_ind = $num_col_b;
                            foreach (@$submitted_predefined_columns) {
                                foreach my $header_predef_col (keys %{$_}) {
                                    if ($_->{$header_predef_col}) {
                                        $ws->write($line, $pre_col_ind, $_->{$header_predef_col});
                                        $pre_col_ind++;
                                    }
                                }
                            }
                        }

                        $line++;
                    }
                }
            }
        }
    }

    # write traits and format trait columns
    #
    my $lt = CXGN::List::Transform->new();

    my $transform = $lt->transform($schema, "traits_2_trait_ids", \@trait_list);

    if (@{$transform->{missing}}>0) {
    	print STDERR "Warning: Some traits could not be found. ".join(",",@{$transform->{missing}})."\n";
    }
    my @trait_ids = @{$transform->{transform}};

    my %cvinfo = ();
    foreach my $t (@trait_ids) {
        my $trait = CXGN::Trait->new( { bcs_schema=> $schema, cvterm_id => $t });
        $cvinfo{$trait->display_name()} = $trait;
        #print STDERR "**** Trait = " . $trait->display_name . "\n\n";
    }

    for (my $i = 0; $i < @trait_list; $i++) {
        #if (exists($cvinfo{$trait_list[$i]})) {
            #$ws->write(5, $i+6, $cvinfo{$trait_list[$i]}->display_name());
            $ws->write(6, $i+$num_col_before_traits, $trait_list[$i]);
        #}
        #else {
        #    print STDERR "Skipping output of trait $trait_list[$i] because it does not exist\n";
        #    next;
        #}

        for (my $n = 0; $n < $line; $n++) {
            if ($cvinfo{$trait_list[$i]}) {
                my $format = $cvinfo{$trait_list[$i]}->format();
                if ($format eq "numeric") {
                    $ws->data_validation($n+7, $i+$num_col_before_traits, { validate => "any" });
                }
                elsif ($format =~ /\,/) {  # is a list
                    $ws->data_validation($n+7, $i+$num_col_before_traits, {
                        validate => 'list',
                        value    => [ split ",", $format ]
                    });
                }
            }
        }
    }

    $workbook->close();

}

1;
