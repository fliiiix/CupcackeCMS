<?php
$current_site = "Passwort wiederherstellen";
include 'templates/header.tpl';
require_once('utils.php');
$db = new_db_o();

# Kontrolliere, ob ein Key vorhanden ist und ob er gültig ist
if (isset($_GET["key"])) {
    $key = escape($_GET["key"]);
    $sql = 'SELECT `user_id` FROM `pw_forgot` WHERE `link_component`=?';
    $ergebnis = $db->prepare($sql);
    $ergebnis->bind_param('s', $key);
    $ergebnis->execute();
    $ergebnis->store_result();
    if ($ergebnis->num_rows < 1) {
        $ergebnis->close();
        $invalid_key = 1;
    } else {
        $ergebnis->bind_result($valid_user_id);
        $ergebnis->fetch();
        $ergebnis->close();
    }
} else {
    $invalid_key = 1;
}

# Passwort ändern, wenn alle Checks durchlaufen sind ;-)
if (isset($_POST["password"]) && isset($_POST["password_verify"]) && isset($_POST["change_password"])) {
    if (($_POST["password"] == "") || ($_POST["password_verify"] == ""))
        $errormsg = "Bitte kein Passwort-Feld leer lassen";
    else {
        if ($_POST["password"] != $_POST["password_verify"]) {
            $errormsg = "Die beiden Passwörter stimmen nicht überein";
        } else {
            if (strlen($_POST["password"]) < 8) {
                $errormsg = "Bitte gebe ein Passwort, das länger als 7 Zeichen ist ein";
            } else {
                $password_hash = hash("whirlpool", $_POST["password"], false);
                $sql = 'UPDATE `user` SET `pw_hash`=? WHERE `id`=?';
                $eintrag = $db->prepare($sql);
                $eintrag->bind_param('si', $password_hash, $valid_user_id);
                $eintrag->execute();
                $eintrag->close();

                $sql = 'DELETE FROM `pw_forgot` WHERE `link_component`=?';
                $eintrag = $db->prepare($sql);
                $eintrag->bind_param('s', $key);
                $eintrag->execute();
                $eintrag->close();
                $success_msg = 1;
            }
        }
    }
}
?>
<h2> Passwort zurücksetzen</h2>
<?php if (isset($invalid_key)) { ?>
    <div class="alert alert-error">Der Passwort-Zurücksetzen-Link, über den du auf diese Seite gekommen bist, ist ungültig oder abgelaufen</div>
    <?php
} else {
    if (isset($success_msg)) {
        ?>
        <div class="alert alert-success">Dein Passwort wurde erfolgreich geändert <a href='index.php'>Zurück zur Startseite</a></div>
        <?php
    } else {
        if (isset($errormsg)) {
            echo '<div class="alert alert-error">' . $errormsg . '</div>';
        }
        ?>
        <form name="form1" method="post" action="<?php if (isset($_GET["key"])) echo "?key=" . $_GET["key"]; ?>">
            <table border="0">
                <tr>
                    <td>Neues Passwort:</td>
                    <td><input name="password" type="password"></td>
                </tr>
                <tr>
                    <td>Neues Passwort bestätigen:</td>
                    <td><input name="password_verify" type="password"></td>
                </tr>
                <tr>
                    <td colspan="2" align="right"><input name="change_password" class="btn btn-primary" type="submit" value="Passwort ändern"></td>
                </tr>
            </table>
        </form>
        <?php
    }
}
include 'templates/footer.tpl';
?>
