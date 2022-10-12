
package SGN::Controller::AJAX::Search::Vector;

use Moose;

BEGIN { extends 'Catalyst::Controller::REST' }

use Data::Dumper;
use JSON;
use CXGN::Stock::SearchVector;

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON' },
   );


sub stock_search :Path('/ajax/search/vectors') Args(0) {
    my $self = shift;
    my $c = shift;
    print STDERR "Stock search AJAX\n";
    my $schema = $c->dbic_schema("Bio::Chado::Schema", 'sgn_chado');
    my $people_schema = $c->dbic_schema("CXGN::People::Schema");
    my $phenome_schema = $c->dbic_schema("CXGN::Phenome::Schema");
    my $params = $c->req->params() || {};

    my $owner_first_name;
    my $owner_last_name;
    if (exists($params->{person} ) && $params->{person} ) {
        my $editor = $params->{person};
        my @split = split ',' , $editor;
        $owner_first_name = $split[0];
        $owner_last_name = $split[1];
        $owner_first_name =~ s/\s+//g;
        $owner_last_name =~ s/\s+//g;
    }

    my $rows = $params->{length};
    my $offset = $params->{start};
    my $limit = defined($offset) && defined($rows) ? ($offset+$rows)-1 : undef;

    my $stockprops_values = $params->{editable_stockprop_values} ? decode_json $params->{editable_stockprop_values} : {};


    #This defines the stockprops that will be returned in the results.
    my $stockprop_columns_view = $params->{extra_stockprop_columns_view} ? decode_json $params->{extra_stockprop_columns_view} : {};
    my $stockprop_columns_view_array = $params->{stockprop_extra_columns_view_array} ? decode_json $params->{stockprop_extra_columns_view_array} : [];
    #print STDERR Dumper $stockprop_columns_view;
    print STDERR Dumper $stockprops_values;
    print STDERR "\n\n->{stock_type}\n\n". Dumper $params->{stock_type};

    my $stock_search = CXGN::Stock::SearchVector->new({
        bcs_schema=>$schema,
        people_schema=>$people_schema,
        phenome_schema=>$phenome_schema,
        match_type=>$params->{any_name_matchtype},
        match_name=>$params->{any_name},
        stock_type_name=>$params->{stock_type},
        stockprops_values=>$stockprops_values,
        stockprop_columns_view=>$stockprop_columns_view,
        limit=>$limit,
        offset=>$offset,
        minimal_info=>$params->{minimal_info},
        display_pedigree=>0
    });
    my ($result, $records_total) = $stock_search->search();

    my $draw = $params->{draw};
    if ($draw){
        $draw =~ s/\D//g; # cast to int
    }

    #print STDERR Dumper $result;
    my @return;
    foreach (@$result){
        if (!$params->{minimal_info}){
            my $stock_id = $_->{stock_id};
            my $uniquename = $_->{uniquename};
            my $type = $_->{stock_type};
            my $organism = $_->{species};
            my $synonym_string = join ',', @{$_->{synonyms}};
            my @owners = @{$_->{owners}};
            my @owners_html;
            foreach (@owners){
                push @owners_html ,'<a href="/solpeople/personal-info.pl?sp_person_id='.$_->[0].'">'.$_->[2].' '.$_->[3].'</a>';
            }
            my $owners_string = join ', ', @owners_html;

            my @return_row;
            if ($type eq "cross"){
                @return_row = ( "<a href=\"/cross/$stock_id\">$uniquename</a>", $type, $organism, $synonym_string, $owners_string );
            }  elsif ($type eq "family_name"){
                @return_row = ( "<a href=\"/family/$stock_id\">$uniquename</a>", $type, $organism, $synonym_string, $owners_string );
            } elsif ($type eq "seedlot"){
                @return_row = ( "<a href=\"/breeders/seedlot/$stock_id\">$uniquename</a>", $type, $organism, $synonym_string, $owners_string );
            } else {
                @return_row = ( "<a href=\"/stock/$stock_id/view\">$uniquename</a>", $type, $organism, $synonym_string, $owners_string );
            }
            foreach my $property (@$stockprop_columns_view_array){
                push @return_row, $_->{$property};
            }
            push @return, \@return_row;

        } else {
            push @return, [$_->{stock_id}, $_->{uniquename}];
        }
    }

    #print STDERR Dumper \@return;
    $c->stash->{rest} = { data => [ @return ], draw => $draw, recordsTotal => $records_total,  recordsFiltered => $records_total };
}

1;
