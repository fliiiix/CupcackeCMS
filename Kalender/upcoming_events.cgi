#!/usr/bin/perl

# before anything else, the script needs to find out its own name
#
# some servers (notably IIS on windows) don't set the cwd to the script's
# directory before executing it.  So we get that information
# from $0 (the full name & path of the script).
BEGIN{($_=$0)=~s![\\/][^\\/]+$!!;push@INC,$_}

$name = $0;
$name =~ s/.+\/.+\///;  # for unix
$name =~ s/.+\\.+\\//;  # for windows
$path = $0;
$path =~ s/(.+\/).+/$1/g;  # for unix
$path =~ s/(.+\\).+/$1/g;  # for windows

if ($path ne "") {
	chdir $path;
	push @INC,$path;
}
# finished discovering name

local $template_html;
local $event_details_template;
local $list_item_template;
local $calendar_item_template;
local $upcoming_item_template;

my $config_file = "upcoming_events.config";
my $plans_url = "";

# check for required modules.
require "includes.pl";


$module_found=0;
foreach $temp_path (@INC) {
  if (-e "$temp_path/JSON") {
$module_found=1;}
}
if ($module_found == 0) {
  $fatal_error=1;
  $error_info .= "unable to locate required module <b>JSON</b>!\n";
} else {
	require "JSON/PP58.pm";
	use JSON::PP;
}

if ($fatal_error == 1) {  # print error and bail out
  &fatal_error();
}

use Data::Dumper;

# time-related globals
$rightnow = time() + 3600 * $current_calendar{gmtime_diff};
@rightnow_array = gmtime $rightnow;
$rightnow_year = $rightnow_array[5]+1900;
$rightnow_month = $rightnow_array[4];
$rightnow_mday = $rightnow_array[3];
$next_year = $rightnow_year+1;
$rightnow_description = formatted_time($rightnow, "hh:mm:ss mn md yy");
@weekday_sequence = @day_names;


my $output_file= $options{'upcoming_events'}{'output_filename'};

my @filestats = stat "$output_file";
my $last_modified_timestamp = $filestats[9];

if ( $last_modified_timestamp > $rightnow - $options{'upcoming_events'}{'cache_seconds'} ) {
    open (FH, $options{'upcoming_events'}{'output_filename'}) || {$debug_info.= "unable to open file $options{'upcoming_events'}{'output_filename'}\n"};
    my $contents = join("",<FH>);
    close FH;

	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/html; charset=US-ASCII\n
$contents
p1

	exit(0);


}


$plans_url = $options{'upcoming_events'}{'calendar_url'};
  
if ($theme_url eq "")
  {$theme_url = "$plans_url/theme";}

$graphics_path ="$theme_url/graphics";                      # where misc. graphics are 
$icons_path = "$theme_url/icons";                           # where icons are
$css_path = "$theme_url/plans.css";                         # css file


# load templates
&load_templates();

# load calendar data
&load_calendars();

my $list_html = "";

# extract timeframe
my $timeframe= $options{'upcoming_events'}{'timeframe'};

# extract calendars to include
my @calendars_to_show = @{$options{'upcoming_events'}{'included_calendars'}};

my %calendars_in_list = ();


foreach $calendar_to_show (@calendars_to_show) {
	$calendars_in_list{$calendar_to_show} = 1;
}

  
# load background calendars?
if ( $options{'upcoming_events'}{'background_calendars_mode'} eq "dropdown") {
	#$debug_info .= "include background calendars!\n";
	foreach $calendar_to_show (@calendars_to_show) {
		foreach $background_cal_id (keys %{$calendars{$calendar_to_show}{local_background_calendars}}) {
			#$debug_info .= "background calendar: $background_cal_id\n";
			if ($calendars_in_list{$background_cal_id} != 1) {
				push @calendars_to_show, $background_cal_id;
				$calendars_in_list{$background_cal_id} = 1
			}
		}
	}
}

# include background calendars in list?
if ($options{'upcoming_events'}{'background_calendars_mode'} eq "merge") {
	#$debug_info .= "include background calendars!\n";
	foreach $calendar_to_show (@calendars_to_show) {
		foreach $background_cal_id (keys %{$calendars{$calendar_to_show}{local_background_calendars}}) {
			#$debug_info .= "background calendar: $background_cal_id\n";
			if ($calendars_in_list{$background_cal_id} != 1) {
				push @calendars_to_show, $background_cal_id;
				$calendars_in_list{$background_cal_id} = 1
			}
		}
	}
}
  
