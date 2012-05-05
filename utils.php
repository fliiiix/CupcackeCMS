<?php
# Sammlung von nützlichen Funktionen für CupcackeCMS

function db_connect (){
	mysql_connect("localhost", "db_user", "passwort") or die(mysql_error());
    mysql_select_db("datenbankname") or die(mysql_error());
}

function login_user ($username,$password){
$ergebnis = mysql_query("SELECT id FROM users WHERE name=\"" . mysql_real_escape_string($username) . "\" AND pw_hash=\"" . hash("whirlpool",$password,false) . "\"");
	if (!$ergebnis)
      return "Datenbank-Fehler!";
	else {
	  if ($row = mysql_fetch_array($ergebnis)) {
	    $user_id = $row["id"];
		mysql_query("DELETE FROM cookie_mapping WHERE user_id=" . $user_id);
		while (true){
		  $cookie_content = rand(0,getrandmax());
		  $ergebnis = mysql_query("SELECT * FROM cookie_mapping WHERE cookie_content=" . $cookie_content);
		  if (mysql_num_rows($ergebnis) == 0) {
		    mysql_query("INSERT INTO cookie_mapping (user_id,random) VALUES (" . $user_id . "," . $cookie_random . ")");
		    setcookie("CupcackeCMS_Cookie",$cookie_random,time()+3600);
		    return;
		  }
		}
	  } else
		  return "Falscher Benutzername oder falsches Passwort!";
	}
		
}
?>