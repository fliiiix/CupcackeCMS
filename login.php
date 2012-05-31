<!DOCTYPE html>
<!--
Login-Seite
-->
<?php
require_once('utils.php');
# Überprüfen, ob der Nutzer das richtige Passwort und den richtigen Benutzernamen angegeben hat
# Wenn alle Daten stimmen zum Admin-Interface weiterleiten
if (isset($_POST["username"]) && isset($_POST["password"]) && isset($_POST["login_button"])) {
	db_connect();
	setcookie("CupcackeCMS_Cookie","",-1);
    if (!$errormsg = login_user($_POST["username"],$_POST["password"])){
	  header("Location: admin.php");
	  exit();
	}
}
?>
<html>
<head>
<title>CupcackeCMS - Login</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
</head>
<body>
  <form method="post" action="">
    <strong class="title">Login</strong><br />
    <?php if (isset($errormsg)){
    echo $errormsg . "<br/>"; }?>
    <label for="username">Benutzername</label><br />
    <input type="text" name="username" id="username" /><br />
    <label for="password">Passwort</label><br />
    <input type="password" name="password" id="password" /><br />
    <input type="submit" value="Einloggen" id="login_button" name="login_button"/><br />
    <a href="recover_password.php">Passwort vergessen</a>
  </form>
</body>
</html>