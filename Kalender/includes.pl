
my $module_found = 0;
foreach $temp_path (@INC) {
	$module_found = 1 if (-e "$temp_path/plans_config.pl");
}
if ($module_found == 0) {
  $fatal_error = 1;
  $error_info .= "Unable to locate <b>plans_config.pl</b>!  It should be in the same directory as plans.cgi!\n";
} else { require "plans_config.pl"; }



$module_found = 0;
foreach $temp_path (@INC) {
	$module_found = 1 if (-e "$temp_path/CGI");
}

if ($module_found == 0) {
  $fatal_error = 1;
  $error_info .= "unable to locate required module <b>CGI</b>!\n";
} else { use CGI; }

$module_found = 0;
foreach $temp_path (@INC) {
	$module_found = 1 if (-e "$temp_path/CGI/Session");
}

if ($options{sessions} eq "1") {
	if ($module_found == 0) {
		$fatal_error = 1;
		$error_info .= "unable to locate required module <b>CGI::Session</b>!\n";
	} else {
		require CGI::Session;
	}
}


$module_found = 0;
foreach $temp_path (@INC) {
	$module_found = 1 if (-e "$temp_path/Error.pm");
}

if ($module_found == 0) {
  $fatal_error = 1;
  $error_info .= "unable to locate required module <b>Error.pm</b>!\n";
} else {
	use Error qw(:try);
}

use Time::Normalize;



$module_found = 0;
foreach $temp_path (@INC) {
	$module_found = 1 if (-e "$temp_path/CGI/Carp.pm");
}

if ($module_found == 0) {
  $fatal_error = 1;
  $error_info .= "unable to locate required module <b>CGI::Carp</b>!\n";
} else { use CGI::Carp qw/fatalsToBrowser/; }

$module_found = 0;
foreach $temp_path (@INC) {
	$module_found = 1 if (-e "$temp_path/Time");
}

if ($module_found == 0) {
  $fatal_error = 1;
  $error_info .= "unable to locate required module <b>Time.pm</b>!\n";
} else { use Time::Local; }

$module_found = 0;
foreach $temp_path (@INC) {
	$module_found = 1 if (-e "$temp_path/IO.pm");
}

if ($module_found == 0) {
  $fatal_error = 1;
  $error_info .= "unable to locate required module <b>IO.pm</b>!\n";
} else { use IO::Socket; }

if ($fatal_error == 1)  { # print error and bail out
  &fatal_error();
}

$module_found = 0;
foreach $temp_path (@INC) {
	$module_found = 1 if (-r "$temp_path/plans_lib.pl");
}

if ($module_found == 0) {
	$fatal_error = 1;
	$error_info .= "Unable to locate <b>plans_lib.pl</b>!  It should be in the same directory as plans.cgi!\n";
} else {require "plans_lib.pl";}


# multi-language stuff
if (defined $options{language_files}) {
	my @language_files = split(',', $options{language_files});

	# pull in language files
	foreach $language_file (@language_files) {

		$module_found = 0;
		foreach $temp_path (@INC) {
			$module_found = 1 if (-r "$temp_path/$language_file");
		}

		if ($module_found == 0) {
			$fatal_error = 1;
			$error_info .= "Unable to locate language file <b>$language_file</b>!  It should be in the same directory as plans.cgi!\n";
		} else {require $language_file;}

	}
}

return 1;
