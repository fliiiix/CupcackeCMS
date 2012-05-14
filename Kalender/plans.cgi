#!/usr/bin/perl

require v5.6.1;

# before anything else, the script needs to find out its own name
#
# some servers (notably IIS on windows) don't set the cwd to the script's
# directory before executing it.  So we get that information
# from $0 (the full name & path of the script).
BEGIN{($_=$0)=~s![\\/][^\\/]+$!!;push@INC,$_}

$name = $0;
$name =~ s/.+\/?.+\///;  # for unix
$name =~ s/.+\\.+\\//;  # for windows
$path = $0;
$path =~ s/(.+\/).+/$1/g;  # for unix
$path =~ s/(.+\\).+/$1/g;  # for windows

# The "use Cwd" method would be nice, but it doesn't work with
# some versions of IIS/ActivePerl
#use Cwd;
#$path = cwd;

if ($path ne "") {
  chdir $path;
  push @INC,$path;
}

# finished discovering name

#use Data::Dumper;

# some global variables (more further down)
local $plans_version = "8.2.1";        # version
local $debug_info;
local %options;
local $fatal_error = 0;          # fatal errors cause plans to abort and print an error message to the browser
local $error_info = "";
local $html_output;
local $script_url = "";
local $messages = "";   # formatted in plain text with newlines.  Converted to html at display time.

local $template_html;
local $local_template_file = 0; # tells whether the template was loaded via a filesystem open or through a http request.
local $event_details_template;
local $list_item_template;
local $calendar_item_template;
local $upcoming_item_template;

local %calendars;
local %current_calendar;
local %latest_calendar;
local %new_calendars;
local $normalized_timezone = 0;
local $normalized_timezone_pending_events = 0;

# used when adding new entries
local $max_cal_id = 0;
local $max_event_id = 0;
local $max_series_id = 0;
local $max_user_id = 0;
local $max_action_id = 0;

# used to protect against refreshes
local $latest_cal_id = 0;
local $latest_event_id = 0;
local $latest_new_cal_id = 0;
local $latest_new_event_id = 0;

local $session;
local $json = new JSON::PP;
local %users;
my $profile;
local $logged_in = 0;
local $logged_in_as_root = 0;
local $logged_in_as_current_cal_user = 0;
local $logged_in_as_current_cal_admin = 0;

local $lg_name = "";
local $lg_password = "";

local %events;
local %new_events;
local @pending_events_to_display;

local %text;
local %cookie_parms;
local $cookie_text = "";
local $cookie_header_text = "";
local $max_remote_event_id = 0;

local $options{default_template_path} = "";
local $theme_url = "";
local $options{choose_themes} = "";
local $graphics_url = "";
local $ical_export_url = "";
local $icons_url = "";
local $input_cal_id_valid = 0;
local $options{right_click_menus_enabled} = 0;
local %cal_options;

local $rightnow;
local @months;
local @months_abv;
local @day_names;
local $loaded_all_events;    # flag used to avoid calling load_events("all") twice
                             # not needed for calendars (we always load all calendars)

local @disabled_tabs;

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


if ($fatal_error == 1)  { # print error and bail out
  &fatal_error();
}

# anonymous events only work when sessions are turned on
$options{'anonymous_events'} = $options{'anonymous_events'} && $options{'sessions'};


if (defined $options{language_files}) {
  my @language_files = split(',', $options{language_files});
  # create a javascript file with language strings
  open (FH, "$options{default_theme_path}/$options{js_language_file}") || {$debug_info.= "unable to open file $options{default_theme_path}/$options{js_language_file}\n"};
  flock FH,2;
  my $first_lang_line=<FH>;
  close FH;

  if ($options{generate_js_lang} eq "1" || $first_lang_line !~ /$plans_version/) {
    my $lang_string = "";
    $lang_string .= "//$plans_version\n";
    $lang_string .= "var plans_lang = {};\n";

    # generate %lang keys
    foreach $lang_key (keys %lang) {
      if (ref $lang{$lang_key} eq "ARRAY") {
        $lang_string .= "plans_lang['$lang_key']=[";
        my $first = 1;
        foreach $key (@{$lang{$lang_key}}) {
          if (!$first) {$lang_string .= ',';}
          if ($first) {$first = 0;}

          my $lang_val = &js_string($key);
          $lang_string .= "'$lang_val'";
        }
        $lang_string .= "];\n";

      } else {
        my $lang_val = &js_string($lang{$lang_key});

        $lang_string .= "plans_lang['$lang_key']='$lang_val';\n"
      }
    }

    open (FH, ">$options{default_theme_path}/$options{js_language_file}") || {$debug_info .= "unable to open file $options{default_theme_path}/$options{js_language_file} for writing!\n"};
    flock FH,2;
    print FH $lang_string;
    close FH;
  }
} else {
  $fatal_error=1;
  $error_info .= "No language files defined in plans.config!\n";
}

if ($fatal_error == 1) { # print error and bail out
  &fatal_error();
}


# init cgi stuff
$q = new CGI;
if ($options{calendar_url} ne "") {
  $script_url = $options{calendar_url};
} else {
  $script_url = $q->url(-path_info>=1);
}
$script_url =~ /(.*)\//;          # remove trailing / and all text after
$script_url = $1;                 # remove trailing / and all text after

%cookie_parms = %{ &extract_cookie_parms() };
my $cookie_path = $q->url( -absolute => 1 );
$cookie_path =~ s/$name$//;
$cookie_path =~ s/admin\/?$//; # This is better than using just '/'

# check if data files or tables are present
&check_data();

# fatal error?  Print error and bail out
if ($fatal_error == 1) {
&fatal_error();}


if ($theme_url eq "") { # not defined in config file
  $theme_url = "$script_url/theme";
}

if ($options{choose_themes}) {
  $chosen_url = $q->param('theme_url');
  $chosen_url = $cookie_parms{'theme_url'} if ($chosen_url eq "");
  $theme_url = $chosen_url if ($chosen_url ne "");
}

$graphics_url ="$theme_url/graphics";                      # where misc. graphics are
$ical_export_url ="$theme_url/ical";                       # where icalendar .ics files are placed 
$ical_export_url =~ s/http:\/\//$options{ical_prefix}/;	   # replace with custom prefix
$icons_url = "$theme_url/icons";                           # where icons are
$css_path = "$theme_url/plans.css";                        # css file

# globals from http parameters
my $active_tab = $q->param('active_tab') + 0; # +0 ensures numericity
$active_tab = 0 if ($active_tab > scalar @{$lang{tab_text}} - 1);

my $api_command = $q->param('api_command');

my $add_edit_cal_action = $q->param('add_edit_cal_action');
$add_edit_cal_action = "" if (!&contains(["add", "edit", "view_pending"],$add_edit_cal_action));  # validate

my $add_edit_event = $q->param('add_edit_event');
$add_edit_event = "" if (!&contains(["add", "edit"],$add_edit_event));  # validate

local $current_event_id = $q->param('evt_id');
$current_event_id = "" if ($current_event_id !~ /^R?\d+$/);  # validate

local $pending_event_id = $q->param('pending_event_id');
$pending_event_id = "" if ($pending_event_id !~ /^R?\d+$/);  # validate

local $cal_start_month = $q->param('cal_start_month') + 0; # +0 ensures numericity
local $cal_start_year = $q->param('cal_start_year') + 0;   # +0 ensures numericity
local $cal_num_months = $q->param('cal_num_months') + 0;   # +0 ensures numericity


# if view parameters not supplied in http request, check cookie
$cal_start_month = $cookie_parms{'cal_start_month'} if ($q->param('cal_start_month') eq "");
$cal_start_year = $cookie_parms{'cal_start_year'} + 0 if ($cal_start_year == 0);
$cal_num_months = $cookie_parms{'cal_num_months'} + 0 if ($cal_num_months  == 0);

my $special_action = $q->param('special_action');  # needs no validation - never used in output

local $display_type = $q->param('display_type') + 0;   # +0 ensures numericity
$display_type = $cookie_parms{'display_type'} if ($q->param('display_type') eq "");


$messages = $q->param('messages') if ($q->param('messages') ne "");


# other globals
my $event_start_date;
my $event_start_timestamp;
my $event_days;
my $start_mday;
my $start_mon;
my $start_year;
my @timestamp_array;

my $prev_month_link = "";
my $next_month_link = "";

# load calendar data
&load_calendars();
&load_users();
&load_actions();

local $current_cal_id = 0;

if ($q->param('cal_id') eq "") {
  $current_cal_id = $cookie_parms{'current_cal_id'} if ($current_cal_id == 0);
} else {
  $current_cal_id = $q->param('cal_id');
}
$current_cal_id += 0; # +0 ensures numericity


foreach $cal_id (keys %calendars) {
	if ($cal_id eq $current_cal_id) {
		$input_cal_id_valid = 1;
	}
}

if ($current_cal_id eq "") {
	$input_cal_id_valid = 0;
}

if ($current_cal_id =~ /\D/) {
	$input_cal_id_valid = 0;
}

$current_cal_id = 0 if ($current_event_id eq "" &&  !$input_cal_id_valid);

# make all calendars selectable by default
foreach $cal_id (keys %calendars) {
$default_cal{selectable_calendars}{$cal_id} = 1;}

%current_calendar = %{$calendars{$current_cal_id}};

# time-related globals
$rightnow = time() + 3600 * $current_calendar{gmtime_diff};
@rightnow_array = gmtime $rightnow;
$rightnow_year = $rightnow_array[5]+1900;
$rightnow_month = $rightnow_array[4];
$rightnow_mday = $rightnow_array[3];
$next_year = $rightnow_year+1;
$rightnow_description = formatted_time($rightnow, "hh:mm:ss mn md yyyy");

@weekday_sequence = @day_names;

# session stuff

if ($options{sessions} eq "1") {
	$lg_name = $current_cal_id;
	$lg_password = $q->param('cal_password');

	&delete_old_sessions(1);  # in days


	my $current_session_id = $q->cookie("plans_sid") || undef;

	$session = new CGI::Session(undef, $current_session_id, {Directory=>$options{sessions_directory}});
	$session->expire("+1d");

	#$debug_info .=  "current_session_id: $current_session_id\n";

	# log out?
	if ($q->param('logout') eq "1") {
		$session->delete();
		$logged_in = 0;
		$cookie_text .= "Set-Cookie; plans_sid=deleted; path=$cookie_path;\n";
	} else {

		# try to match session with user id.  (If this fails, it's not really a session.)
		my $results = &init_session($q, $session);
		$profile = $session->param("~profile");

		if (defined $profile->{calendar_permissions}) {
			$logged_in = 1;
			$cookie_text .= "Set-Cookie: plans_sid=".$session->id."; path=$cookie_path;\n";
		}
	}
}

# $debug_info .= "cal password: " . $q->param('cal_password') . "\n";
# $debug_info .= "encrypted cal password: " . crypt($q->param('cal_password'), $options{salt}) . "\n";
# $debug_info .= "root cal password: " . $calendars{0}{password} . "\n";

if ($options{sessions} eq "1") {
  $logged_in_as_root = ($profile->{calendar_permissions}->{0}->{admin} eq "1") ? 1:0;
  $logged_in_as_current_cal_user = ($profile->{calendar_permissions}->{$current_cal_id}->{user} ne "") ? 1:0;
  $logged_in_as_current_cal_admin = ($profile->{calendar_permissions}->{$current_cal_id}->{admin} ne "") ? 1:0;
} elsif ($q->param('cal_password') ne "") {
  $logged_in_as_root = ($calendars{0}{password} eq crypt($q->param('cal_password'), $options{salt})) ? 1:0;
  $logged_in_as_current_cal_admin = ($current_calendar{password} eq crypt($q->param('cal_password'), $options{salt})) ? 1:0;

  foreach $user_id (keys %users) {
    my %user = %{$users{$user_id}};
    my %user_calendars = %{$user{calendars}};
    foreach $user_cal_id (keys %user_calendars) {
      if ($user_cal_id eq $current_cal_id && $user{calendars}{$user_cal_id}{edit_events} eq "1" &&
          $user{password} eq crypt($q->param('cal_password'), $options{salt})) {
        $logged_in_as_current_cal_user = 1;
        last;
      }
      last if ($logged_in_as_current_cal_user == 1);
    }
    last if ($logged_in_as_current_cal_user == 1);
  }
}

$logged_in_as_current_cal_user = 0 if (!$options{users}) ;

#$debug_info .=  "init_session results: $results\n";
#$debug_info .=  "logged-in: ".$session->param("~logged-in")."\n";
#$debug_info .=  "session id: ".$session->id."\n";
#$debug_info .=  "profile user_id: ".$profile->{calendar_permissions}->{$current_cal_id}."\n";

#$debug_info .=  "options{sessions}: $options{sessions}\n";
#$debug_info .=  "logged_in_as_root: $logged_in_as_root\n";
#$debug_info .=  "logged_in_as_current_cal_user: $logged_in_as_current_cal_user\n";
#$debug_info .=  "logged_in_as_current_cal_admin: $logged_in_as_current_cal_admin\n";
#$debug_info .=  "current_calendar{password}: $current_calendar{password}\n";
#$debug_info .=  ($profile->{calendar_permissions}->{$current_cal_id}->{admin})."\n";


# custom stylesheet?
if ($current_calendar{custom_stylesheet} ne "") {
  $css_path = "http://$current_calendar{custom_stylesheet}";
}

# if this is a custom calendar request, shoehorn the request parameters in
if ($q->param('custom_calendar') eq "1") {
  $current_cal_id = $q->param('custom_calendar_calendar') + 0;
  @custom_calendar_backgound_calendars = $q->param('custom_calendar_background_calendars');

  foreach $local_background_calendar (keys %{$calendars{$current_cal_id}{local_background_calendars}}) {
delete $calendars{$current_cal_id}{local_background_calendars}{$local_background_calendar};}

  foreach $local_background_calendar (@custom_calendar_backgound_calendars) {
$calendars{$current_cal_id}{local_background_calendars}{$local_background_calendar} = 1;}

  %current_calendar = %{$calendars{$current_cal_id}};
}




# make sure we can select the current calendar
#$current_calendar{selectable_calendars}{$current_cal_id} = 1;


# rotate weekday_sequence by the offset defined in the week start day.
for ($l1=0;$l1 < $current_calendar{week_start_day};$l1++) {
push @weekday_sequence, (shift @weekday_sequence);}



# load background_colors
my @temp_lines = split ("\n", $event_background_colors);

foreach $temp_line (@temp_lines) {
  next if ($temp_line !~ /\w/); # skip any blank lines

  $temp_line =~ s/^\s+//;
  my ($hex_color, $hex_color_title) = split (/,*\s+/, $temp_line, 2);
  $hex_color_title = "&nbsp;" if ($hex_color_title eq "");

  push @event_bgcolors, {color => $hex_color, title => $hex_color_title};
}


#evaluate browser type and version
$_ = $ENV{HTTP_USER_AGENT};

if (/Mozilla/) {
  if (/Opera.([0-9\.]+)/) { $browser_type = 'Opera'; $browser_version=$1;} elsif (/MSIE.([0-9.]+)/) { $browser_type = 'IE'; $browser_version = $1;} elsif (/Mozilla\/([0-9\.]+)/) {$browser_type = 'Mozilla'; $browser_version=$1;
    if (($browser_version<5) || (/Netscape/)) {$browser_type = "Netscape";} }
  if (/\)[^0-9.]+[0-9]*[\/\ ]([0-9.]+)/) {$browser_version=$1;}
} elsif (/(\w+)\/([0-9\.]+)/) {$browser_type = $1; $browser_version = $2}

#evaluate, transform, tweak, adjust, modify input values
#$debug_info .= "browser type: $browser_type<br/>";



#if no month is selected, use the current month
if ($cal_start_month eq "" ) {
	$cal_start_month = $rightnow_month;
	#$cal_start_month = 2;
}

#if the input year is out of range use the current year
if (($cal_start_year+0) < 1902 || ($cal_start_year+0)> 2037) {
  $cal_start_year = $rightnow_year;
}

$cal_num_months = $current_calendar{default_number_of_months} if ($cal_num_months < 1);
$cal_num_months = $current_calendar{default_number_of_months} if ($cal_num_months > $current_calendar{max_number_of_months});
$cal_num_months = 1 if ($cal_num_months > $current_calendar{max_number_of_months});
$cal_num_months = 1 if ($cal_num_months == 0);


#calculate calendar end month and year
$cal_end_month = $cal_start_month;
$cal_end_year = $cal_start_year;
for ($l1=1;$l1<$cal_num_months;$l1++) {
  $cal_end_month++;
  if ($cal_end_month == 12) {
    $cal_end_month=0;
    $cal_end_year++;
  }
}

#check to make sure num_months+cal_start_date doesn't go out of bounds
if ($cal_end_year < 1902 || $cal_end_year> 2037) {
  $cal_end_year = $cal_start_year;
  $cal_end_month = $cal_start_month;
  $cal_num_months = 1;
}

# time window for loading events

my $cal_start_timestamp = timegm(0,0,0,1,$cal_start_month,$cal_start_year) - 2592000;
my $cal_end_timestamp = timegm(0,0,0,1,$cal_end_month,$cal_end_year) + 5184000;
if ($q->param('cal_start_timestamp') ne "" && $q->param('cal_start_timestamp') !~ /\D/) {
$cal_start_timestamp = $q->param('cal_start_timestamp');}
if ($q->param('cal_end_timestamp') ne "" && $q->param('cal_end_timestamp') !~ /\D/) {
$cal_end_timestamp = $q->param('cal_end_timestamp');}


#$debug_info .="start: $cal_start_timestamp\nend: $cal_end_timestamp\nrightnow: $rightnow\n";

# load event data, for main calendar and its background calendars
my @temp_calendars = ($current_cal_id);
foreach $local_background_calendar (keys %{$current_calendar{local_background_calendars}}) {
  push @temp_calendars, $local_background_calendar;
}

my $initial_load_events = 1;
$initial_load_events = 0 if ($q->param('get_upcoming_events') eq "1");

&load_events($cal_start_timestamp, $cal_end_timestamp, \@temp_calendars) if ($initial_load_events == 1);

if ($current_event_id ne "") {
  &load_event($current_event_id);
}


# load events from remote background calendars

if (scalar keys %{$current_calendar{remote_background_calendars}} > 0) {
  $remote_calendars_status="";
  my $temp = scalar keys %{$current_calendar{remote_background_calendars}};
  foreach $remote_calendar_id (keys %{$current_calendar{remote_background_calendars}}) {
    # pull in remote calendar name
    my $remote_calendar_url = $current_calendar{remote_background_calendars}{$remote_calendar_id}{url};
    $remote_calendar_complete_url = $remote_calendar_url;
    #$debug_info .= "remote calendar: $remote_calendar_complete_url\n";

    $remote_calendar_complete_url .= "?remote_calendar_request=1&cal_id=$current_calendar{remote_background_calendars}{$remote_calendar_id}{remote_id}&cal_start_year=$cal_start_year&cal_start_month=$cal_start_month&num_months=$cal_num_months";
    #$debug_info .= "remote calendar url: $remote_calendar_complete_url\n";

    my $xml_results = &get_remote_file($remote_calendar_complete_url);

    if ($xml_results =~ /<error>/) {
      $xml_results =~ s/</&lt;/g;
      $xml_results =~ s/>/&gt;/g;

      #$debug_info .= "Error fetching remote calendar: $xml_results\n";
    } else {
      my %remote_calendar = %{&xml2hash($xml_results)};

      my $remote_cal_title = $remote_calendar{'xml'}{calendar}{title};
      my $remote_cal_gmtime_diff = $remote_calendar{'xml'}{calendar}{gmtime_diff};

      #$debug_info .= "remote_cal_gmtime_diff: $remote_cal_gmtime_diff\n";
      #my $temp = $xml_results;
      #$temp=~ s/>/&gt;/g;
      #$temp=~ s/</&lt;/g;
      #$debug_info .= "xml results: $temp\n";

      &load_remote_events($xml_results, $remote_calendar_id, $remote_cal_gmtime_diff);
    }
  }
}

# this should be done after all $current_cal_id is calculated and events are loaded.
&normalize_timezone();
&normalize_timezone_pending_events();




# calculate previous X months range.
my $previous_cal_start_month = $cal_start_month - $cal_num_months;
my $previous_cal_start_year = $cal_start_year;
if ($previous_cal_start_month < 0) {
  $previous_cal_start_year = $cal_start_year - 1 - int(abs($cal_num_months - $cal_start_month) / 12);
  $previous_cal_start_month = 12 - abs($previous_cal_start_month) % 12;
}

# for the case when num_months = 12 and start_month=0
if ($previous_cal_start_month == 12) {
  $previous_cal_start_month=0;
  $previous_cal_start_year++;
}


# singular or plural?
if ($cal_num_months > 1) {
  $prev_string = $lang{previous_months};
  $prev_string =~ s/###num###/$cal_num_months/;
} else {
  $prev_string = $lang{previous_month};
}


# calculate next X months range.
my $next_cal_start_month = $cal_start_month + $cal_num_months;
my  $next_cal_start_year = $cal_start_year;
if ($next_cal_start_month > 11) {
  $next_cal_start_year = $cal_start_year + int(abs($cal_num_months + $cal_start_month) / 12);
  $next_cal_start_month = abs($cal_start_month + $cal_num_months) % 12;
}


# singular or plural?
if ($cal_num_months > 1) {
  $next_string = $lang{next_months};
  $next_string =~ s/###num###/$cal_num_months/;
} else {
  $next_string = $lang{next_month};
}




if ($q->param('diagnostic_mode') eq "1") {
  my $diagnostic_results = &diagnostic_info;


  $html_output = <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/html; charset=$lang{charset}\n
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
<title>Diagnostic mode</title>
</head>
<body style="font-family: arial;">


<h2>Plans Diagnostic information</h2>
<p>
$diagnostic_results

</p><p>
<b>Debug info:</b><br/>
<div style="color=:#0000ff;">
$debug_info
</div>
</body>
</html>

p1

  print $html_output;

  exit(0);
}

# dispatch all actions

if ($api_command eq "delete_event" || $api_command eq "add_update_event" ) {
	&api_add_delete_events();
	exit(0);
}

if ($api_command eq "delete_calendar" || $api_command eq "add_update_calendar" ) {
	&api_add_delete_calendar();
	exit(0);
}

if ($api_command eq "approve_delete_pending_calendars" ) {
	&api_approve_delete_pending_calendars();
	exit(0);
}

if ($api_command eq 'add_edit_user') {
  &add_edit_user();
  exit(0);
}


if ($api_command eq 'detect_remote_calendars' ) {
  &detect_remote_calendars();
  exit(0);
}

if ($api_command eq 'add_ical') {
  &add_new_ical();
  exit(0);
}

if ($api_command eq 'js_login') {
  &js_login();
  exit(0);
}

if ($api_command eq 'preview_date') {
	&load_templates();
	&preview_date();
	exit(0);
} 

if ($api_command eq 'set_email_reminder') {
	&load_templates();
	&set_email_reminder();
	exit(0);
}

if ($api_command eq 'manage_pending_events') {
  &manage_pending_events();
  exit(0);
}

if ($q->param('remote_calendar_request') eq "1") {
  &remote_calendar_request();
  exit(0);
}

if ($q->param('export_calendar') eq "1") {
  if ($q->param('export_type') eq "ascii_text") {
    &ascii_text_cal($cal_start_month, $cal_start_year, $cal_end_month, $cal_end_year);
    exit(0);
  } elsif ($q->param('export_type') eq "csv_file") {
    &csv_file($cal_start_month, $cal_start_year, $cal_end_month, $cal_end_year);
    exit(0);
  } elsif ($q->param('export_type') eq "csv_file_palm") {
    &csv_file_palm($cal_start_month, $cal_start_year, $cal_end_month, $cal_end_year);
    exit(0);
  } elsif ($q->param('export_type') eq "vcalendar") {
    &vcalendar_export_cal($cal_start_month, $cal_start_year, $cal_end_month, $cal_end_year);
    exit(0);
  } elsif ($q->param('export_type') eq "icalendar") {

    my $html_output =<<p1;
Cache-control: no-cache,no-store,private
Content-disposition: filename="events.ics"
Content-Type: text/calendar; charset=$lang{charset}

p1

    $html_output .= &icalendar_export_cal($cal_start_month, $cal_start_year, $cal_end_month, $cal_end_year);
    print $html_output;
    exit(0);
  }
}

if ($q->param('export_event') eq "1") {
  if ($q->param('export_type') eq "ascii_text") {
    &ascii_text_event();
    exit(0);
  } elsif ($q->param('export_type') eq "icalendar") {
    &icalendar_export_event();
    exit(0);
  } elsif ($q->param('export_type') eq "vcalendar") {
    &vcalendar_export_event();
    exit(0);
  }
} elsif ($q->param('get_upcoming_events') eq "1") {
  &get_upcoming_events();
  exit(0);
} elsif ($q->param('view_event') eq "1") {
  &load_templates();
  &view_event();
  exit(0);
} elsif ($q->param('view_pending_event') eq "1") {
  &load_templates();
  my %pending_event = %{$new_events{$pending_event_id}};
  &view_pending_event(\%pending_event);
  exit(0);
} 
&load_templates();



# ssi-style includes in the template
if ($local_template_file) {
  my $new_html = $template_html;

  $template_html =~ s/###include\s+(.+)###/&load_file($1)/ge;

  #while ($new_html =~ s/###include\s+(.+)###//g)
  if(0) {
    my $include_file=$1;
    if (-e $include_file) {
      open (FH, "$include_file") || ($debug_info .="<br/>unable to open include file $include_file for reading<br/>");
      flock FH,2;
      my @include_lines=<FH>;
      close FH;
      $include_html = join "", @include_lines;
    }
    $template_html =~ s/###include\s+(.+)###/$include_html/;
  }
}




