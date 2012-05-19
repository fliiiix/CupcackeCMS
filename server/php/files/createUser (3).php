<?php
	//error loggin
	error_reporting(E_ALL|E_STRICT);	
	ini_set('display_errors', 1);
	
	
	include 'Konfiguration.php';
	mysql_select_db('UserDB'); //Auswahl der DB
	
	//INSERT INTO `UserDB`.`user` (`Id` ,`Username` ,`Passwort`)VALUES (NULL , 'felix ', 'testPw');
	
	
	$z = mysql_query("INSERT INTO UserDB.user (Id, Username, Passwort) VALUES( null, '$_POST[createuserName]', '$_POST[createpasswort]')") or die(mysql_error());;
	mysql_close(); //Verbindung zum Server schließen
?>