#!/usr/bin/perl



$perl_version = (sprintf ("%vd",$^V));

$module_found=0;
foreach $temp_path (@INC) {
  if (-e "$temp_path/Error.pm") {
	$module_found = 1;
  }
}

if ($module_found == 0) {
	$required_modules .= "Required module <b>Error.pm</b> not found!   <br/>";
} 

print <<p1;
Cache-control: no-cache,no-store,private
Content-Type: text/html; charset=$lang{charset}\n
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
<title>Plans system check</title>
</head>
<body style="font-family: arial;">


<h2>Plans System check</h2>
<h3>Perl version</h3>
<p>
Plans requires version 5.8 or higher.
<br/>Your version of perl is $perl_version.

<h3>Required Perl Modules</h3>
</p><p>
<div style="color=:#0000ff;">
$required_modules
</div>
</body>
</html>



p1