# one big list?
if ($options{'upcoming_events'}{'one_big_list'} )  {
	$debug_info .= "Displaying as one big list\n";
	# squelch all other calendars
	my $main_calendar = $calendars_to_show[0];
	foreach $calendar_to_show (@calendars_to_show) {
	if ($calendar_to_show ne $main_calendar)
		{$calendars{$main_calendar}{local_background_calendars}{$calendar_to_show}=1;}

	if ($options{'upcoming_events'}{'background_calendars_mode'} eq "merge") {
		foreach $background_cal_id (keys %{$calendars{$calendar_to_show}{local_background_calendars}}) {
			$calendars{$main_calendar}{local_background_calendars}{$background_cal_id}=1;}
		}
	}

	@calendars_to_show = ();
	#delete @calendars_to_show;
	@calendars_to_show = ($main_calendar);
}
  
  
#  $debug_info .= "Calendars in list: ";
#  my $temp="";
#  foreach $calendar_to_show (@calendars_to_show)
#    {$temp .=  " $calendars{$calendar_to_show}{title} ($calendar_to_show),";}
#  chop $temp;
#  $debug_info .= "$temp\n";

$list_start_timestamp = $rightnow;
$list_end_timestamp = $list_start_timestamp + 86400 * $timeframe;

my @temp2 = keys %calendars_in_list;

load_events($list_start_timestamp, $list_end_timestamp, \@temp2);


$current_cal_id = $calendars_to_show[0];

&normalize_timezone();

my %event_lists = ();

foreach $cal_id (sort {$a <=> $b} @calendars_to_show) {
	$event_lists{$cal_id} = &generate_upcoming_events($cal_id);
}

$list_html .=<<p1;

<script type="text/javascript"><!--

function update_event_list() {
	jQuery('.event_list_box').hide();
	var selected_cal_id = jQuery('#org :selected').val();
	jQuery('#event_list_'+selected_cal_id).show();
}

function display_event(evt_id, event_link) {
 
	info_window = null;
	if ( event_link == "" ) { 
		var URL_string="$plans_url/plans.cgi?view_event=1&evt_id="+evt_id;
		info_window = this.open(URL_string, "info_window", "resizable=yes,status=yes,scrollbars=yes,width=400,height=400");
	} else {
		info_window = this.open(event_link, "info_window", "toolbar=yes,resizable=yes,status=yes,scrollbars=yes");
	}
	info_window.focus();

}

jQuery(window).bind('load', update_event_list);

//-->
</script>

<link rel="stylesheet" href="$theme_url/upcoming_events.css" type="text/css">

<div>
p1

	$list_html .=<<p1;
<select id="org" onchange="update_event_list()">
p1
foreach $cal_id (@calendars_to_show) {
	$list_html .=<<p1;
<option value = "$cal_id">$calendars{$cal_id}{title}</option>
p1
}  
$list_html .=<<p1;
</select>
</div>
p1


foreach $cal_id ( keys %event_lists ) {

	$list_html .=<<p1;
<div id="event_list_$cal_id" class="event_list_box" style="display:none;">
p1

	$list_html .= $event_lists{$cal_id};

	$list_html .=<<p1;
</div>
p1

}


$debug_info =~ s/\n/<br>/g;
 
my $html_output = <<p1;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<link rel="stylesheet" href="$theme_url/plans.css" type="text/css">
<link rel="stylesheet" href="$theme_url/upcoming_events.css" type="text/css">
p1

$html_output .= &get_js_includes( $theme_url );

$html_output .= <<p1;
<title>Upcoming events results:</title>
<body>
$debug_info
$list_html
</body>
</html>
p1

print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/html; charset=US-ASCII

$html_output
p1

open (datafile, ">$output_file") || ($debug_info .="unable to open data file $output_file for writing\n");
flock datafile,2;
print datafile $html_output;
close datafile;


exit(0);                                                              



############################################################################################################


