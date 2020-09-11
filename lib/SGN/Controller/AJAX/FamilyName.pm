
=head1 NAME

SGN::Controller::AJAX::Cross - a REST controller class to provide the
functions for adding crosses

=head1 DESCRIPTION

Add a new cross or upload a file containing crosses to add

=head1 AUTHOR

Jeremy Edwards <jde22@cornell.edu>
Lukas Mueller <lam87@cornell.edu>

=cut

package SGN::Controller::AJAX::Cross;

use Moose;
use Try::Tiny;
use DateTime;
use Time::HiRes qw(time);
use POSIX qw(strftime);
use Data::Dumper;
use File::Basename qw | basename dirname|;
use File::Copy;
use File::Slurp;
use File::Spec::Functions;
use Digest::MD5;
use List::MoreUtils qw /any /;
use CXGN::Stock::StockLookup;
use CXGN::FamilyName;
use Carp;
use File::Path qw(make_path);
use File::Spec::Functions qw / catfile catdir/;
use CXGN::Cross;
use JSON;
use Tie::UrlEncoder; our(%urlencode);
use LWP::UserAgent;
use HTML::Entities;
use URI::Encode qw(uri_encode uri_decode);
use Sort::Key::Natural qw(natsort);

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON', 'text/html' => 'JSON' },
);


sub get_family_parents :Path('/ajax/family/parents') :Args(1) {
    my $self = shift;
    my $c = shift;
    my $family_id = shift;
    my $schema = $c->dbic_schema("Bio::Chado::Schema");

    my $family = CXGN::FamilyName->new({schema=>$schema, family_stock_id=>$family_id});

    my $result = $family->get_family_parents();
    my @family_parents;
    foreach my $r (@$result){
        my ($female_parent_id, $female_parent_name, $female_stock_type, $male_parent_id, $male_parent_name, $male_stock_type) =@$r;
        push @family_parents, [qq{<a href="/stock/$female_parent_id/view">$female_parent_name</a>}, $female_stock_type, qq{<a href="/stock/$male_parent_id/view">$male_parent_name</a>}, $male_stock_type];
    }

    $c->stash->{rest} = { data => \@family_parents };

}


sub get_family_members :Path('/ajax/family/members') :Args(1) {
    my $self = shift;
    my $c = shift;
    my $family_id = shift;
    my $schema = $c->dbic_schema("Bio::Chado::Schema");

    my $family = CXGN::FamilyName->new({schema=>$schema, family_stock_id=>$family_id});

    my $result = $family->get_family_members();

    my @crosses;
    foreach my $r (@$result){
        my ($cross_id, $cross_name, $cross_type, $crossing_experiment_id, $crossing_experiment_name, $progeny_number) =@$r;
        push @crosses, {
            cross_id => $cross_id,
            cross_name => $cross_name,
            cross_type => $cross_type,
            crossing_experiment_id => $crossing_experiment_id,
            crossing_experiment_name => $crossing_experiment_name,
            progeny_number => $progeny_number
        };
    }

    $c->stash->{rest} = { data => \@crosses };

}


sub get_all_progenies :Path('/ajax/family/all_progenies') :Args(1) {
    my $self = shift;
    my $c = shift;
    my $family_id = shift;
    my $schema = $c->dbic_schema("Bio::Chado::Schema");

    my $family = CXGN::FamilyName->new({schema=>$schema, family_stock_id=>$family_id});

    my $result = $family->get_all_progenies();

    my @progenies;
    foreach my $r (@$result){
        my ($progeny_id, $progeny_name, $cross_id, $cross_name) =@$r;
        push @progenies, {
            progeny_id => $progeny_id,
            progeny_name => $progeny_name,
            cross_id => $cross_id,
            cross_name => $cross_name,
        };
    }

    $c->stash->{rest} = { data => \@progenies };

}


###
1;
###
