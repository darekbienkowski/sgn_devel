
package SGN::Controller::Access;

use Moose;
use CXGN::Access;

BEGIN { extends 'Catalyst::Controller'; }

sub :Path('/access/manage') Args(0) {
    my $self = shift;
    my $c = shift;

    my $message;
    my $sp_person_id = $c->user() ? $c->user()->get_object->get_sp_person_id() : undef;
    if (!$c->stash->{access}->check_user("access_manage", $sp_person_id)) {
	$message = "You don't have sufficient privileges to access this page.";
    }

    else {
	print STDERR "Access granted to page /access \n";
    }

    $c->stash->{message} = $message;

    $c->stash->{template} = '/site/access/manage.mas';

}

1;
