#!/usr/bin/env perl


=head1 NAME

 AddSpProductProfilePropertyCvAndCvterm

=head1 SYNOPSIS

mx-run AddProductProfilePropertyCvAndCvterm [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION
This patch adds sp_product_profile_property cv and product_profile_json cvterm
This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

Titima Tantikanjana <tt15@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package AddProductProfilePropertyCvAndCvterm;

use Moose;
use Bio::Chado::Schema;
use Try::Tiny;
extends 'CXGN::Metadata::Dbpatch';


has '+description' => ( default => <<'' );
This patch adds the 'sp_product_profile_property' cv and 'product_profile_json' sp_product_profile_property cvterm

has '+prereq' => (
	default => sub {
        [],
    },

);

sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    print STDOUT "\nExecuting the SQL commands.\n";
    my $schema = Bio::Chado::Schema->connect( sub { $self->dbh->clone } );
    my $cv_rs = $schema->resultset("Cv::Cv");
    my $cvterm_rs = $schema->resultset("Cv::Cvterm");

    print STDERR "CREATING CV...\n";
    my $cv = $cv_rs->find_or_create({ name => 'sp_product_profile_property' });

    print STDERR "ADDING CVTERMS...\n";
	my $terms = {
	    'sp_product_profile_property' => [
            'product_profile_json'],
	};

	foreach my $t (keys %$terms){
		foreach (@{$terms->{$t}}){
			$schema->resultset("Cv::Cvterm")->create_with({
				name => $_,
				cv => $t
			});
		}
	}

    print "You're done!\n";
}


####
1; #
####
