<?php
$current_site = "Passwort wiederherstellen";
include 'templates/header.tpl';
require_once('utils.php');
db_connect();

# Kontrolliere, ob ein Key vorhanden ist und ob er gültig ist
if (isset($_GET["key"])){
  $key = mysql_real_escape_string($_GET["key"]);
  $query = mysql_query("SELECT user_id FROM pw_forgot WHERE link_component=\"" . $key . "\"");
  if (mysql_num_rows($query) == 0){
    $invalid_key = 1;
  } else {
    $row = mysql_fetch_array($query);
    $valid_user_id = $row["user_id"];
  }
} else {
  $invalid_key = 1;
}

# Passwort ändern, wenn alle Checks durchlaufen sind ;-)
if (isset($_POST["password"]) && isset($_POST["password_verify"]) && isset($_POST["change_password"])){
  if (($_POST["password"] == "") || ($_POST["password_verify"] == ""))
    $errormsg = "Bitte kein Passwort-Feld leer lassen";
  else {
    if ($_POST["password"] != $_POST["password_verify"]){
      $errormsg = "Die beiden Passwörter stimmen nicht überein";
    } else {
      if (strlen($_POST["password"]) < 8){
        $errormsg = "Bitte gebe ein Passwort, das länger als 7 Zeichen ist ein";
      } else {
        mysql_query("UPDATE user WHERE id=" . $valid_user_id . " SET pw_hash=\"" . hash("whirlpool",$_POST["password"],false));
        mysql_query("DELETE FROM pw_forgot WHERE link_component=\"" . $key . "\"");
        $success_msg = 1;
      }
    }
  }
}

if (isset($invalid_key)){?>
  <b style="color:red">Der Passwort-Zurücksetzen-Link, über den du auf diese Seite gekommen bist, ist ungültig oder abgelaufen</b>
<?php
} else {
  if (isset($success_msg)){ ?>
    <b style="color:green">Dein Passwort wurde erfolgreich geändert</b>
  <?php } else {
  if (isset($errormsg)){
    echo "<b style=\"color:red\">" . $errormsg . "</b>";
  }?>
<form name="form1" method="post" action="<?php if (isset ($_GET["key"])) echo "?key=" . $_GET["key"]; ?>">
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
      <td colspan="2" align="right"><input name="change_password" type="submit" value="Passwort ändern"></td>
    </tr>
  </table>
</form>
<?php 
}
}
include 'templates/footer.tpl';
?>
