<?php
error_reporting(E_ALL | E_STRICT);
$current_site = "Neue E-Mail-Adresse bestätigen";
include 'templates/header.tpl'; 
require_once('utils.php');
db_connect();

$invalid_key = 0;

// Kontrolle, ob der Key-Parameter gesetzt ist
if (!isset($_GET["key"])){
	$invalid_key = "1";
}

// Kontrolle, ob der Key aus der URL in der Datenbank vorhanden ist, wenn ja Vornamen, Nachnamen und E-Mail-Adresse abfragen und in Variablen schreiben
if (isset($_GET["key"])){
	$key = mysql_real_escape_string($_GET["key"]);
	$query = mysql_query("SELECT * FROM change_email WHERE random=\"" . $key . "\"");
	if (mysql_num_rows($query) == 0){
	  $invalid_key = "1";
	} else {
		$row = mysql_fetch_array($query);
		$valid_user_id = $row["user_id"];
		$new_email = $row["new_email"];
		mysql_query("UPDATE user SET email=\"" . $new_email . "\" WHERE id=" . $valid_user_id);
		mysql_query("DELETE FROM change_email WHERE random=\"" . $key . "\"");
		$success_msg = 1;
	}
}
if ($invalid_key == 1){
	echo "<b style=\"color:red\">Dein E-Mail-Bestätigungs-Link ist fehlerhaft oder abgelaufen</b>";
}
if (isset($success_msg)){
	echo "<b style=\"color:green\">Deine neue E-Mail-Adresse wurde erfolgreich bestätigt</b>";
}
include 'templates/footer.tpl';
?>