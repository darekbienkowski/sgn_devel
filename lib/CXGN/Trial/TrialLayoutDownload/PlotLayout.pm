package CXGN::Trial::TrialLayoutDownload::PlotLayout;

=head1 NAME

CXGN::Trial::TrialLayoutDownload::PlotLayout - an object to handle downloading a plot level trial layout. this should only be called from CXGN::Trial::TrialLayoutDownload

=head1 USAGE

my $trial_plot_layout = CXGN::Trial::TrialLayoutDownload::PlotLayout->new({
    bcs_schema=>$schema,
    treatment_trial_list=>\@treatment_trials,
});
my $result = $trial_plot_layout->retrieve();

=head1 DESCRIPTION

Will output an array of arrays, where each row is a plot in the trial. the columns are based on the supplied selected_cols and the columns will include any treatments (management factors) that are part of the trial.

=head1 AUTHORS

=cut

use strict;
use warnings;
use Moose;
use Try::Tiny;
use Data::Dumper;
use SGN::Model::Cvterm;
use CXGN::Stock;
use CXGN::Stock::Accession;

extends 'CXGN::Trial::TrialLayoutDownload';

has 'bcs_schema' => ( isa => 'Bio::Chado::Schema',
    is => 'rw',
    required => 1,
);

#This is a hashref of the cached trial_layout_json that comes from CXGN::Trial::TrialLayout
has 'design' => (
    isa => 'HashRef[Str]',
    is => 'rw',
    required => 1
);

has 'selected_cols' => (
    isa => 'HashRef[Str]',
    is => 'rw',
    required => 1
);

#This treatment_info_hash contains all the info needed to make and fill the columns for the various treatments (management factors). All of these lists are in the same order.
#A key called treatment_trial_list that is a arrayref of the CXGN::Trial entries that represent the treatments (management factors) in this trial
#A key called treatment_trial_names_list that is an arrayref of just the treatment (management factor) names
#A key called treatment_units_hash_list that is a arrayref of hashrefs where the hashrefs indicate the stocks that the treatment was applied to.
has 'treatment_info_hash' => (
    isa => 'HashRef',
    is => 'rw',
);

#This phenotype_performance_hash is a hashref of hashref where the top key is the trait name, subsequent key is the stock id, and subsequent object contains mean, mix, max, stdev, count, etc for that trait and stock
has 'phenotype_performance_hash' => (
    isa => 'HashRef',
    is => 'rw',
);

sub retrieve {
    my $self = shift;
    my $schema = $self->bcs_schema();
    my %selected_cols = %{$self->selected_cols};
    my %design = %{$self->design};
    my $treatment_info_hash = $self->treatment_info_hash || {};
    my $treatment_list = $treatment_info_hash->{treatment_trial_list} || [];
    my $treatment_name_list = $treatment_info_hash->{treatment_trial_names_list} || [];
    my $treatment_units_hash_list = $treatment_info_hash->{treatment_units_hash_list} || [];
    my $phenotype_performance_hash = $self->phenotype_performance_hash || {};
    my @trait_names = sort keys %$phenotype_performance_hash;
    my @output;

    my @possible_cols = ('plot_name','plot_id','accession_name','accession_id','plot_number','block_number','is_a_control','rep_number','range_number','row_number','col_number','seedlot_name','seed_transaction_operator','num_seed_per_plot','pedigree','location_name','trial_name','year','synonyms','tier','plot_geo_json');

    my @header;
    foreach (@possible_cols){
        if ($selected_cols{$_}){
            push @header, $_;
        }
    }
    foreach (@$treatment_name_list){
        push @header, "ManagementFactor:".$_;
    }
    foreach (@trait_names){
        push @header, $_;
    }
    push @output, \@header;

    foreach my $key (sort { $a <=> $b} keys %design) {
        my $design_info = $design{$key};
        my $line;
        foreach (@possible_cols){
            if ($selected_cols{$_}){
                if ($_ eq 'location_name'){
                    push @$line, $location_name;
                } elsif ($_ eq 'plot_geo_json'){
                    push @$line, $design_info->{"plot_geo_json"} ? encode_json $design_info->{"plot_geo_json"} : '';
                } elsif ($_ eq 'trial_name'){
                    push @$line, $trial_name;
                } elsif ($_ eq 'year'){
                    push @$line, $trial_year;
                } elsif ($_ eq 'tier'){
                    my $row = $design_info->{"row_number"} ? $design_info->{"row_number"} : '';
                    my $col = $design_info->{"col_number"} ? $design_info->{"col_number"} : '';
                    push @$line, $row."/".$col;
                } elsif ($_ eq 'synonyms'){
                    my $accession = CXGN::Stock::Accession->new({schema=>$schema, stock_id=>$design_info->{"accession_id"}});
                    push @$line, join ',', @{$accession->synonyms}
                } elsif ($_ eq 'pedigree'){
                    my $accession = CXGN::Stock->new({schema=>$schema, stock_id=>$design_info->{"accession_id"}});
                    push @$line, $accession->get_pedigree_string('Parents');
                } else {
                    push @$line, $design_info->{$_};
                }
            }
        }
        $line = $self->_add_treatment_to_line($treatment_stock_hashes, $line, $design_info->{'plot_name'});
        $line = $self->_add_trait_performance_to_line($selected_trait_names, $line, $fieldbook_trait_hash, $design_info);
        push @output, $line;
    }

    return \@output;
}

1;