if($options{choose_themes}) {
  my $theme_file="choose_theme.html";
  my $theme_html="";
  if (-e $theme_file) {
    open (FH, "$theme_file") || ($debug_info .="<br/>unable to open theme file $theme_file for reading<br/>");
    flock FH,2;
    my @theme_lines=<FH>;
    close FH;
    $theme_html = join "", @theme_lines;
  }
  $template_html =~ s/###choose theme###/$theme_html/;
} else {
  $template_html =~ s/###choose theme###//;
}


my %new_cookie_parms = ( "cal_start_month" => $cal_start_month,
					   "cal_start_year" => $cal_start_year,
					   "cal_num_months" => $cal_num_months,
					   "current_cal_id" => $current_cal_id,
					   "display_type" => $display_type
					  );

my $view_cookie = &encode( encode_json( \%new_cookie_parms ) );
$cookie_text .= "Set-Cookie: plans_view=$view_cookie; path=$cookie_path; expires=Thu, 31-Dec-2099 00:00:00 GMT\n";
$cookie_header_text = $cookie_text;

$html_output .=<<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/html; charset=$lang{charset}
###cookie_text###

$template_html
p1


$html_output =~ s/###current calendar title###/$current_calendar{title}/g;
$html_output =~ s/###current calendar details###/$current_calendar{details}/g;
$html_output =~ s/###calendar\{(\d+)\}\{(.+?)\}###/$calendars{$1}{$2} if ($2 ne 'admin_password')/ge;
$html_output =~ s/###event\{(\d+)\}\{(.+?)\}###/$events{$1}{$2}/ge;

$json_calendar_controls = encode_json( \%new_cookie_parms );

$json_events = "";
foreach $event_id (keys %events) {
	$json_events .= "jQuery.planscalendar.events['$event_id'] = " . event2json( $events{$event_id} ) . ";\n";
}

foreach $calendar_id (sort {$a <=> $b} keys %calendars) {
	$json_calendars .= "jQuery.planscalendar.calendars.push(" . calendar2json( $calendars{$calendar_id} ) . ");\n";
}

$json_pending_calendars = &calendars2json( \%new_calendars, 1 );

@temp = &assemble_icon_menus( $event_icons_menu );
$json_icons = encode_json( \@temp );

$json_event_background_colors = encode_json( \@event_bgcolors);

$insert_text =<<p1;
<script type="text/javascript" ><!--


###common javascript###
###page-specific javascript###

jQuery.planscalendar.calendar_controls = $json_calendar_controls;
$json_events
$json_calendars
jQuery.planscalendar.pending_calendars = $json_pending_calendars;
jQuery.planscalendar.icons = $json_icons;
jQuery.planscalendar.event_background_colors = $json_event_background_colors;

//-->
</script>
p1

chomp $insert_text;
$html_output =~ s/###javascript stuff###/$insert_text/;

# insert library javascript before all other javascript.
$temp = &get_js_includes( $theme_url );
$html_output =~ s/(<script)/$temp$1/;


#default page
&display_default();

exit(0);




sub display_default {
	my $common_javascript = "";
	my $page_javascript = "";
	my $browser_javascript = "";

	chomp $insert_text;
	my $css_text =<<p1;
<link rel="stylesheet" href="$theme_url/colorpicker/css/layout.css" type="text/css">
<link rel="stylesheet" href="$theme_url/colorpicker/css/colorpicker.css" type="text/css">
<link rel="stylesheet" href="$css_path" type="text/css">
p1


  $html_output =~ s/###css stuff###/$css_text/g;
  $html_output =~ s/###css file###/$css_path/g;  # holdover for pre-8.0 themes

  # tab menu stuff
 $insert_text =<<p1;
<br/>
p1


	#lay out the actual menu tabs
	for ($l1=0;$l1<scalar @{$lang{tab_text}};$l1++) {
		next if (&contains (\@disabled_tabs, $l1));
		my $tab_class = ($l1==0) ? 'ui-state-default ui-corner-top ui-tabs-selected ui-state-active' : 'ui-state-default ui-corner-top';

		$insert_text .=<<p1;
<li class="$tab_class">
<a href="#menu_tab_$l1"><span>$lang{tab_text}[$l1]</span></a>
</li>
p1
	}
	chomp $insert_text;


	if ($q->param('custom_calendar') == 1) {
		$html_output =~ s/###tab menu stuff###//g;
	} else {
		$html_output =~ s/###tab menu stuff###/$insert_text/g;
	}


	$insert_text ="";
	$event_details_js_template = "";

	foreach $event_id (keys %events) {
		$event_details_js_template = generate_event_details_template($events{$event_id});
		last; # we only need to do this once
	}

	#invisible html for context menu
    $insert_text .=<<p1;
<script type="text/html" id="event_details_tmpl">
$event_details_js_template
</script>
p1

  	# finished displaying tab menus, now display the appropriate stuff for the selected tab

  if ($active_tab eq "0") { # tab 1 = main calendar view


    $prev_month_link .=<<p1;
<a class="prev_next" href="$script_url/$name?cal_id=$current_cal_id&cal_start_month=$previous_cal_start_month&amp;cal_start_year=$previous_cal_start_year">$prev_string</a>
p1
    $next_month_link .=<<p1;
<a class="prev_next" href="$script_url/$name?cal_id=$current_cal_id&cal_start_month=$next_cal_start_month&amp;cal_start_year=$next_cal_start_year">$next_string</a>
p1

	$cal_controls_text = &generate_calendar_controls();

    if ($q->param('custom_calendar') == 1) {
      $html_output =~ s/###calendar controls###//g;
    } else {
      $html_output =~ s/###calendar controls###/$cal_controls_text/g;
    }

    if ( !$logged_in && $options{force_login} ) {
      $insert_text .= &forced_login();
    } else {
      $insert_text .= &do_calendar_list_view();
    }

    #select event range

    $cal_month_start_date = timegm(0,0,0,1,$cal_start_month,$cal_start_year);
    @cal_month_start_date_array = gmtime $cal_month_start_date;

    $events_start_timestamp = $cal_month_start_date - 604800;                            # +7 day margin
    $events_end_timestamp = &find_end_of_month($cal_end_month, $cal_end_year) + 604800;  # +7 day margin

    #now that we have selected the appropriate events, we can
    #generate the corresponding javascript and calendar view
    #and insert/add it to the html output.
    $page_javascript .= &calendar_view_javascript($events_start_timestamp, $events_end_timestamp);

    #replace javascript placeholders with actual html/javascript code

    $html_output =~ s/###previous month link###/$prev_month_link/g;
    $html_output =~ s/###next month link###/$next_month_link/g;

  }

  #done with main active tab stuff (the stuff that's different depending
  #on which tab is active.  The following stuff is the same regardless
  #of which tab is active.

  $html_output =~ s/###calendar area###/$insert_text/g;
  $html_output =~ s/###version###/$plans_version/g;


  my $add_event_to_current_cal_text =<<p1;
<a target = "_self" href="$script_url/$name?active_tab=1&amp;cal_id=$current_cal_id">$lang{add_event_to_this_calendar}</a>
p1
  chomp $add_event_to_current_cal_text;

  my $current_calendar_options_text =<<p1;
<a target="_self" href="$script_url/$name?active_tab=2&amp;cal_id=$current_cal_id&amp;add_edit_cal_action=edit">$lang{edit_calendar_options}</a>
p1
  chomp $current_calendar_options_text;

  my $current_calendar_subscribe_text =<<p1;
<a target="_new" href="$ical_export_url/plans_calendar_$current_calendar{id}.ics">$lang{subscribe_to_this_calendar}</a>
p1
  chomp $current_calendar_subscribe_text;

  $current_calendar_subscribe_text = '' if ( $options{'ical_export'} ne "1" );

  if ($active_tab eq "0") {
    $html_output =~ s/###add event to current calendar link###/$add_event_to_current_cal_text/;
    $html_output =~ s/###edit calendar options link###/$current_calendar_options_text/;
  	
    if ( !$logged_in && $options{force_login} ) {
      $html_output =~ s/###subscribe calendar link###//g;
      $html_output =~ s/###export calendar link###//;
      $html_output =~ s/###custom calendar link###//;
    } else {
  	  $html_output =~ s/###subscribe calendar link###/$current_calendar_subscribe_text/g;
      my $temp = &export_calendar_link();
      $html_output =~ s/###export calendar link###/$temp/;

      my $custom_calendar_link =<<p1;
<a href="javascript:custom_calendar()">$lang{make_custom_calendar}</a>
p1
      chomp $custom_calendar_link;
      $html_output =~ s/###custom calendar link###/$custom_calendar_link/;

      #$debug_info .= "custom calendar link: $custom_calendar_link\n";
    }
  } else {
    $html_output =~ s/###subscribe calendar link###//g;
    $html_output =~ s/###add event to current calendar link###//;
    $html_output =~ s/###edit calendar options link###//;
    $html_output =~ s/###custom calendar link###//;
    $html_output =~ s/###export calendar link###//;
  }


  # pending event stuff
  $html_output =~ s/###messages###//;

  my $pending_events_area = &generate_pending_events_area();

  if ($pending_events_area ne "") {
    $pending_events_area = <<p1;
<div id="logged_in_stuff">
$pending_events_area
</div>
p1
  }

  $html_output =~ s/###logged-in stuff###/$pending_events_area/;


  $common_javascript .= &common_javascript();
  $common_javascript .= &generate_pending_events_javascript() if (&pending_events_visible());


  #replace javascript placeholders with actual html/javascript code
  $html_output =~ s/###page-specific javascript###/\n$page_javascript/;
  $html_output =~ s/###common javascript###/\n$common_javascript/;


  $debug_info = "$error_info$debug_info";

  if ($debug_info =~ /\S/) {
    $debug_info =~ s/\n/<br\/>\n/g;
    $debug_info = <<p1;
<div style="width:100%;padding:10px;margin:10px;border:solid 1px #000;background-color:#fff;">
<b>Error, Warnings, & Debug Messages:</b><br/>
$debug_info
<\/div>
p1
  }
  $html_output =~ s/###debug stuff###/$debug_info/g;
  $html_output =~ s/###cookie_text###/$cookie_header_text/;

  print $html_output;

} #********************end default view code*****************************

sub add_edit_calendars {

	my %results;
	$results{'messages'} = [];
	$results{'success'} = 0;

	my $cal_id = $current_cal_id;    # need to validate cal id for add/edit

	my $cal_valid = 1;

	if ($q->param('add_edit_cal_action') eq "delete") {
		#delete calendar

		&load_events("all");
		&normalize_timezone();

		my $del_valid=1;

		#check password.

		if ($options{disable_passwords} ne "1" && !$logged_in_as_root && !$logged_in_as_current_cal_admin) {
			$del_valid=0;
			push @{$results{messages}}, "$lang{update_cal_error1}<b>$current_calendar{title}</b>";
		}

		# prevent delete of primary calendar
		if ($cal_id eq "0") {
			$del_valid=0;
			push @{$results{messages}}, $lang{update_cal_error2};
		}


		if ($del_valid == 1) { #actually delete the calendar.
			# first, delete all its events
			my @deleted_event_ids;
			my @updated_event_ids;
			foreach $event_id (keys %events) {
				# if the event is only on one calendar, delete it
				if (scalar@{$events{$event_id}{cal_ids}} == 1) {
					if ($events{$event_id}{cal_ids}[0] eq $cal_id) {
						push @deleted_event_ids, $event_id;
					} else {next;}
				} else { # otherwise, just remove that calendar from its cal_ids
					my $index=0;
					foreach $temp_cal_id (@{$events{$event_id}{cal_ids}}) {
						if ($temp_cal_id eq $cal_id) {
							break;
						}
						$index++;
					}
					splice @{$events{$event_id}{cal_ids}}, $index, 1; {
					push @updated_event_ids, $event_id;}
				}
			}
			&delete_events(\@deleted_event_ids);
			&update_events(\@updated_event_ids);

			# next, delete the calendar in question
			&delete_calendar($cal_id);  # redundant in flat-file mode, needed for sql mode

			# finally, delete any references in other calendars (background calendars)
			my @cals_to_update;

			foreach $calendar_id (sort {$a <=> $b} keys %calendars) {
				#$debug_info .= "calendar $calendar_id\n";
				if ($calendars{$calendar_id}{local_background_calendars}{$cal_id} eq "1") {
					delete $calendars{$calendar_id}{local_background_calendars}{$cal_id};
					push @cals_to_update, $calendar_id;
				}

				if ($calendars{$calendar_id}{selectable_calendars}{$cal_id} eq "1") {
					delete $calendars{$calendar_id}{selectable_calendars}{$cal_id};
					push @cals_to_update, $calendar_id;
				}
			}

			&update_calendars(\@cals_to_update);

			my $temp = $lang{update_cal_error3};
			$temp =~ s/###title###/$current_calendar{title}/;
			push @{$results{messages}}, $temp;
		}

		$results{success} = $del_valid;
		# properly format errors, warnings

    } else {  #the user added/updated a calendar

      #check all input fields for validity
      my $cal_title = $q->param('cal_title');
      my $cal_link = $q->param('cal_link');
      my $cal_details = $q->param('cal_details');

      my @local_background_calendars = $q->param('background_calendars');
      my @selectable_calendars = $q->param('selectable_calendars');
      my $list_background_calendars_together = $q->param('list_background_calendars_together');
      my $background_events_display_style = $q->param('background_events_display_style');
      my $background_events_fade_factor = $q->param('background_events_fade_factor');
      my $background_events_color = $q->param('background_events_color');
      my $new_calendars_automatically_selectable = "y" if ($q->param('new_calendars_automatically_selectable') =~ "y");

      my $allow_remote_calendar_requests = $q->param('allow_remote_calendar_requests');
      my $remote_calendar_requests_require_password = $q->param('remote_calendar_requests_require_password');
      my $remote_calendar_requests_password = $q->param('remote_calendar_requests_password');

      my $new_remote_calendars_xml = $q->param('new_remote_calendars_xml');
      my $calendar_events_color = $q->param('calendar_events_color');

      my $default_number_of_months = $q->param('default_number_of_months');
      my $max_number_of_months = $q->param('max_months');
      my $gmtime_diff = $q->param('gmtime_diff');
      my $date_format = $q->param('date_format');
      $date_format = lc $date_format;
      my $week_start_day = $q->param('week_start_day');
      my $event_change_email = $q->param('event_change_email');

      my $custom_template = $q->param('custom_template');
      $custom_template =~ s/http:\/\///g;

      my $custom_stylesheet = $q->param('custom_stylesheet');
      $custom_stylesheet =~ s/http:\/\///g;

      my $cal_password = $q->param('cal_password');
      my $new_cal_password = $q->param('new_cal_password');
      my $repeat_new_cal_password = $q->param('repeat_new_cal_password');

      $cal_title =~ s/\r//g;                 # some browsers sneak these in
      $cal_link =~ s/\r//g;                  # some browsers sneak these in
      $cal_details =~ s/\r//g;               # some browsers sneak these in

      #check for required fields
      if ($cal_title eq "") {
        $cal_valid=0;
		push @{$results{messages}}, '[error]' . $lang{update_cal_error5};
      }
	
      #strip all html from label field
      if ($cal_title =~ m/<(.*)>/) {
		push @{$results{messages}}, '[warning]' .$lang{update_cal_error6};
        $cal_title =~ s/<(.*)>//g;
      }

      $cal_link =~ s/http:\/\///g;  #strip http:// from link field

      #check for date format

     
      if ( $date_format =~ /y{2}/  && $date_format !~ /y{4}/ ) {
        $date_format =~ s/yy/yyyy/g;
      }

      if ($date_format !~ /^(mm|dd|yyyy)\W(mm|dd|yyyy)\W(mm|dd|yyyy)$/ ) {
        $cal_valid=0;
		push @{$results{messages}}, '[error]' .$lang{update_cal_error6_5};
      }

      if ($add_edit_cal_action eq "edit") {
        if ($options{disable_passwords} ne "1") {
          #this action is an edit of an existing calendar, so we need to make a replacement.
          if (!(defined $calendars{$cal_id})) {
            $cal_valid=0;
			push @{$results{messages}}, '[error]' .$lang{update_cal_error7};
          } else { #check password
            if ($options{disable_passwords} ne "1" && !$logged_in_as_root && !$logged_in_as_current_cal_admin) {
              $cal_valid=0;
				push @{$results{messages}}, '[error]' ."$lang{update_cal_error1} <b>$calendars{$cal_id}{title}</b>";
            }
          }

          #check for new password
          if ($new_cal_password ne "" || $repeat_new_cal_password ne "") {
            if ($new_cal_password ne $repeat_new_cal_password) {
              $cal_valid=0;
				push @{$results{messages}}, '[error]' .$lang{update_cal_error8};
            } else {
              $calendars{$cal_id}{password} = crypt($new_cal_password, $options{salt});
            }
          }
        }

        # check for gmtime_diff field
        if ($options{force_single_timezone} eq "1" && $cal_id ne "0") {
          $gmtime_diff = $calendars{0}{gmtime_diff}
        }

        # encrypt remote calendar password
        $remote_calendar_requests_password = crypt($remote_calendar_requests_password, $options{salt});

        if ($cal_valid == 1) {  # update calendar record
          my $xml_data = "";
          $calendars{$cal_id}{title} = $cal_title;
          $calendars{$cal_id}{details} = $cal_details;
          $calendars{$cal_id}{link} = $cal_link;
          $calendars{$cal_id}{new_calendars_automatically_selectable} = $new_calendars_automatically_selectable;
          $calendars{$cal_id}{list_background_calendars_together} = $list_background_calendars_together;
          $calendars{$cal_id}{calendar_events_color} = $calendar_events_color;
          $calendars{$cal_id}{background_events_display_style} = $background_events_display_style;
          $calendars{$cal_id}{background_events_fade_factor} = $background_events_fade_factor;
          $calendars{$cal_id}{background_events_color} = $background_events_color;
          $calendars{$cal_id}{default_number_of_months} = $default_number_of_months;
          $calendars{$cal_id}{max_number_of_months} = $max_number_of_months;
          $calendars{$cal_id}{gmtime_diff} = $gmtime_diff;
          $calendars{$cal_id}{date_format} = $date_format;
          $calendars{$cal_id}{week_start_day} = $week_start_day;
          $calendars{$cal_id}{event_change_email} = $event_change_email;
          $calendars{$cal_id}{custom_template} = $custom_template;
          $calendars{$cal_id}{custom_stylesheet} = $custom_stylesheet;
          $calendars{$cal_id}{allow_remote_calendar_requests} = $allow_remote_calendar_requests;
          $calendars{$cal_id}{remote_calendar_requests_require_password} = $remote_calendar_requests_require_password;
          $calendars{$cal_id}{remote_calendar_requests_password} = $remote_calendar_requests_password;

          # update local background calendars
          foreach $local_background_calendar (keys %{$calendars{$cal_id}{local_background_calendars}}) {
            delete $calendars{$cal_id}{local_background_calendars}{$local_background_calendar};
          }

          foreach $local_background_calendar (@local_background_calendars) {
            $calendars{$cal_id}{local_background_calendars}{$local_background_calendar} = 1;
          }

          #$debug_info .= "new remote calendars xml: $new_remote_calendars_xml\n";

          #delete existing remote background calendars
          foreach $current_remote_calendar_id (keys %{$current_calendar{remote_background_calendars}}) {
            if ($q->param("delete_remote_calendar_$current_remote_calendar_id") ne "") {
              my $temp = $lang{get_remote_calendar5};
              $temp =~ s/###remote url###/$current_calendar{remote_background_calendars}{$current_remote_calendar_id}{url}/g;
              $temp =~ s/###remote id###/$current_calendar{remote_background_calendars}{$current_remote_calendar_id}{remote_id}/g;
				push @{$results{messages}}, $temp;

              delete $calendars{$current_cal_id}{remote_background_calendars}{$current_remote_calendar_id};
            }
          }

          # update remote background calendars
          unless ($new_remote_calendars_xml eq "") {
            my %new_remote_calendars = %{&xml2hash($new_remote_calendars_xml)};
            #$debug_info .= "$new_remote_calendars{remote_calendars}{remote_calendar}\n";

            my $new_remote_cal_id = &max(keys %{$calendars{$cal_id}{remote_background_calendars}}) + 1;
            #$debug_info .= (scalar keys %{$calendars{$cal_id}{remote_background_calendars}})." remote calendars already\n";
            #$debug_info .= "new_remote_cal_id: $new_remote_cal_id\n";

            if ($new_remote_calendars{remote_calendars}{remote_calendar} =~ /array/i) { # multiple remote background calendars
              foreach $temp (@{$new_remote_calendars{remote_calendars}{remote_calendar}}) {
                my %new_remote_calendar = %{$temp};

                $found=0;
                foreach $current_remote_calendar_id (keys %{$current_calendar{remote_background_calendars}}) {
                  #$debug_info .= "comparing $current_calendar{remote_background_calendars}{$current_remote_calendar_id}{url} with $new_remote_calendar{url}\n";
                  $found=1 if ($current_calendar{remote_background_calendars}{$current_remote_calendar_id}{url} eq $new_remote_calendar{url} &&
                  $current_calendar{remote_background_calendars}{$current_remote_calendar_id}{type} eq $new_remote_calendar{type} &&
                  $current_calendar{remote_background_calendars}{$current_remote_calendar_id}{version} eq $new_remote_calendar{version} &&
                  $current_calendar{remote_background_calendars}{$current_remote_calendar_id}{password} eq $new_remote_calendar{password} &&
                  $current_calendar{remote_background_calendars}{$current_remote_calendar_id}{remote_id} eq $new_remote_calendar{remote_id});
                }

                if ($found==0) {
                  $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{url} = $new_remote_calendar{url};
                  $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{type} = $new_remote_calendar{type};
                  $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{version} = $new_remote_calendar{version};
                  $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{password} = $new_remote_calendar{password};
                  $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{remote_id} = $new_remote_calendar{remote_id};
                  $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{title} = $new_remote_calendar{title};
                  $new_remote_cal_id++;
                } else {
                  my $temp = $lang{get_remote_calendar4};
                  $temp =~ s/###remote url###/$new_remote_calendar{url}/g;
                  $temp =~ s/###remote id###/$new_remote_calendar{remote_id}/g;
				  push @{$results{messages}}, $temp;
                }

                #$debug_info .= "remote calendar: $new_remote_calendar{url}\n";
                #$debug_info .= "type: $new_remote_calendar{type}\n";
              }
            } else { # single remote background calendar

              # check against existing remote background calendars.
              my %new_remote_calendar = %{$new_remote_calendars{remote_calendars}{remote_calendar}};

              $found=0;
              foreach $current_remote_calendar_id (keys %{$current_calendar{remote_background_calendars}}) {
                #$debug_info .= "comparing $current_calendar{remote_background_calendars}{$current_remote_calendar_id}{url} with $new_remote_calendar{url}\n";
                if ($current_calendar{remote_background_calendars}{$current_remote_calendar_id}{url} eq $new_remote_calendar{url} &&
                  $current_calendar{remote_background_calendars}{$current_remote_calendar_id}{type} eq $new_remote_calendar{type} &&
                  $current_calendar{remote_background_calendars}{$current_remote_calendar_id}{version} eq $new_remote_calendar{version} &&
                  $current_calendar{remote_background_calendars}{$current_remote_calendar_id}{password} eq $new_remote_calendar{password} &&
                  $current_calendar{remote_background_calendars}{$current_remote_calendar_id}{remote_id} eq $new_remote_calendar{remote_id}) {
                  $found=1;
                }
              }

              if ($found==0) {
                $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{url} = $new_remote_calendar{url};
                $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{type} = $new_remote_calendar{type};
                $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{version} = $new_remote_calendar{version};
                $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{password} = $new_remote_calendar{password};
                $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{remote_id} = $new_remote_calendar{remote_id};
                $calendars{$cal_id}{remote_background_calendars}{$new_remote_cal_id}{title} = $new_remote_calendar{title};
              } else {
                my $temp = $lang{get_remote_calendar4};
                  $temp =~ s/###remote url###/$new_remote_calendar{url}/g;
                  $temp =~ s/###remote id###/$new_remote_calendar{remote_id}/g;
				  push @{$results{messages}}, $temp;
              }
            }
          }

          #$calendars{$cal_id}{remote_background_calendars} = $remote_calendar_requests_password;

          # update selectable calendars
          foreach $selectable_calendar (keys %{$calendars{$cal_id}{selectable_calendars}}) {
            delete $calendars{$cal_id}{selectable_calendars}{$selectable_calendar};
          }
          foreach $selectable_calendar (@selectable_calendars) {
            $calendars{$cal_id}{selectable_calendars}{$selectable_calendar} = 1;
          }
        }

        if ($cal_valid == 1) { #all checks successful, add/update calendar!
          &update_calendar($cal_id);
		  push @{$results{messages}}, "<b>$calendars{$current_cal_id}{title}</b> $lang{update_cal_success}";
        } else {
          $cal_add_results .= $lang{update_cal_failure};
        }
      } else {  # add new calendar
      
        # check password, if necessary
        if ($options{anonymous_calendar_requests} eq "1") {
			# TODO - come up with a better auth token
			
            #my $t1 = $q->param('as');
            #my $t2 = $rightnow;
            #if (abs($t1 - $t2) > 3600) {
            #  $cal_valid=0;
            #}
        } else {
        
          if ($options{disable_passwords} ne "1" && !$logged_in_as_root && !$logged_in_as_current_cal_admin) {
            $cal_valid=0;
		    push @{$results{messages}}, '[error]' ."$lang{update_cal_error0}";
          }
        } 

        #check new password
        if ($options{disable_passwords} ne "1") {
          if ($new_cal_password ne $repeat_new_cal_password) {
            $cal_valid=0;
		    push @{$results{messages}}, '[error]' . $lang{update_cal_error9};
          } elsif ($new_cal_password eq "" || $repeat_new_cal_password eq "" ) {
            $cal_valid=0;
		    push @{$results{messages}}, '[error]' . $lang{update_cal_error10};
          } else {
            $input_password = crypt($new_cal_password, $options{salt});
          }
        }

        my $new_cal_id;

        if ($cal_valid == 1) {
          $new_cal_id = $max_action_id + int(rand(100));  # just in case several people decide to add something new at the same time.

          $new_calendars{$new_cal_id}{id} = $new_cal_id;
          $new_calendars{$new_cal_id}{title} = $cal_title;
          $new_calendars{$new_cal_id}{details} = $cal_details;
          $new_calendars{$new_cal_id}{link} = $cal_link;
          $new_calendars{$new_cal_id}{list_background_calendars_together} = $list_background_calendars_together;
          $new_calendars{$new_cal_id}{calendar_events_color} = $calendar_events_color;
          $new_calendars{$new_cal_id}{background_events_fade_factor} = $background_events_fade_factor;
          $new_calendars{$new_cal_id}{background_events_color} = $background_events_color;
          $new_calendars{$new_cal_id}{default_number_of_months} = $default_number_of_months;
          $new_calendars{$new_cal_id}{max_number_of_months} = $max_number_of_months;
          $new_calendars{$new_cal_id}{gmtime_diff} = $gmtime_diff;
          $new_calendars{$new_cal_id}{date_format} = $date_format;
          $new_calendars{$new_cal_id}{week_start_day} = $week_start_day;
          $new_calendars{$new_cal_id}{custom_template} = $custom_template;
          $new_calendars{$new_cal_id}{custom_stylesheet} = $custom_stylesheet;
          $new_calendars{$new_cal_id}{password} = $input_password;
          $new_calendars{$new_cal_id}{update_timestamp} = $rightnow;
          $new_calendars{$new_cal_id}{allow_remote_calendar_requests} = $allow_remote_calendar_requests;
          $new_calendars{$new_cal_id}{remote_calendar_requests_require_password} = $remote_calendar_requests_require_password;
          $new_calendars{$new_cal_id}{remote_calendar_requests_password} = $remote_calendar_requests_password;

          # local background calendars
          foreach $local_background_calendar (@local_background_calendars) {
            $new_calendars{$new_cal_id}{local_background_calendars}{$local_background_calendar} = 1;
          }

          # selectable calendars
          foreach $selectable_calendar (@selectable_calendars) {
            $new_calendars{$new_cal_id}{selectable_calendars}{$selectable_calendar} = 1;
          }
        }

        # check for refreshes!
        if ($cal_valid == 1) {
          my %latest_new_calendar = $new_calendars{$latest_new_cal_id};
          if ($new_calendars{$new_cal_id}{title} eq $latest_new_calendar{title} &&
              $new_calendars{$new_cal_id}{details} eq $latest_new_calendar{details} &&
              $new_calendars{$new_cal_id}{link} eq $latest_new_calendar{link}) {
            $cal_valid = 0;
		    push @{$results{messages}}, $lang{update_cal_dup};
          }
        }

        if ($cal_valid == 1) { #all checks successful, add calendar!
          &add_action($new_cal_id, "new_calendar");
		  $results{'calendar'} = $new_calendars{$new_cal_id};

          my $new_cal_details = &generate_cal_details($new_calendars{$new_cal_id});
          $new_cal_details =~ s/<a.+Delete this.+<\/a>//;
          $new_cal_details =~ s/Link directly.+<\/a>//s;

          if ($options{new_calendar_request_notify} ne "") {
			my $body = <<p1;
$lang{add_cal_email_notify1}

$new_cal_details

<a href="$script_url/$name?active_tab=2&add_edit_cal_action=view_pending">$lang{add_cal_success3}</a>

p1
            &send_email($options{new_calendar_request_notify}, $options{reply_address}, $options{reply_address}, $lang{add_cal_email_notify2}, $body);
          }

          my $temp = $lang{add_cal_success1};  # add successful
          $temp = $lang{add_cal_success4} if ($add_edit_cal_action eq "edit"); # update successful
		  push @{$results{messages}}, $temp;
		  push @{$results{messages}}, $lang{add_cal_success2};

          $results{'calendars_waiting_for_approval'} = \%new_calendars;

        } else {
			push @{$results{messages}}, $lang{add_cal_fail1};
        }
      }
		$results{'success'} = $cal_valid;
    }

	return \%results;
} #********************end add_edit_calendars code*****************************


