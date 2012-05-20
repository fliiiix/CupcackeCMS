<php
require_once('utils.php');
// nicht berechtigte Nutzer rauswerfen
if (!isset($_COOKIE["CupcakeCMS_Cookie"])){
	header("Location: index.php");
	exit();
} else {
  setcookie("CupcakeCMS_Cookie",$_COOKIE["CupcakeCMS_Cookie"],time()+3600);
}
db_connect();
// Nutzer überprüfen
$ergebnis = mysql_query("SELECT id_user from cookie_mapping WHERE random=" . intval($_COOKIE["CupcakeCMS_Cookie"]));
if ($row = mysql_fetch_array($ergebnis))
$userid = $row["id_user"];
else {
	header("Location: index.php");
	exit();
}
// Logout
if (isset($_GET["logout"])){
	mysql_query("DELETE FROM cookie_mapping WHERE id_user=" . $userid);
	setcookie("Fridgeboard_Cookie","",-1);
	header("Location: index.php");
	exit();
?>