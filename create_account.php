<!DOCTYPE html>
<?php
require_once('utils.php');
db_connect();

// Kontrolle, ob der Key-Parameter gesetzt ist
if (!isset($_GET["key"])){
	$invalid_key = "1";
}

// Kontrolle, ob der Key aus der URL in der Datenbank vorhanden ist
if (isset($_GET["key"])){
	$key = mysql_real_escape_string($_GET["key"]);
	$query = mysql_query("SELECT * FROM email_verify WHERE random=\"" . $key . "\"");
	if (!$row = mysql_fetch_array($ergebnis)){
	  $invalid_key = "1";
	}
}

if (isset($_POST["vorname"]) && isset($_POST["nachname"]) && isset($_POST["email"]) && isset($_POST["password"]) && isset($_POST["password_verify"]) && isset($_POST["account_erstellen"])) {
	// Accunt will erstellt werden…
	$password = $_POST["password"];
	$password_verify = $_POST["password_verify"];	
	$email = $_POST["email"];
	$nachname = $_POST["nachname"];
	$vorname = $_POST["vorname"];
	if (3 > strlen($vorname)){
	  $errormsg = "Bitte gebe einen Vornamen, der länger als 3 Zeichen ist ein";
	  $vorname = "";
	}
	elseif(3 > strlen($nachname)){
	  $errormsg = "Bitte gebe einen Nachnamen, der länger als 3 Zeichen ist ein";
	  $nachname = "";
	}
	elseif(8 > strlen($password)){
	  $errormsg = "Bitte gebe ein Passwort, das länger als 7 Zeichen ist ein";
	  $password = "";
	  $password_verify = "";
	}
	elseif(8 > strlen($email)){
	  $errormsg = "Bitte gebe eine E-Mail-Adresse, die länger als 7 Zeichen ist";
	  $email = "";
	}
	elseif($password != $password_verify){
	  $errormsg = "Bitte gebe zwei übereinstimmende Passwörter ein";
	  $password = "";
	  $password_verify = "";
	}
	elseif($nachname != mysql_real_escape_string($nachname)){
	  $errormsg = "Bitte gebe einen Nachnamen, in dem keine invaliden Zeichen vorkommen ein";
	  $nachname = "";
	}
	elseif($vorname != mysql_real_escape_string($vorname)){
	  $errormsg = "Bitte gebe einen Vornamen, in dem keine invaliden Zeichen vorkommen ein";
	  $vorname = "";
	}
	elseif(!filter_var($email, FILTER_VALIDATE_EMAIL)){
	  $errormsg = "Bitte gebe eine valide E-Mail-Adresse ein";
	  $email = "";
	}
	else {
	    $ergebnis = mysql_query("SELECT * FROM user WHERE email=\"" . mysql_real_escape_string($email) . "\"");
	    if (!$ergebnis)
	      $errormsg = "Query-Fail!";
	    else {
          if (mysql_num_rows($ergebnis) > 0)
	        $errormsg = "Diese E-Mail-Adresse existiert leider schon";
		  else {
		    $ergebnis = mysql_query("INSERT INTO user (vorname,nachname,email,pw_hash) VALUES(\"" . mysql_real_escape_string($vorname) . "\",\"" . mysql_real_escape_string($nachname) . "\",\"" . mysql_real_escape_string($email) . "\",\"" . hash("whirlpool", $password, false) . "\")");
		    if (!$ergebnis)
		      $errormsg = "User konnte nicht gespeichert werden!"; 
		    else {
			  echo "Der User wurde erfolgreich erstellt. <a href=\"index.php\">Zurück zur Startseite</a>";
		    }
	      }
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
      <td>&nbsp;<input name="vorname" type="text" maxlength="30" <?php if (isset($vorname)) echo "value =\"" . $vorname . "\""; ?> ></td>
    </tr>
    <tr>
      <td>&nbsp;Nachname:</td>
      <td>&nbsp;<input name="nachname" type="text" maxlength="30" <?php if (isset($nachname)) echo "value =\"" . $nachname . "\""; ?> ></td>
    </tr>
    <tr>
      <td>&nbsp;E-Mail:</td>
      <td>&nbsp;<input name="email" type="text" maxlength="256" <?php if (isset($email)) echo "value=\"" . $email . "\""; ?> ></td>
    </tr>
    <tr>
      <td>&nbsp;Passwort:</td>
      <td>&nbsp;<input name="password" type="password" <?php if (isset($password)) echo "value =\"" . $password . "\""; ?> ></td>
    </tr>
    <tr>
      <td>&nbsp;Passwort bestätigen:</td>
      <td>&nbsp;<input name="password_verify" type="password" <?php if (isset($password)) echo "value =\"" . $password_verify . "\""; ?> ></td>
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