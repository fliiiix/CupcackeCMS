<?php
define ( 'MYSQL_HOST',      'localhost' );
 
define ( 'MYSQL_BENUTZER',  'root' );
define ( 'MYSQL_KENNWORT',  'warhammer40k' );

define ( 'MYSQL_DATENBANK', 'UserDB' );

mysql_connect(MYSQL_HOST,MYSQL_BENUTZER,MYSQL_KENNWORT) or die ("Keine Verbindung moeglich");
mysql_select_db(MYSQL_DATENBANK) or die ("Datenbank ist nicht erreichbar.");

/*$dbort = 'localhost';
	$dbuser = 'root';
	$dbpw = 'warhammer40k';
	
	mysql_connect($dbort,$dbuser,$dbpw); //Verbindungsaufbau zum Server auf dem die DB läuft*/
?>