sub approve_delete_pending_calendars {

	my %results;
	$results{'messages'} = [];
	$results{'success'} = 1;

    my @pending_calendars_to_delete;
    my @calendars_to_add;
    my @calendars_to_update;

    #check password
    $input_password = crypt($q->param('main_password'), $options{salt});

    if ($options{disable_passwords} ne "1") {
		if ($input_password ne $master_password) {
			$results{'success'} = 0;
			push @{$results{messages}}, $lang{view_pending_calendars7};
			return \%results;
		}
    }

    #go through each new calendar in the new calendars file, take appropriate action
    foreach $new_cal_id (keys %new_calendars) {
		my $new_cal_details = &generate_cal_details($new_calendars{$new_cal_id});

		if ($q->param("pending_calendar_".$new_cal_id."_approve_delete") eq "approve") {
			$max_cal_id+=1; #calculate new id # for the new calendar

			foreach $cal_id (keys %calendars) {
				if ($calendars{$cal_id}{new_calendars_automatically_selectable} =~ "y") {
					$calendars{$cal_id}{selectable_calendars}{$max_cal_id} = 1;
					push @calendars_to_update, $cal_id;
				}
			}

			$calendars{$max_cal_id} = $new_calendars{$new_cal_id};
			$calendars{$max_cal_id}{id} = $max_cal_id;

			# make sure the calendar can select itself.
			$calendars{$max_cal_id}{selectable_calendars}{$max_cal_id} = 1 if (scalar keys %{$calendars{$max_cal_id}{selectable_calendars}} > 0);

			$approve_or_delete_result = $new_calendars{$new_cal_id}{'title'} . ' : ' .$lang{view_pending_calendars8};
			delete $new_calendars{$new_cal_id};
			push @pending_calendars_to_delete, $new_cal_id;
			push @calendars_to_add, $max_cal_id;

		} elsif ($q->param("pending_calendar_".$new_cal_id."_approve_delete") eq "delete") {
			$approve_or_delete_result = $new_calendars{$new_cal_id}{'title'} . ' : ' . $lang{view_pending_calendars9};
			delete $new_calendars{$new_cal_id};
			push @pending_calendars_to_delete, $new_cal_id;
		} else {
			$approve_or_delete_result = $new_calendars{$new_cal_id}{'title'} . ' : ' . $lang{view_pending_calendars10};
		}

		push @{$results{messages}}, $approve_or_delete_result;
    }

	&delete_pending_actions(\@pending_calendars_to_delete);
	&add_calendars(\@calendars_to_add);
	&update_calendars(\@calendars_to_update);
	return \%results;
} 


sub do_calendar_list_view() {
  my $return_text = "";

  if ($cal_num_months> 1) {
    $cal_title_string .=<<p1;
$months[$cal_start_month] $cal_start_year  - $months[$cal_end_month] $cal_end_year
p1
  } else {
    $cal_title_string .=<<p1;
$months[$cal_start_month] $cal_start_year
p1
  }

  # previous and next month(s) link
  $return_text .=<<p1;
<div style="text-align:center;white-space:nowrap;">
$prev_month_link
<span class="cal_title" style="margin-left:3em;margin-right:3em;">
$cal_title_string
</span>
$next_month_link
</div>


<div style="clear:both;margin:auto;">
p1

  if ($display_type == 1) { #list view

    $return_text .= &render_list($cal_start_month, $cal_start_year, $cal_end_month, $cal_end_year);
  } else {  #calendar view

    $return_text .= &render_calendar($cal_start_month, $cal_start_year, $cal_end_month, $cal_end_year);
  }
    $return_text .=<<p1;
</div>
p1
  return $return_text;

}  ###############end do_calendar_list_view ###################



sub add_edit_events {

  my %results;

  my $recurring_event = $q->param('recurring_event');
  my $all_in_series = $q->param('all_in_series');

  # load (reload) all events (we have to write events beyond the default time window)
  if ( $options{data_storage_mode} == 0 ) {
    unless ($loaded_all_events eq "1") {
      &load_events("all");
      &normalize_timezone();
    }
  }

  my $login_valid = 0;

  if ($options{disable_passwords} eq "1") {
    $login_valid = 1
  } elsif ($current_cal_id ne "") {
    #$debug_info .= "current_cal_id: $current_cal_id\n";
    if ($options{multi_calendar_event_mode} == 0 || $options{multi_calendar_event_mode} == 1)  { # only the event's calendar's user or the root user are allowed
      $login_valid = 1 if ($logged_in_as_root || $logged_in_as_current_cal_admin || $logged_in_as_current_cal_user);  # current calendar user
    } elsif ($options{multi_calendar_event_mode} == 2) { # any of the event's calendars' users or the root user are allowed
      if ($logged_in_as_root || $logged_in_as_current_cal_admin || $logged_in_as_current_cal_user)  { # current calendar user
        $login_valid = 1;
      } else {
        my $cal_password_valid = 0;
        foreach $cal_id (@evt_other_cal_ids) {
          my $temp = $cal_id;
          $cal_password_valid = 1 if ($profile->{calendar_permissions}->{$cal_id}->{admin} eq "1"); # shared calendar admin
          $cal_password_valid = 1 if ($profile->{calendar_permissions}->{$cal_id}->{user} ne "");  # shared calendar user
        }
        $login_valid = 1 if ($cal_password_valid == 1);
      }
    }
  }

  if ($q->param('del_event_button') ne "" || $api_command eq "delete_event") {
    $del_valid = 1;  #delete event.

    if ($login_valid == 0) {
      $del_valid = 0;
      push @{$results{messages}}, "[error]$lang{update_event_err1} '$current_calendar{title}'";
    }


    if ( ! &event_exists( $current_event_id ) ) {
      $del_valid=0;
      push @{$results{messages}}, "[error]$lang{update_event_err2}";
    }

    if ($del_valid == 1) { #actually delete the event(s).
      if ($all_in_series ne "1") {
        my $subj = $lang{notify_subj};
        $subj =~ s/\$1/$script_url\/$name/;

        my $body = $lang{event_delete_notify};
        $body =~ s/\$1/$events{$current_event_id}{title}/;
        $body =~ s/\$2/$calendars{$current_cal_id}{title}/;

        foreach $email (@{$current_calendar{delete_emails}}) {
          #$debug_info .= "email notification sent to $email\n";
          &send_email($email, $options{reply_address}, $options{reply_address}, $subj, $body) if ($options{email_mode} > 0);
        }

        &delete_event($current_event_id);
        push @{$results{messages}}, "[status]$lang{update_event_delete_successful}";

      } else {
        # get the ids of the events in the series.
        my @events_in_series = &get_events_in_series($q->param('series_id'));
        &normalize_timezone();
        &delete_events(\@events_in_series);
        push @{$results{messages}}, "[status]$lang{update_event_delete_successful_recurring}";
      }
      $results{success} = 1;
    } else {
      $results{success} = 0;
    }
  } else  { # not a delete
    if (!$login_valid) {
      if ($options{anonymous_events} && $add_edit_event eq "add" ) {
        my $temp = $lang{update_event_err16};
        $temp =~ s/###calendar###/<b>$current_calendar{title}<\/b>/g;
        push @{$results{messages}}, ("[error]".$temp);
      } else {
        push @{$results{messages}}, "[error]".($lang{update_event_err1}."'".$current_calendar{title}."'");
      }
    }

    #check all input fields for validity
    my $event_valid = 1;
    my $event_id = $q->param('evt_id');        # only if editing.
    #my $event_cal_id = $current_cal_id;

    my @evt_other_cal_ids;
    @evt_other_cal_ids = $q->param('evt_other_cal_ids') if ($options{multi_calendar_event_mode} > 0);

    my $event_cal_password = $q->param('cal_password');
    my $event_title = $q->param('evt_title');
    my $event_icon = $q->param('evt_icon');
    my $event_details = $q->param('evt_details');
    my $event_unit_number = $q->param('unit_number');
    my $event_bgcolor = $q->param('evt_bgcolor');
    my $event_block_merge = $q->param('evt_block_merge');
    my $event_series_id = $q->param('series_id');

    my $event_duration = 0;
    my $event_start_timestamp = 0;
    my $event_end_timestamp = 0;

    $recur_end_date = $q->param('recur_end_date');
    my $all_day_event = $q->param('evt_all_day_event');
    my $no_end_time = "";
    my $event_start_time = $q->param('evt_start_time');
    my $event_end_time = $q->param('evt_end_time');
    $event_start_date = $q->param('evt_start_date');
    my $event_days = $q->param('evt_days');

    my %recurrence_parms;
    $recurrence_parms{'recurrence_type'} = $q->param('recurrence_type');
    $recurrence_parms{'weekday_of_month_type'} = $q->param('weekday_of_month_type');
    $recurrence_parms{'every_x_days'} = $q->param('every_x_days');
    $recurrence_parms{'every_x_weeks'} = $q->param('every_x_weeks');
    $recurrence_parms{'year_fit_type'} = $q->param('year_fit_type');
    $recurrence_parms{'recur_end_date'} = $q->param('recur_end_date');
    my @custom_months = $q->param('custom_months');
    $recurrence_parms{'custom_months'} = \@custom_months;
    $recurrence_parms{'recur_end_timestamp'} = 0;

    my %input_parms;  # parms that are input by the user, but not stored as final event data
    $input_parms{'update_all_in_series'} = $q->param('all_in_series');
    $input_parms{'event_days'} = $event_days;
    $input_parms{'event_start_time'} = $event_start_time;
    $input_parms{'event_end_time'} = $event_end_time;
    $input_parms{'all_day'} = $all_day_event;

    # Check data for legitimacy.
    # some of these checks might be a bit redundant.
    if ($current_cal_id eq "") {
      $event_valid = 0;
      push @{$results{messages}}, "[error]".$lang{update_event_err3};
    }
    if ($event_title eq "") {
      $event_valid = 0;
      push @{$results{messages}}, "[error]".$lang{update_event_err4};
    }
    if ($event_icon eq "") {
      $event_valid = 0;
      push @{$results{messages}}, "[error]".$lang{update_event_err5};
    }

    $event_title =~ s/\r//g;                 # some browsers sneak these in
    $event_details =~ s/\r//g;               # some browsers sneak these in

    #strip html
    if ($event_title =~ m/<(.*)>/) {
      my $temp = $event_title;
      $temp =~ s/</&lt;/g;
      $temp =~ s/>/&gt;/g;
      push @{$results{messages}}, "[warning]".$lang{update_event_err7};
      $event_title =~ s/<(.*)>//g;
    }

    # strip out all non-numeric information from unit number
    my $unit_number = $event_unit_number;
    $unit_number =~ s/\D//g;

    #check event calendar name against existing calendars
    if (!defined == $calendars{$current_cal_id}) {
      $event_valid = 0;
      push @{$results{messages}}, "[error]".$lang{update_event_err8};
    }

    $event_valid = 0 if ($login_valid == 0 && !$options{anonymous_events});

    # check dates
    if ($event_valid == 1) {
      my $verify_date_results = &verify_date($event_start_date);
      if ($verify_date_results ne "") {
        $event_valid = 0;
        my @sub_results = split("\n", $verify_date_results);
        foreach $sub_result (@sub_results) {
          push @{$results{messages}}, "[error]$lang{update_event_err9} $sub_result";
        }
        
        if ($event_days eq "") {
          push @{$results{messages}}, "[error]$lang{update_event_err9}$lang{date_verify_err2}";
        }
        
        if ($event_days =~ m/\D/ || $event_days <= 0) {
          my $temp = $lang{date_verify_err3};
          $temp =~ s/\$1/$event_days/;
          push @{$results{messages}}, "[error]$lang{update_event_err9}$temp";
        }
      }
    }

    # check recurring "repeat until" date
    if ($event_valid == 1) {
      if ($recurring_event ne "" && $add_edit_event eq "add") {
        my $verify_date_results = &verify_date($recurrence_parms{'recur_end_date'}, \%recurrence_parms);
        if ($verify_date_results ne "") {
          $event_valid = 0;
          my @sub_results = split("\n", $verify_date_results);
          foreach $sub_result (@sub_results) {
            push @{$results{messages}}, "[error]$lang{update_event_err10} $sub_result";
          }
        }
      }
    }

    # check time
    if ($event_valid == 1 && $all_day_event ne "1") {
      my $verify_time_results = &verify_time($event_start_time);
      if ($verify_time_results ne "") {
        $event_valid = 0;
        my @sub_results = split("\n", $verify_time_results);
        foreach $sub_result (@sub_results) {
          push @{$results{messages}}, "[error]$lang{update_event_err14} $sub_result";
        }
      }

      if ($event_end_time ne "") {
        my $verify_time_results = &verify_time($event_end_time);
        if ($verify_time_results ne "") {
          $event_valid = 0;
          my @sub_results = split("\n", $verify_time_results);
          foreach $sub_result (@sub_results) {
            push @{$results{messages}}, "[error]$lang{update_event_err15} $sub_result";
          }
        }
      }
    }

    if ($event_valid == 1) {
      my ($start_mon, $start_mday, $start_year) = &format2mdy($event_start_date, $current_calendar{date_format});
      $start_mon--;  # convert month to 0-11 format

      ($event_start_timestamp, $event_end_timestamp) = &timestamp_from_datetime($start_mday,$start_mon,$start_year,$event_days,$event_start_time,$event_end_time,$all_day_event);

      $event_end_timestamp +=1 if ($event_start_timestamp == $event_end_timestamp);  # give all events a duration of at least 1 second

      $event_duration = $event_end_timestamp - $event_start_timestamp;
      $no_end_time = 1 if ($event_duration == 1);

      $recurrence_parms{'duration'} = $event_duration if ($recurring_event ne "");

      if ($recurring_event ne "" && $add_edit_event eq "add") {
        my ($recur_end_mon, $recur_end_mday, $recur_end_year) = &format2mdy($recurrence_parms{'recur_end_date'}, $current_calendar{date_format});
        $recur_end_mon--;
        $recurrence_parms{'recur_end_timestamp'} = timegm(0,0,0,$recur_end_mday,$recur_end_mon,$recur_end_year);
      }

      # display warning if start timestamp is before present date
      if ($event_start_timestamp < $rightnow-86400) {
        push @{$results{messages}}, "[warning]$lang{update_event_err11}";
      }
    }

    # check for refreshes!
    if ($recurring_event eq "") {
      my %latest_event = $events{$latest_event_id};

      if ($latest_event{cal_ids}[0] eq $current_cal_id &&
          $latest_event{start} eq $event_start_timestamp &&
          $latest_event{end} eq $event_end_timestamp &&
          $latest_event{title} eq $event_title &&
          $latest_event{details} eq $event_details &&
          $latest_event{icon} eq $event_icon &&
          $latest_event{bgcolor} eq $event_bgcolor &&
          $latest_event{unit_number} eq $event_unit_number) {
        $event_valid = 0;
        push @{$results{messages}}, "[error]$lang{update_event_err12}";
      }
    } else { # recurring event refresh protection is a little trickier.
      # it's currently not implemented
    }

    if ($add_edit_event eq "edit") {
      #check to make sure the event id matches some event in the data structure. It always should, but we check anyway.
      if (!defined $events{$event_id}) {
        $event_valid = 0;
        push @{$results{messages}}, "[error]$lang{update_event_err13}";
      }
    }

    # properly format errors & warnings
    $message_results="";

    if ($event_valid == 1) {
      $results{success} = 1;
      #$debug_info .= "(add_update_event) event_id: $event_id\n";
      unshift @evt_other_cal_ids, $current_cal_id;

      my %new_event = (recurring => $recurring_event,
                       cal_ids => \@evt_other_cal_ids,
                       start => $event_start_timestamp,
                       end => $event_end_timestamp,
                       all_day_event => $all_day_event,
                       days => &calculate_event_days($event_start_timestamp, $event_end_timestamp),
                       title => $event_title,
                       details => $event_details,
                       icon => $event_icon,
                       bgcolor => $event_bgcolor,
					   block_merge => $event_block_merge,
                       unit_number => $event_unit_number,
                       update_timestamp => $rightnow,
                       existing_id => $event_id,
                       recurrence_parms => \%recurrence_parms);

      if ($login_valid) {
		my %commit_results = %{&commit_event(\%new_event, \%input_parms)};
		my @commit_messages = @{$commit_results{messages}};
		my @new_event_ids = @{$commit_results{new_event_ids}};
        $results{messages} = \(@{$results{messages}}, @commit_messages);  # array concatenate
        $results{new_event_ids} = \@new_event_ids;
      } elsif ( $options{anonymous_events} && $add_edit_event eq "add"  ) { # anonymous event add -> update queue
        my $new_event_id = $max_action_id + int(rand(100));  # just in case several people decide to add something new at the same time.
        $new_event{id} = $new_event_id;

        # add event to %events data structure
        $new_events{$new_event_id} = \%new_event;

        # notify email(s)
        if ($options{email_mode} > 0) {
          my $subj = $lang{notify_subj};
          $subj =~ s/\$1/$script_url\/$name/;

          my $body = $lang{event_pending_notify};
          $body =~ s/\$1/$events{$current_event_id}{title}/;
          $body =~ s/\$2/$calendars{$current_cal_id}{title}/;
          $body =~ s/\$3/$script_url\/$name?view_pending_event=1&pending_event_id=$new_event_id/;

          foreach $add_email (@{$current_calendar{add_emails}}) {
            push @{$results{messages}}, "[status]email notification sent to $add_email";
            &send_email($add_email, $options{reply_address}, $options{reply_address}, $subj, $body);
          }
        }

        &add_action($new_event_id, "new_event");
        $event_box_text .= &generate_event_details(\%new_event, $event_details_template);

        $results{text} .= <<p1;
<p style="font-weight:bold;">$lang{update_event_add_pending_successful}</p>
$event_box_text
<ul>
<li><a href="$script_url/$name?active_tab=1">$lang{update_event_add_successful_add_new}</a></li>
</ul>
p1
      } else {
        $results{'success'} = 0;
      }
     
    }
  }

  return \%results;

} #******************** end add_edit_event *****************************


