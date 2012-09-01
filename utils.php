<?php
//Sammlung von nützlichen Funktionen für CupcackeCMS

# Mit der Datenbank verbinden
function db_connect (){
	mysql_connect("localhost", "root", "") or die(mysql_error());
	mysql_select_db("cupcackecms") or die(mysql_error());
}

# Name der Webseite für das <title>-Tag
global $site_name;
$site_name = "CupcackeCMS";

# Login-Funktion für die Startseite
function login_user ($email,$password){
	$ergebnis = mysql_query("SELECT id FROM user WHERE email=\"" . mysql_real_escape_string($email) . "\" AND pw_hash=\"" . hash("whirlpool",$password,false) . "\" AND aktiv=" . 2);
	if ($ergebnis){
		if ($row = mysql_fetch_array($ergebnis)) {
			$user_id = $row["id"];
			mysql_query("DELETE FROM cookie_mapping WHERE user_id=" . $user_id);
			$cookie_content = rand(0,getrandmax());
			$ergebnis = mysql_query("SELECT * FROM cookie_mapping WHERE cookie_content=" . $cookie_content);
			if ((!$ergebnis) && (mysql_num_rows($ergebnis) == 0) || true) {
				mysql_query("INSERT INTO cookie_mapping (user_id,cookie_content) VALUES (" . $user_id . "," . $cookie_content . ")");
				setcookie("CupcackeCMS_Cookie",$cookie_content,time()+3600);
				return true;
			}
			else { return "Falscher Benutzername oder falsches Passwort oder deaktivierter Account"; }
		} 
		else { return "Falscher Benutzername oder falsches Passwort oder deaktivierter Account"; }
	} 
	else { return "Datenbank-Fehler!"; } 
}

# Logout-Funktion für alle Backend-Seiten
function logout ($valid_user_id){
	mysql_query("DELETE FROM cookie_mapping WHERE user_id=" . $valid_user_id);
	setcookie("CupcackeCMS_Cookie","",-1);
}

# Kontrolle, ob der User, der sich momentan auf der Seite befindet eingeloggt ist
function verify_user(){
	if (isset($_COOKIE["CupcackeCMS_Cookie"])){
		$query = mysql_query("SELECT user_id FROM cookie_mapping WHERE cookie_content=" . intval($_COOKIE["CupcackeCMS_Cookie"]));
		if ($row = mysql_fetch_array($query)){
			$valid_user_id = $row["user_id"];
			return $valid_user_id;
		} else {
			return false;
		}
	} else {
		return false;
	}
}

# Namen des momentan eingeloggten Users zurückgeben
function current_username($valid_user_id){
	$query = mysql_query("SELECT vorname,nachname FROM user WHERE id=" . $valid_user_id);
	$row = mysql_fetch_array($query);
	$username = $row["vorname"] . " " . $row["nachname"];
	return $username;
}
?>
