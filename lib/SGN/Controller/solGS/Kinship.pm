package SGN::Controller::solGS::Kinship;


use Moose;
use namespace::autoclean;

use Carp qw/ carp confess croak /;
use File::Slurp qw /write_file read_file/;
use File::Copy;
use File::Basename;
use File::Spec::Functions;
use File::Path qw / mkpath  /;


BEGIN { extends 'Catalyst::Controller' }


__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON'},
    );


sub kinship_analysis :Path('/kinship/analysis/') Args() {
    my ($self, $c) = @_;

    $c->stash->{template} = '/solgs/kinship/analysis.mas';
 
}


sub run_kinship :Path('kinship/run/analysis') Args() {
    my ($self, $c) = @_;

    my $pop_id        = $c->req->param('kinship_pop_id');
    my $protocol_id   = $c->req->param('genotyping_protocol_id'); ;
    my $trait_id      = $c->req->param('trait_id');
    my $combo_pops_id = $c->req->param('combo_pops_id');
    my $list_id       = $c->req->param('list_id');   
    my $dataset_id    = $c->req->param('dataset_id');
    my $data_structure = $c->req->param('data_structure');

    if ($list_id)
    {
	$c->stash->{data_structure} = 'list';
    }
    elsif ($dataset_id)
    {
	$c->stash->{data_structure} = 'dataset';	
    }
      
    $c->controller('solGS::genotypingProtocol')->stash_protocol_id($c, $protocol_id);
   
    $c->stash->{list_id}       = $list_id;
    $c->stash->{dataset_id}    = $dataset_id;
    $c->stash->{combo_pops_id} = $combo_pops_id;
    $c->stash->{trait_id}      = $trait_id;
    
    if ($combo_pops_id)
    {
	$c->controller('solGS::combinedTrials')->get_combined_pops_list($c, $combo_pops_id);
	$c->stash->{pops_ids_list} = $c->stash->{combined_pops_list};	
    }
   
    $self->run_kinship($c);	  	   
    
}


sub kinship_result :Path('/solgs/kinship/result/') Args() {
    my ($self, $c) = @_;   

    my $pop_id = $c->req->param('kinship_pop_id');
    my $protocol_id = $c->req->param('genotyping_protocol_id'); ;
    my $trait_id = $c->req->param('trait_id');
    
    my $kinship_files = $self->get_kinship_coef_files($c, $pop_id, $protocol_id, $trait_id);
    my $json_file = $kinship_files->{json_file};

    print STDERR "\njson_file: $json_file\n";
      
    if (-s $json_file)
    {
        $c->stash->{rest}{data_exists} = 1; 
	$c->stash->{rest}{data} = read_file($json_file);

	$self->stash_kinship_output($c);
	
    } 

}


sub get_kinship_coef_files {
    my ($self, $c, $pop_id, $protocol_id, $trait_id) = @_;

    $c->stash->{pop_id} = $pop_id;
    $c->stash->{genotyping_protocol_id} = $protocol_id;
    
    my $matrix_file;
    my $json_file;
    
    if ($trait_id)
    {
	$c->controller('solGS::solGS')->get_trait_details($$trait_id);
	$c->controller('solGS::Files')->relationship_matrix_adjusted_file($c);
	
	$json_file = $c->stash->{relationship_matrix_adjusted_json_file};
	$matrix_file = $c->stash->{relationship_matrix_adjusted_table_file};
    }
    else
    {
	$c->controller('solGS::Files')->relationship_matrix_file($c);
	$matrix_file = $c->stash->{relationship_matrix_table_file};
	$json_file = $c->stash->{relationship_matrix_json_file};
    }

    return {'json_file' => $json_file, 
	    'matrix_file' => $matrix_file
    };
}


sub run_kinship {
    my ($self, $c) = @_;

    $self->kinship_query_jobs_file($c);
    $c->stash->{prerequisite_jobs} = $c->stash->{kinship_query_jobs_file};
    
    $self->kinship_r_jobs_file($c);
    $c->stash->{dependent_jobs} = $c->stash->{kinship_r_jobs_file};
    
    $c->controller('solGS::solGS')->run_async($c);
    
}


sub kinship_r_jobs_file {
    my ($self, $c) = @_;

    $self->kinship_r_jobs($c);
    my $jobs = $c->stash->{kinship_r_jobs};
      
    my $temp_dir = $c->stash->{kinship_temp_dir};
    my $jobs_file =  $c->controller('solGS::Files')->create_tempfile($temp_dir, 'kinship-r-jobs-file');	   
   
    nstore $jobs, $jobs_file
	or croak "kinship r jobs : $! serializing kinship r jobs to $jobs_file";

    $c->stash->{kinship_r_jobs_file} = $jobs_file;
    
}


sub kinship_r_jobs {
    my ($self, $c) = @_;

    my $file_id = $c->stash->{file_id};
    
    $self->kinship_output_files($c);
    my $output_file = $c->stash->{kinship_output_files};

    $self->kinship_input_files($c);
    my $input_file = $c->stash->{kinship_input_files};

    $c->stash->{analysis_tempfiles_dir} = $c->stash->{kinship_temp_dir};
    
    $c->stash->{input_files}  = $input_file;
    $c->stash->{output_files} = $output_file;
    $c->stash->{r_temp_file}  = "kinship${file_id}";
    $c->stash->{r_script}     = 'R/solGS/kinship.r';
    
    $c->controller('solGS::solGS')->get_cluster_r_job_args($c);
    my $jobs  = $c->stash->{cluster_r_job_args};

    if (reftype $jobs ne 'ARRAY') 
    {
	$jobs = [$jobs];
    }

    $c->stash->{kinship_r_jobs} = $jobs;
   
}


