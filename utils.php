<?php
//Sammlung von nützlichen Funktionen für CupcackeCMS

# Mit der Datenbank verbinden
function db_connect (){
	mysql_connect("localhost", "root", "") or die(mysql_error());
	mysql_select_db("cupcackecms") or die(mysql_error());
}

# Name der Webseite für das <title>-Tag
$GLOBALS["site_name"] = "CupcackeCMS";

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
			else { return "Falscher Benutzername, falsches Passwort oder deaktivierter Account."; }
		} 
		else { return "Falscher Benutzername, falsches Passwort oder deaktivierter Account."; }
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
    db_connect ();
     if (isset($_COOKIE["CupcackeCMS_Cookie"])){
		$query = mysql_query("SELECT user_id FROM cookie_mapping WHERE cookie_content=" . intval($_COOKIE["CupcackeCMS_Cookie"]));
		if ($row = mysql_fetch_array($query)){
			return $row["user_id"];
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

# Kalender-Funktion
function calendar($month,$year){
	$current_m = $month;
	$current_y = $year;
	# Namen des angezeigten Monats feststellen, ersten Wochentag dieses Monats feststellen, letzten Tag dieses Monats feststellen
	$current_m_name = date("F", mktime(0, 0, 0, $current_m, 1, $current_y));
	$current_m_first_wd = date("w", mktime(0, 0, 0, $current_m, 1, $current_y));
	$current_m_last_d = date("d", mktime(0, 0, 0, $current_m+1, 0, $current_y));
	# Tabellen-Stuff (Wochentages-Leiste)
	$output  = '<table>';
	$output .= '  <tr>';
	$output .= '    <td colspan="7">' . $current_m_name . '</td>';
 	$output .= '  </tr>';
 	$output .= '  <tr>';
	$output .= '    <td>Mo</td>';
  	$output .= '    <td>Di</td>';
  	$output .= '    <td>Mi</td>';
  	$output .= '    <td>Do</td>';
  	$output .= '    <td>Fr</td>';
  	$output .= '    <td>Sa</td>';
  	$output .= '    <td>So</td>';
  	$output .= '  </tr>';
  	$output .= '  <tr>';
  	# Leere Tabellen-Felder ausgeben, wenn der erste Tag des Monats kein Montag ist
  	if ($current_m_first_wd > 1) {
  		$output .= '<td colspan="' . ($current_m_first_wd - 1) . '">&nbsp;</td>';
  	}
  	# Die einzelnen Tabellen-Felder mit den Tages-Daten generieren
  	for ($act_day=1, $act_wd=$current_m_first_wd; $act_day <= $current_m_last_d; $act_day++, $act_wd++) {
  		# Datum ausgeben
  		$output .= '<td>' . $act_day . '</td>';
  		# Zeile nach einem Sonntag beenden
  		if ($act_wd == 7) {
  			$output .= '</tr>';
  			# Wenn der Monat noch nicht zu Ende ist noch eine neue Zeile öffnen
  			if ($act_day < $current_m_last_d) {
  				$output .= '<tr>';
  			}
  			$act_wd = 0;
  		}
  	}
  	# Wenn der letzte Tag des Monats kein Sonntag ist am Ende der Tabellen-Zeile noch leere Zellen einfügen
  	if ($act_wd > 1){
  		$output .= '<td colspan="' . (7 - $act_wd) . '">&nbsp;</td></tr>';
  	}
  	$output .='</table>';
  	return array('html' => $output, 'current_m' => $current_m, 'current_y' => $current_y);
}

function calendar_link($dir, $current_m, $current_y){
	$output = '<a href="?m=';
	if ($dir == 'f') {
		$arrows = '>>>';
		if ($current_m == 12) {
			$next_m = 1;
			$next_y = $current_y++;
		} else {
			$next_m = $current_m++;
			$next_y = $current_y;
		}
	}
	if ($dir == 'b') {
		$arrows = '<<<';
		if ($current_m == 1) {
			$next_m = 12;
			$next_y = $current_y - 1;
		} else {
			$next_m = $current_m - 1;
			$next_y = $current_y;
		}
	}
	$output .= $next_m . '&y=' . $next_y . '">' . $arrows . '</a>';
	return $output;
}
?>
