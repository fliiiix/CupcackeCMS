<?php
error_reporting(E_ALL | E_STRICT);
$current_site = "Account-Einstellungen";
include 'templates/header.tpl'; 
require_once('utils.php');
$db = new_db_o();

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
$sql = 'SELECT `vorname`,`nachname`,`email` FROM `user` WHERE `id`=?';
$eintrag = $db->prepare($sql);
$eintrag->bind_param('i', $valid_user_id);
$eintrag->execute();
$eintrag->bind_result($vorname, $nachname, $current_email);
$eintrag->fetch();
$eintrag->close();

# Wenn der Passwort-Ändern-Button geklickt wird überprüfen, ob die beiden Passwörter übereinstimmen, wenn ja das Passwort in der Datenbank ändern und eine Erfolgs-Meldung ausgeben
if (isset($_POST["password"]) && isset($_POST["password_verify"]) && isset($_POST["change_password"])) {
	if(8 > strlen($_POST["password"])){
	  $errormsg = "Bitte gebe ein Passwort, welches mindestens 8 zeichen enthält";
	} else {
		if($_POST["password"] != $_POST["password_verify"]){
			$errormsg = "Bitte gebe zwei übereinstimmende Passwörter ein";
		} 
                else {
                        $sql = 'UPDATE `user` SET `pw_hash`="?" WHERE `id`="?"';
                        $eintrag = $db->prepare($sql);
                        $eintrag->bind_param('si', hash("whirlpool", mysql_real_escape_string($_POST["password"])), $valid_user_id);
                        $eintrag->execute();
                        $eintrag->close();
			$success_msg = "Dein Passwort wurde erfolgreich geändert";
		}
	}
}

# Email-Bestätigungs-Mail verschicken, wenn eine richtige E-Mail-Adresse eingegeben wird
if (isset($_POST["email"]) && isset($_POST["email_verify"]) && isset($_POST["change_email"])){
	if ($_POST["email"] != $_POST["email_verify"]){
		$email_errormsg = "Bitte übereinstimmende E-Mail-Adressen eingeben";
	} 
        else {
		if (!filter_var($_POST["email"], FILTER_VALIDATE_EMAIL)) {
			$email_errormsg = "Bitte eine valide E-Mail-Adresse eingeben";
		} 
                else {
			$new_email = escape($_POST["email"]);
			$sql = 'SELECT `id` FROM `change_email` WHERE `random`="?"';
                        $eintrag = $db->prepare($sql);
                        do{
				$random = hash("haval128,3",rand(0,getrandmax()),false);
                                $eintrag->bind_param('s', $random);
                                $eintrag->execute();
                                $eintrag->store_result();
				if ($eintrag->num_rows == 0){
					$eintrag->close();
                                        
                                        $sql = 'INSERT INTO change_email (user_id, random, new_email) VALUES(?, ?, ?)';
                                        $eintrag = $db->prepare($sql);
                                        $eintrag->bind_param('iss', $valid_user_id, $random, $new_email);
                                        $eintrag->execute();
                                        $eintrag->close();
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
			"http://" . $_SERVER['SERVER_NAME'] . "/verify_email.php?change_key=" . $random . "\r\n" . 
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
<div class="span5" style="margin-left: 0px; padding-left: 0px;">
<h3>Passwort ändern</h3>
Wenn du dein Passwort ändern möchtest.<br /><br />
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
<div class="span5">
	<h3>E-Mail-Adresse ändern</h3>
	Deine momentane E-Mail-Adresse ist <?php echo $current_email; ?><br /><br />
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