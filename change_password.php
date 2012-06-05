<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<?php
require_once("utils.php");
if (isset($_GET["key"])){
  db_connect();
  $ergebnis = mysql_query("SELECT user_id from pw_forgot WHERE link_component=\"" . mysql_real_escape_string($_GET["key"]) . "\"");
  if (!$row = mysql_fetch_array($ergebnis))
	  $invalid_key = "1";
}
if (isset($_POST["password"]) && isset($_POST["password_verify"]) && isset($_POST["change_password"])){
  if (($_POST["password"] == "") || ($_POST["password_verify"] == ""))
	  $errormsg = "Bitte kein Passwort-Feld leer lassen";
  else {
	  if ($_POST["password"] != $_POST["password_verify"])
	    $errormsg = "Die beiden Passwörter stimmen nicht überein";
	  else {
		if (strlen($_POST["password"]) < 8)
		  $errormsg = "Bitte gebe ein Passwort, das länger als 7 Zeichen ist ein";
		else {
			if (isset($_GET["key"])){
				db_connect();
				$ergebnis = mysql_query("SELECT user_id from pw_forgot WHERE link_component=\"" . mysql_real_escape_string($_GET["key"]) . "\"");
				if ($row = mysql_fetch_array($ergebnis)){
					$valid_user_id = $row["user_id"];
					mysql_query("UPDATE user SET pw_hash=\"" . hash("whirlpool",$_POST["password"],false) . "\" WHERE id=" . $valid_user_id);
					$go_on_name = "Zur Login-Seite";
					$go_on_link = "index.php";
				} else
				  $errormsg = "Falscher Passwort-Zurücksetzen-Link";
			} else {
			  if (!isset($_COOKIE["CupcackeCMS_Cookie"])){
				header("Location: index.php");
				exit();
			  }
			  db_connect();
			  $ergebnis = mysql_query("SELECT user_id from cookie_mapping WHERE cookie_content=" . intval($_COOKIE["CupcackeCMS_Cookie"]));
			  if (!$row = mysql_fetch_array($ergebnis)){
				  header("Location: index.php");
				  exit();
			  } else {
				  $valid_user_id = $row["user_id"];
				  mysql_query("UPDATE user SET pw_hash=\"" . hash("whirlpool",$_POST["password"],false) . "\" WHERE id=" . $valid_user_id);
				  $go_on_name = "Zurück zur Startseite";
				  $go_on_link = "index.php";
			  }
			}
			if (isset($valid_user_id))
			  mysql_query("DELETE FROM pw_forgot WHERE user_id=" . $valid_user_id);
	  }
    }
  }
}
?>
<html>
<head>
<title>Fliegenberg - Passwort ändern</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
</head>
<body>
		<meta http-equiv="content-type" content="text/html; charset=UTF-8" />
	</head>
	<body>
<?php 
if (isset($invalid_key)){
?>
Dieser Link ist entweder falsch oder wurde schon benutzt, um ein Passwort zurückzusetzen.<br>
<a href="index.php">Zur Login-Seite</a>
<?php } else {
if (isset($go_on_name)){ ?>
Das Passwort wurde geändert.<br>
<a href="<?php echo $go_on_link; ?>"><?php echo $go_on_name; ?></a>
<?php } else {
if (isset($errormsg)){ ?>
<table border="1" bordercolor="#FF0000">
  <tr>
    <td><?php echo $errormsg; ?></td>
  </tr>
</table>
<?php } ?>
Hier kannst du ein neues Passwort für deinen Account festlegen:<br>
<br>
<form name="form1" method="post" action="<?php if (isset ($_GET["key"])) echo "?key=" . $_GET["key"]; ?>">
  <table border="0">
    <tr>
      <td>&nbsp;Neues Passwort:</td>
      <td>&nbsp;
        <input name="password" type="password"></td>
    </tr>
    <tr>
      <td>&nbsp;Passwort bestätigen:</td>
      <td>&nbsp;
        <input name="password_verify" type="password"></td>
    </tr>
    <tr>
      <td colspan="2" align="right"><input name="change_password" type="submit" value="Passwort ändern"></td>
    </tr>
  </table>
</form>
<?php }
}?>
</body>
</html>