sub commit_event() { # commit an add or update of an event
	my ($new_event_ref, $input_parms_ref) = @_;

		
	my %results;
	$results{'messages'} = [];
	$results{'new_event_ids'} = [];

	my $new_event_id;

	my %new_event = %{$new_event_ref};
	my %input_parms = %{$input_parms_ref};

	
	#unless ($loaded_all_events eq "1") {
	#	&load_events("all");
	#	&normalize_timezone();
	#}

	if ($add_edit_event eq "add")  { # add a new event
		if ($new_event{'recurring'} eq "") {
			my $event_box_text = "";
			$new_event_id = ++$max_event_id;

			$events{$new_event_id} = deep_copy(\%new_event);
			$events{$new_event_id}{id} = $new_event_id;

			&add_event($new_event_id);
			$event_box_text .= &generate_event_details($events{$new_event_id}, $event_details_template);
			
			push @{$results{new_event_ids}}, $new_event_id;
			#temporarily offset event times by calendar gmtime diff

			push @{$results{messages}}, $lang{update_event_add_successful};
		} else { # recurring events loop
			my %recurrence_parms = %{$new_event{'recurrence_parms'}};

			my $new_series_id = ++$max_series_id;

			my $date_text = "";

			my @recurring_events_timestamps = @{&calculate_recurring_events($new_event{'start'}, \%recurrence_parms)};

			my @recurring_event_ids = ();

			foreach $recurring_event_start_timestamp (@recurring_events_timestamps) {
				my $new_event_id = ++$max_event_id;
				my $recurring_event_end_timestamp = $recurring_event_start_timestamp + $recurrence_parms{'duration'};

				$events{$new_event_id} = deep_copy(\%new_event);
				$events{$new_event_id}{id} = $new_event_id;
				$events{$new_event_id}{series_id} = $new_series_id;
				$events{$new_event_id}{start} = $recurring_event_start_timestamp;
				$events{$new_event_id}{end} = $recurring_event_end_timestamp;
				$events{$new_event_id}{recurrence_parms} = [];

				push @recurring_event_ids, $new_event_id;
				push @{$results{new_event_ids}}, $new_event_id;

				my $date_range = &nice_date_range_format($recurring_event_start_timestamp, $recurring_event_end_timestamp, "-");

				$date_text .= <<p1;
<li>$date_range</li>
p1
			}

			&add_events(\@recurring_event_ids);

			$event_box_text .= &generate_event_details($events{$max_event_id}, $event_details_template);

			my $temp = <<p1;
<p style="font-weight:bold;">$lang{update_event_add_successful_recurring}</p>
<ul>
$date_text
</ul>
$event_box_text
p1
			push @{$results{messages}}, $temp;
		}

		if ($options{email_mode} > 0) {
			my $subj = $lang{notify_subj};
			$subj =~ s/\$1/$script_url\/$name/;

			my $body = $lang{event_add_notify};
			$body =~ s/\$1/$new_event{title}/;
			$body =~ s/\$2/$calendars{$current_cal_id}{title}/;
			$body =~ s/\$3/$script_url\/$name?view_event=1&evt_id=$max_event_id/;

			foreach $add_email (@{$current_calendar{add_emails}}) {
				push @{$results{messages}}, "[status]email notification sent to $add_email";
				&send_email($add_email, $options{reply_address}, $options{reply_address}, $subj, $body);
			}
		}
	} elsif ($add_edit_event eq "edit") { #if we need to replace an existing record
		my $event_id = $new_event{'existing_id'};
		&load_event( $event_id );
		&normalize_timezone( );

		my $old_series_id = $events{$event_id}{'series_id'};

		if ($new_event{'recurring'} eq "" || $input_parms{'update_all_in_series'} ne "1") {
			$events{$event_id} = deep_copy(\%new_event);
			$events{$event_id}{id} = $event_id;
			$events{$event_id}{'series_id'} = $old_series_id;

			&update_event($event_id);
			push @{$results{new_event_ids}}, $event_id;

			$event_box_text .= &generate_event_details($events{$event_id}, $event_details_template);

			push @{$results{messages}}, $lang{update_event_update_successful};
		} else  { # update recurring events
			# get the ids of the events in the series.
        	my @events_in_series = &get_events_in_series($old_series_id);
			&normalize_timezone( );

			foreach $event_id (@events_in_series) {
				my %event = %{$events{$event_id}};

				my @temp = gmtime($event{end});

				($recurring_event_start_timestamp, $recurring_event_end_timestamp) = &timestamp_from_datetime($temp[3],$temp[4],$temp[5]+1900,$input_parms{'event_days'},$input_parms{'event_start_time'},$input_parms{'event_end_time'},$input_parms{'all_day'});

				$events{$event_id} = deep_copy(\%new_event);
				$events{$event_id}{id} = $event_id;
				$events{$event_id}{series_id} = $old_series_id;
				$events{$event_id}{start} = $recurring_event_start_timestamp;
				$events{$event_id}{end} = $recurring_event_end_timestamp;
				$events{$event_id}{recurrence_parms} = [];
				push @{$results{new_event_ids}}, $event_id;
			}
			&update_events(\@events_in_series);

			push @{$results{messages}}, $lang{update_event_update_successful_recurring};
		}

		if ($options{email_mode} > 0) {
			my $subj = $lang{notify_subj};
			$subj =~ s/\$1/$script_url\/$name/;

			my $body = "";
			$body = $lang{event_update_notify};
			$body =~ s/\$1/$new_event{title}/;
			$body =~ s/\$2/$calendars{$current_cal_id}{title}/;
			$body =~ s/\$3/$script_url\/$name?view_event=1&evt_id=$event_id/;

			foreach $email (@{$current_calendar{update_emails}}) {
				$debug_info .= "email notification sent to $email\n";
				&send_email($email, $options{reply_address}, $options{reply_address}, $subj, $body);
			}
		}
	}

	return \%results;
}





sub common_javascript {
  my $logged_in_boolean = ($logged_in) ? "true":"false";
  my $date_format = lc $current_calendar{date_format};
  $return_string .=<<p1;



jQuery.planscalendar.plans_url = '$script_url/$name';
jQuery.planscalendar.theme_url = '$theme_url';
jQuery.planscalendar.css_path = '$css_path';
jQuery.planscalendar.date_format = '$date_format';
jQuery.planscalendar.current_calendar_id = '$current_calendar{id}';
jQuery.planscalendar.logged_in = $logged_in_boolean;

jQuery.planscalendar.plans_options['right_click_menus_enabled'] = $options{right_click_menus_enabled};
jQuery.planscalendar.plans_options['disable_passwords'] = $options{disable_passwords};
jQuery.planscalendar.plans_options['sessions'] = $options{sessions};
jQuery.planscalendar.plans_options['anonymous_events'] = $options{anonymous_events};
jQuery.planscalendar.plans_options['users'] = $options{users};
jQuery.planscalendar.plans_options['all_calendars_selectable'] = $options{all_calendars_selectable};
jQuery.planscalendar.plans_options['email_mode'] = $options{email_mode};
jQuery.planscalendar.plans_options['unit_number_icons'] = $options{unit_number_icons};
jQuery.planscalendar.plans_options['new_events_all_day'] = $options{new_events_all_day};
jQuery.planscalendar.plans_options['default_event_start_time'] = '$options{default_event_start_time}';
jQuery.planscalendar.plans_options['default_event_end_time'] = '$options{default_event_end_time}';
jQuery.planscalendar.plans_options['twentyfour_hour_format'] = '$options{twentyfour_hour_format}';
jQuery.planscalendar.plans_options['allow_merge_blocking'] = '$options{allow_merge_blocking}';
jQuery.planscalendar.plans_options['multi_calendar_event_mode'] = '$options{multi_calendar_event_mode}' * 1;
jQuery.planscalendar.plans_options['show_event_background_color_descriptions'] = '$options{show_event_background_color_descriptions}' * 1;


p1

  return $return_string;
}  #********************end common_javascript **********************


sub calendar_view_javascript {
  my ($events_start_timestamp, $events_end_timestamp) = @_;
  my $return_string="";

  #generate pre-formatted html for each event view
  $return_string .= &generate_event_details_javascript($events_start_timestamp, $events_end_timestamp);


  $return_string .=<<p1;

function custom_calendar() {

p1

  $custom_form_text .=<<p1;
<div class="cal_title">
$lang{custom_calendar_title}
</div>

<form action="$script_url/$name" method="POST">
<input type="hidden" name="custom_calendar" value="1">

<label for="custom_calendar_calendar" class="required_field">
$lang{custom_calendar_choose_calendar}
</label>
<br/>
<select id="custom_calendar_calendar" name="custom_calendar_calendar">
p1

  foreach $cal_id (sort {$a <=> $b} keys %calendars) {
    $custom_form_text .=<<p1;
<option value = "$cal_id">$calendars{$cal_id}{title}
p1
  }

  $custom_form_text .=<<p1;
</select>
<br/><br/>
<label for="custom_calendar_background_calendars" class="optional_field">
$lang{custom_calendar_choose_bg_calendar}
</label>
<br/>

<select id="custom_calendar_background_calendars" name="custom_calendar_background_calendars" multiple size=6>
p1

  foreach $cal_id (sort {$a <=> $b} keys %calendars) {
    $custom_form_text .=<<p1;
<option value = "$cal_id">$calendars{$cal_id}{title}
p1
  }

  $custom_form_text .=<<p1;
</select>
<br/><br/>
p1

  if ($display_type == 1) {$list_selected = "selected";} else {$cal_selected = "selected";}

  $custom_form_text .=<<p1;
<label for="display_type" class="required_field">
$lang{custom_calendar_display_type}
</label>
<select name="display_type" onChange="jQuery.planscalendar.blink('#controls_submit_button');">
p1

    #foreach $possible_display_type (@{$options{display_types}})
    for (my $l1=0;$l1<scalar @{$options{display_types}};$l1++) {
      if ($options{display_types}[$l1] ne "1") {
next};
      my $selected="";

      if ($l1 eq $display_type) {
$selected = "selected";}

      $custom_form_text .=<<p1;
<option value="$l1" $selected>$lang{controls_display_type}[$l1]
p1
    }
    $custom_form_text .=<<p1;
</select>
<br/><br/>

<label for="cal_start_month" class="required_field">
$lang{custom_calendar_time_range}
</label>

<table class="layout" summary="">
<tr><td nowrap align=right>

$lang{controls_start_month}
</td><td nowrap>
<select id="cal_start_month" name="cal_start_month">
p1
  #list each month in the year
  $month_index=0;
  foreach $possible_month (@months) {
    if ($cal_start_month eq $month_index) {
      $custom_form_text .=<<p1;
<option value="$month_index" selected>$possible_month
p1
    } else {
      $custom_form_text .=<<p1;
<option value="$month_index">$possible_month
p1
    }
    $month_index++;
  }
  $custom_form_text .=<<p1;
</select>
<input name="cal_start_year" value = "$cal_start_year" size=4>
</td></tr>
<tr><td nowrap align=left colspan=2>

$lang{controls_num_months}
<input name="cal_num_months" value = "$cal_num_months" size=3>

</td></tr>
</table>
<br/><br/>

<input type=submit value = "$lang{custom_calendar_make_calendar}">
p1
  $custom_form_text =~ s/\//\\\//g;
  $custom_form_text =~ s/\n/\\n/g;
  $custom_form_text =~ s/"/\\"/g;

  $return_string .=<<p1;
  info_window = this.open("", "info_window", "resizable=yes,status=yes,scrollbars=yes,width=400,height=500");
  doc = info_window.document;
  doc.open('text/html');
  doc.write('<html>');
  doc.write('<title>$lang{custom_calendar_title}<\\/title>');
  doc.write('<base target=\\"'+main_window_name+'\\">');
  doc.write('<link rel=\\"stylesheet\\" href=\\"$css_path\\" type=\\"text/css\\" media=screen>');
  doc.write('<body>');
  doc.write("$custom_form_text");
  doc.write('<\\/body><\\/html>');
  doc.close();
  //info_window.focus();
}

p1
  return $return_string;
}  #***********************end calendar_view_javascript************************"






sub generate_users_javascript() {
	my ($cal_id) = @_;
	my $results = "";
	my @user_results = [];
	foreach $user_id (keys %users) {
		my $valid_for_current_calendar = 0;

		foreach $cal_id (keys %{$users{$user_id}{calendars}}) {
			if ($cal_id eq $current_cal_id) {
				$valid_for_current_calendar = 1;
				last;
			}
		}

		next if ($valid_for_current_calendar == 0);
	#next if ($user_id eq "");

		my %user = %{$users{$user_id}};
		push @user_results, {'user_id' => $user_id,
							 'user_name' => $user{'name'}};
	}
	return @user_results;
}

sub generate_pending_events_javascript() {

	my $results = "";
	my @pending_events = &pending_events_as_array();

	$results = 'jQuery.planscalendar.pending_events = ' . encode_json( \@pending_events ) . ";\n";

	return $results;
}

sub pending_events_as_array() {

	my $results = "";
	my @pending_events;

	foreach $pending_event_id (sort {$new_events{$a}{update_timestamp} <=> $new_events{$b}{update_timestamp}} keys %new_events) {

		my %pending_event = %{$new_events{$pending_event_id}};
		push @pending_events, \%pending_event;
		
	}

	return @pending_events;
}



sub add_edit_calendars_javascript {
	my $return_string = "";

	$return_string .= &generate_users_javascript($current_calendar{id});

	my $editing_calendar = ( $q->param('add_edit_cal_action') eq "edit" ) ? 'true' : 'false';

  $return_string.=<<p1;
var editing_calendar = $editing_calendar;

function update_users() {
  if (!users || users.length == 0) return;
}


p1

  $return_string.=<<p1;

function show_help() {
  info_window = this.open("", "info_window", "resizable=yes,status=yes,scrollbars=yes,top="+info_window_y+",left="+info_window_x+",width=400,height=400");

  doc = info_window.document;
  doc.open('text/html');
  doc.write('<html>');
  doc.write('<title>$lang{help_box_title}<\\/title>');
  doc.write('<link rel=\\"stylesheet\\" href=\\"$css_path\\" type=\\"text/css\\" media=screen>');
  doc.write('$popup_javascript_info');

  doc.write('<body onResize=\\"javascript:do_onresize()\\">');
  doc.write(help_text);
  doc.write('<\\/body><\\/html>');
  doc.close();
  //info_window.focus();
}

function preview_cal() {
  var cal_title = document.update_cal_form.cal_title.value
  var cal_link = document.update_cal_form.cal_link.value
  var cal_details = document.update_cal_form.cal_details.value;

  if (cal_title == "") {
    evt_label = "<span style=\\"color:#ff0000\\">$lang{preview_calendar_temp_title}<\\/span>";
    add_disable = true;
  }

  //
  if (document.getElementById("preview_warning")) {
    document.getElementById("preview_warning").innerHTML="";
  }

  info_window = this.open("", "info_window", "resizable=yes,status=yes,scrollbars=yes,top="+info_window_y+",left="+info_window_x+",width=400,height=400");

  doc = info_window.document;
  doc.open('text/html');
  doc.write('<html>');
  doc.write('<title>$lang{preview_calendar_title}<\\/title>');
  doc.write('<link rel=\\"stylesheet\\" href=\\"$css_path\\" type=\\"text/css\\" media=screen>');
  doc.write('$popup_javascript_info');

  doc.write('<body onResize=\\"javascript:do_onresize()\\">');
  doc.write("<div class=\\"info_box\\" style=\\"padding:5px;\\"><br/><div style=\\"white-space:nowrap;\\"><span class=\\"cal_title\\">");
  doc.write("<a target=\\"_blank\\" href=\\""+cal_link+"\\">"+cal_title+"<\\/a><\\/span><\\/div><br/><div>"+cal_details+"<\\/div><\\/div>");
  doc.write('<\\/body><\\/html>');
  doc.close();
  //info_window.focus();
}
p1

  my @help_text_map = ("title",
                       "link",
                       "details",
                       "password",
                       "new_password",
                       "current_password",
                       "change_password",
                       "selectable_calendars",
                       "background_calendars",
                       "remote_background_calendars",
                       "background_events_display_style",
                       "events_display_style",
                       "list_background_calendars_together",
                       "default_number_of_months",
                       "max_months",
                       "gmtime_diff",
                       "date_format",
                       "week_start_day",
                       "new_calendars_automatically_selectable",
                       "allow_remote_calendar_requests",
                       "remote_calendar_requests_password",
                       "event_change_email",
                       "popup_window_size",
                       "custom_stylesheet",
                       "custom_template",
                       "add_user",
                       "add_new_ical");

  my $help_text_javascript = "";
  foreach $key (@help_text_map) {
    my  $help_text=<<p1;
<div class="help_box">
$lang{'help_cal_'.$key}
</div>
p1
    $help_text =~ s/\n/\\n/g;
    $help_text =~ s/"/\\"/g;
    $help_text =~ s/'/\\'/g;
    $help_text =~ s/\//\\\//g;
    $help_text =~ s/###css file###/$css_path/g;

    $help_text_javascript .=<<p1;
    if (topic == "$key")
      help_text += "$help_text";
p1
  }

  return $return_string
}  #********************end add_edit_calendars_javascript**********************


sub generate_cal_details() {
  my ($calendar_ref) = @_;

  my %calendar = %{$calendar_ref};

  my $results = <<p1;
<div class="cal_title">
$calendar{title}
</div>

<div>
$calendar{details}
</div>
p1

$writable{calendar_file}  and $return_text .= <<p1;
<div style="white-space:nowrap;">
<span class="small_note">
<a href="$script_url/$name?active_tab=2&amp;add_edit_cal_action=edit&amp;cal_id=$calendar{id}">$lang{calendar_add_edit}</a>
</span>
</div>
p1

  $return_text .= <<p1;
<div style="white-space:nowrap;margin-top:2em;">
<span class="small_note">
$lang{calendar_direct_link}<br/>
<a href="$script_url/$name?cal_id=$calendar{id}">$script_url/$name?cal_id=$calendar{id}</a>
</span>
</div>
p1

  return $results;
}



