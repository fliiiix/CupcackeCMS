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

use Data::Dumper;

# test date format parsing

$date_format = "mm/dd/yy";

$date = "8/10/2009";
my ($mon, $mday, $year) = &format2mdy($date, $date_format);
assertEqual( $mon, 8);
assertEqual( $mday, 10);
assertEqual( $year, 2009);

$date = "8/10/09";
my ($mon, $mday, $year) = &format2mdy($date, $date_format);
assertEqual( $mon, 8);
assertEqual( $mday, 10);
assertEqual( $year, 2009);


$date_format = "mm/dd/yyyy";

$date = "8/10/2009";
my ($mon, $mday, $year) = &format2mdy($date, $date_format);
assertEqual( $mon, 8);
assertEqual( $mday, 10);
assertEqual( $year, 2009);

$date = "8/10/09";
my ($mon, $mday, $year) = &format2mdy($date, $date_format);
assertEqual( $mon, 8);
assertEqual( $mday, 10);
assertEqual( $year, 2009);

$date = "13/45/2009";
my ($mon, $mday, $year) = &format2mdy($date, $date_format);
assertEqual( $mon, -1);
assertEqual( $mday, -1);
assertEqual( $year, -1);







sub assertEqual( ) {
	my ( $v1, $v2 ) = @_;
	if ( $v1 ne $v2 )  {
		print "FAIL: $v1 not equal to $v2 \n";
	}
}