sub generate_upcoming_events {
	my $return_text = "";
	($calendar_id) = @_;

	my @selected_cal_events;

	#$debug_info .= "include background calendars: ".$list->{include_background_calendars}."\n";
	foreach $event_id (keys %events) {
		foreach $temp_cal_id (@{$events{$event_id}{cal_ids}}) {
			#$debug_info .= "checking event $event_id cal_id $temp_cal_id\n";
			my $found = 0;
			if ($temp_cal_id eq $calendar_id) {
				push @selected_cal_events, $event_id;
				last;
			}


			if ($options{'upcoming_events'}{'background_calendars_mode'} eq "merge" 
                || $options{'upcoming_events'}{'one_big_list'})	{
				foreach $background_cal_id (keys %{$calendars{$calendar_id}{local_background_calendars}}) {
					if ($temp_cal_id eq $background_cal_id) {
						#$debug_info .= "match!\n";
						push @selected_cal_events, $event_id;
						$found = 1;
						last;
					}
				}
			}
			if ($found==1) {last;}
		}
	}


	$return_text .=<<p1;
<ul class="upcoming_events">
p1
	#display events for selected org
	foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @selected_cal_events) {
		my %event = %{$events{$event_id}};
		if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$list_start_timestamp, $list_end_timestamp)) {  
			@event_start_timestamp_array = gmtime $event{start};
			my $date_string;
			my $weekday_string;

			# handle link
			my $event_link = "";
			$event_link = "$event{details}" if ($event{details_url} eq "1");

			$date_string = &nice_date_range_format($event{start}, $event{end}, "-");

			# abbreviate months
			for($l1=0;$l1<12;$l1++)
				{$date_string =~ s/$months[$l1]/$months_abv[$l1]/g;}
			# remove year
			$date_string =~ s/, \d{4}//g;

			if ($event{days} == 1) { #single-day event
				$date_string="$months_abv[$event_start_timestamp_array[4]] $event_start_timestamp_array[3]";
				$weekday_string = $day_names_abv[$event_start_timestamp_array[6]]
			} else { #multi-day event
				@event_end_timestamp_array = gmtime $event{end};
				if ($event_start_timestamp_array[4] eq $event_end_timestamp_array[4]) {
					$date_string="$months_abv[$event_start_timestamp_array[4]] $event_start_timestamp_array[3]-$event_end_timestamp_array[3]";
				} else {
					$date_string="$months_abv[$event_start_timestamp_array[4]] $event_start_timestamp_array[3] - $months_abv[$event_end_timestamp_array[4]] $event_end_timestamp_array[3]";
				}
				$weekday_string = "$day_names_abv[$event_start_timestamp_array[6]]-$day_names_abv[$event_end_timestamp_array[6]]";
			}

			my $weekday_abv_string = $weekday_string;
			for ($l1=0;$l1<scalar @day_names;$l1++) {
				$weekday_abv_string =~ s/$day_names[$l1]/$day_names_abv[$l1]/g;
			}


			my $icon_text="";
			my $unit_icon_text="";
			if ($event{unit_number} ne "") {
				$icon_text = $event{unit_number};
				$icon_text =~ s/(\d)/<img src="$graphics_path\/unit_number_patch_$1_16x10.gif" style=\"vertical-align:middle;border:0\" alt=\"\"\/>/g;
			}

			if ($event{icon} eq "blank") {
				$icon_text .= "$unit_icon_text";
			} else {
				$icon_text .= "$unit_icon_text<img class=\"event_icon\" src=\"$icons_path/$event{icon}_16x16.gif\" alt=\"\"/>";
			}

			$event{title} =~ s/^\s+//;

			my $event_time = "";
			if ($event{all_day_event} ne "1") {
				$event_time = &nice_time_range_format($event{start}, $event{end});
				$event_time = " <span class=\"event_time\">$event_time</span> ";
			}

			my $temp = $upcoming_item_template;
      
			$temp =~ s/###id###/$event_id/g;
			$temp =~ s/###time###/$event_time/g;
			$temp =~ s/###date###/$date_string/g;
			$temp =~ s/###background color###/$event{bgcolor}/g;
			$temp =~ s/###icon###/$icon_text/g;
			$temp =~ s/###title###/$event{title}/g;
			$temp =~ s/###event link###/$event_link/g;
			$temp_item_text =~ s/###weekday###/$weekday_string/g;
			$temp_item_text =~ s/###weekday_abv###/$weekday_abv_string/g;

			$return_text .= $temp;

		}
	}

	$return_text .=<<p1;

        
</ul>

p1
	return $return_text;
  
}  #********************end generate_upcoming_events subroutine**********************




sub generate_event_details_javascript
{
  my ($events_start_timestamp, $events_end_timestamp) = @_;
  
  my $return_string="";
 
  my $num_events = 0;
  $index=0;

  #loop through the events, check to see if they fall 
  #within the current calendar month
      
  #debug end timestamp

  foreach $event_id (keys %events)
  {
    my %event = %{$events{$event_id}};

    if (&time_overlap($event{start},$event{end},$events_start_timestamp,$events_end_timestamp))
    {
      #$debug_info .= "event details for $event{title}\n";

      $num_events++;
      #show cal_details
      
      my $cal_detail_text="";
      #$debug_info .= "generating event details for $event{title}\n";
      my $event_details = &generate_event_details(\%event);
      
      $event_detail_text =<<p1;
$event_details      
p1

      #prepare event detail text to be stored in a javascript array
      $event_detail_text =~ s/\n/\\n/g;
      $event_detail_text =~ s/"/\\"/g;
      $event_detail_text =~ s/\//\\\//g;

      $event_defs .= <<p1;
event_details_$temp_list_index [$event_id] = new Object;
event_details_$temp_list_index [$event_id].id = "$event_id";
event_details_$temp_list_index [$event_id].text = "$event_detail_text";
p1
      $index++;
    }
  }

  $return_string .=<<p1;
var event_details_$temp_list_index = new Array($num_events);  // array to hold days in current month view
$event_defs
p1
  return $return_string;
      
}  #********************end generate_event_details_javascript subroutine**********************

sub fatal_error()
{
  $error_info =~ s/\n/<br>/g;

  $html_output .=<<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/html; charset=iso-8859-1\n
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>Plans error!</title>
</head>
<body>

<b>Plans error:</b><br>
$error_info
p1
  if ($debug_info ne "")
  {
    $debug_info =~ s/\n/<br>/g;
    $html_output .=<<p1;
<hr>
Debug info:<br>
$debug_info
p1

  }

  $html_output .=<<p1;
</body>
</html>
p1

  print $html_output;
  exit(0);
}