sub render_calendar {
	my ($cal_start_month, $cal_start_year, $cal_end_month, $cal_end_year, $selected_events) = @_;

  my $return_text = "";
  my $week_events = {};
  my $week_slots = {};
  my $debug = 0;
  my @debug_events = ("105");
  
  my $show_month_breaks = ($cal_num_months > 1 && $options{continuous_multimonth} ne '1' ? 1 : 0);

  my $cal_month_idx = 0;
  my $last_cal_month;
  my $is_first_cal_date = 1;
  my @use_other_month = (0, 1);

  #initialize loop variables
  my $cal_start_timestamp = timegm(0,0,0,1,$cal_start_month,$cal_start_year);
  my $cal_end_timestamp = find_end_of_month($cal_end_month, $cal_end_year);

  my $current_month = $cal_start_month;
  my $current_year = $cal_start_year;

  while ($current_year < $cal_end_year || ($current_year == $cal_end_year && $current_month <= $cal_end_month)) {
    $last_cal_month = ($current_year * 100 + $current_month) == ($cal_end_year * 100 + $cal_end_month);

    foreach $key (keys %week_events) {delete $week_events{$key};}
    foreach $key (keys %week_slots) {delete $week_slots{$key};}

    #for calendars with multiple months, display the name of each month above the calendar
    if ($show_month_breaks) {
      $return_text .=<<p1;
<p class="cal_month_title" style="padding:5px;">
$months[$current_month] $current_year
</p>
p1
    }
    #calculate where to start the calendar (first sunday)
    #first, calculate what day of the week this month begins on

    #format for timegm: timegm($sec,$min,$hour,$mday,$mon,$year);

    my $cal_month_start_date = timegm(0,0,0,1, $current_month, $current_year);
    my @cal_month_start_date_array = gmtime $cal_month_start_date;

    my $cal_start_day_offset = $cal_month_start_date_array[6] - $current_calendar{week_start_day};
    $cal_start_day_offset += 7 if ($cal_start_day_offset < 0);

    my $cal_start_date = $cal_month_start_date - (86400 * $cal_start_day_offset);

    # in continuous_multimonth mode, skip first week if we already drew it in the previous iteration
    $cal_start_date = $cal_start_date + 604800 if (!$show_month_breaks && $cal_month_idx > 0 && $cal_start_day_offset != 0);
    
    # start with other_month if the first month does not start on the first day of the week (i.e there is an offset)
    @use_other_month = (1, 0) if (!$show_month_breaks && $cal_month_idx == 0 && $cal_start_day_offset != 0 && $current_month % 2);

    my @cal_start_date_array = gmtime $cal_start_date;

    my $cal_end_date = $cal_start_date + 86400*37;

    my $next_month = $current_month+1;
    if ($next_month == 12) {$next_month=0;}

    #cal_date keeps track of the date (in timestamp format)
    #as the calendar loop iterates through each day on the calendar page
    my $cal_date = $cal_start_date;
    my @cal_date_array = gmtime $cal_date;

    my %max_day_events;
    my %week_max_slots;

    #make a first pass through the month, assemble event week events structure:
    #week_events{week_index}{id} ={}
    #this hash has 4 keys--start_weekday, start_day, length and slot_order (slot_order will be calculated in the second pass)
    for ($l1=0;$cal_date_array[4] != $next_month;$l1++)  { #each calendar has 5 or 6 weeks
      $week_start_timestamp = $cal_date;
      $week_end_timestamp = $week_start_timestamp + 604800;
      $max_day_events{$l1} = 0;

      @cal_date_array = gmtime $cal_date;
      foreach $event_id (keys %events) {
        $debug = 1 if ($debug == 1 && (&contains(\@debug_events, $event_id) || $debug_events[0] eq "all"));

        my %event = %{$events{$event_id}};

        if (&time_overlap($event{start}, $event{end}, $week_start_timestamp, $week_end_timestamp)) {

          my @event_date_array = gmtime $event{start};
          my @event_end_date_array = gmtime $event{end};
          my $event_start_weekday = $event_date_array[6] - $current_calendar{week_start_day};
          my $event_end_weekday = $event_end_date_array[6] - $current_calendar{week_start_day};

          $event_start_weekday +=7 if ($event_start_weekday < 0);
          $event_end_weekday +=7 if ($event_end_weekday < 0);

          #$event_start_weekday = 0 if ($event_start_weekday < 0);
          #$event_end_weekday = 0 if ($event_end_weekday < 0);
          #$event_start_weekday = 6 if ($event_start_weekday > 6);
          #$event_end_weekday = 6 if ($event_end_weekday > 6);

          my $days_before_week_start = 0;
          my $days_after_week_end = 0;

          $debug_info .= "week $l1 event $event_id event_date_array[6]: $event_date_array[6]\n" if ($debug);
          $debug_info .= "week $l1 event $event_id event_end_date_array[6]: $event_end_date_array[6]\n" if ($debug);
          $debug_info .= "week $l1 event $event_id current_calendar{week_start_day}: $current_calendar{week_start_day}\n" if ($debug);
          $debug_info .= "week $l1 event $event_id event_start_weekday: $event_start_weekday event_end_weekday: $event_end_weekday\n" if ($debug);

          # the event might fall completely within the week boundary, or it
          # might overlap event begins or ends outside the week boundaries
          # (there are four possible cases):
          if ($event{start} < $week_start_timestamp && $event{end} > $week_end_timestamp) { # the event both starts and ends outside this week
            $debug_info .= "case 0\n" if ($debug);
            $week_events{$l1}{$event{id}}{start_weekday} = 0;
            $week_events{$l1}{$event{id}}{length} = 7;
          } elsif ($event{start} < $week_start_timestamp) {  # the event starts before this week and ends within it
            $debug_info .= "case 1\n" if ($debug);
            #$days_before_week_start = int(($week_start_timestamp - $event{start})/86400);
            $week_events{$l1}{$event{id}}{start_weekday} = 0;
            #$week_events{$l1}{$event{id}}{length} = $event{days} - $days_before_week_start;
            $week_events{$l1}{$event{id}}{length} = $event_end_weekday+1;
            $debug_info .= "week $l1 event $event_id week_start_timestamp: $week_start_timestamp start: $event{start} start_wkday: $week_events{$l1}{$event{id}}{start_weekday} length: $week_events{$l1}{$event{id}}{length}\n" if ($debug);
          } elsif ($event{end} > $week_end_timestamp) { # the event starts within this week and ends after it
            $debug_info .= "case 2\n" if ($debug);
            $week_events{$l1}{$event{id}}{start_weekday} = $event_start_weekday;
            $week_events{$l1}{$event{id}}{length} = 7-$event_start_weekday;
            if ($debug == 1) {
             foreach $debug_event_id (@debug_events) {
                next if ($debug_event_id ne $event{id});
                $debug_info .= "event $debug_event_id days: $events{$debug_event_id}{days} event_start_weekday: $event_start_weekday event_end_weekday: $event_end_weekday  length: $week_events{$l1}{$debug_event_id}{length}\n";
             }
            }
          } else { #the event begins and ends within the week
            $debug_info .= "case 3\n" if ($debug);
            $week_events{$l1}{$event{id}}{length} = $event{days};
            $week_events{$l1}{$event{id}}{start_weekday} = $event_start_weekday;
          }

          if ($week_events{$l1}{$event{id}}{start_weekday} < 0) {
            $week_events{$l1}{$event{id}}{start_weekday} += 7;
          } elsif ($week_events{$l1}{$event{id}}{start_weekday} > 6) {
            $week_events{$l1}{$event{id}}{start_weekday} -= 7;
          }
          $week_events{$l1}{$event{id}}{length} = 7 if ($week_events{$l1}{$event{id}}{length} > 7);

          $debug_info .= "week $l1 event $event_id event_start_weekday: $week_events{$l1}{$event{id}}{start_weekday} length: $week_events{$l1}{$event{id}}{length}\n\n" if ($debug);
        }
      }

      $temp_debug_info = "";
      $cal_date += 604800;

      # each day has at least two slots (the date, and a blank box beneath it)
      for ($l2=0;$l2<7;$l2++) {
        $week_slots{$l1}{$l2}{0}{width}=1;
        $week_slots{$l1}{$l2}{0}{depth}=1;
        $week_slots{$l1}{$l2}{1}{width}=1;
        $week_slots{$l1}{$l2}{1}{depth}=1;
      }

      if ($debug == 1) {
        foreach $debug_event_id (@debug_events) {
          $debug_info .= "event $debug_event_id length: $week_events{$l1}{$debug_event_id}{length} start: $events{$debug_event_id}{start}\n";
        }
      }

      #order the week_events
      #fill in the %slots data structure:
      # $week_slots{week_index}{day_index}{slot_index}
      #   $width      = colspan
      #   $depth      = rowspan
      #   $spacer     = 1 if spacer slot.
      #   @ids        = event ids


      my $max_week_needed_slots = 0;
      my %max_day_needed_slots;

      # hey man, that's a sharp-lookin' sort you got there
      foreach $week_event_id (sort {
                                    return $week_events{$l1}{$b}{length} <=> $week_events{$l1}{$a}{length}
                                      if ($week_events{$l1}{$b}{length} != $week_events{$l1}{$a}{length});

                                      return $events{$a}{title} cmp $events{$b}{title}
                                        if ($events{$b}{all_day_event} ne "" && $events{$a}{all_day_event} ne "");

                                      return $events{$b}{all_day_event} cmp $events{$a}{all_day_event}
                                        if ($events{$b}{all_day_event} ne "" || $events{$a}{all_day_event} ne "");

                                      return $events{$a}{start} <=> $events{$b}{start};
                                    }
                                   keys %{$week_events{$l1}})
      {
        #$debug = 0;
        #$debug = 1 if (&contains(\@debug_events, $week_event_id));

        #$debug_info .= "week $l1 week_event $week_event_id length: $week_events{$l1}{$week_event_id}{length} start: $events{$week_event_id}{start}\n" if ($debug);

        $empty_slot = 0;

        #starting at 1 leaves a row of empty slots (row 0), where the calendar dates will go.
        for ($l4=1; $empty_slot != 1; $l4++) {
          $empty_slot = 1;
          #check each day of the week_event, to make sure the slot is empty
          for ($l2=0; $l2<$week_events{$l1}{$week_event_id}{length}; $l2++) {
            $day_index=$l2+$week_events{$l1}{$week_event_id}{start_weekday};

            if (scalar @{$week_slots{$l1}{$day_index}{$l4}{ids}} > 0) {
              $empty_slot = 0;
            }
          }
          $slot_index=$l4;
        }

        #$debug_info .= "event $week_event_id start_wkday $week_events{$l1}{$week_event_id}{start_weekday} slot $slot_index length $week_events{$l1}{$week_event_id}{length}\n" if ($debug);

        #fill up $week_slots with the new event (extend horizontally)
        for ($l2=0; $l2<$week_events{$l1}{$week_event_id}{length}; $l2++) {
          #$slots_in_row{$l1}{$slot_index}++;

          $day_index = $l2+$week_events{$l1}{$week_event_id}{start_weekday};
          push @{$week_slots{$l1}{$day_index}{$slot_index}{ids}}, $week_event_id;

          if ($l2==0)  { # first slot gets the width
$week_slots{$l1}{$day_index}{$slot_index}{width} = $week_events{$l1}{$week_event_id}{length};} else         { # other slots get 0 for length (they get absorbed later)
$week_slots{$l1}{$day_index}{$slot_index}{width} = 0;}
          $week_slots{$l1}{$day_index}{$slot_index}{depth} = 1;
        }

        #keep track of the maximum number of slots each week has
        if ($slot_index > $week_max_slots{$l1}) {
          $week_max_slots{$l1} = $slot_index;
          $max_day_events{$l1} = $slot_index;
        }
      }

      # give all blank slots width and depth of 1
      for ($l2=0;$l2<7;$l2++) {
        for ($l3=1;$l3<$week_max_slots{$l1}+1;$l3++)   { # for each slot
          if ($week_slots{$l1}{$l2}{$l3}{depth} eq "" || $week_slots{$l1}{$l2}{$l3}{width} eq "") {
            $week_slots{$l1}{$l2}{$l3}{width}=1;
            $week_slots{$l1}{$l2}{$l3}{depth}=1;
          }
        }
      }

      my $total_spacers=0;
      # insert spacer slots below multi-day events.
      for ($l3=1;$l3<$week_max_slots{$l1}+1;$l3++)   { # for each slot
        my $inserted_spacers=0;
        for ($l2=0;$l2<7;$l2++) {
          if ($week_slots{$l1}{$l2}{$l3}{width} > 1)  { #multi-day event, add spacers beneath
            # create spacer row
            if ($inserted_spacers == 0) {
              # move everything else down and increment the number of rows
              $week_max_slots{$l1}++;
              for ($l4=0;$l4<7;$l4++)   { # insert blank slots
                for ($l5=$week_max_slots{$l1};$l5>$l3+1;$l5--)   { # count backwards
                  $week_slots{$l1}{$l4}{$l5} = &deep_copy($week_slots{$l1}{$l4}{$l5-1});
                }
                $week_slots{$l1}{$l4}{$l3+1}{width} = 1;
                $week_slots{$l1}{$l4}{$l3+1}{depth} = 1;
                $week_slots{$l1}{$l4}{$l3+1}{spacer} = 0;
                $week_slots{$l1}{$l4}{$l3+1}{ids} = "";
              }
              $inserted_spacers=1
            }

            # insert spacers into previously created row.
            for ($l4=$l2;$l4<$l2+$week_slots{$l1}{$l2}{$l3}{width};$l4++) {
              $week_slots{$l1}{$l4}{$l3+1}{spacer}=1;
              #$debug_info .= "inserted spacer into row: ".($l3+1).", column $l4, event ".($week_slots{$l1}{$l4}{$l3}{ids}[0])."\n";
              $total_spacers++;
            }
            #$debug_info .= "week $l1 day 0, slot 3: ".$week_slots{$l1}{0}{3}{ids}[0]."\n";

          }
        }
      }

      #if ($l1 == 3) {
        #$debug_info .= "$total_spacers spacers inserted for week $l1.\n";
        #$debug_info .= "week $l1 day 0, slot 3: ".$week_slots{$l1}{0}{3}{ids}[0]."\n";
      #}

      #$debug_info .= "week $l1, event slots in row 1:  $slots_in_row{$l1}{1}\n";

      # calculate slots in each row:
      for ($l3=1;$l3<$week_max_slots{$l1};$l3++)   { # for each slot
        if ((scalar @{$week_slots{$l1}{$l2}{$l3}{ids}}) > 0 ) {
          $slots_in_row{$l1}{$l3} += $week_slots{$l1}{$l2}{$l3}{width};
          #$debug_info .= "event in row $l1.  Incrementing slots_in_row {$l1} {$l3} to $slots_in_row{$l1}{$l3}\n";
        }
        if ($week_slots{$l1}{$l2}{$l3}{spacer} == 1) {
          $slots_in_row{$l1}{$l3}++;
          #$debug_info .= "spacer in row $l1.  Incrementing slots_in_row {$l1} {$l3} to $slots_in_row{$l1}{$l3}\n";
        }
      }

      %max_day_needed_slots = (0=>$week_max_slots{$l1},1=>$week_max_slots{$l1},2=>$week_max_slots{$l1},3=>$week_max_slots{$l1},4=>$week_max_slots{$l1},5=>$week_max_slots{$l1},6=>$week_max_slots{$l1});


      #$slots_in_row{$l1}{$slot_index}++;

      # extend event slots vertically.
      for ($l2=0;$l2<7;$l2++)   { # for each day of the week
        for ($l3=1;$l3<$week_max_slots{$l1};$l3++)   { # for each slot
          if (scalar @{$week_slots{$l1}{$l2}{$l3}{ids}} > 0 && $week_slots{$l1}{$l2}{$l3}{width} > 0) { # if this slot begins an event
            my $start_slot = $l3+1;
            for ($l4=$start_slot; $l4<$week_max_slots{$l1}+1; $l4++) {
              #$debug_info .= "checking slot $l4 below event slot ($l2, $l3)\n";
              #if ($week_slots{$l1}{$l2}{$l4}{width} == 0)
              #  {next;}

              if (scalar @{$week_slots{$l1}{$l2}{$l4}{ids}} > 0 && $week_slots{$l1}{$l2}{$l4}{width} eq $week_slots{$l1}{$l2}{$l3}{width}) { # another event below this one, with the same width.
                if ($l1 eq "3" && $debug) {
                $debug_info .= "week $l1 slot ($l2, $l3) extended vertically because of another event below with the same width.\n";}
                #$debug_info .= "week $l1 slot ($l2, $l3) extended vertically because of another event below with the same width.\n";
                #$debug_info .= "same-width event slot below week $l1, slot ($l2, $l3)\n";
                $week_slots{$l1}{$l2}{$l4}{width}=0;
                $week_slots{$l1}{$l2}{$l4}{depth}=0;
                $week_slots{$l1}{$l2}{$l3}{depth}++;
                push @{$week_slots{$l1}{$l2}{$l3}{ids}}, @{$week_slots{$l1}{$l2}{$l4}{ids}};

                $max_day_needed_slots{$l2}--;
                #$slots_in_row{$l1}{$l4}--;

              } elsif ($week_slots{$l1}{$l2}{$l3}{width} == 1 && (scalar @{$week_slots{$l1}{$l2}{$l4}{ids}}) == 0 && $week_slots{$l1}{$l2}{$l4}{spacer} == 0) { # blank slot below 1-slot wide event slot
                if ($l1 eq "3" && $debug) {
                $debug_info .= "week $l1 slot ($l2, $l3) extended vertically because of a blank slot below.\n";}
                #$debug_info .= "week $l1 slot ($l2, $l3) extended vertically because of a blank slot below.\n";
                #$debug_info .= "week $l1 slot ($l2, $l4) # ids:".scalar @{$week_slots{$l1}{$l2}{$l4}{ids}}."\n";
                #$debug_info .= "blank slot below week $l1, slot ($l2, $l3)\n";
                $week_slots{$l1}{$l2}{$l4}{width}=0;
                $week_slots{$l1}{$l2}{$l4}{depth}=0;
                $week_slots{$l1}{$l2}{$l3}{depth}++;
                $max_day_needed_slots{$l2}--;
                #$debug_info .= "week $l1, slot ($l2, $l3) depth: $week_slots{$l1}{$l2}{$l3}{depth} \n";
              } else {
                $debug_info .= "week $l1 slot ($l2, $l4) occupied.  Finished attempting to extend slot $l3\n" if ($debug);
                last;
              }
            }
          }
        }
      }
      #$debug_info .= "week $l1, event slots in row 1:  $slots_in_row{$l1}{1}\n";

      # extend blank slots vertically into other blank slots.
      for ($l2=0;$l2<7;$l2++)   { # for each day of the week

        for ($l3=1;$l3<$week_max_slots{$l1};$l3++)   { # for each slot

          next if (scalar @{$week_slots{$l1}{$l2}{$l3}{ids}} > 0);

          if ($week_slots{$l1}{$l2}{$l3}{width} > 0 && $week_slots{$l1}{$l2}{$l3}{spacer} == 0)  { # if it's blank (but not a spacer)

            my $start_slot = $l3+1;
            for ($l4=$start_slot; $l4<$week_max_slots{$l1}+1; $l4++) {
              if ($week_slots{$l1}{$l2}{$l4}{width} == 1 && $week_slots{$l1}{$l2}{$l4}{spacer} == 0) {
                #$debug_info .= "blank slot below week $l1, slot ($l2, $l3)\n" if ($debug);
                $week_slots{$l1}{$l2}{$l4}{width}=0;
                $week_slots{$l1}{$l2}{$l4}{depth}=0;
                $week_slots{$l1}{$l2}{$l3}{depth}++;
                $max_day_needed_slots{$l2}--;
              } else {
                last;
              }
            }
          }
        }
      }
      #$debug_info .= "week $l1, event slots in row 1:  $slots_in_row{$l1}{1}\n";
      #$debug_info .= "week $l1 slot (4, 1) depth: $week_slots{$l1}{4}{1}{depth}\n";

      # yet another pass. trim vertical depth and re-calculate max_slots

      # calculate trim
      my $trim = 0;
      #$debug_info .= "\n week $l1 max slots: $week_max_slots{$l1}\n";


      #$debug_info .= "\nweek $l1, max_day_needed_slots: $max_day_needed_slots{0} $max_day_needed_slots{1} $max_day_needed_slots{2} $max_day_needed_slots{3} $max_day_needed_slots{4} $max_day_needed_slots{5} $max_day_needed_slots{6} $max_day_needed_slots{7}\n" if ($debug);

      $max_week_needed_slots = max(values %max_day_needed_slots);
      #$debug_info .= "week $l1 max_week_needed_slots: $max_week_needed_slots\n";

      #if ($max_day_needed_slots >$max_week_needed_slots)
      #  {$max_week_needed_slots = $max_day_needed_slots;}
      #$debug_info .= "max needed slots for week $l1, $max_week_needed_slots\n";

      my $trim = $week_max_slots{$l1} - $max_week_needed_slots;

      # apply trim
      #$debug_info .= "trim for week $l1, $trim\n";
      for ($l2=0;$l2<7;$l2++)   { # for each day of the week

        for ($l3=$week_max_slots{$l1};$l3>0;$l3--)   { # for each slot, counting backwards (upwards)

          if ($week_slots{$l1}{$l2}{$l3}{depth} > 0)  { # blank or non-blank, with depth > 0

            #$debug_info .= "trimming week $l1, slot ($l2, $l3) by $trim\n";
            $week_slots{$l1}{$l2}{$l3}{depth} = $week_slots{$l1}{$l2}{$l3}{depth} - $trim;
            last;
          }
        }
      }

      $week_max_slots{$l1} = $week_max_slots{$l1} - $trim;

    }  # repeat for next week

    # print day names
    if ($cal_month_idx == 0 || $show_month_breaks) {
      my @lowercase_day_names;
      foreach $day_name (@day_names) {
        push @lowercase_day_names, lc $day_name;
      }

      $return_text .=<<p1;
<table class="calendar" summary="">
<tr>
<td class="day_names $lowercase_day_names[0]">$weekday_sequence[0]</td>
<td class="day_names $lowercase_day_names[1]">$weekday_sequence[1]</td>
<td class="day_names $lowercase_day_names[2]">$weekday_sequence[2]</td>
<td class="day_names $lowercase_day_names[3]">$weekday_sequence[3]</td>
<td class="day_names $lowercase_day_names[4]">$weekday_sequence[4]</td>
<td class="day_names $lowercase_day_names[5]">$weekday_sequence[5]</td>
<td class="day_names $lowercase_day_names[6]">$weekday_sequence[6]</td>
</tr>
p1
    }

    #cal_date keeps track of the date (in timestamp format)
    #as the calendar loop iterates through each day on the calendar page
    $cal_date = $cal_start_date;
    @cal_date_array = gmtime $cal_date;

    #locked and loaded, data structures assembled--now it's time to kick it, calendar-style.
    for ($l1=0;$cal_date_array[4] != $next_month; $l1++)  { #each calendar has 5 or 6 weeks

      my $last_week=0;
      my $timestamp_next_week = $cal_date+604800;
      my @timestamp_next_week_array = gmtime $timestamp_next_week;

	  $last_week = 1 if ($current_month != $timestamp_next_week_array[4]);

      my $week_date_index = $cal_date;

      # draw the table!
      for ($l3=0;$l3<$week_max_slots{$l1}+1;$l3++) {
        $return_text .="<tr id=\"week_$cal_date\">";

        $week_date_index = $cal_date;
        for ($l2=0;$l2<7;$l2++) { # 7 days / week

          @cal_date_array = gmtime $week_date_index;
          my $td_class = "day ".lc($day_names[$l2]);

          # display date numbers differently, depending on whether they are in the current month or not
          my $cal_month_name = "";
          if ($show_month_breaks || $cal_num_months == 1) {
            $td_class .= " other_month" if ($cal_date_array[4] != $current_month);
          } else {
            $td_class .= " other_month_multi" if ($use_other_month[$cal_date_array[4] % 2]);
            $cal_month_name = $months[$cal_date_array[4]] if ($cal_date_array[3] == 1);
          }

          #if ($l2 == $week_events{$l1}{$week_slots{$l1}{$l2}{$l3}{id}}{start_weekday} && $week_events{$l1}{$week_slots{$l1}{$l2}{$l3}{id}}{start_weekday} ne "")

          if ($l3 == 0)  { #if it's the top blank slot, put the date in there.

            $return_text .=<<p1;
<td class="$td_class" date="$week_date_index">
<div class="date">$cal_date_array[3]&nbsp;$cal_month_name</div>
</td>
p1
          } elsif ($week_slots{$l1}{$l2}{$l3}{spacer} != 0)  { # spacer slot

            my $spacer_class = "spacer";
            if ($l3 == $week_max_slots{$l1}-1) {
              $spacer_class .= " bottom";
            }
            $return_text .=<<p1;
<td class="$td_class $spacer_class" style="$td_style" date="$week_date_index" colspan=1 rowspan=1>
</td>
p1
          } elsif ($week_slots{$l1}{$l2}{$l3}{width} != 0)  { # slot containing events

            $num_cols = $week_slots{$l1}{$l2}{$l3}{width};
            $num_rows = $week_slots{$l1}{$l2}{$l3}{depth};

            if (scalar @{$week_slots{$l1}{$l2}{$l3}{ids}} > 0) {

              $td_style="border-top-width:0px;border-bottom-width:0px;";

#($l2,$l3) $num_cols\lx$num_rows
              $return_text .=<<p1;
<td class="$td_class" style="$td_style" date="$week_date_index" colspan="$num_cols" rowspan="$num_rows">
p1

              foreach $event_id (@{$week_slots{$l1}{$l2}{$l3}{ids}}) {
                my $multi_day_event = ($week_slots{$l1}{$l2}{$l3}{width} > 1) ? 1:0;

                my $background_event = (&contains($events{$event_id}{cal_ids}, $current_calendar{id})) ? 0:1;

                $return_text .= &display_calendar_event($event_id, $multi_day_event, $background_event)
              }

              $return_text .=<<p1;
</td>
p1
            } elsif ($week_slots{$l1}{$l2}{$l3}{ids} eq "" && $week_slots{$l1}{$l2}{$l3}{width} > 0)  { # blank slot

              $td_style="border-top-width:0px;border-bottom-width:0px;";

#($l2,$l3) blank $num_cols\lx$num_rows
              $return_text .=<<p1;
<td class="$td_class" style="$td_style" colspan=$num_cols rowspan=$num_rows date="$week_date_index">
</td>
p1
            }
          }
          $week_date_index += 86400;
        }  # next day (first row)

        #right border
        $return_text .=<<p1;
</tr>
p1
      } # event slot index


      # this little trick is the cat's pajamas.  It's another row of
      # table cells that cause each calendar day to come down a little
      # bit below the lowest event.  It makes the calendar look sharp.

      # Also, if the week has a small number of events, we expand the height of the bottom cell.
      # This makes all the calendar cells look square, which is the bee's knees.

      my $bottom_height_style = "";
      if ($max_day_events{$l1} < 2) {
        my $height = (4-$max_day_events{$l1}) . "em";   # this algorithm was developed by guess & check
        #my $height = "100px";   # this algorithm was developed by guess & check
        $bottom_height_style = "line-height:$height;";
      }

	  $tr_class .= " last_week" if ( $last_week == 1 );

      $return_text .=<<p1;
<tr style="$bottom_height_style" class="$tr_class">
p1
      $week_date_index = $cal_date;
      for ($l2=0;$l2<7;$l2++) { #each week has 7 days(!)

        my $td_class = "";
        @cal_date_array = gmtime $week_date_index;
        $td_class .= "day ".lc($day_names[$l2])." cell_bottom";

        $td_class .= " today" if ($cal_date_array[4] == $rightnow_month &&
                                  $cal_date_array[3] == $rightnow_mday &&
                                  $cal_date_array[5]+1900 == $rightnow_year);

        if ($show_month_breaks || $cal_num_months == 1) {
          $td_class .= " other_month" if ($cal_date_array[4] != $current_month);
        } else {
          $td_class .= " other_month_multi" if ($use_other_month[$cal_date_array[4] % 2]);
        }
		

        $return_text .=<<p1;
<td class="$td_class" style="line-height:5px;border-top-width:0px;$bottom_height_style" date="$week_date_index">&nbsp;</td>
p1
        $week_date_index+=86400;
      }
      $return_text .=<<p1;
</tr>
p1
      $cal_date+=604800;
      @cal_date_array = gmtime $cal_date;
    }

#close table tag for each month or only for last month on continuous_multimonth mode
if ($show_month_breaks || $last_cal_month) {
    $return_text .=<<p1;
</table>
<br style="page-break-after:always;"/>
p1
}

    #increment to the next month--the method used
    #here is the most painless way of making
    #this work the right way in all cases.
    $current_month++;
    $cal_month_idx++;
    
    if ($current_month == 12) {
      $current_month=0;
      $current_year++;
    }
  }

  return $return_text;
}  #********************end render_calendar subroutine**********************


sub background_event_colorize {
	my ($event_id, $calendar_id) = @_;

	my %event = %{$events{$event_id}};
	my %calendar = %{$calendars{$calendar_id}};
	my $event_bgcolor = $event{bgcolor};

	if ($calendars{$event{cal_ids}[0]}{calendar_events_color} ne "") {
		$event_bgcolor = $calendars{$event{cal_ids}[0]}{calendar_events_color};
	}

	if ($calendar{background_events_display_style} eq "single_color") {
		$event_bgcolor = $calendar{background_events_color};
	}

	return $event_bgcolor;
}

sub display_calendar_event {
  my ($event_id, $multi_day, $background_event) = @_;
  my %event = %{$events{$event_id}};
  my $results = "";

  my $event_bgcolor = $event{bgcolor};

  # force white color if the background is dark
  my $textcolor_style = "";
  my $r = hex substr $event_bgcolor,1,2;
  my $g = hex substr $event_bgcolor,3,2;
  my $b = hex substr $event_bgcolor,5,2;
  my $bright = ($r*299+$g*587+$b*114)/1000;

  $textcolor_style = "color:#fff" if ($bright < 128);

  #$textcolor_style = "color:#000" if ($event_bgcolor == "");

  $event_bgcolor = $current_calendar{calendar_events_color} if ($current_calendar{calendar_events_color} ne "");

  my $event_box_class = "event_box";

  # handle link
  my $event_link = "javascript:display_event('$event_id');";
  $event_link = "$event{details}" if ($event{details_url} eq "1");

  if ($background_event) {
    $event_box_class .= " background";
    $event_bgcolor = &background_event_colorize($event_id, $current_calendar{id});
  }

  my $series_text = ($event{series_id} eq "") ? "" : " series_id=\"$event{series_id}\"";

  
  # handle icon
  my $icon_text = "";
  my $unit_icon_text = "";
  if ($event{unit_number} ne "") {
    $unit_icon_text = $event{unit_number}." ";
    $unit_icon_text =~ s/(\d)/<img src="$theme_url\/images\/unit_number_patch_$1_16x10.gif" border="0" alt=\"\" vspace=0 hspace=0 style="vertical-align:middle;">/g;
  }

  my $link_style = "";
  if ($event{icon} ne "blank" && $event{icon} ne "") {
    $icon_text = <<p1;
<img align="bottom" src = "$icons_url/$event{icon}_16x16.gif" style="margin-left:-22px;margin-right:5px;margin-bottom:-5px;" alt="">
p1
    chomp $icon_text;
    $link_style = "padding-left:29px";
  }

	my $fade_style = "";

	if ($calendar{background_events_display_style} eq "single_color") {
		$fade_style = "opacity:". 1- ( $calendar{background_events_fade_factor} / 100 );
	}


  if ($multi_day == 0) {
    my $event_time = "";
    if ($event{all_day_event} ne "1") {
      $event_time = &nice_time_range_format($event{start}, $event{end});
      $event_time = "<span class=\"event_time\" style=\"$textcolor_style;\"> $event_time </span><br/>";
    }


    my $temp_item_text = $calendar_item_template;
    $temp_item_text =~ s/###icon###/$icon_text$unit_icon_text/g;
    $temp_item_text =~ s/###title###/$event{title}/g;
    $temp_item_text =~ s/###id###/$event{id}/g;
    $temp_item_text =~ s/###time###/$event_time/g;
    my $calendar_title = $calendars{$event{cal_ids}[0]}{title};
    $temp_item_text =~ s/###calendar title###/$calendar_title/g;

    $results .=<<p1;
<a href="$event_link" class="$event_box_class" style="display:block;text-align:left;$link_style$fade_style;background-color:$event_bgcolor;$textcolor_style;cursor:pointer;cursor:hand;" event_id="$event_id"$series_text>
$temp_item_text</a>
p1

  } else { # multi-day-event

    # handle the case where an event is < 24 hours and crosses midnight.
    my $nudge_edge="";
    my $event_time = "";

    if ($event{all_day_event} ne "1") {
      if ($event{end} - $event{start} < 86400) {
        my $offset = 25;
        my $width = 50;
        $nudge_edge = "width:$width%;position:relative;left:$offset%;";
      }

      $event_time = &nice_time_range_format($event{start}, $event{end});
      $event_time = "<span class=\"event_time\" style=\"$textcolor_style;\"> $event_time </span>";
    }

    if ($event{icon} ne "blank" && $event{icon} ne "") {
      $icon_text = <<p1;
<img src="$icons_url/$event{icon}_16x16.gif" style="vertical-align:middle;margin-right:5px;" alt="">
p1
      chomp $icon_text;
    }

    my $temp_item_text = $calendar_item_template;
    $temp_item_text =~ s/###icon###/$icon_text$unit_icon_text/g;
    $temp_item_text =~ s/###title###/$event{title}/g;
    $temp_item_text =~ s/###time###/$event_time/g;
    my $calendar_title = $calendars{$event{cal_ids}[0]}{title};
    $temp_item_text =~ s/###calendar title###/$calendar_title/g;

    $results .=<<p1;
<a href="$event_link" class="$event_box_class" style="display:block;text-align:center;background-color:$event_bgcolor;$textcolor_style;cursor:pointer;cursor:hand;$nudge_edge" event_id="$event_id"$series_text>
$temp_item_text</a>
p1
    }
}




