<!DOCTYPE html>
<?php
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
	$query = mysql_query("SELECT * FROM email_verify WHERE random=\"" . $key . "\"");
	if (mysql_num_rows($query) == 0){
	  $invalid_key = "1";
	} else{
		$row = mysql_fetch_array($query);
		$valid_user_id = $row["user_id"];
		$query = mysql_query("SELECT vorname,nachname,email,rolle FROM user WHERE id=" . $valid_user_id);
		$row = mysql_fetch_array($query);
		$preset_vorname = $row["vorname"];
		$preset_nachname = $row["nachname"];
		$email = $row["email"];
		$rolle = $row["rolle"];
	}
}

if (isset($_POST["vorname"]) && isset($_POST["nachname"]) && isset($_POST["email"]) && isset($_POST["password"]) && isset($_POST["password_verify"]) && isset($_POST["account_erstellen"])) {
	// Accunt will erstellt werden…
	if (3 > strlen($_POST["vorname"])){
	  $errormsg = "Bitte gebe einen Vornamen, der länger als 3 Zeichen ist ein";
	}
	elseif(3 > strlen($_POST["nachname"])){
	  $errormsg = "Bitte gebe einen Nachnamen, der länger als 3 Zeichen ist ein";
	}
	elseif(8 > strlen($_POST["password"])){
	  $errormsg = "Bitte gebe ein Passwort, das länger als 7 Zeichen ist ein";
	}
	elseif($_POST["password"] != $_POST["password_verify"]){
	  $errormsg = "Bitte gebe zwei übereinstimmende Passwörter ein";
	}
	elseif($_POST["nachname"] != mysql_real_escape_string($_POST["nachname"])){
	  $errormsg = "Bitte gebe einen Nachnamen, in dem keine invaliden Zeichen vorkommen ein";
	}
	elseif($_POST["vorname"] != mysql_real_escape_string($_POST["vorname"])){
	  $errormsg = "Bitte gebe einen Vornamen, in dem keine invaliden Zeichen vorkommen ein";
	}
	else {
		$query = mysql_query("INSERT INTO user (vorname,nachname,pw_hash) VALUES(\"" . mysql_real_escape_string($_POST["vorname"]) . "\",\"" . mysql_real_escape_string($_POST["nachname"]) . "\",\"" . hash("whirlpool", mysql_real_escape_string($_POST["password"]), false) . "\") WHERE id=" . $valid_user_id);
		    if (!$query){
		    	$errormsg = "User konnte nicht gespeichert werden!";
		    }
		    else {
			  echo "Der User wurde erfolgreich erstellt. <a href=\"index.php\">Zurück zur Startseite</a>";
		    }
	}
}
?>
<html>
<head>
<title>CupcakeCMS - Neuen Account erstellen</title>
<link rel="stylesheet" href="css/style.css" type="text/css" />
<script type="text/javascript" src="js/jquery.js"></script>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
</head>
<body>
 <?php if (isset($errormsg)){ 
 	echo $errormsg;?>
<br>
<?php }
if ($invalid_key == 1){
	echo "<b style=\"color:red\">Ihr Account-Bestätigungs-Link ist fehlerhaft oder abgelaufen</b>";
} else { ?>
Account erstellen
<form method="post">
<table border="0">
    <tr>
      <td>&nbsp;Vorname:</td>
      <td>&nbsp;<input name="vorname" type="text" maxlength="30" value="<?php echo $preset_vorname; ?>" ></td>
    </tr>
    <tr>
      <td>&nbsp;Nachname:</td>
      <td>&nbsp;<input name="nachname" type="text" maxlength="30" value="<?php echo $preset_nachname; ?>" ></td>
    </tr>
    <tr>
      <td>&nbsp;E-Mail:</td>
      <td><?php echo $email; ?></td>
    </tr>
    <tr>
      <td>&nbsp;Rolle:</td>
      <td><?php if ($rolle == 1){
      	echo "Nutzer";
      } else {
      	echo "Administrator";
      }
      ?></td>
    </tr>
    <tr>
      <td>&nbsp;Passwort:</td>
      <td>&nbsp;<input name="password" type="password"></td>
    </tr>
    <tr>
      <td>&nbsp;Passwort bestätigen:</td>
      <td>&nbsp;<input name="password_verify" type="password"></td>
    </tr>
    <tr>
    <td colspan="2" align="right"><input name="account_erstellen" type="submit" value="Account erstellen"></td>
    </tr>
  </table>
</form>
<?php
} ?>
	</body>
</html>