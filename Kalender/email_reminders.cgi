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

if ($fatal_error == 1) {
  &fatal_error();  # print error and bail out
}

my $new_lines = "";
my @events_in_file = ();

&load_calendars();
local $current_cal_id = 0;

  
# load upcoming event data
open (FH, "$options{email_reminders_datafile}") || ($debug_info .="\nUnable to open file $options{email_reminders_datafile}");
flock FH,2;
my @lines=<FH>;
close datafile;

foreach $line (@lines) {  # need pre-load to ensure we only need one call to normalize_timezone
  if ($line !~ /\w/) {next};  # skip blank spaces 

  my $temp_line = $line;
  $temp_line =~ s/<\/?email_reminder>//g;
  my ($evt_id) = &xml_quick_extract($temp_line, "evt_id");
  my ($before) = &xml_quick_extract($temp_line, "before");
  my ($script_url) = &xml_quick_extract($temp_line, "script_url");
  $script_url = &decode($script_url);
  my ($extra_text) = &xml_quick_extract($temp_line, "extra_text");
  $extra_text = &decode($extra_text);
  my ($to_address) = &xml_quick_extract($temp_line, "email_address");
  $to_address = &decode($to_address);
  
  &load_event($evt_id);
  push @events_in_file, {evt_id => $evt_id,
                         before => $before,
                         script_url => $script_url,
                         extra_text => $extra_text,
                         to_address => $to_address,
                         line => $line};
  
  #push @events_to_remind, $evt_id;
}
&normalize_timezone();

my $results = "";

foreach $event_reminder_ref (@events_in_file) {
  my %event_reminder_stuff = %{$event_reminder_ref};
  my $evt_id = $event_reminder_stuff{evt_id};

  %current_event = %{$events{$evt_id}};
  my $current_cal_id = $current_event{cal_ids}[0];
  
  %current_calendar = %{$calendars{$current_cal_id}};
  
  $rightnow = time() + 3600 * $current_calendar{gmtime_diff};
  
  my $to_address = $event_reminder_stuff{to_address};
  my $extra_text = $event_reminder_stuff{extra_text};
  my $script_url = $event_reminder_stuff{script_url};
  my $before = $event_reminder_stuff{before};
  
  my $event_timestamp = $current_event{start};
  $date_string = &nice_date_range_format($current_event{start}, $current_event{end}, " - ");

  my $event_time = "";
  if ($current_event{all_day_event} ne "1") {
    $event_time = &nice_time_range_format($current_event{start}, $current_event{end});
  }

  my $reminder_text = $lang{email_reminder_text};

  $reminder_text =~ s/###time###/$event_time/g;
  $reminder_text =~ s/###title###/$current_event{title}/g;
  $reminder_text =~ s/###date###/$date_string/g;
  $reminder_text =~ s/###details###/$current_event{details}/g;
  $reminder_text =~ s/###extra text###/$extra_text/g;
  $reminder_text =~ s/###link###/$script_url?view_event=1&evt_id=$current_event{id}/g;
  
  my $check_timestamp = $event_timestamp;
  $check_timestamp -= $calendars{$current_event{cal_ids}[0]}{gmtime_diff};
  
  if (($check_timestamp - $rightnow) < $before) {
    if ($current_event{title} ne "") {  # blank title == deleted event
      $test_reminder_results = &send_email_reminder(\%current_event, $to_address, $reminder_text);
      if ($test_reminder_results eq "1") {
        $results .= "Reminder for event $evt_id ($current_event{title}) sent successfully to <i>$to_address</i>!\n";
      } else {
        $results .= "Reminder not sent to <i>$to_address</i>:<br/><br/>($test_reminder_results)\n";
      }
    }
  } else {
    $new_lines .= $event_reminder_stuff{line};
  }
}

open (FH, ">$options{email_reminders_datafile}") || ($debug_info .="\nUnable to open file $options{email_reminders_datafile} for writing!");
flock FH,2;
print FH $new_lines;
close datafile;

$results = "No email reminders to send!" if ($results eq "");

$results =~ s/\n/<br\/>\n/g;
$debug_info =~ s/\n/<br\/>\n/g;

print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/html; charset=iso-8859-1\n
<html>
<body>
$results
$debug_info
</html>
</body>
p1

sub fatal_error() {
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
  if ($debug_info ne "") {
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


