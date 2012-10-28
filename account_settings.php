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

# Momentane E-Mail-Adresse und Namen des Users aus der Datenbank holen
$query = mysql_query("SELECT vorname,nachname,email FROM user WHERE id=" . $valid_user_id);
$row = mysql_fetch_array($query);
$current_email = $row["email"];
$vorname = $row["vorname"];
$nachname = $row["nachname"];

# Wenn der Passwort-Ändern-Button geklickt wird überprüfen, ob die beiden Passwörter übereinstimmen, wenn ja das Passwort in der Datenbank ändern und eine Erfolgs-Meldung ausgeben
if (isset($_POST["password"]) && isset($_POST["password_verify"]) && isset($_POST["change_password"])) {
	if(8 > strlen($_POST["password"])){
	  $errormsg = "Bitte gebe ein Passwort, das länger als 7 Zeichen ist ein";
	} else {
		if($_POST["password"] != $_POST["password_verify"]){
			$errormsg = "Bitte gebe zwei übereinstimmende Passwörter ein";
		} else {
			mysql_query("UPDATE user SET pw_hash=\"" . hash("whirlpool", mysql_real_escape_string($_POST["password"])) . "\" WHERE id=" . $valid_user_id);
			$success_msg = "Dein Passwort wurde erfolgreich geändert";
		}
	}
}

# Email-Bestätigungs-Mail verschicken, wenn eine richtige E-Mail-Adresse eingegeben wird
if (isset($_POST["email"]) && isset($_POST["email_verify"]) && isset($_POST["change_email"])){
	if ($_POST["email"] != $_POST["email_verify"]){
		$email_errormsg = "Bitte übereinstimmende E-Mail-Adressen eingeben";
	} else {
		if (!filter_var($_POST["email"], FILTER_VALIDATE_EMAIL)) {
			$email_errormsg = "Bitte eine valide E-Mail-Adresse eingeben";
		} else {
			$new_email = mysql_real_escape_string($_POST["email"]);
			do{
				$random = hash("haval128,3",rand(0,getrandmax()),false);
				$ergebnis = mysql_query("SELECT * FROM change_email WHERE random=\"" . $random . "\"");
				if (mysql_num_rows($ergebnis) == 0){
					mysql_query("INSERT INTO change_email (user_id, random, new_email) VALUES(" . $valid_user_id . ",\"" . $random . "\",\"" . $new_email . "\")");
					$repeat = false;
				}
			} while($repeat);
			$headers = "From: noreply@fliegenberg.de" . "\n" .
			"X-Mailer: PHP/" . phpversion() . "\n" .
			"Mime-Version: 1.0" . "\n" . 
			"Content-Type: text/plain; charset=UTF-8" . "\n" .
			"Content-Transfer-Encoding: 8bit" . "\r\n";
			$message = "Hallo " . $vorname . " " . $nachname . ", \r\n" .
			"\r\n" .
			"jemand hat auf Fliegenberg.de die Änderung der zu deinem Account gehörigen E-Mail-Adresse veranlasst." . "\r\n" . 
			"Klicke auf den folgenden Link, um diese neue E-Mail-Adresse zu bestätigen: \r\n".
			"\r\n".
			"http://" . $_SERVER['SERVER_NAME'] . "/verify_email.php?key=" . $random . "\r\n" . 
			"\r\n".
			"Wenn du deine E-Mail-Adresse gar nicht ändern möchtest ignoriere diese Mail einfach. \r\n".
			"Mit freundlichen Grüßen\r\n".
			"\r\n".
			"Dein Fliegenberg-Team";
			mail($new_email, "Änderung deiner E-Mail-Adresse auf " . $_SERVER['SERVER_NAME'], $message, $headers);
			$success_msg = "Die Bestätigungs-Mail für deine neue E-Mail-Adresse wurde erfolgreich versandt";
		}
	}
}

?>
<h2>Account-Einstellungen</h2>
<?php if (isset($errormsg)){ 
 	echo "<b style=\"color:red\">" . $errormsg . "</b>";?>
<?php } ?>
<div>
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
</div>
<div>
	<b>E-Mail-Adresse ändern</b><br />
	Deine momentane E-Mail-Adresse ist <?php echo $current_email; ?><br />
	<?php if (isset($email_errormsg)){ 
 	echo "<b style=\"color:red\">" . $email_errormsg . "</b>";?>
 	<?php } ?>
	<form method="post">
	<table>
		<tr>
			<td>Neue E-Mail-Adresse:</td>
			<td><input name="email" type="text" maxlength="256"></td>
		</tr>
		<tr>
			<td>Neue E-Mail-Adresse bestätigen:</td>
			<td><input name="email_verify" type="text" maxlength="256"></td>
		</tr>
	</table>
  <input class="btn btn-primary" type="submit" value="E-Mail-Adresse ändern" name="change_email">
</form>
</div>
<?php if (isset($success_msg)){ 
 	echo "<b style=\"color:green\">" . $success_msg . "</b>";?>
<?php }
include 'templates/footer.tpl'; ?>