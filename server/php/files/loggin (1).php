<?php
session_start();
?>
<html>
<head>
<link href="main.css" rel="stylesheet" type="text/css">
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Startseite</title>
</head>
<div id="headerDiv">
<?php
	//error loggin
	error_reporting(E_ALL|E_STRICT);
	ini_set('display_errors', 1);
	
	
	include 'Konfiguration.php';
	
	mysql_select_db('UserDB'); //Auswahl der DB
	
	$z = mysql_query("SELECT * FROM user WHERE  Username = '" . mysql_real_escape_string($_POST['userName']) . "' and Passwort = '" . mysql_real_escape_string($_POST['passwort']) ."'") or die(mysql_error());;
	mysql_close(); //Verbindung zum Server schließen
	
	if(mysql_num_rows($z) == 1)
	{
		$_SESSION['eingelogt'] = TRUE;
		echo "du bist eingelogt";
	}
	else 
	{
		$_SESSION['eingelogt'] = FALSE;
		echo "falscher Username oder Passwort";
	}
?>
</div>
</html>