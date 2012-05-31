<?php
# Sammlung von nützlichen Funktionen für CupcackeCMS

function db_connect (){
	mysql_connect("localhost", "root", "") or die(mysql_error());
    mysql_select_db("cupcackecms") or die(mysql_error());
}

function login_user ($username,$password){
$ergebnis = mysql_query("SELECT id FROM user WHERE email=\"" . mysql_real_escape_string($username) . "\" AND pw_hash=\"" . hash("whirlpool",$password,false) . "\" AND aktiv =" . 1);
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
		    mysql_query("INSERT INTO cookie_mapping (user_id,cookie_content) VALUES (" . $user_id . "," . $cookie_content . ")");
		    setcookie("CupcackeCMS_Cookie",$cookie_content,time()+3600);
		    return;
		  }
		}
	  } else
		  return "Falscher Benutzername oder falsches Passwort!";
	}	
}
?>
