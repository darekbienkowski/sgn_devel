
=head1 NAME

CXGN::Location - helper class for locations

=head1 SYNOPSYS

 my $location = CXGN::Location->new( { bcs_schema => $schema } );
 $location->set_altitude(280);
 etc.

=head1 AUTHOR

Bryan Ellerbrock <bje24@cornell.edu>

=head1 METHODS

=cut

package CXGN::Location;

use Moose;
use Data::Dumper;
use Try::Tiny;
use SGN::Model::Cvterm;

has 'bcs_schema' => (
	isa => 'Bio::Chado::Schema',
	is => 'rw',
    required => 1,
);

has 'nd_geolocation_id' => (
	isa => "Int",
	is => 'rw',
);

has 'name' => (
    isa => 'Str',
	is => 'rw',
);

has 'abbreviation' => (
    isa => 'Maybe[Str]',
	is => 'rw',
);

has 'country' => (
    isa => 'Maybe[Str]',
	is => 'rw',
);

has 'type' => (
    isa => 'Maybe[Str]',
	is => 'rw',
);

has 'latitude' => (
    isa => 'Maybe[Int]',
	is => 'rw',
);

has 'longitude' => (
    isa => 'Maybe[Int]',
	is => 'rw',
);

has 'altitude' => (
    isa => 'Maybe[Int]',
	is => 'rw',
);

sub get_location {
    my $self = shift;
    my $id = shift;

    my $row = $self->bcs_schema->resultset("NaturalDiversity::NdGeolocation")->find( { nd_geolocation_id => $id });

    if ($row){
        $self->name($row->description());
	    print STDERR "Found location ".$self->description()." with id ".$self->nd_geolocation_id()."\n";
        #$self->abbreviation($row->value());
        #$self->country($row->description());
        #$self->type($row->description());
        $self->latitude($row->latitude());
        $self->longitude($row->longitude());
        $self->altitude($row->altitude());
        return $self;
    }
    else {
	    die "No locations were found with id ".$self->nd_geolocation_id()."\n";
    }
}

sub add_location {
	my $self = shift;
    my $params = shift;
    my $schema = $self->bcs_schema();

    my $description = $params->{description};
    my $longitude   = $params->{longitude};
    my $latitude    = $params->{latitude};
    my $altitude    = $params->{altitude};

    my $exists = $schema->resultset('NaturalDiversity::NdGeolocation')->search( { description => $description } )->count();

    if ($exists > 0) {
	    return { error => "The location - $description - already exists. Please choose another name." };
    }

    if ( ($latitude && $latitude !~ /^-?[0-9.]+$/) || ($latitude && $latitude < -90) || ($latitude && $latitude > 90)) {
	    return { error => "Latitude (in degrees) must be a number between 90 and -90." };
    }

    if ( ($longitude && $longitude !~ /^-?[0-9.]+$/) || ($longitude && $longitude < -180) || ($longitude && $longitude > 180)) {
	    return { error => "Longitude (in degrees) must be a number between 180 and -180." };
    }

    if ( ($altitude && $altitude !~ /^[0-9.]+$/) || ($altitude && $altitude < -418) || ($altitude && $altitude > 8848) ) {
        return { error => "Altitude (in meters) must be a number between -418 (Dead Sea) and 8,848 (Mt. Everest)." };
    }

    my ($new_row, $error);
	try {
        $new_row = $schema->resultset('NaturalDiversity::NdGeolocation')
          ->new({
    	     description => $description,
    	    });

        if ($longitude) { $new_row->longitude($longitude); }
        if ($latitude) { $new_row->latitude($latitude); }
        if ($altitude) { $new_row->altitude($altitude); }

        $new_row->insert();
    }
    catch {
        $error =  $_;
    };

    if ($error) {
        print STDERR "Error creating location $description: $error\n";
        return { error => $error };
    } else {
        print STDERR "Location $description added successfully\n";
        return { success => "Location $description added successfully\n" };
    }
}

