<?php
$current_site = "Passwort zurücksetzen";
include 'templates/header.tpl';
require_once('utils.php');

if (isset($_POST["email"]) && isset($_POST["password_reset"])) {
    if ($_POST["email"] == "") {
        $errormsg = "Bitte eine E-Mail-Adresse eingeben";
    } else {
        $db = new_db_o();
        $valid_email = escape($_POST["email"]);
        $sql = 'SELECT `id`,`vorname`,`nachname` FROM `user` WHERE `email`=?';
        $ergebnis = $db->prepare($sql);
        $ergebnis->bind_param('s', $valid_email);
        $ergebnis->execute();
        $ergebnis->store_result();
        if ($ergebnis->num_rows > 0) {
            $ergebnis->bind_result($out_id, $out_vorname, $out_nachname);
            $ergebnis->fetch();
            $ergebnis->close();
            $valid_user_id = $out_id;
            $valid_name = $out_vorname . " " . $out_nachname;
        } else {
            $ergebnis->close();
            $errormsg = " Die E-Mail-Adresse ist nicht valide";
        }
    }
    if (isset($valid_user_id)) {
        $sql = 'DELETE FROM `pw_forgot` WHERE `user_id`=?';
        $eintrag = $db->prepare($sql);
        $eintrag->bind_param('i', $valid_user_id);
        $eintrag->execute();
        $repeat = true;
        do {
            $link_component = hash("haval128,3", rand(0, getrandmax()), false);
            $sql = 'SELECT * FROM `pw_forgot` WHERE `link_component`=?';
            $ergebnis = $db->prepare($sql);
            $ergebnis->bind_param('s', $link_component);
            $ergebnis->execute();
            $ergebnis->store_result();
            if ($ergebnis->num_rows < 1) {
                $ergebnis->close();
                $repeat = false;
                $sql = 'INSERT INTO `pw_forgot` (`user_id`, `link_component`) VALUES (?,?)';
                $eintrag = $db->prepare($sql);
                $eintrag->bind_param('is', $valid_user_id, $link_component);
                $eintrag->execute();
                $eintrag->close();
            }
        } while ($repeat);
        $headers = "From: noreply@fliegenberg.ch" . "\n" .
                "X-Mailer: PHP/" . phpversion() . "\n" .
                "Mime-Version: 1.0" . "\n" .
                "Content-Type: text/plain; charset=UTF-8" . "\n" .
                "Content-Transfer-Encoding: 8bit" . "\r\n";
        $message = "Hallo " . $valid_name . ", \r\n" .
                "\r\n" .
                "jemand hat auf fliegenberg.ch ein neues Passwort für deinen Account angefordert." . "\r\n" .
                "Kein Problem, hier kommt ein Link, mit dem du ein neues Passwort setzen kannst: \r\n" .
                "\r\n" .
                "http://" . $_SERVER['SERVER_NAME'] . "/reset_password.php?key=" . $link_component . "\r\n" .
                "\r\n" .
                "Wenn du keine Änderung deines Passworts veranlasst hast, dann ignoriere diese Mail bitte einfach. \r\n" .
                "\r\n" .
                "Mit freundlichen Grüßen\r\n" .
                "Dein Fliegenberg-Team";
        mail($valid_email, "Neues Passwort für fliegenberg.ch", $message, $headers);
    }
}
if (!isset($valid_user_id)) {
    if (isset($errormsg)) {
        ?>
        <div class="alert alert-error"><button type="button" class="close" data-dismiss="alert">×</button><?php echo $errormsg; ?></div>
        <br />
    <?php } ?>
    <h2>Passwort zurücksetzen</h2>
    Du hast dein Passwort vergessen? Kein Problem!<br>
    Gebe einfach hier deine E-Mail-Adresse mit der du dich registriert hast ein und wir schicken dir einen Link zum Zurücksetzen des Passworts für deinen Account an deine E-Mail-Adresse.
    <br>
    <br>
    <div>
        <form method="post">
            <input class="input" style="margin-bottom:0px;" name="email" id="email" type="text" placeholder="E-Mail-Adresse">
            <input class="btn btn-primary" name="password_reset" type="submit" value="Passwort zurücksetzen">
        </form>
    </div>

<?php } else { ?>
    <div class="alert alert-success">Die E-Mail zum Ändern deines Passworts wurde erfolgreich versandt <a href="index.php">Zurück zur Startseite</a></div>
<?php
}
include 'templates/footer.tpl';
?>