sub display_list_event {
  my ($event_id, $background_event, $sameday) = @_;
  my %event = %{$events{$event_id}};
  my $results="";

  @event_start_timestamp_array = gmtime $event{start};

  my $date_string;
  my $weekday_string;

  if ($event{days} == 1) {
 #single-day event
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

  # weekday abbreviations
  my $weekday_abv_string = $weekday_string;
  for ($l1=0;$l1<scalar @day_names;$l1++) {
    $weekday_abv_string =~ s/$day_names[$l1]/$day_names_abv[$l1]/g;
  }

  my $icon_text="";
  my $unit_icon_text="";
  if ($event{unit_number} ne "") {
    $icon_text = $event{unit_number};
    $icon_text =~ s/(\d)/<img src="$graphics_url\/unit_number_patch_$1_16x10.gif" style=\"position:relative;top:5px;\" alt=\"\">/g;
  }

  if ($event{icon} eq "blank" || $event{icon} eq "") {
    $icon_text .= "$unit_icon_text";
  } else {
    $icon_text .= "$unit_icon_text<img src = \"$icons_url/$event{icon}_16x16.gif\" style=\"position:relative;top:5px;\" alt=\"\">";
  }

  my $event_bgcolor = $event{bgcolor};

  if ($calendars{$event{cal_ids}[0]}{calendar_events_color} ne "") {
$event_bgcolor = $calendars{$event{cal_ids}[0]}{calendar_events_color};}

  if ($background_event eq "1") {
    $event_bgcolor = &background_event_colorize($event_id, $current_calendar{id});
  }

  # event time
  my $event_time = "";
  if ($event{all_day_event} ne "1") {
    $event_time = &nice_time_range_format($event{start}, $event{end});
    $event_time = "<span class=\"event_time\">$event_time</span>";
  }

  my $event_link = "javascript:display_event('$event{id}');";
  if ($event{details_url} eq "1") {
$event_link = "$event{details}";}

  my $margin_top="7px";
  $margin_top = "0" if ($sameday);


  my $temp_item_text = $list_item_template;


  $temp_item_text =~ s/###variable_margin###/$margin_top/g;
  $temp_item_text =~ s/###id###/$event_id/g;
  $temp_item_text =~ s/###bgcolor###/$event_bgcolor/g;
  $temp_item_text =~ s/###link###/$event_link/g;
  $temp_item_text =~ s/###details###/$event{details}/g;
  $temp_item_text =~ s/###icon###/$icon_text/g;
  $temp_item_text =~ s/###title###/$event{title}/g;
  $temp_item_text =~ s/###date###/$date_string/g;
  $temp_item_text =~ s/###weekday###/$weekday_string/g;
  $temp_item_text =~ s/###weekday_abv###/$weekday_abv_string/g;
  $temp_item_text =~ s/###time###/$event_time/g;


  $results .= $temp_item_text;

  $no_results .=<<p1;
<li style="padding:0;margin:0;margin-top:$margin_top;"$event_context_menu_text>
<span class="small_note" style="margin:0;border:0;vertical-align:middle;width:7em;white-space:nowrap;text-align:right;cursor:pointer;cursor:hand;"  onclick="display_event('$event_id')" > $date_string </span>
<a class="event_box" style="text-align:left;white-space:nowrap;background-color:$event_bgcolor;" href="$event_link"> $icon_text $event_time $event{title}</a>
</li>
p1




  return $results;
}



sub render_list {
  my $return_text = "";
  ($start_month, $start_year, $end_month, $end_year) = @_;

  #calculate where to start and end the list

  #format for timegm: timegm($sec,$min,$hour,$mday,$mon,$year);
  my $list_start_timestamp = timegm(0,0,0,1,$start_month,$start_year);
  my $list_end_timestamp = &find_end_of_month($end_month, $end_year);

  # loop through all the events.

  #Create an array of events which fall
  # within the current list view dates
  my @selected_cal_events;

  #and a funky data structure for the background calendars
  # each element of this hash will be an array.
  my $shared_cal_events={};  #empty hash

  foreach $event_id (keys %events) {
    if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$list_start_timestamp,$list_end_timestamp)) {
      my $event_in_current_calendar = 0;

      foreach $temp_cal_id (@{$events{$event_id}{cal_ids}}) {
        if ($temp_cal_id eq $current_cal_id) {
push @selected_cal_events, $event_id;}

        foreach $background_cal_id (keys %{$current_calendar{local_background_calendars}}) {
          if ($temp_cal_id eq $background_cal_id) {
            if ($current_calendar{list_background_calendars_together} eq "yes") {
              push @selected_cal_events, $event_id;
            } else {
              push @{$shared_cal_events{$background_cal_id}}, $event_id if (!&contains(\@selected_cal_events, $event_id));
            }
          }
        }
      }
    }
  }

  # initialize loop variables
  $current_month = $start_month;
  $current_year = $start_year;

    $return_text .=<<p1;
p1

  while ($current_year < $end_year || ($current_year == $end_year && $current_month <= $end_month)) {
    my $current_month_start_timestamp = timegm(0,0,0,1,$current_month,$current_year);
    my $current_month_end_timestamp = &find_end_of_month($current_month, $current_year);

    $return_text .=<<p1;
<div class="list_month_box">
p1

    if ($cal_num_months> 1) {
      $return_text .=<<p1;
<h1>
$months[$current_month] $current_year
</h1>
p1
    }

    if ($current_calendar{list_background_calendars_together} eq "yes") {
      $return_text .=<<p1;
<ul class="list_cal_box" style="list-style-type:none;float:left;text-align:left;">
<h4>$calendars{$current_cal_id}{title}</h4>
p1
      #display events for selected calendar
      my $previous_event_id;
      foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @selected_cal_events) {
        my %event = %{$events{$event_id}};
        if (&time_overlap($event{start},$event{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
          my $background_event = "";
          $background_event = "1" if ($event{cal_ids}[0] ne $current_cal_id);

          my @temp1 = gmtime($event{start});
          my @temp2 = gmtime($events{$previous_event_id}{start});

          my $sameday = "";
          $sameday = "1" if ($temp1[3] == $temp2[3]);

          $return_text .= &display_list_event($event_id, $background_event, $sameday);
          $previous_event_id = $event_id;
        }
      }
      $return_text .=<<p1;
</ul>
p1
    } else {
      $return_text .=<<p1;
<ul class="list_cal_box" style="list-style-type:none;float:left;text-align:left;">
<h4>$calendars{$current_cal_id}{title}</h4>
p1
      #display events for selected calendar
      my $previous_event_id;

      foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @selected_cal_events) {
        my %event = %{$events{$event_id}};
        if (&time_overlap($event{start},$event{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
          my @temp1 = gmtime($event{start});
          my @temp2 = gmtime($events{$previous_event_id}{start});

          my $sameday = "";
          $sameday = "1" if ($temp1[3] == $temp2[3]);

          $return_text .= &display_list_event($event_id,0,$sameday);
          $previous_event_id = $event_id;
        }
      }
      $return_text .=<<p1;
</ul>
p1

      foreach $background_cal_id (keys %{$current_calendar{local_background_calendars}}) {
        $return_text .=<<p1;
<ul class="list_cal_box background" style="list-style-type:none;float:left;text-align:left;">
<li style="text-align:center;font-weight:bold;">$calendars{$background_cal_id}{title}</li>
p1
        #list events for that calendar
        my $previous_event_id;
        foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @{$shared_cal_events{$background_cal_id}}) {

          %event = %{$events{$event_id}};
          if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
            my @temp1 = gmtime($event{start});
            my @temp2 = gmtime($events{$previous_event_id}{start});

            my $sameday = "";
            $sameday = "1" if ($temp1[3] == $temp2[3]);

            $return_text .= &display_list_event($event_id,1,$sameday);
            $previous_event_id = $event_id;

          }
        }
        $return_text .=<<p1;
</ul>
<br style="clear:both;"/>  <!--needed because IE sucks-->
p1
      }
    }

    $return_text .=<<p1;
<br style="clear:both;"/> <!-- because IE sucks-->
<br style="clear:both;"/> <!-- because IE sucks-->
</div>
<br style="clear:both;"/> <!-- because IE sucks-->
<br style="clear:both;"/> <!-- because IE sucks-->
p1

    #increment to the next month--the method used
    #here is the most painless way of making
    #this work the right way in all cases.
    $current_month +=1;
    if ($current_month == 12) {
      $current_month=0;
      $current_year++;
    }
  }

  $return_text .=<<p1;
p1
  return $return_text;

}  #********************end generate_list subroutine**********************


sub generate_event_details_javascript {
  my ($events_start_timestamp, $events_end_timestamp) = @_;

  my $return_string="";

  my $num_events = 0;
  my $num_remote_events = 0;
  my $event_defs="";
  my $remote_event_defs="";

  $index=0;

  #loop through the events, check to see if they fall
  #within the current calendar month
  foreach $event_id (keys %events) {
    my %event = %{$events{$event_id}};
    if (&time_overlap($event{start},$event{end},$events_start_timestamp,$events_end_timestamp)) {

      if ($event_id =~ /^r/) {
        $num_remote_events++;
        $remote_event_defs .= <<p1;
remote_event_details["$event_id"] = new Object;
remote_event_details["$event_id"].url = "$event{remote_calendar}{url}?view_event=1&evt_id=$event{remote_event_id}";
p1

      }
    }
  }

  $return_string .=<<p1;
var remote_event_details = [];
$remote_event_defs
var event_details = [];
$event_defs
p1
  return $return_string;

}  #********************end generate_event_details_javascript subroutine**********************



sub pending_events_visible {

  if ( ! $options{'anonymous_events'} ) { return 0; }
  if ( ! $options{'sessions'} ) { return 0; }

  # display pending events for this calendar?
  if ($options{pending_events_display} eq '0' || $options{pending_events_display} eq '1' ||
      ($options{pending_events_display} eq '2' && $logged_in_as_current_cal_user) ||   # logged-in user of this calendar
      ($options{pending_events_display} eq '3' && $logged_in_as_current_cal_user) ||   # logged-in user of this calendar
      ($options{pending_events_display} eq '3' && $logged_in_as_current_cal_admin) ||   # logged-in admin of this calendar
      $logged_in_as_root  # root
  ) {return 1};

  return undef;
}

sub forced_login {
  my $results = "";

  $results .= <<p1;
<form name="forced_login_form" id="update_cal_form" action="" method="POST">
<input type="hidden" name="active_tab" value="$active_tab">
<input type="hidden" name="cal_id" value="$current_cal_id"/>
<div class="info_box" style="clear:both;">
<p class="cal_title" style="text-align:center;">
$lang{login}
</p>
<div class="leftcol" style="">
<label class="required_field" for="cal_password">$lang{cal_password}</label>
</div>

<div class="rightcol" style="white-space:nowrap;">
<input type="password" name="cal_password" id="cal_password" size=12 />
<span class="small_note" ><a style="vertical-align:top;" href="javascript:jQuery.planscalendar.display_help('current_password','$lang{cal_password}')">$lang{help_on_this}</a></span>
</div>

<div class="leftcol">
&nbsp;
</div>
<div class="rightcol" style="white-space:nowrap;">
<input type="submit" value="$lang{submit}"/>
</div>
<br style="clear:both;"/>
</div>
</form>
p1

  return $results;
}

sub generate_pending_events_area {
	# events & calendars pending approval, etc.

	my $results = "";

	my $pending_events_text = "";
	# display pending events for this calendar?

	if (&pending_events_visible()) {
		foreach $new_event_id (keys %new_events) {
			push @pending_events_to_display, $new_event_id;
		}


		$pending_events_text .= "<a id=\"pending_events_display_toggle_button\" href=\"javascript:void(0)\">";
		$pending_events_text .= (scalar @pending_events_to_display)." ";

		if (scalar @pending_events_to_display == 1) {
			$pending_events_text .= $lang{pending_event1};
		} else {
			$pending_events_text .= $lang{pending_event2};
		}
		$pending_events_text .= "</a>";
	}


	if ($pending_events_text ne "") {
		$results .= "$pending_events_text <div id=\"pending_events\">";
		$results .= "</div>";
	}

return $results;
}





sub csv_file_palm {

  ($start_month, $start_year, $end_month, $end_year) = @_;

  #calculate where to start and end the list

  #format for timegm: timegm($sec,$min,$hour,$mday,$mon,$year);
  my $list_start_timestamp = timegm(0,0,0,1,$start_month,$start_year);
  my $list_end_timestamp = &find_end_of_month($end_month, $end_year);

  #@cal_month_start_date_array = gmtime $cal_month_start_date;

  # loop through all the events.

  #Create an array of events which fall
  # within the current list view dates
  my @selected_cal_events;

  #and a funky data structure for the background calendars
  # each element of this hash will be an array.
  my $shared_cal_events={};  #empty hash

  foreach $event_id (keys %events) {
    if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$list_start_timestamp,$list_end_timestamp)) {
      my $event_in_current_calendar = 0;

      foreach $temp_cal_id (@{$events{$event_id}{cal_ids}}) {
        if ($temp_cal_id eq $current_cal_id) {
push @selected_cal_events, $event_id;}
        foreach $background_cal_id (keys %{$current_calendar{local_background_calendars}}) {
          if ($temp_cal_id eq $background_cal_id) {
push @{$shared_cal_events{$background_cal_id}}, $event_id;}
        }
      }
    }
  }

  $html_output =<<p1;
Cache-control: no-cache,no-store,private
Content-disposition: filename="events.csv"
Content-Type: text/csv; charset=$lang{charset}\n
p1
  #initialize loop variables
  #$current_timestamp = $list_start_timestamp;
  $current_month = $start_month;
  $current_year = $start_year;

  $html_output .=<<p1;
CSV datebook: Category, Private, Description, Note, Event, Begin, End, Alarm, Advance, Advance Units, Repeat Type, Repeat Forever, Repeat End, Repeat Frequency, Repeat Day, Repeat Days, Week Start, Number of Exceptions, Exceptions
p1


  while ($current_year < $end_year || ($current_year == $end_year && $current_month <= $end_month)) {
    my $current_month_start_timestamp = timegm(0,0,0,1,$current_month,$current_year);
    my $current_month_end_timestamp = &find_end_of_month($current_month, $current_year);
    #display events for selected calendar
    foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @selected_cal_events) {
      my %event = %{$events{$event_id}};

      if (&time_overlap($event{start},$event{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
        my $csv_subject = "$event{title}";

        @event_start_timestamp_array = gmtime $event{start};
        my $csv_start_date = ($event_start_timestamp_array[5]+1900)." ".($event_start_timestamp_array[4]+1)." ".($event_start_timestamp_array[3]);
        my $csv_start_time = "$event_start_timestamp_array[2]:$event_start_timestamp_array[1]";

        @event_end_timestamp_array = gmtime $event{end};
        my $csv_end_date = ($event_end_timestamp_array[5]+1900)." ".($event_end_timestamp_array[4]+1)." ".($event_end_timestamp_array[3]);
        my $csv_end_time = "$event_end_timestamp_array[2]:$event_end_timestamp_array[1]";

        my $csv_description = $event{details};
        $csv_description =~ s/"/""/g;
        $csv_description =~ s/\n/\\n/g;

        if ($event{days} != 1) {
          @event_end_timestamp_array = gmtime $event{end};
          $csv_end_date = ($event_end_timestamp_array[5]+1900)." ".($event_end_timestamp_array[4]+1)." ".($event_end_timestamp_array[3]);
        }

        $html_output .=<<p1;
"$calendars{$current_cal_id}{title}","0","$csv_subject","$csv_description","1","$csv_start_date $csv_start_time","$csv_end_date $csv_end_time","0","0","0","0","1","$csv_end_date","0","0","0000000","0","0",""
p1
      }
    }
    foreach $background_cal_id (keys %{$current_calendar{local_background_calendars}}) {
      #list events for that calendar
      foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @{$shared_cal_events{$background_cal_id}}) {
        my %event = %{$events{$event_id}};

        if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
          my $csv_subject = "$event{title}";

          @event_start_timestamp_array = gmtime $event{start};
          my $csv_start_date = ($event_start_timestamp_array[5]+1900)." ".($event_start_timestamp_array[4]+1)." ".($event_start_timestamp_array[3]);
          my $csv_start_time = "$event_start_timestamp_array[2]:$event_start_timestamp_array[1]";

          @event_end_timestamp_array = gmtime $event{end};
          my $csv_end_date = ($event_end_timestamp_array[5]+1900)." ".($event_end_timestamp_array[4]+1)." ".($event_end_timestamp_array[3]);
          my $csv_end_time = "$event_end_timestamp_array[2]:$event_end_timestamp_array[1]";

          my $csv_description = $event{details};
          $csv_description =~ s/"/""/g;
          $csv_description =~ s/\n/\\n/g;

          $csv_description =~ s/"/""/g;
          $csv_description =~ s/\n/\\n/g;


          if ($event{days} != 1) {
            @event_end_timestamp_array = gmtime $event{end};
            $csv_end_date = ($event_end_timestamp_array[5]+1900)." ".($event_end_timestamp_array[4]+1)." ".($event_end_timestamp_array[3]);
          }

          $html_output .=<<p1;
"$calendars{$background_cal_id}{title}","0","$csv_subject","$csv_description","1","$csv_start_date $csv_start_time","$csv_end_date $csv_end_time","0","0","0","0","1","$csv_end_date","0","0","0000000","0","0",""
p1
        }
      }
    }

    #increment to the next month--the method used
    #here is the most painless way of making
    #this work the right way in all cases.
    $current_month +=1;
    if ($current_month == 12) {
      $current_month=0;

      $current_year++;
    }
  }
  $html_output .= $debug_info;
  print $html_output;
}




sub csv_file {

  ($start_month, $start_year, $end_month, $end_year) = @_;

  #calculate where to start and end the list

  #format for timegm: timegm($sec,$min,$hour,$mday,$mon,$year);
  my $list_start_timestamp = timegm(0,0,0,1,$start_month,$start_year);
  my $list_end_timestamp = &find_end_of_month($end_month, $end_year);

  #@cal_month_start_date_array = gmtime $cal_month_start_date;

  # loop through all the events.

  #Create an array of events which fall
  # within the current list view dates
  my @selected_cal_events;

  #and a funky data structure for the background calendars
  # each element of this hash will be an array.
  my $shared_cal_events={};  #empty hash

  foreach $event_id (keys %events) {
    if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$list_start_timestamp,$list_end_timestamp)) {
      my $event_in_current_calendar = 0;

      foreach $temp_cal_id (@{$events{$event_id}{cal_ids}}) {
        if ($temp_cal_id eq $current_cal_id) {
push @selected_cal_events, $event_id;}
        foreach $background_cal_id (keys %{$current_calendar{local_background_calendars}}) {
          if ($temp_cal_id eq $background_cal_id) {
push @{$shared_cal_events{$background_cal_id}}, $event_id;}
        }
      }
    }
  }

  $html_output =<<p1;
Cache-control: no-cache,no-store,private
Content-disposition: filename="events.csv"
Content-Type: text/plain; charset=$lang{charset}\n\n
p1
  #initialize loop variables
  #$current_timestamp = $list_start_timestamp;
  $current_month = $start_month;
  $current_year = $start_year;

  $html_output .=<<p1;
"Subject","Start Date","Start Time","End Date","End Time","All day event","Reminder on/off","Reminder Date","Reminder Time","Meeting Organizer","Required Attendees","Optional Attendees","Meeting Resources","Billing Information","Categories","Description","Location","Mileage","Priority","Private","Sensitivity","Show time as"
p1


  while ($current_year < $end_year || ($current_year == $end_year && $current_month <= $end_month)) {
    my $current_month_start_timestamp = timegm(0,0,0,1,$current_month,$current_year);
    my $current_month_end_timestamp = &find_end_of_month($current_month, $current_year);
    #display events for selected calendar
    foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @selected_cal_events) {
      my %event = %{$events{$event_id}};

      if (&time_overlap($event{start},$event{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
        my $csv_subject = "$event{title} ($calendars{$current_cal_id}{title})";

        @event_start_timestamp_array = gmtime $event{start};
        my $csv_start_date = ($event_start_timestamp_array[4]+1)."/$event_start_timestamp_array[3]/".($event_start_timestamp_array[5]+1900);
        my $csv_start_time = ($event_start_timestamp_array[2]).":$event_start_timestamp_array[1]:".($event_start_timestamp_array[0]);

        @event_end_timestamp_array = gmtime $event{end};
        my $csv_end_date = ($event_end_timestamp_array[4]+1)."/$event_end_timestamp_array[3]/".($event_end_timestamp_array[5]+1900);
        my $csv_end_time = ($event_end_timestamp_array[2]).":$event_end_timestamp_array[1]:".($event_end_timestamp_array[0]);

        my $csv_description = $event{details};
        $csv_description =~ s/"/""/g;
        $csv_description =~ s/\n/\\n/g;

        if ($event{days} != 1) {
          @event_end_timestamp_array = gmtime $event{end};
          $csv_end_date = ($event_end_timestamp_array[4]+1)."/$event_end_timestamp_array[3]/".($event_end_timestamp_array[5]+1900);
        }

        $html_output .=<<p1;
"$csv_subject","$csv_start_date","$csv_start_time",$csv_end_date,"$csv_end_time","True","True","$csv_start_date","12:00:00 AM",,,,,,,"$csv_description",,,"Normal","False","Normal","1"
p1
      }
    }
    foreach $background_cal_id (keys %{$current_calendar{local_background_calendars}}) {
      #list events for that calendar
      foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @{$shared_cal_events{$background_cal_id}}) {
        my %event = %{$events{$event_id}};

        if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
          my $csv_subject = "$event{title} ($calendars{$background_cal_id}{title})";

          @event_start_timestamp_array = gmtime $event{start};
          my $csv_start_date = ($event_start_timestamp_array[4]+1)."/$event_start_timestamp_array[3]/".($event_start_timestamp_array[5]+1900);
          my $csv_start_time = ($event_start_timestamp_array[2]).":$event_start_timestamp_array[1]:".($event_start_timestamp_array[0]);

          @event_end_timestamp_array = gmtime $event{end};
          my $csv_end_date = ($event_end_timestamp_array[4]+1)."/$event_end_timestamp_array[3]/".($event_end_timestamp_array[5]+1900);
          my $csv_end_time = ($event_end_timestamp_array[2]).":$event_end_timestamp_array[1]:".($event_end_timestamp_array[0]);

          my $csv_description = $event{details};
          $csv_description =~ s/"/""/g;
          $csv_description =~ s/\n/\\n/g;

          $csv_description =~ s/"/""/g;
          $csv_description =~ s/\n/\\n/g;


          if ($event{days} != 1) {
            @event_end_timestamp_array = gmtime $event{end};
            $csv_end_date = ($event_end_timestamp_array[4]+1)."/$event_end_timestamp_array[3]/".($event_end_timestamp_array[5]+1900);
          }

          $html_output .=<<p1;
"$csv_subject","$csv_start_date","$csv_start_time",$csv_end_date,"$csv_end_time","True","True","$csv_start_date","12:00:00 AM",,,,,,,"$csv_description",,,"Normal","False","Normal","1"
p1
        }
      }
    }

    #increment to the next month--the method used
    #here is the most painless way of making
    #this work the right way in all cases.
    $current_month +=1;
    if ($current_month == 12) {
      $current_month=0;

      $current_year++;
    }
  }
  $html_output .= $debug_info;
  print $html_output;
}




sub vcalendar_export_cal {
  ($start_month, $start_year, $end_month, $end_year) = @_;

  #calculate where to start and end the list

  #format for timegm: timegm($sec,$min,$hour,$mday,$mon,$year);
  my $list_start_timestamp = timegm(0,0,0,1,$start_month,$start_year);
  my $list_end_timestamp = &find_end_of_month($end_month, $end_year);

  # loop through all the events.

  #Create an array of events which fall
  # within the current list view dates
  my @selected_cal_events;

  #and a funky data structure for the background calendars
  # each element of this hash will be an array.
  my $shared_cal_events={};  #empty hash

  foreach $event_id (keys %events) {
    if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$list_start_timestamp,$list_end_timestamp)) {
      my $event_in_current_calendar = 0;

      foreach $temp_cal_id (@{$events{$event_id}{cal_ids}}) {
        if ($temp_cal_id eq $current_cal_id) {
push @selected_cal_events, $event_id;}
        foreach $background_cal_id (keys %{$current_calendar{local_background_calendars}}) {
          if ($temp_cal_id eq $background_cal_id) {
push @{$shared_cal_events{$background_cal_id}}, $event_id;}
        }
      }
    }
  }



  $html_output =<<p1;
Cache-control: no-cache,no-store,private
Content-disposition: filename="events.vcs"
Content-Type: text/csv; charset=$lang{charset}

BEGIN:VCALENDAR
PRODID:-//Plans//EN
VERSION:1.0
METHOD:PUBLISH
p1
  #initialize loop variables
  #$current_timestamp = $list_start_timestamp;
  $current_month = $start_month;
  $current_year = $start_year;


  while ($current_year < $end_year || ($current_year == $end_year && $current_month <= $end_month)) {
    my $current_month_start_timestamp = timegm(0,0,0,1,$current_month,$current_year);
    my $current_month_end_timestamp = &find_end_of_month($current_month, $current_year);
    #display events for selected calendar
    foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @selected_cal_events) {
      my %event = %{$events{$event_id}};

      if (&time_overlap($event{start},$event{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
        $html_output .= &event2vcal(\%event)."\n";
      }
    }
    foreach $background_cal_id (keys %{$current_calendar{local_background_calendars}}) {
      #list events for that calendar
      foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @{$shared_cal_events{$background_cal_id}}) {
        my %event = %{$events{$event_id}};

        if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
          $html_output .= &event2vcal(\%event)."\n";
        }
      }
    }

    #increment to the next month--the method used
    #here is the most painless way of making
    #this work the right way in all cases.
    $current_month +=1;
    if ($current_month == 12) {
      $current_month=0;

      $current_year++;
    }
  }

  $html_output .=<<p1;
END:VCALENDAR
p1

  $html_output .= $debug_info;
  print $html_output;
}




sub ascii_text_cal {
  ($start_month, $start_year, $end_month, $end_year) = @_;

  #calculate where to start and end the list

  #format for timegm: timegm($sec,$min,$hour,$mday,$mon,$year);
  my $list_start_timestamp = timegm(0,0,0,1,$start_month,$start_year);
  my $list_end_timestamp = &find_end_of_month($end_month, $end_year);

  # loop through all the events.

  #Create an array of events which fall
  # within the current list view dates
  my @selected_cal_events;

  #and a funky data structure for the background calendars
  # each element of this hash will be an array.
  my $shared_cal_events={};  #empty hash

  foreach $event_id (keys %events) {
    if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$list_start_timestamp,$list_end_timestamp)) {
      my $done = 0;
      foreach $temp_cal_id (@{$events{$event_id}{cal_ids}}) {
        if ($temp_cal_id eq $current_cal_id) {
push @selected_cal_events, $event_id;}
        foreach $background_cal_id (keys %{$current_calendar{local_background_calendars}}) {
          if ($temp_cal_id eq $background_cal_id) {
            push @{$shared_cal_events{$background_cal_id}}, $event_id;
            $done = 1;
            last;
          }
        }
        if ($done == 1) {last;}
      }
    }
  }

  $html_output =<<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=$lang{charset}\n\n
