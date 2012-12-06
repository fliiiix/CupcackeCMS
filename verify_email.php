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

		$aktiv = 2;
		$sql = 'UPDATE `user` SET `aktiv`=? WHERE `id`=?';
		$eintrag = $db->prepare($sql);
		$eintrag->bind_param('ii', $aktiv, $valid_user_id);
		$eintrag->execute();
		$eintrag->close();

		$success_msg = '<div class="alert alert-success">Deine E-Mail-Adresse für deinen neuen Account wurde erfolgreich bestätigt.</div>';
	}
}

if ($invalid_key == 1){
	echo '<div class="alert alert-error">Der E-Mail-Bestätigungs-Link, über den du auf diese Seite gekommen bist, ist ungültig oder abgelaufen.</div>';
}
if (isset($success_msg)){
	echo $success_msg;
}
include 'templates/footer.tpl';
?>