sub kinship_query_jobs_file {
    my ($self, $c) = @_;

    $self->kinship_query_jobs($c);
    my $jobs = $c->stash->{kinship_query_jobs};
  
    my $temp_dir = $c->stash->{pca_temp_dir};
    my $jobs_file =  $c->controller('solGS::Files')->create_tempfile($temp_dir, 'kinship-query-jobs-file');	   
   
    nstore $jobs, $jobs_file
	or croak "kinship query jobs : $! serializing kinship query jobs to $jobs_file";

    $c->stash->{kinship_query_jobs_file} = $jobs_file;
    
}


sub kinship_query_jobs {
    my ($self, $c) = @_;

    $self->create_kinship_genotype_data_query_jobs($c);
    my $jobs = $c->stash->{kinship_geno_query_jobs};
    

    if (reftype $jobs ne 'ARRAY') 
    {
	$jobs = [$jobs];
    }

    $c->stash->{kinship_query_jobs} = $jobs;
}

sub create_kinship_genotype_data_query_jobs {
    my ($self, $c) = @_;

    my $data_str = $c->stash->{data_structure};
    my $protocol_id = $c->stash->{genotyping_protocol_id};
   
    if ($data_str =~ /list/)
    {
	$c->controller('solGS::List')->create_list_geno_data_query_jobs($c);
	$c->stash->{kinship_geno_query_jobs} = $c->stash->{list_geno_data_query_jobs};
    } 
    elsif ($data_str =~ /dataset/)
    {
	$c->controller('solGS::Dataset')->create_dataset_geno_data_query_jobs($c);
	$c->stash->{kinship_geno_query_jobs} = $c->stash->{dataset_geno_data_query_jobs};
    }
    else
    {
	if ($c->req->referer =~ /solgs\/selection\//) 
	{
	    $c->stash->{pops_ids_list} = [$c->stash->{training_pop_id}, $c->stash->{selection_pop_id}];
	}

	my $trials = $c->stash->{pops_ids_list} || [$c->stash->{training_pop_id}] || [$c->stash->{selection_pop_id}];

	$c->controller('solGS::solGS')->get_cluster_genotype_query_job_args($c, $trials, $protocol_id);
	$c->stash->{kinship_geno_query_jobs} = $c->stash->{cluster_genotype_query_job_args};
    }
    
}


sub stash_kinship_output {
    my ($self, $c) = @_;
    
    $self->prep_download_kinship_files($c);
      
    $c->stash->{rest}{kinship_table_file} = $c->stash->{download_kinship_table};
    $c->stash->{rest}{kinship_averages_file} = $c->stash->{download_kinship_averages};
    $c->stash->{rest}{inbreeding_file} = $c->stash->{download_inbreeding};
    
}


sub prep_download_kinship_files {
  my ($self, $c) = @_; 
  
  my $tmp_dir      = catfile($c->config->{tempfiles_subdir}, 'kinship');
  my $base_tmp_dir = catfile($c->config->{basepath}, $tmp_dir);
   
  mkpath ([$base_tmp_dir], 0, 0755);  

  $c->controller('solGS::Files')->relationship_matrix_adjusted_file($c);  
  my $kinship_txt_file  = $c->stash->{relationship_matrix_adjusted_file};
  #my $kinship_json_file = $c->stash->{relationship_matrix_json_file};

  $c->controller('solGS::Files')->inbreeding_coefficients_file($c); 
  my $inbreeding_file = $c->stash->{inbreeding_coefficients_file};

  $c->controller('solGS::Files')->average_kinship_file($c);
  my $ave_kinship_file = $c->stash->{average_kinship_file};
  
  $c->controller('solGS::Files')->copy_file($kinship_txt_file, $base_tmp_dir);					     
  $c->controller('solGS::Files')->copy_file($inbreeding_file, $base_tmp_dir); 
  $c->controller('solGS::Files')->copy_file($ave_kinship_file, $base_tmp_dir);  
										     
  $kinship_txt_file = fileparse($kinship_txt_file);
  $kinship_txt_file = catfile($tmp_dir, $kinship_txt_file);

  $inbreeding_file = fileparse($inbreeding_file);
  $inbreeding_file = catfile($tmp_dir, $inbreeding_file);

  $ave_kinship_file = fileparse($ave_kinship_file);
  $ave_kinship_file = catfile($tmp_dir, $ave_kinship_file);
  
  $c->stash->{download_kinship_table} = $kinship_txt_file;
  $c->stash->{download_kinship_averages}   = $ave_kinship_file;
  $c->stash->{download_inbreeding}    = $inbreeding_file;

}


sub begin : Private {
    my ($self, $c) = @_;

    $c->controller('solGS::Files')->get_solgs_dirs($c);
  
}

#####
1;
#####
