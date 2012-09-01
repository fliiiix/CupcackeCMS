<?php
$current_site = "Passwort zurücksetzen";
include 'templates/header.tpl';
require_once('utils.php');

if (isset($_POST["email"]) && isset($_POST["passwort_reset"])){
  if ($_POST["email"] == ""){
	  $errormsg = "Bitte eine E-Mail-Adresse eingeben";
	}
  else{
	db_connect();
	$valid_email = mysql_real_escape_string($_POST["email"]);
	$ergebnis = mysql_query("SELECT id,vorname,nachname FROM user WHERE email=\"" . $valid_email . "\"");
	if ($row = mysql_fetch_array($ergebnis)){
		$valid_user_id = $row["id"];
		$valid_name = $row["vorname"] . " " . $row["nachname"];
	} else {
			$errormsg = " Die E-Mail-Adresse ist nicht valide";
		}
	}
	if (isset($valid_user_id)){
		mysql_query("DELETE FROM pw_forgot WHERE user_id=" . $valid_user_id);
		$repeat = true;
		do{
			$link_component = hash("haval128,3",rand(0,getrandmax()),false);
			$ergebnis = mysql_query("SELECT * FROM pw_forgot WHERE link_component=\"" . $link_component . "\"");
			if (mysql_num_rows($ergebnis) == 0){
			  $repeat = false;
			  mysql_query("INSERT INTO pw_forgot (user_id, link_component) VALUES(" . $valid_user_id . ", \"" . $link_component . "\")");
			}
		}while($repeat);
		$headers = "From: noreply@fliegenberg.de" . "\n" .
                   "X-Mailer: PHP/" . phpversion() . "\n" .
				   "Mime-Version: 1.0" . "\n" . 
				   "Content-Type: text/plain; charset=UTF-8" . "\n" .
				   "Content-Transfer-Encoding: 8bit" . "\r\n";
	    $message = "Hallo " . $valid_name . ", \r\n" .
		           "\r\n" .
		           "jemand hat auf fliegenberg.de ein neues Passwort für deinen Account angefordert." . "\r\n" . 
				   "Kein Problem, hier kommt ein Link, mit dem du ein neues Passwort setzen kannst: \r\n".
				   "\r\n".
				   "http://" . $_SERVER['SERVER_NAME'] . "/reset_password.php?key=" . $link_component . "\r\n" . 
				   "\r\n" .
				   "Wenn du keine Änderung deines Passworts veranlasst hast, dann ignoriere diese Mail bitte einfach. \r\n".
				   "\r\n".
				   "Mit freundlichen Grüßen\r\n".
				   "Dein Fliegenberg-Team";
        mail($valid_email, "Neues Passwort für Fliegenberg.de", $message, $headers);
	}
  }
if (!isset($valid_user_id)){
if (isset($errormsg)){ ?>
<table border="1" bordercolor="#FF0000">
  <tr>
    <td><?php echo $errormsg; ?></td>
  </tr>
</table>
<br>
  <?php }?>
<h1>Passwort zurücksetzen</h1>
<b>Du hast dein Passwort vergessen? Kein Problem!</b><br>
Gebe einfach hier deine E-Mail-Adresse mit der du dich registriert hast ein und wir schicken dir einen Link zum Zurücksetzen des Passworts für deinen Account an deine E-Mail-Adresse.
<br>
<br>
<div>
	<input class="input" style="margin-bottom:0px;" name="email" id="email" type="text" placeholder="E-Mail-Adresse">
	<input class="btn btn-primary" name="passwort_reset" type="submit" value="Passwort zurücksetzen">
</div>

<?php } else {?>
<b style="color:green">Die E-Mail zum Ändern deines Passworts wurde erfolgreich versandt</b>
<?php } 
include 'templates/footer.tpl';?>
