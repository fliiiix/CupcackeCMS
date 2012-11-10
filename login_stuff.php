<?php
require_once('utils.php');
// nicht berechtigte Nutzer rauswerfen
if (!isset($_COOKIE["CupcackeCMS_Cookie"])){
	header("Location: index.php");
	exit();
} else {
  setcookie("CupcackeCMS_Cookie",$_COOKIE["CupcakeCMS_Cookie"],time()+3600);
}
db_connect();
// Nutzer überprüfen
$ergebnis = mysql_query("SELECT user_id from cookie_mapping WHERE random=" . intval($_COOKIE["CupcakeCMS_Cookie"]));
if ($row = mysql_fetch_array($ergebnis))
$userid = $row["id_user"];
else {
	header("Location: index.php");
	exit();
}
// Logout
if (isset($_GET["logout"])){
	mysql_query("DELETE FROM cookie_mapping WHERE user_id=" . $userid);
	setcookie("CupcackeCMS_Cookie","",-1);
	header("Location: index.php");
	exit();
}
?>