p1
  #initialize loop variables
  #$current_timestamp = $list_start_timestamp;

  $current_month = $start_month;
  $current_year = $start_year;

  while ($current_year < $end_year || ($current_year == $end_year && $current_month <= $end_month)) {
    my $current_month_start_timestamp = timegm(0,0,0,1,$current_month,$current_year);
    my $current_month_end_timestamp = &find_end_of_month($current_month,$current_year);

    $html_output .=<<p1;

*******************************************
$months[$current_month] $current_year
*******************************************

* $current_calendar{title}
p1
    #display events for selected calendar
    foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @selected_cal_events) {
      %event = %{$events{$event_id}};

      if (&time_overlap($event{start},$event{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
        @event_start_timestamp_array = gmtime $event{start};
        my $event_time = "";
        if ($event{days} == 1) {
 #single-day event
          $date_string="$months_abv[$event_start_timestamp_array[4]] $event_start_timestamp_array[3] ".($event_start_timestamp_array[5]+1900);
          if ($event{all_day_event} ne "1") {
            $event_time = &nice_time_range_format($event{start}, $event{end});
            $event_time = " ($event_time)";
          }
        } else { #multi-day event

          $date_string = &nice_date_range_format($event{start}, $event{end}, "-")." ".($event_start_timestamp_array[5]+1900);
        }
        my $event_details = $event{details};
        $event_details =~ s/\n[ \t\r\f]+/\n/g;
        chomp $event_details;

        #indent each line of the details
        $event_details =~ s/\n/\n    /g;


        $html_output .="  $date_string$event_time: $event{title}\n";
        if ($event_details ne "") {
          $html_output .= "    $event_details\n";
        }
        $html_output .= "\n";
      }
    }

    foreach $background_cal_id (keys %{$current_calendar{local_background_calendars}}) {
      $html_output .=<<p1;
* $calendars{$background_cal_id}{title}
p1
      #list events for that calendar
      foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @{$shared_cal_events{$background_cal_id}}) {
        my %event = %{$events{$event_id}};

        if (&time_overlap($event{start},$event{end},$current_month_start_timestamp, $current_month_end_timestamp)) {
          @event_start_timestamp_array = gmtime $event{start};
          my $event_time = "";
          if ($event{days} == 1) {
 #single-day event
            $date_string="$months_abv[$event_start_timestamp_array[4]] $event_start_timestamp_array[3] ".($event_start_timestamp_array[5]+1900);
            if ($event{all_day_event} ne "1") {
            $event_time = &nice_time_range_format($event{start}, $event{end});
              $event_time = " ($event_time)";
            }
          } else { #multi-day event

            $date_string = &nice_date_range_format($event{start}, $event{end}, "-")." ".($event_start_timestamp_array[5]+1900);
          }
          my $event_details = $event{details};
          $event_details =~ s/\n[ \t\r\f]+/\n/g;
          chomp $event_details;

          #indent each line of the details
          $event_details =~ s/\n/\n    /g;


          $html_output .="  $date_string$event_time: $event{title}\n";
          if ($event_details ne "") {
            $html_output .= "    $event_details\n";
          }
          $html_output .= "\n";
        }
      }
    }

    #increment to the next month--the method used
    #here is the most painless way of making
    #this work the right way in all cases.
    $current_month +=1;
    if ($current_month == 12) {
      $current_month=0;
      $current_year++;
    }
  }
  $html_output .= $debug_info;
  print $html_output;

}  #********************end ascii_text_cal subroutine**********************

sub ascii_text_event {
  my %current_event = %{$events{$current_event_id}};

  $html_output =<<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=$lang{charset}\n\n

p1

  my @event_start_timestamp_array = gmtime $current_event{start};
  my $date_string="";

  my $event_time = "";
  if ($current_event{days} == 1) {
 #single-day event
    $date_string="$months_abv[$event_start_timestamp_array[4]] $event_start_timestamp_array[3] ".($event_start_timestamp_array[5]+1900);
    if ($current_event{all_day_event} ne "1") {
      $event_time = &nice_time_range_format($current_event{start}, $current_event{end});
      $event_time = "($event_time)";
    }
  } else { #multi-day event

    $date_string = &nice_date_range_format($current_event{start}, $current_event{end}, "-")." ".($event_start_timestamp_array[5]+1900);
  }
  my $event_details = $current_event{details};
  $event_details =~ s/\n\s+/\n/g;
  $event_details =~ s/\n{2,}/\n/g;
  chomp $event_details;

  #indent each line of the details
  $event_details =~ s/\n/\n    /g;


  $html_output .="  $date_string$event_time: $current_event{title}\n";
  if ($event_details ne "") {
    $html_output .= "    $event_details\n\n";
  }
  $html_output .= $debug_info;
  print $html_output;

}  #********************end ascii_text_event subroutine**********************



sub icalendar_export_event  { # only for 1 event

  # when exporting to outlook, plans uses the vcalendar standard.
  # (http://www.imc.org/rfc2445)
  # This standard is horribly supported by MS outlook (outlook 2000, at the
  # time of this writing.  Outlook refuses to correctly interpret the
  # date-time strings in the following ways:

  # 1.  If the date-time parameter does not specify a time (only a date), do you
  # think outlook sets its "all-day event" flag?  Nope.  It just assumes the
  # event occurs at 000000 hours (12 midnight).

  # 2.  if no time zone is specified, the date-time string is supposed to be
  # interpreted as if it applied to the *current* timezone the user's computer
  # is in (according to the standard).  Do you think outlook does this?  Nope.
  # If no timezone is specified, outlook assumes the time zone is GMT.  As if this
  # weren't enough, outlook "helpfully" adjusts the time to the user's time zone.
  # Depending on how far a user is from GMT, this may cause the day to change.

  # Since there's no way to predict what time zone a user is in, it is impossible
  # to compensate on the server side for outlook's stupidity.  The workaround is
  # to generate event times for each event (even though this is misleading because
  # the events are all-day events), and force all the event times to 12 noon.
  # This puts them as far from the previous and next days as possible, giving the
  # least chance for outlook to screw up the day when it does its adjustment.

  my %current_event = %{$events{$current_event_id}};

  my $ical_string = &event2ical(\%current_event);

#Content-type: text/plain
#Last-modified: Wed, 30 Jan 2002 22:43:12 GMT
  $html_output =<<p1;
Content-type: text/x-vcalendar
Content-disposition: filename="event.ics"

BEGIN:VCALENDAR
PRODID:-//Plans//EN
VERSION:2.0
METHOD:PUBLISH
$ical_string
END:VCALENDAR

p1
  print $html_output;

}  #********************end vcalendar_export subroutine**********************






sub vcalendar_export_event  { # only for 1 event

  my %current_event = %{$events{$current_event_id}};

  $vcal_string .= &event2vcal(\%current_event);

  #my $last_modified = &formatted_time($rightnow, "md mn yy hh:mm:ss GMT");
  #Last-modified: $last_modified

#Content-type: text/plain
  $html_output =<<p1;
Content-type: text/vcs
Content-disposition: filename="event.vcs"

BEGIN:VCALENDAR
PRODID:-//Plans//EN
VERSION:1.0
METHOD:PUBLISH
$vcal_string
END:VCALENDAR

p1
  print $html_output;

}  #********************end vcalendar_export_event subroutine**********************



sub calculate_recurring_events {
  my ($start_timestamp, $recurrence_parms_ref) = @_;

  my %recurrence_parms = %{$recurrence_parms_ref};
  my @recurring_events_array = ();
  my @custom_months = @{$recurrence_parms{'custom_months'}};

  my @timestamp_array = gmtime $start_timestamp;

  #my $start_timestamp = $start_timestamp+50;
  #calculate the weekday_in_month_count for the start timestamp
  # (is it the first tuesday?  second saturday?  This is required for
  # things to work right.

  $real_year = 1900 + $timestamp_array[5];
  $temp_start_timestamp = timegm(0,0,0,1,$timestamp_array[4],$real_year);
  @temp_start_timestamp_array = gmtime($temp_start_timestamp);

  my $weekday_in_month_count = 0;
  #figure out what weekday of the month the start timestamp is
  for (;$temp_start_timestamp < $start_timestamp;$temp_start_timestamp+=86400) {
    @temp_start_timestamp_array = gmtime($temp_start_timestamp);
    if ($temp_start_timestamp_array[6] == $timestamp_array[6]) {
      $weekday_in_month_count++;
    }
  }

  #this must be done, or the week-of-month recurring dates will be hosed
  #@temp_array = gmtime $start_timestamp;
  #my $current_month = $temp_array[4];
  my $last_week=0;


  # set the start timestamp to a day boundary.
  my $boundary_timestamp = timegm(0,0,0,$timestamp_array[3],$timestamp_array[4],$real_year);

  my $timed_event_diff = $start_timestamp - $boundary_timestamp;
  $start_timestamp = $boundary_timestamp;

  # The recurring event algorithm loops through each day in the timeframe
  # and tests its validity against the recurrence parameters.

  # These tests take the form of "assumed valid unless proven otherwise"
  # Doing it this way lets the various recurrence type tests operate
  # independently of each other, while looping only once through the timeframe

  for ($recur_timestamp = $start_timestamp; $recur_timestamp <= $recurrence_parms{'recur_end_timestamp'}; $recur_timestamp += 86400) {
    $last_week=0;
    my @recur_timestamp_array = gmtime $recur_timestamp;
    my $current_month = $recur_timestamp_array[4];

    #look a week ahead, to see if the current weekday is the last one in the month
    my $recur_timestamp_next_week = $recur_timestamp+604800;
    my @recur_timestamp_next_week_array = gmtime $recur_timestamp_next_week;

    $last_week = 1 if ($current_month != $recur_timestamp_next_week_array[4]);

    $real_year = 1900 + $recur_timestamp_array[5];

    $recur_timestamp_valid=1;
    if ($recurrence_parms{'recurrence_type'} eq "same_day_of_month") {
      $recur_timestamp_valid=0 if ($recur_timestamp_array[3] != $timestamp_array[3]);
    } elsif ($recurrence_parms{'recurrence_type'} eq "same_weekday") {
      if ($recur_timestamp_array[6] != $timestamp_array[6]) {
        $recur_timestamp_valid=0;
      } elsif ($recurrence_parms{'weekday_of_month_type'} eq "only_first_week") {
        $recur_timestamp_valid=0 if ($weekday_in_month_count != 0);
      } elsif ($recurrence_parms{'weekday_of_month_type'} eq "only_second_week") {
        $recur_timestamp_valid=0 if ($weekday_in_month_count != 1);
      } elsif ($recurrence_parms{'weekday_of_month_type'} eq "only_third_week") {
        $recur_timestamp_valid=0 if ($weekday_in_month_count != 2);
      } elsif ($recurrence_parms{'weekday_of_month_type'} eq "only_fourth_week") {
        $recur_timestamp_valid=0 if ($weekday_in_month_count != 3);
      } elsif ($recurrence_parms{'weekday_of_month_type'} eq "only_fifth_week") {
        $recur_timestamp_valid=0 if ($weekday_in_month_count != 4);
      } elsif ($recurrence_parms{'weekday_of_month_type'} eq "only_last_week") {
        if ($last_week != 1) {
          $recur_timestamp_valid=0;
        } else {
          #$debug_info .= "timestamp: $recur_timestamp\n";
          #$debug_info .= "current month: $current_month\n";
          #$debug_info .= "lookahead timestamp: $recur_timestamp_next_week\n";
          #$debug_info .= "lookahead month: $recur_timestamp_next_week_array[4]\n";
        }
      }
    } elsif ($recurrence_parms{'recurrence_type'} eq "every_x_days") {
      $recur_timestamp_valid=0 if (($recur_timestamp - $start_timestamp) % (86400 * $recurrence_parms{'every_x_days'}) !=0);
    } elsif ($recurrence_parms{'recurrence_type'} eq "every_x_weeks") {
      $recur_timestamp_valid=0 if (($recur_timestamp - $start_timestamp) % (86400 * 7 * $recurrence_parms{'every_x_weeks'}) !=0);
    }

    if ($recurrence_parms{'year_fit_type'} eq "custom_months") {
      my $month_valid=0;
      foreach $custom_month (@custom_months) {
        $month_valid=1 if ($custom_month == $recur_timestamp_array[4]);
      }
      $recur_timestamp_valid=0 if ($month_valid == 0);
    }

    if ($recur_timestamp_valid == 1) {
      push @recurring_events_array, $recur_timestamp+$timed_event_diff;
      my $real_year = $recur_timestamp_array[5]+1900;
    }

    #count how many of the event's weekdays we have come across in
    #each month.  This is for validating events that occur on the
    #second tuesday, fifth monday, etc.
    if ($recur_timestamp_array[6] == $timestamp_array[6]) {
      $weekday_in_month_count++;
    }

    #reset week_in_month count if this is the last week in the month
    $weekday_in_month_count=0 if ($last_week == 1 && $recur_timestamp_array[6] == $timestamp_array[6]);
  }

  if (scalar @recurring_events_array == 0) {
    $debug_info .= "Error!  No valid recurring event dates found!\n";
  }

  #$debug_info .= "returning ".(scalar @recurring_events_array)." recurring events\n";

  return \@recurring_events_array;
}


sub verify_date() {
  # $date is of the format similar to mm/dd/yyyy (or a permutation like dd/mm/yyyy)
  my ($date, $recurrence_parms_ref) = @_;
  my %recurrence_parms = %{$recurrence_parms_ref};

  my $results="";

  if ($date !~ /^(\w{1,2}\W\w{1,2}\W\w{2,4}|\w{1,2}\W\w{2,4}\W\w{1,2}|\w{2,4}\W\w{1,2}\W\w{1,2})$/) {
    $lang{date_verify_err0} =~ s/###date###/$date/;
    $lang{date_verify_err0} =~ s/###format###/$current_calendar{date_format}/;
    $results .= $lang{date_verify_err0}."\n";
  }

  if ($recurrence_parms{'recurrence_type'} eq "every_x_days") {
    if ($recurrence_parms{'every_x_days'} == 0) {
$results .= $lang{date_verify_err7}."\n"};
  } elsif ($recurrence_parms{'recurrence_type'} eq "every_x_weeks") {
    if ($recurrence_parms{'every_x_weeks'} == 0) {
$results .= $lang{date_verify_err8}."\n"};
  }



  if ($date eq "") {
    $results .= $lang{date_verify_err1}."\n";
  }

  my ($mon, $day, $year) = &format2mdy($date, $current_calendar{date_format});

  return $results;
}

sub verify_time {
  my ($time) = @_;
  my $results="";
  if($options{twentyfour_hour_format}) {
     if ($time !~ /(\d+):(\d+)/) {
      $lang{time_verify_err0} =~ s/\{0\}/$time/;
      $results .= $lang{time_verify_err0};
    } else {
      my $hours = $1;
      my $minutes = $2;
      if ($hours > 23 || $hours < 0){
        $lang{time_verify_err1} =~ s/\{0\}/$hours/;
        $results .= $lang{time_verify_err1};
      }

      if ($minutes > 59 || $minutes < 0){
        $lang{time_verify_err2} =~ s/\{0\}/$minutes/;
       $results .= $lang{time_verify_err2};
      }
    }
  } else {

    if ($time !~ /(\d+):(\d+)\s*($lang{am}|$lang{pm})/) {
      $lang{time_verify_err0} =~ s/\{0\}/$time/;
      $results .= $lang{time_verify_err0};
    } else {
      my $hours = $1;
      my $minutes = $2;
      my $ampm = $3;

      if ($hours > 12 || $hours < 0) {
        $lang{time_verify_err1} =~ s/\{0\}/$hours/;
        $results .= $lang{time_verify_err1};
      }

      if ($minutes > 60 || $minutes < 0) {
        $lang{time_verify_err2} =~ s/\{0\}/$minutes/;
        $results .= $lang{time_verify_err2};
      }

    }
  }
  return $results;
}



sub preview_date {

	my $results = {};
	$results{'success'} = 1;
	$results{'messages'} = [];

	my @valid_dates;

	my %recurrence_parms;
	$recurrence_parms{'recurrence_type'} = $q->param('recurrence_type');
	$recurrence_parms{'weekday_of_month_type'} = $q->param('weekday_of_month_type');
	$recurrence_parms{'every_x_days'} = $q->param('every_x_days');
	$recurrence_parms{'every_x_weeks'} = $q->param('every_x_weeks');
	$recurrence_parms{'year_fit_type'} = $q->param('year_fit_type');
	$recurrence_parms{'recur_end_date'} = $q->param('recur_end_date');
	$recurrence_parms{'recur_end_timestamp'} = 0;

	my @custom_months = $q->param('custom_months');

	$recurrence_parms{'custom_months'} = \@custom_months;

	my $recurring_event = $q->param('recurring_event');
	my $event_start_date = $q->param('evt_start_date');
	my $recur_end_date = $q->param('recur_end_date');
	my $event_days = $q->param('evt_days');
	my $event_start_time = $q->param('evt_start_time');
	my $event_end_time = $q->param('evt_end_time');
	my $all_day_event = $q->param('all_day_event');

	my $date_valid = &verify_date($event_start_date);

	if ( $date_valid ne "" ) {
		$results{'success'} = 0;
		push @{$results{messages}}, $date_valid;

	}

	if ($event_days eq "") {
		$results{'success'} = 0;
		push @{$results{messages}}, $lang{date_verify_err2};
	}

	if ($event_days =~ m/\D/ || $event_days <= 0) {
		$results{'success'} = 0;
		my $temp = $lang{date_verify_err3};
		$temp =~ s/\$1/$event_days/;
		push @{$results{messages}}, $temp;
	}


	if ($recurring_event) {
		my $temp .= &verify_date($recurrence_parms{'recur_end_date'}, \%recurrence_parms);
		if ($temp ne "") {
			$results{'success'} = 0;
			push @{$results{messages}}, $lang{date_preview_for_recurring_end_date}. " " . $temp;
		}
	}

	if ($results{'success'} == 1) {
		my ($start_mon, $start_mday, $start_year) = &format2mdy($event_start_date, $current_calendar{date_format});
		my ($recur_end_mon, $recur_end_mday, $recur_end_year) = &format2mdy($recurrence_parms{'recur_end_date'}, $current_calendar{date_format});
		$start_mon--;
		$recur_end_mon--;

		my ($event_start_timestamp, $event_end_timestamp) = &timestamp_from_datetime($start_mday,$start_mon,$start_year,$event_days,$event_start_time,$event_end_time,$all_day_event);


		@timestamp_array = gmtime $event_start_timestamp;
		my $real_year = $timestamp_array[5]+1900;

		if ($recurring_event == 1) {
			#calculate end timestamp
			$recurrence_parms{'recur_end_timestamp'} = timegm(0,0,0,$recur_end_mday,$recur_end_mon,$recur_end_year);

			my @recurring_events_array = @{&calculate_recurring_events($event_start_timestamp, \%recurrence_parms)};
			foreach $recurring_event_timestamp (@recurring_events_array) {
				$timestamp1 = $recurring_event_timestamp;
				$timestamp2 = $recurring_event_timestamp + 86400 * ($event_days-1);
				if ($timestamp1 == $timestamp2) {$timestamp2++;}

				$date_range = &nice_date_range_format($timestamp1, $timestamp2, "-");
				push @valid_dates, $date_range;
			}

		} else {
			my $date = "";
			$timestamp1 = $event_start_timestamp;
			$timestamp2 = $event_start_timestamp + 86400 * ($event_days-1);
			if ($timestamp1 == $timestamp2) {$timestamp2++;}

			$date_range = &nice_date_range_format($timestamp1, $timestamp2, "-");
			push @valid_dates, $date_range;
		}

	} 

	$results{success} = ($results{success} eq "1") ? JSON::PP::true() : JSON::PP::false();
	$results{debug_info} = $debug_info;
	$results{valid_dates} = \@valid_dates;;

	$json_results = encode_json \%results;
	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=iso-8859-1\n
$json_results
p1

  exit(0);



}  # end preview date subroutine



sub view_event {
  my %current_event = %{$events{$current_event_id}};

  my $event_info = &generate_event_details(\%current_event, $event_details_template);
  $debug_info =~ s/\n/<br\/>\n/g;

  my $html_output .=<<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/html; charset=$lang{charset}\n
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
<meta http-equiv="pragma" content="no-cache">
<link rel="stylesheet" href="$css_path" type="text/css" media=screen>
p1

  $html_output .= &get_js_includes( $theme_url );

  $html_output .= <<p1;
<title>$current_event{title}</title>
</head>
<body">

$event_info
$debug_info
</body>
</html>
p1

  print $html_output;
}  # view_event


sub view_pending_event {
  my ($pending_event_ref) = @_;
  my %pending_event = %{$pending_event_ref};

  $event_details_template =~ s/###export event link###/$lang{event_details_export_disable}/g;
  $event_details_template =~ s/###edit event link###/$lang{event_details_edit_disable}/g;
  $event_details_template =~ s/###email reminder link###/$lang{event_email_reminder_disable}/g;


  my $event_info = &generate_event_details(\%pending_event, $event_details_template);
  $debug_info =~ s/\n/<br\/>\n/g;

  my $html_output .=<<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/html; charset=$lang{charset}\n
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
<meta http-equiv="pragma" content="no-cache">
<link rel="stylesheet" href="$css_path" type="text/css" media=screen>
p1

  $html_output .= &get_js_includes( $theme_url );

  $html_output .= <<p1;
<title>$current_event{title}</title>
</head>
<body>

$event_info
$debug_info
</body>
</html>
p1

  print $html_output;
}  # view_pending_event



sub set_email_reminder {


	my $results = {};
	$results{'success'} = 1;
	$results{'messages'} = [];

	my %current_event = %{$events{$current_event_id}};

	my $reminder_results = "";
	my $to_address = $q->param('email_address');
	my $extra_text = $q->param('extra_text');
	$to_address =~ s/\s//g;
	$to_address =~ s/;/,/g;
	chomp $to_address;

	my $reminder_seconds = $q->param('reminder_seconds');
	my $reminder_time = $q->param('reminder_time');

	$reminder_time = lc $reminder_time;

	my $email_valid = &validate_emails($to_address);

	if ($email_valid ne "") {
		$reminder_results = $lang{email_reminder_invalid_address};
		$reminder_results =~ s/###address###/$email_valid/g;
		push @{$results{messages}}, $reminder_results;
		$results{'success'} = 0;
	} else {
		my @event_reminder_ids = ($current_event{id});
		my @future_event_reminder_ids;
		if ($q->param('all_in_series') ne "") {
			@event_reminder_ids = &get_events_in_series($current_event{series_id});
			&normalize_timezone();
		}

		foreach $event_reminder_id (@event_reminder_ids) {
			if ($events{$event_reminder_id}{start} > $rightnow) {
				push @future_event_reminder_ids, $event_reminder_id;
			}
		}

		foreach $event_reminder_id (@future_event_reminder_ids) {
			# assemble email reminder xml
			my $reminder_xml = "";

			$reminder_xml .= &xml_store($event_reminder_id, "evt_id").
								&xml_store($reminder_seconds, "before").
								&xml_store($to_address, "email_address").
								&xml_store($extra_text, "extra_text").
								&xml_store("$script_url/$name", "script_url").
								&xml_store($rightnow, "timestamp");

			$reminder_xml = "<email_reminder>$reminder_xml</email_reminder>\n";

			# write email reminder to file
			open (FH, ">>$options{email_reminders_datafile}") || ($debug_info .="<br/>Unable to open email reminders data file $options{email_reminders_datafile} for writing<br/>");
			print FH $reminder_xml;
			close FH;
		}

		my $test_reminder_results = "";
		if ($q->param('send_test_now') == 1) {

			my $reminder_text = $lang{email_reminder_test_text};
			$reminder_text =~ s/###reminder_time###/$reminder_time/g;

			my $date_string = &nice_date_range_format($current_event{start}, $current_event{end}, " - ");

			my $event_time = "";
			if ($current_event{all_day_event} ne "1") {
				$event_time = &nice_time_range_format($current_event{start}, $current_event{end});
			}

			$reminder_text =~ s/###time###/$event_time/g;
			$reminder_text =~ s/###title###/$current_event{title}/g;
			$reminder_text =~ s/###date###/$date_string/g;
			$reminder_text =~ s/###extra text###/$extra_text/g;
			$reminder_text =~ s/###details###/$current_event{details}/g;
			$reminder_text =~ s/###link###/$script_url\/$name?view_event=1&evt_id=$current_event{id}/g;


			$test_reminder_results = &send_email_reminder(\%current_event, $to_address, $reminder_text);

			if ($test_reminder_results eq "1") {
				$test_reminder_results = $lang{email_reminder_test_success};
				$test_reminder_results =~ s/###address###/$to_address/g;
			} else {
				$test_reminder_results = $lang{email_reminder_test_fail};
				$test_reminder_results =~ s/###results###/$test_reminder_results/g;
			}
		}

		$lang{email_reminder_results1} =~ s/###address###/$to_address/g;
		$lang{email_reminder_results1} =~ s/###reminder time###/$reminder_time/g;

		if ($q->param('send_test_now') == 1) {
			$lang{email_reminder_results1} .= $lang{email_reminder_results3}
		} else {
			$lang{email_reminder_results1} .= $lang{email_reminder_results2}
		}


		push @{$results{messages}}, $lang{email_reminder_results1};
		push @{$results{messages}}, $test_reminder_results;;

	}


	$results{success} = ($results{success} eq "1") ? JSON::PP::true() : JSON::PP::false();
	$results{debug_info} = $debug_info;

	$json_results = encode_json \%results;
	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=iso-8859-1\n

$json_results
p1



}  # set_email_reminder

