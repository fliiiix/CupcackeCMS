<?php
error_reporting(E_ALL | E_STRICT);
$current_site = "Account-Einstellungen";
include 'templates/header.tpl'; 
require_once('utils.php');
db_connect();

# Nicht eigeloggte User rauswerfen, sonst valide User-ID speichern
$valid_user_id = verify_user();
if ($valid_user_id == false){
  header("Location: index.php");
  exit();
}

# Nutzernamen des Nutzers feststellen
$username = current_username($valid_user_id);

# Logout
if (isset($_GET["logout"])){
  logout($valid_user_id);
  header("Location: index.php");
  exit();
}

# Wenn der Passwort-Ändern-Button geklickt wird überprüfen, ob die beiden Passwörter übereinstimmen, wenn ja das Passwort in der Datenbank ändern
if (isset($_POST["password"]) && isset($_POST["password_verify"]) && isset($_POST["change_password"])) {
	if(8 > strlen($_POST["password"])){
	  $errormsg = "Bitte gebe ein Passwort, das länger als 7 Zeichen ist ein";
	}
	if($_POST["password"] != $_POST["password_verify"]){
	  $errormsg = "Bitte gebe zwei übereinstimmende Passwörter ein";
	}
	if (!isset($errormsg)) {
		mysql_query("UPDATE user SET pw_hash=\"" . hash("whirlpool", mysql_real_escape_string($_POST["password"])) . "\" WHERE id=" . $valid_user_id);
		$success_msg = "Dein Passwort wurde erfolgreich geändert";
	}
}
?>
<h2>Account-Einstellungen</h2>
<?php if (isset($errormsg)){ 
 	echo "<b style=\"color:red\">" . $errormsg . "</b>";?>
<br>
<?php } ?>
<b>Passwort ändern</b>
<form method="post">
	<table>
		<tr>
			<td>Neues Passwort:</td>
			<td><input name="password" type="password"></td>
		</tr>
		<tr>
			<td>Neues Passwort bestätigen:</td>
			<td><input name="password_verify" type="password"></td>
		</tr>
	</table>
  <input class="btn btn-primary" type="submit" value="Passwort ändern" name="change_password">
</form>
<?php if (isset($success_msg)){ 
 	echo "<b style=\"color:green\">" . $success_msg . "</b>";?>
<?php }
include 'templates/footer.tpl'; ?>