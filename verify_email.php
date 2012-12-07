<?php
error_reporting(E_ALL | E_STRICT);
$current_site = "Neue E-Mail-Adresse bestätigen";
include 'templates/header.tpl'; 
require_once('utils.php');
$db = new_db_o();

$invalid_key = 0;

// Kontrolle, ob der Key-Parameter gesetzt ist
if (!isset($_GET["change_key"]) && !isset($_GET['new_key'])){
	$invalid_key = 1;
}

# Falls der Key für die Bestätigung geänderter E-Mail-Adressen vorhanden ist diesen überprüfen
if (isset($_GET["change_key"])){
	$key = escape($_GET["change_key"]);
	$sql = 'SELECT `user_id`,`new_email` FROM `change_email` WHERE `random`=?';
	$ergebnis = $db->prepare($sql);
	$ergebnis->bind_param('s', $key);
	$ergebnis->execute();
	$ergebnis->store_result();
	if ($ergebnis->num_rows < 1){
	  $invalid_key = 1;
	  $ergebnis->close();
	} else {
		$ergebnis->bind_result($valid_user_id, $new_email);
		$ergebnis->fetch();
		$ergebnis->close();

		$sql = 'UPDATE `user` SET `email`=? WHERE `id`=?';
		$eintrag = $db->prepare($sql);
		$eintrag->bind_param('si', $new_email, $valid_user_id);
		$eintrag->execute();
		$eintrag->close();

		$sql = 'DELETE FROM `change_email` WHERE `random`=?';
		$eintrag = $db->prepare($sql);
		$eintrag->bind_param('s', $key);
		$eintrag->execute();
		$eintrag->close();
		
		$success_msg = '<div class="alert alert-success">Deine neue E-Mail-Adresse wurde erfolgreich bestätigt.</div>';
	}
}

# Falls der Key für die Bestätigung geänderter E-Mail-Adressen vorhanden ist diesen überprüfen
if (isset($_GET['new_key'])){
	$key = escape($_GET["new_key"]);
	$sql = 'SELECT `user_id` FROM `email_verify` WHERE `random`=?';
	$ergebnis = $db->prepare($sql);
	$ergebnis->bind_param('s', $key);
	$ergebnis->execute();
	$ergebnis->store_result();
	if ($ergebnis->num_rows < 1){
		$invalid_key = 1;
		$ergebnis->close();
	} else {
		$ergebnis->bind_result($valid_user_id);
		$ergebnis->fetch();
		$ergebnis->close();
                
                echo '<div class="alert alert-success">Deine E-Mail-Adresse für deinen neuen Account wurde erfolgreich bestätigt.</div>';
                
                if(isset($_POST["passwort"]) && $_POST["passwort"] != "" &&
                  isset($_POST["passwortRetype"]) && $_POST["passwortRetype"] != "" && 
                  $_POST["passwort"] == $_POST["passwortRetype"] && (strlen($_POST["passwort"]) >= 8)){
                    $aktiv = 2;
                    $passwortHash = hash("whirlpool", $_POST["passwort"], false);
                    $sql = 'UPDATE `user` SET `aktiv`=?, `pw_hash`=?  WHERE `id`=?';
                    $eintrag = $db->prepare($sql);
                    $eintrag->bind_param('isi', $aktiv, $passwortHash, $valid_user_id);
                    $eintrag->execute();
                    $eintrag->close();

                    $sql = 'DELETE FROM `email_verify` WHERE `random`=?';
                    $eintrag = $db->prepare($sql);
                    $eintrag->bind_param('s', $key);
                    $eintrag->execute();
                    $eintrag->close();
                    
                    echo '<div class="alert alert-success">Deine Passwort wurde gespeichert du kannst dich jetzt mit deiner E-Mail Adresse und deinem Passwort anmelden</div>';
                }
                else{
                    if(isset($_POST["passwort"])){
                        echo '<div class="alert alert-error">Bitte Überprüfe die Passwörter vielleicht hast du nicht zwei mal das gleiche Passwort eingegeben. Oder dein Passwort ist kürzer als 8 Zeichen.</div>';
                    }
                    echo '<h2>Passwort</h2>
                    <br>
                    <div>
                        <form method="post">
                            <input class="input" style="margin-bottom:0px;" name="passwort" id="passwort" type="text" placeholder="Passwort">
                            <input class="input" style="margin-bottom:0px;" name="passwortRetype" id="passwortRetype" type="text" placeholder="Passwort Wiederholen">
                            <input class="btn btn-primary" name="setPassword" type="submit" value="Passwort Speichern">
                        </form>
                    </div>';
                }
	}
}

if ($invalid_key == 1){
	echo '<div class="alert alert-error">Der E-Mail-Bestätigungs-Link, über den du auf diese Seite gekommen bist, ist ungültig oder abgelaufen.</div>';
}
include 'templates/footer.tpl';
?>