sub detect_remote_calendars() {

	my $results = {};
	$results{'success'} = 1;
	$results{'messages'} = [];


	my $remote_calendar_url = $q->param('remote_calendar_url');
	$remote_calendar_url =~ s/\?.+//;

	$remote_calendar_url .= "/" if ($remote_calendar_url !~ /\.cgi$/);
	$remote_calendar_base_url = $remote_calendar_url;
	$remote_calendar_url .= "?remote_calendar_request=1&get_public_calendars=1";

	my $xml_results = &get_remote_file($remote_calendar_url);

	my %remote_calendars = %{&xml2hash($xml_results)};

	my @public_calendars;

	if (ref $remote_calendars{'xml'}{public_calendar} eq "ARRAY") {
		@public_calendars = @{$remote_calendars{'xml'}{public_calendar}};
	} else {
		push @public_calendars, $remote_calendars{'xml'}{public_calendar};
	}

	$results{public_calendars} = \@public_calendars;
	$results{url} = $remote_calendar_base_url;
	$results{remote_calendar_version} = $remote_calendars{'xml'}{plans_version};
	$results{success} = ($results{success} eq "1") ? JSON::PP::true() : JSON::PP::false();
	$results{debug_info} = $debug_info;

	$json_results = encode_json \%results;
	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=iso-8859-1\n

$json_results
p1

  exit(0);

}


sub remote_calendar_request() {
  my $html_output .=<<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/xml; charset=$lang{charset}\n

p1
  my $results = "";
  my $current_cal_ids_string = $q->param('cal_id');

  $results .=<<p1;
<plans_version>$plans_version</plans_version>
p1

  # if the client requests a list of all calendars that are publically share-able.
  if ($q->param('get_public_calendars') eq "1") {
    foreach $cal_id (keys %calendars) {
      if ($calendars{$cal_id}{allow_remote_calendar_requests}) {
        my $temp=$calendars{$cal_id}{remote_calendar_requests_require_password};
        $results .=<<p1;
<public_calendar><id>$cal_id</id><title>$calendars{$cal_id}{title}</title><requires_password>$temp</requires_password></public_calendar>
p1
      }
    }
  } else  { # return xml data for the events.

    my @current_cal_ids = ();
    my @temp = split (",",$current_cal_ids_string);

    my $cal_id_valid=1;

    foreach $cal_id (@temp) {
      if ($cal_id !~ /\D/) {
        push @current_cal_ids, $cal_id;
      } else {
        $cal_id_valid=0;
        $results .= "<error>Invalid calendar ID: $cal_id</error>";
        last;
      }
    }
    if ($cal_id_valid) {
      foreach $current_cal_id (@current_cal_ids) {
          $results .=<<p1;
<calendar><id>$current_cal_id</id><title>$calendars{$current_cal_id}{title}</title><gmtime_diff>$calendars{$current_cal_id}{gmtime_diff}</gmtime_diff></calendar>
p1
      }

      foreach $current_cal_id (@current_cal_ids) {
        foreach $event_id (keys %events) {

          my $event_in_current_calendar = 0;

          foreach $temp_cal_id (@{$events{$event_id}{cal_ids}}) {
            if ($temp_cal_id eq $current_cal_id) {
              $event_in_current_calendar = 1;
              last;
            }
          }

          next if ($event_in_current_calendar == 0);

          my $xml_data = &event2xml($events{$event_id});
          $results .=<<p1;
$xml_data
p1
        }
      }
    }
  }

  if ($debug_info ne "") {
$results .= "<debug_info>$debug_info</debug_info>";}

  $html_output .= "<xml>$results</xml>";

  print $html_output;

}




#******************* the following subroutines don't display any HTML **********




sub diagnostic_info() {
  my $results = "";

  $results .= <<p1;
<b>Script Name:</b>$name<br/>
<br/>
p1

 if ($options{email_mode} && !$writable{email_reminders_datafile}) {
   $results .=<<p1;
<b>Warning:</b> The email reminders data file: $options{email_reminders_datafile} is not writable.  This will
cause some email functions to be disabled or not work correctly.<br/>
p1
 }
 if ($options{data_storage_mode} == 0 && !$writable{calendars_file}) {
   $results .=<<p1;
<b>Warning:</b> The calendars data file: $options{calendars_file} is not writable.  The add/edit calendars tab won't appear
unless this file is writable.<br/>
p1
 }
 if ($options{data_storage_mode} == 0 && !$writable{pending_actions_file}) {
   $results .=<<p1;
<b>Warning:</b> The pending actions data file: $options{pending_actions_file} is not writable.  The add/edit calendars tab won't appear
unless this file is writable.<br/>
p1
 }
 if ($options{data_storage_mode} == 0 && !$writable{events_file}) {
   $results .=<<p1;
<b>Warning:</b> The events data file: $options{events_file} is not writable.  The add/edit events tab won't appear
unless this file is writable.<br/>
p1
 }

  my $cwd = `pwd`;

  $results .=<<p1;
<b>Plans version:</b> $plans_version<br/>
<b>script name:</b> $name<br/>
<b>script file path:</b> <span style="color:#00f;">$cwd</span><br/>
<b>script url path:</b> $script_url<br/>
<br/>
<b>Theme url:</b> $theme_url<br/>
<b>graphics url:</b> $graphics_url<br/>
<b>icons url:</b> $icons_url<br/>
<br/>
<b>Options:</b><br/>
p1

 # blank out options that we don't want public
 delete $options{db_name};
 delete $options{db_hostname};
 delete $options{db_username};
 delete $options{db_password_file};
 delete $options{mysql_password};
 delete $options{salt};

  foreach $option (keys %options) {
    $results .=<<p1;
<b>$option:</b> $options{$option}<br/>
p1
  }
  return $results;

}       # end diagnostic subroutine


sub assemble_icon_menus() {
  # this function extracts a data structure for the icon menus from the xml definition
  my ($data)= @_;

  my @new_menuitems=();

  my @menuitems = &xml_extract($data, "menuitem", 0);
  if (scalar @menuitems == 0) {
    $debug_info .= "Warning.  There's a menu with no menuitems.  This may be caused by an older version of Perl ( < 5.6).\n";
    $debug_info .= "$data";
  } else {
    foreach my $menuitem (@menuitems) {
      my $icon_name = $menuitem->{attributes}{"value"};
      my $icon_description = $menuitem->{data};
      $new_menuitems[$menuitem->{position}] = [$icon_name,$icon_description];
    }
  }

  # then get the submenus
  my @submenus = &xml_extract($data, "menu", 0);
  foreach $submenu (@submenus) {
    my $temp = $submenu->{data};
    my $temp2 = $submenu->{attributes}{name};
    my @submenuitems = assemble_icon_menus($temp);
    $new_menuitems[$submenu->{position}] = [$temp2, \@submenuitems];
  }

  return @new_menuitems;
}   #******************** end assemble_icon_menus **********************


sub generate_flat_icon_menus {
  my ($icons_list, $selected_icon) = @_;
  my $return_text="";

  my $indent = " ";
  for ($l1=0;$l1<$index_number;$l1++) {
    $indent .= "  ";
  }

  foreach $icon_ref (@{$icons_list}) {
    my $identifier = @{$icon_ref}[1];

    if ($identifier =~ /ARRAY/)   { # if it's a submenu
     $icon_menu_index_number++;
     my $submenu_name = @{$icon_ref}[0];

     $return_text .= <<p1;
<optgroup label="$submenu_name">
p1
     $return_text .= &generate_flat_icon_menus(@{$icon_ref}[1], $selected_icon);
     $return_text .= <<p1;
</optgroup>
p1
    } else  { # if it's a menu item
      my $icon_filename = @{$icon_ref}[0];
      my $icon_name = @{$icon_ref}[1];

      $icon_name = &decode($icon_name);

      if ($icon_filename eq $selected_icon) {
      $return_text .= <<p1;
<option value = "$icon_filename" selected>$icon_name</option>
p1
      } else {
      $return_text .= <<p1;
<option value = "$icon_filename">$icon_name</option>
p1
      }
    }
  }
  return $return_text;

}   #******************** end generate_flat_icon_menus **********************


sub get_upcoming_events() {
  my $days_before = $q->param('days_before')+0;
  my $days_after = $q->param('days_after')+0;
  my $background_calendars_mode = $q->param('background_calendars_mode');
  my $upcoming_events_id = $q->param('upcoming_events_id');
  my $results = "";

  my $start = $rightnow - $days_before*86400;
  my $end = $rightnow + $days_after*86400;

  # clear events
  %events = ();

  my @cal_ids = split(',',$q->param('cal_ids'));


  #$results .= &common_javascript();
  my $date_format = lc $current_calendar{date_format};
  $results .= "date_format = '$date_format';\n";

  my %all_calendar_ids;

  foreach $calendar_id (@cal_ids) {
    next if ($calendars{$calendar_id}{id} eq "");

    foreach $local_background_calendar_id (keys %{$calendars{$calendar_id}{local_background_calendars}}) {
      $all_calendar_ids{$local_background_calendar_id} = 1;
    }
    $all_calendar_ids{$calendar_id} = 1;
  }
  
  foreach $calendar_id (keys %all_calendar_ids) {
    $results .= "calendars['$calendar_id'] = " . &calendar2json($calendars{$calendar_id}) . ";\n";
  }

  my @temp;
  if ($background_calendars_mode ne "none") {
    @temp = keys %all_calendar_ids;
  } else {
    @temp = @cal_ids;
  }
  
  &load_events($start, $end, \@temp);
  &normalize_timezone;

  $results .= "all_calendars = new Array('".(join "','", keys %all_calendar_ids)."');\n";

  foreach $event_id (keys %events) {
    $results .= "upcoming_events['$event_id'] = " . &event2json($events{$event_id}) . ";\n";
    $results .= "upcoming_events_order.push('$event_id'); \n";
  }

  if ($debug_info ne "") {
    $debug_info = &javascript_cleanup($debug_info);
    $results .= "if ($upcoming_events_id.debug) debug('$debug_info');\n";
  }

  $results .= "$upcoming_events_id.plans_theme_url='$theme_url';\n";
  $results .= "$upcoming_events_id.show();\n";

  my $nice_expires = $rightnow + $options{upcoming_events_cache_seconds};
  $nice_expires = uc &formatted_time($nice_expires, "mn/md/yy hh:mm:ss AMPM");

  my $cache_line = "Cache-control: no-cache,no-store,private";
  $cache_line = "Cache-Control: max-age=$options{upcoming_events_cache_seconds};\nExpires: $nice_expires;" if ($options{upcoming_events_cache_seconds} > 0);


  my $html_output .=<<p1;
$cache_line
Content-Type: text/html; charset=$lang{charset}\n
$results
p1

  print $html_output;
}







sub export_calendar_link() {
  my $results = "";

  $results .=<<p1;
<a href="javascript:document.export_cal_form.submit();">$lang{export}</a> $lang{these_events_to}
<form name="export_cal_form" target="_blank" action="$script_url/$name" method="POST">
<input type="hidden" name="export_calendar" value=1>

<select name="export_type">
<option value="ascii_text">$lang{text_option}
<option value="csv_file">$lang{csv_file}
<option value="csv_file_palm">$lang{csv_file_palm}
<option value="icalendar">$lang{icalendar_option}
<option value="vcalendar">$lang{vcalendar_option}
</select>
</form>
p1

}




sub add_edit_user() {
	my $results = {};
	$results{'success'} = 0;
	$results{'messages'} = [];
	my $status = 1;

	my $id = $q->param('user_id');
	my $name = $q->param('name');
	my $notes = $q->param('notes');
	my $password = $q->param('password');
	my $new_password = $q->param('new_password');
	my $repeat_password = $q->param('repeat_password');
	my $delete_flag = $q->param('delete');


	my $login_valid = 0;
	# validate password
	if ($logged_in_as_root) { # plans 'root' password
		$login_valid = 1;
	} elsif ($logged_in_as_current_cal_admin) { # current calendar admin
		$login_valid = 1;
	}


	if (!$login_valid) {
    	if ($delete_flag eq "1") {
			push @{$results{messages}}, $lang{user_not_deleted};
		} else {
			push @{$results{messages}}, $lang{user_not_added};
		}
	} else {
		# delete?
		if ($delete_flag eq "1") {
			my $temp = $lang{user_deleted};
			$temp =~ s/\$1/$users{$id}{name}/;
			push @{$results{messages}}, $temp;

			delete $user{calendars}{$calendar_id};

			if (scalar keys %{$user{calendars}} == 0) {
				delete $users{$user_id};
			}
			&update_user($user_id);

			&delete_user($id);
			$results{'success'} = 1;
			$results{'users'} = &generate_users_javascript;

		} else {
			# add or update?
			if ($id eq "") { # add

				$password = crypt($password, $options{salt});

				my $new_id = $max_user_id+1;
				my %cal_refs;
				$cal_refs{$current_cal_id}{edit_events} = 1;

				$users{$new_id} = {id => $new_id,
								name => $name,
								notes => $notes,
								password => $password,
								calendars => \%cal_refs
				};
				&add_user($new_id);
				$results{'success'} = 1;
				$results{'users'} = &generate_users_javascript;

				push @{$results{messages}}, $lang{user_added};
			} else { # update
				$password = crypt($password, $options{salt});

				my %cal_refs;
				$cal_refs{$current_cal_id}{edit_events} = 1;

				$users{$id} = {id => $id,
							name => $name,
							notes => $notes,
							password => $password,
							calendars => \%cal_refs
				};
				&update_user($id);
				$results{'success'} = 1;
				$results{'users'} = &generate_users_javascript;

				push @{$results{messages}}, $lang{user_updated};
			}
		}
	}


	if ($results{'success'} eq "1") {
		$results{calendars} = &calendars_as_array( \%calendars );
	}

	$results{success} = ($results{success} eq "1") ? JSON::PP::true() : JSON::PP::false();
	$results{debug_info} = $debug_info;

	$json_results = encode_json \%results;
	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=iso-8859-1\n

$json_results
p1


  exit(0);
}

sub add_new_ical {

	my $results = {};
	$results{'success'} = 0;
	$results{'messages'} = [];

	my $ical_url = &decode($q->param('ical_url'));

	if (!$logged_in_as_root) {
			push @{$results{messages}}, 'You must be logged in to add an iCal!';
	} else {
		# try getting the URL
		my $url_results = &get_remote_file($ical_url);
		$debug_info .= $url_results;

		if ($url_results eq "404 not found!" || $url_results =~ /cannot connect/i) {
			push @{$results{messages}}, 'iCal calendar <b>not</b> added!  (invalid url)';
			$results .= "messages = 'iCal calendar <b>not</b> added!  (invalid url)';";
		} else {
			my %new_calendar = &deep_copy(\%default_cal);
			my $new_cal_id = $max_cal_id + 1;

			$new_calendar{id} = $new_cal_id;
			$new_calendar{title} = "($ical_url)";
			$new_calendar{type} = "ical";
			$new_calendar{url} = $ical_url;

			$calendars{$new_cal_id} = &deep_copy(\%new_calendar);

			&add_calendars([$new_calendar{id}]);

			push @{$results{messages}}, 'iCal calendar ($ical_url) added!';
			$results{'success'} = 1;
		}
	}

	if ($results{'success'} eq "1") {
		$results{calendars} = &calendars_as_array( \%calendars );
	}

	$results{success} = ($results{success} eq "1") ? JSON::PP::true() : JSON::PP::false();
	$results{debug_info} = $debug_info;

	$json_results = encode_json \%results;
	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=iso-8859-1\n

$json_results
p1


  exit(0);

}



sub js_login() {

	my $results = {};
	$results{'success'} = 0;
	$results{'messages'} = [];

	if ($logged_in) {
		$results{'success'} = 1;
		push @{$results{messages}}, $lang{'logged_in1'};
		
		$results{'session_id'} = $session->id;
		$results{'cookie_path'} = $cookie_path;
  	} elsif( $q->param('logout') eq "1") {
		$results{'success'} = 1;
		push @{$results{messages}}, $lang{'logged_in2'};
  	} else {
		$results{'success'} = 0;
		push @{$results{messages}}, $lang{'logged_in3'};
  	}

	$results{success} = ($results{success} eq "1") ? JSON::PP::true() : JSON::PP::false();
	$results{debug_info} = $debug_info;

	$json_results = encode_json \%results;
	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=iso-8859-1\n
$json_results
p1

  exit(0);
}


sub manage_pending_events() {
	&normalize_timezone();

	my $approve = $q->param('approve');
	my $delete = $q->param('delete');

	my $results = {};
	$results{'success'} = 1;
	$results{'messages'} = [];


	if ($logged_in_as_root || $logged_in_as_current_cal_admin) {
		$add_edit_event = "add";

		my @events_to_approve = split(',', $q->param('approve'));
		my @events_to_delete = split(',', $q->param('delete'));

		foreach $event_to_approve (@events_to_approve) {
			&commit_event($new_events{$event_to_approve});

			my $temp = $lang{pending_event_approved};
			$temp =~ s/\$1/$event_to_approve/;
			push @{$results{messages}}, $temp;
		}

		foreach $event_to_delete (@events_to_delete) {
			my $temp = $lang{pending_event_deleted};
			$temp =~ s/\$1/$event_to_delete/;
			push @{$results{messages}}, $temp;
		}

		push @events_to_delete, @events_to_approve;
		&delete_pending_actions(\@events_to_delete);

		$results .= "window.location='$script_url/$name?messages=".&encode($messages)."';";
		#$results .= "alert(\"window.location=$script_url/$name&messages=".&encode($messages)."\");";
	} else {
		$results{'success'} = 0;
		push @{$results{messages}}, $lang{invalid_password};
	}

	$results{success} = ($results{success} eq "1") ? JSON::PP::true() : JSON::PP::false();
	$results{debug_info} = $debug_info;

	if ($results{'success'} eq "1") {
		$results{calendars} = &calendars_as_array( \%calendars );
		&load_actions();

		my @pending_events = &pending_events_as_array();
		$results{'pending_events'} = \@pending_events;
		$results{'pending_events_area_html'} = &generate_pending_events_area();

		$results{'calendar_html'} = &regenerate_calendar_html(); 

		#$results{new_events} = \%events;
	}

	$json_results = encode_json \%results;

	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=iso-8859-1\n
$json_results
p1

}

sub generate_calendar_controls() {
	my $results = "";

	$results .=<<p1;
<div class="calendar_select" style="margin:5px;padding:2px;float:left;text-align:left;">
$lang{controls_calendar_label}<br/>
p1

	my @selectable_calendars;

	if ($options{all_calendars_selectable}) {
		@selectable_calendars = keys %calendars;
	} else {
		@selectable_calendars = keys %{$current_calendar{selectable_calendars}};
		unshift @selectable_calendars, $current_cal_id if (!&contains(\@selectable_calendars, $current_cal_id));
	}

    if (scalar @selectable_calendars > 1) {
		$results .=<<p1;
<select id="cal_id" name="cal_id" onChange="jQuery.planscalendar.blink('#controls_submit_button');">
p1

	#list each calendar for the user to select
	my %explicit_calendar_order;
	if ($options{calendar_select_order} ne "alpha" && $options{calendar_select_order} ne "") {
		my @cal_order_ids = split(',',$options{calendar_select_order});
		my $cal_order_index = 0;

		foreach $selectable_calendar_id (@selectable_calendars) {
			$explicit_calendar_order{"$selectable_calendar_id"} = 9999999;
		}

		foreach $cal_order_id (@cal_order_ids) {
			next if ($cal_order_id eq "");
			$explicit_calendar_order{"$cal_order_id"} = $cal_order_index;
			$cal_order_index++;
		}
	}

	foreach $selectable_calendar_id (sort {
                                        if ($options{calendar_select_order} eq "alpha") {
                                          return lc $calendars{$a}{title} cmp lc $calendars{$b}{title};
                                        } elsif ($options{calendar_select_order} ne "") {
return $explicit_calendar_order{"$a"} <=> $explicit_calendar_order{"$b"} || lc $calendars{$a}{title} cmp lc $calendars{$b}{title};} else {
return $a <=> $b;}

    									}  @selectable_calendars) {
		my $selected ="";
		$selected =" selected" if ($selectable_calendar_id eq $current_calendar{id});
		$selectable_calendar_id=~ s/\D//g;

		$results .=<<p1;
<option value = "$selectable_calendar_id"$selected>$calendars{$selectable_calendar_id}{title}
p1
      }

	$results .=<<p1;
</select>
p1
	} else {
		$results .=<<p1;
<span style="font-weight:bold;">$current_calendar{title}</span>
<input type="hidden" name="cal_id" value="$current_calendar{id}"/>
p1
	}
	$results .=<<p1;
</div>

<div style="margin:5px;padding:2px;float:left;text-align:left;">
$lang{controls_display_label}<br/>
<select name="display_type" onChange="jQuery.planscalendar.blink('#controls_submit_button');">
p1

	for (my $l1=0;$l1<scalar @{$options{display_types}};$l1++) {
		next if ($options{display_types}[$l1] ne "1");
		my $selected="";

		if ($l1 eq $display_type) {
			$selected = "selected";
		}

		$results .=<<p1;
<option value="$l1" $selected>$lang{controls_display_type}[$l1]
p1
	}

	$results .=<<p1;
</select>
</div>
p1

	return $results;
}

sub generate_calendars_javascript() {
  my $results = "";

  foreach $calendar_id (sort {$a <=> $b} keys %calendars) {
    my %calendar = %{$calendars{$calendar_id}};
    $results .= "calendars[$calendar_id] = new Object;";
    $results .= "calendars[$calendar_id].users = new Array();";

    foreach $user_ref (@{$calendar{users}}) {
      my %user = %{$user_ref};
      $results .= "calendars[$calendar_id].users[$user{id}] = new Object;";
    }
  }
  return $results;
}


sub api_add_delete_events() {
	my $results = "";

	my %add_edit_events_results =  %{&add_edit_events()};

	if ($add_edit_events_results{'success'} eq "1") {
		$add_edit_events_results{'calendar_html'} = &regenerate_calendar_html(); 
	}

	$add_edit_events_results{success} = ($add_edit_events_results{success} eq "1") ? JSON::PP::true() : JSON::PP::false();
	$add_edit_events_results{new_events} = &events_json_ready( \%events );
	$add_edit_events_results{new_event_ids} = $add_edit_events_results{'new_event_ids'};
	$add_edit_events_results{debug_info} = $debug_info;

	$results = encode_json \%add_edit_events_results;
	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=iso-8859-1\n

$results
p1
}

sub regenerate_calendar_html() {
	&load_templates();
	%events = {};

	# load event data, for main calendar and its background calendars
	my @temp_calendars = ($current_cal_id);
	foreach $local_background_calendar (keys %{$current_calendar{local_background_calendars}}) {
		push @temp_calendars, $local_background_calendar;
	}

	&load_events($cal_start_timestamp, $cal_end_timestamp, \@temp_calendars);
	&normalize_timezone();

	$calendar_html = &render_calendar($cal_start_month, $cal_start_year, $cal_end_month, $cal_end_year);
	return $calendar_html;

}

sub api_add_delete_calendar() {
	my $results = "";

	my %add_edit_calendar_results =  %{&add_edit_calendars()};

	if ($add_edit_calendar_results{'success'} eq "1") {
		&load_templates();
		%calendar = {};
	}

	$add_edit_calendar_results{success} = ($add_edit_calendar_results{success} eq "1") ? JSON::PP::true() : JSON::PP::false();
	$add_edit_calendar_results{new_calendar} = calendar2json( $add_edit_calendar_results{'calendar '});
	$add_edit_calendar_results{debug_info} = $debug_info;

	if ( $q->param('new_calendar_controls') eq "1" ) {
		$add_edit_calendar_results{'calendar_controls'} = &generate_calendar_controls();
	}


	$results = encode_json \%add_edit_calendar_results;
	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=iso-8859-1\n

$results
p1
}

sub api_approve_delete_pending_calendars() {
	my $results = "";

	my %add_edit_calendar_results =  %{&approve_delete_pending_calendars()};

	$add_edit_calendar_results{success} = ($add_edit_calendar_results{success} eq "1") ? JSON::PP::true() : JSON::PP::false();
	$add_edit_calendar_results{pending_calendars} = &calendars_as_array( \%new_calendars );
	$add_edit_calendar_results{calendars} = &calendars_as_array( \%calendars );
	$add_edit_calendar_results{debug_nfo} = $debug_info;

	$results = encode_json \%add_edit_calendar_results;
	print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/plain; charset=iso-8859-1\n

$results
p1
}




sub fatal_error() {
  my $diagnostic_results = &diagnostic_info();


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

<b>Plans error:</b><br/>
$error_info
<br/><br/>
<b>Diagnostic information:</b><br/>
$diagnostic_results
p1

  if ($debug_info ne "") {
    $debug_info =~ s/\n/<br>/g;
    $html_output .=<<p1;
<hr>
Debug info:<br/>
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
