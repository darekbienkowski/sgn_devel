
=head1 NAME

CXGN::Calendar - helper class for trials

=head1 SYNOPSYS

 my $calendar_funcs = CXGN::Calendar->new( { bcs_schema => $schema } );
 $calendar_funcs->check_value_format("2012/01/01 00:00:00");

 etc.

=head1 AUTHOR

Nicolas Morales <nm529@cornell.edu>

=head1 METHODS

=cut

package CXGN::Calendar;

use Moose;
use Try::Tiny;
use SGN::Model::Cvterm;
use Time::Piece;
use Time::Seconds;
use Data::Dumper;


sub check_value_format {
	my $self = shift;
    my $value = shift;

    if ($value) {
        #Events saved through the calendar will have this format
        if ($value =~ /^{"\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d","\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d","/) {
            return $value;
        }
        #Dates saved through the trial 'Add Harvest Date' or 'Add Planting Date' will have this format
        elsif ($value =~ /^\d\d\d\d\/\d\d\/\d\d\s\d\d:\d\d:\d\d$/) {
            $value = $self->format_time($value)->datetime;
            return '{"'.$value.'","'.$value.'","","#"}';
        }
        #Historical dates in teh database often have this format
        elsif ($value =~ /^(\d{4})-(Jan|January|Feb|February|March|Mar|April|Apr|May|June|Jun|July|Jul|August|Aug|September|Sep|October|Oct|November|Nov|December|Dec)-(\d)/) {
            $value = $self->format_time($value)->datetime;
            return '{"'.$value.'","'.$value.'","","#"}';
        }
        else {
            return;
        }
    } else {
	   return;
    }
}

sub parse_calendar_array {
	my $self = shift;
    my $raw_value = shift;

    $raw_value =~ tr/{}"//d;
    my @calendar_array = split(/,/, $raw_value);
    return @calendar_array;
}

#Displaying 00:00:00 time on mouseover and mouseclick is ugly, so this sub is used to determine date display format.
sub format_display_date {
    my $self = shift;
    my $date_display;
    my $formatted_time = shift;

    if ($formatted_time->hms('') == '000000') {
	$date_display = $formatted_time->strftime("%Y-%B-%d");
    } else {
	$date_display = $formatted_time->strftime("%Y-%B-%d %H:%M:%S");
    }
    return $date_display;
}

#FullCalendar's end datetime is exclusive for allday events in the month view. Since all events in the month view are allday = 1, a full day must be added so that it is displayed correctly on the calendar. In the agendaWeek view, not all events are allday = 1, so the end is only modified for allday events.
sub calendar_end_display {
    my $self = shift;
    my $formatted_time = shift;
    my $view = shift;
    my $allday = shift;

    my $end_time;
    $end_time = $formatted_time->epoch;
    if ($view eq 'month' || ($view eq 'agendaWeek' && $allday == 1)) {
	$end_time += ONE_DAY;
    }
    $end_time = Time::Piece->strptime($end_time, '%s')->datetime;
    return $end_time;
}

#On the agendaWeek view, events with start dates with 00:00:00 time are displayed as allDay=true.
sub determine_allday {
    my $self = shift;
    my $allday;
    my $formatted_time = shift;

    if ($formatted_time->hms('') == '000000') {
	$allday = 1;
    } else {
	$allday = 0;
    }
    return $allday;
}

#This function is used to return a Time::Piece object, which is useful for format consistency. It can take a variety of formats, which is important to match historic date data in teh database.
sub format_time {
	my $self = shift;
    my $input_time = shift;

    #print STDERR $input_time."\n";

    my $formatted_time;

    if ($input_time =~ /^\d{4}-\d\d-\d\d$/) {
        #print STDERR '1 '.$input_time."\n";
        $formatted_time = Time::Piece->strptime($input_time, '%Y-%m-%d');
    }
    if ($input_time =~ /^\d\d\d\d\/\d\d\/\d\d\s\d\d:\d\d:\d\d$/) {
        #print STDERR '2 '.$input_time."\n";
        $formatted_time = Time::Piece->strptime($input_time, '%Y/%m/%d %H:%M:%S');
    }
    if ($input_time =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/) {
        #print STDERR '3 '.$input_time."\n";
        $formatted_time = Time::Piece->strptime($input_time, '%Y-%m-%dT%H:%M:%S');
    }
    if ($input_time =~ /^(\d{4})-(Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-(\d{2})$/) {
        #print STDERR '4 '.$input_time."\n";
        $formatted_time = Time::Piece->strptime($input_time, '%Y-%b-%d');
    }
    if ($input_time =~ /^(\d{4})-(Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-(\d{1})$/) {
        my $single_digit_date = substr($input_time, -1);
        my $input_time_1 = substr($input_time, 0, -1);
        $input_time = $input_time_1.'0'.$single_digit_date;
        #print STDERR '5 '.$input_time."\n";
        $formatted_time = Time::Piece->strptime($input_time, '%Y-%b-%d');
    }
    if ($input_time =~ /^(\d{4})-(January|February|March|April|May|June|July|August|September|October|November|December)-(\d{2})$/) {
        #print STDERR '6 '.$input_time."\n";
        $formatted_time = Time::Piece->strptime($input_time, '%Y-%B-%d');
    }
    if ($input_time =~ /^(\d{4})-(January|February|March|April|May|June|July|August|September|October|November|December)-(\d{1})$/) {
        my $single_digit_date = substr($input_time, -1);
        my $input_time_1 = substr($input_time, 0, -1);
        $input_time = $input_time_1.'0'.$single_digit_date;
        #print STDERR '7 '.$input_time."\n";
        $formatted_time = Time::Piece->strptime($input_time, '%Y-%B-%d');
    }
    return $formatted_time;
}


sub get_calendar_events_personal {
	my $self = shift;
    my $c = shift;
    my $person_id = $c->user->get_object->get_sp_person_id;
    my @roles = $c->user->get_roles();
    #print STDERR Dumper \@roles;
    
    my @search_project_ids = '-1';
    foreach (@roles) {
    	my $q="SELECT project_id FROM project WHERE name=?";
    	my $sth = $c->dbc->dbh->prepare($q);
    	$sth->execute($_);
        while (my ($project_id) = $sth->fetchrow_array ) {
    	    push(@search_project_ids, $project_id);

    	    my $q="SELECT subject_project_id FROM project_relationship JOIN cvterm ON (type_id=cvterm_id) WHERE object_project_id=? and cvterm.name='breeding_program_trial_relationship'";
    	    my $sth = $c->dbc->dbh->prepare($q);
    	    $sth->execute($project_id);
    	    while (my ($trial) = $sth->fetchrow_array ) {
                push(@search_project_ids, $trial);
    	    }
    	}
    }

    @search_project_ids = map{$_='me.project_id='.$_; $_} @search_project_ids;
    my $search_projects = join(" OR ", @search_project_ids);
    my $schema = $c->dbic_schema('Bio::Chado::Schema');
    my $search_rs = $schema->resultset('Project::Project')->search(
	undef,
	{join=>{'projectprops'=>{'type'=>'cv'}},
	'+select'=> ['projectprops.projectprop_id', 'type.name', 'projectprops.value', 'type.cvterm_id'],
	'+as'=> ['pp_id', 'cv_name', 'pp_value', 'cvterm_id'],
	}
    );
    $search_rs = $search_rs->search([$search_projects]);
    return $search_rs;
}

sub populate_calendar_events {
	my $self = shift;
    my $search_rs = shift;
    my $view = shift;
    my @events;
    my $allday;
    my $start_time;
    my $start_drag;
    my $start_display;
    my $end_time;
    my $end_drag;
    my $end_display;
    my $formatted_time;
    my @calendar_array;
    my $title;
    my $property;
    while (my $result = $search_rs->next) {

	#Check if project property value is an event, and if it is not, then skip to next result.
    my $calendar_formatted_value = $self->check_value_format($result->get_column('pp_value'));
	if (!$calendar_formatted_value) {
	    next;
	}

    #print STDERR $calendar_formatted_value;

	@calendar_array = $self->parse_calendar_array($calendar_formatted_value);
    if (!$calendar_array[0]) {
        next;
    }

	#We begin with the start datetime, or the first element in the @calendar_array.
	#A time::piece object is returned from format_time(). Calling ->datetime on this object returns an ISO8601 datetime string. This string is what is used as the calendar event's start. Using format_display_date(), a nice date to display on mouse over is returned.
	$formatted_time = $self->format_time($calendar_array[0]);
	$start_time = $formatted_time->datetime;
	$start_display = $self->format_display_date($formatted_time);
	
	#Because fullcalendar does not allow event resizing of allDay=false events in the month view, the allDay parameter must be set depending on the view. The allDay parameter for the agendaWeek view is important and is set using determine_allday().
	if ($view eq 'month') {
	    $allday = 1;
	} elsif ($view eq 'agendaWeek') {
	    $allday = $self->determine_allday($formatted_time);
	}

	#Then we process the end datetime, which is the second element in the calendar_array. calendar_end_display determines what the calendar should display as the end, and format_display_date() returns a nice date to display on mouseover.
	$formatted_time = $self->format_time($calendar_array[1]);
	$end_time = $self->calendar_end_display($formatted_time, $view, $allday);
	$end_display = $self->format_display_date($formatted_time);

	#Because FullCallendar's end date is exclusive, an end datetime with 00:00:00 will be displayed as one day short on the calendar, and so corrections to the event's end must be made. To facilitate event dragging, an event.end_drag property is used. 
	$end_drag = $formatted_time->datetime;

	#To display the project name and project properties nicely in the mouseover and more info, we capitalize the first letter of each word.
	$title = $result->name;
	#$title =~ s/([\w']+)/\u\L$1/g;
	$property = $result->get_column('cv_name');
	$property =~ s/([\w']+)/\u\L$1/g;

	#Variables are pushed into the event array and will become properties of Fullcalendar events, like event.start, event.cvterm_url, etc.
	push(@events, {projectprop_id=>$result->get_column('pp_id'), title=>$title, property=>$property, start=>$start_time, start_drag=>$start_time, start_display=>$start_display, end=>$end_time, end_drag=>$end_drag, end_display=>$end_display, project_id=>$result->project_id, project_url=>'/breeders_toolbox/trial/'.$result->project_id.'/', cvterm_id=>$result->get_column('cvterm_id'), cvterm_url=>'/chado/cvterm?cvterm_id='.$result->get_column('cvterm_id'), allDay=>$allday, p_description=>$result->description, event_description=>$calendar_array[2], event_url=>$calendar_array[3]});
    }
    return \@events;
}

sub display_start_date {
	my $self = shift;
	my $value = shift;

	my $checked_value = $self->check_value_format($value);
    if ($checked_value) {
        my @calendar_array = $self->parse_calendar_array($checked_value);
        if ($calendar_array[0]) {
            my $formatted_time = $self->format_time($calendar_array[0]);
            my $start_time = $formatted_time->datetime;
            my $start_display = $self->format_display_date($formatted_time);
            return $start_display;
        } else {
            return;
        }
    } else {
        return;
    }

}

sub get_breeding_program_roles {
    my $self = shift;
    my $c = shift; 

    my @breeding_program_roles;
    my $q="SELECT username, sp_person_id, name FROM sgn_people.sp_person_roles JOIN sgn_people.sp_person using(sp_person_id) JOIN sgn_people.sp_roles using(sp_role_id)";
    my $sth = $c->dbc->dbh->prepare($q);
    $sth->execute();
    while (my ($username, $sp_person_id, $sp_role) = $sth->fetchrow_array ) {
        push(@breeding_program_roles, [$username, $sp_person_id, $sp_role] );
    }

    #print STDERR Dumper \@breeding_program_roles;
    return \@breeding_program_roles;
}

1;