sub delete_location {
    my $self = shift;
    my $id = shift;

    my $rs = $self->bcs_schema->resultset("NaturalDiversity::NdGeolocation")->search({ nd_geolocation_id=> $id });
    my $name = $rs->first()->description();
    my @experiments = $rs->first()->nd_experiments;
    #print STDERR "Associated experiments: ".Dumper(@experiments)."\n";

    if (@experiments) {
        my $error = "Location $name cannot be deleted because there are ".scalar @experiments." measurements associated with it from at least one trial.\n";
	    print STDERR $error;
	    return { error => $error };
	}
	else {
	    $rs->first->delete();
	    return { success => "Location $name was successfully deleted.\n" };
	}
}

=head2 accessors get_name(), set_name()

 Usage:
 Desc:         retrieve and store location name from/to database
 Ret:
 Args:
 Side Effects: setter modifies the database
 Example:



sub get_name {
    my $self = shift;
    my $row = $self->bcs_schema->resultset("NaturalDiversity::NdGeolocation")->find( { nd_geolocation_id => $self->nd_geolocation_id() });

    if ($row) {
	return $row->description();
    }
}
=cut
sub set_name {
    my $self = shift;
    my $name = shift;
    my $row = $self->bcs_schema->resultset("NaturalDiversity::NdGeolocation")->find( { nd_geolocation_id => $self->nd_geolocation_id() });
    if ($row) {
	    $row->description($name);
	    $row->update();
    }
}

=head2 accessors get_latitude(), set_latitude()

 Usage:
 Desc:         retrieve and store location latitude from/to database
 Ret:
 Args:
 Side Effects: setter modifies the database
 Example:



sub get_latitude {
    my $self = shift;
    my $row = $self->bcs_schema->resultset("NaturalDiversity::NdGeolocation")->find( { nd_geolocation_id => $self->nd_geolocation_id() });

    if ($row) {
	return $row->latitude();
    }
}
=cut
sub set_latitude {
    my $self = shift;
    my $latitude = shift;
    my $row = $self->bcs_schema->resultset("NaturalDiversity::NdGeolocation")->find( { nd_geolocation_id => $self->nd_geolocation_id() });
    if ($row) {
	    $row->latitude($latitude);
	    $row->update();
    }
}

=head2 accessors get_longitude(), set_longitude()

 Usage:
 Desc:         retrieve and store location longitude from/to database
 Ret:
 Args:
 Side Effects: setter modifies the database
 Example:



sub get_longitude {
    my $self = shift;
    my $row = $self->bcs_schema->resultset("NaturalDiversity::NdGeolocation")->find( { nd_geolocation_id => $self->nd_geolocation_id() });

    if ($row) {
	return $row->longitude();
    }
}
=cut
sub set_longitude {
    my $self = shift;
    my $longitude = shift;
    my $row = $self->bcs_schema->resultset("NaturalDiversity::NdGeolocation")->find( { nd_geolocation_id => $self->nd_geolocation_id() });
    if ($row) {
	    $row->longitude($longitude);
	    $row->update();
    }
}

=head2 accessors get_altitude(), set_altitude()

 Usage:
 Desc:         retrieve and store location altitude from/to database
 Ret:
 Args:
 Side Effects: setter modifies the database
 Example:



sub get_altitude {
    my $self = shift;
    my $row = $self->bcs_schema->resultset("NaturalDiversity::NdGeolocation")->find( { nd_geolocation_id => $self->nd_geolocation_id() });

    if ($row) {
	return $row->altitude();
    }
}
=cut
sub set_altitude {
    my $self = shift;
    my $altitude = shift;
    my $row = $self->bcs_schema->resultset("NaturalDiversity::NdGeolocation")->find( { nd_geolocation_id => $self->nd_geolocation_id() });
    if ($row) {
	    $row->altitude($altitude);
	    $row->update();
    }
}

1;
