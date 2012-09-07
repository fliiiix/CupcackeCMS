<?php
error_reporting(E_ALL | E_STRICT);
$current_site = "Admin-Panel";
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

# Nutzer löschen, wenn der entsprechende Button geklickt wird
if (isset($_GET["del"])){
  mysql_query("DELETE FROM user WHERE id=" . mysql_real_escape_string($_GET["del"]));
}

# Nutzer (de)aktivieren, wenn der entsprechende Button geklickt wird
if (isset($_GET["cs"])){
  $change_status = mysql_real_escape_string($_GET["cs"]);
  $query = mysql_query("SELECT aktiv FROM user WHERE id=" . $change_status);
  $row = mysql_fetch_array($query);
  switch ($row["aktiv"]) {
    case (0):
      $new = "";
      break;
    
    case(1):
      $new = 2;
      break;

    case(2):
      $new = 1;
      break;
  }
  mysql_query("UPDATE user SET aktiv=" . $new . " WHERE id=" . $change_status);
}

# Nutzer zum Admin bzw. zum User machen, wenn der entsprechende Button geklickt wird
if (isset($_GET["ru"])){
  $rank_user= mysql_real_escape_string($_GET["ru"]);
  $query = mysql_query("SELECT rolle FROM user WHERE id=" . $rank_user);
  $row = mysql_fetch_array($query);
  if ($row["rolle"] == 1){
    $new = 2;
  }
  if ($row["rolle"] == 2){
    $new = 1;
  }
  mysql_query("UPDATE user SET rolle =" . $new . " WHERE id=" . $rank_user);
}

#get löschen
if(count($_GET) != 0) { header("Location: admin.php"); }

# Bestätigungs-Mail versenden, wenn das Neuen-Nutzer-Erstellen-Formular richtig ausgefüllt wurde
if (isset($_POST["email"]) && isset($_POST["email_retype"]) && isset($_POST["rolle"]) && isset($_POST["create_user"]) && isset($_POST["vorname"]) && isset($_POST["nachname"])){
  if ($_POST["email"] != $_POST["email_retype"]){
    $error_msg = "Bitte übereinstimmende E-Mail-Adressen eingeben";
  } elseif (!filter_var($_POST["email"], FILTER_VALIDATE_EMAIL)) {
    $error_msg = "Bitte eine valide E-Mail-Adresse eingeben";
  } else {
    $email = mysql_real_escape_string($_POST["email"]);
    $nachname = mysql_real_escape_string($_POST["nachname"]);
    $vorname = mysql_real_escape_string($_POST["vorname"]);
    $rolle = intval($_POST["rolle"]);
    $query = mysql_query("SELECT * FROM user WHERE email=\"" . $email . "\"");
    if (mysql_num_rows($query) > 0){
      $error_msg = "Diese E-Mail-Adresse existiert leider schon";
    } else {
      mysql_query("INSERT INTO user (vorname, nachname, email, rolle) VALUES(\"" . $vorname . "\",\"" . $nachname  . "\",\"" .  $email . "\"," . $rolle . ")");
      $query = mysql_query("SELECT id FROM user WHERE email=\"" . $email . "\"");
      $row = mysql_fetch_array($query);
      $new_user_id = $row["id"];
      $repeat = true;
      do{
        $random = hash("haval128,3",rand(0,getrandmax()),false);
        $ergebnis = mysql_query("SELECT * FROM email_verify WHERE random=\"" . $random . "\"");
        if (mysql_num_rows($ergebnis) == 0){
          mysql_query("INSERT INTO email_verify (user_id, random) VALUES(" . $new_user_id . ",\"" . $random . "\")");
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
      "ein Administrator hat dir einen Account für Fliegenberg.de erstellt." . "\r\n" . 
      "Klicke auf den folgenden Link, um deine Daten zu überprüfen, dein Passwort zu setzen und den Account zu aktivieren: \r\n".
      "\r\n".
      "http://" . $_SERVER['SERVER_NAME'] . "/email_verify.php?key=" . $random . "\r\n" . 
      "Wenn du dir keinen Account erstellen möchtest lasse diesen Link einfach verfallen. \r\n".
      "Mit freundlichen Grüßen\r\n".
      "Dein Fliegenberg-Team";
      mail($email, "Account für " . $_SERVER['SERVER_NAME'] . " bestätigen", $message, $headers);
    }
  }
}

# Query für die ganze Tabelle
$query = mysql_query("SELECT * FROM user WHERE NOT id=" . $valid_user_id);
?>
  <style type="text/css">
  #legende {
    border: 1px solid #000;
    padding: 10px 10px 10px 10px;
    width: 340px;
  }

  #create_user div{
    display:none;
    border: 1px solid #000;
    padding: 10px 10px 10px 10px;
  }

  #create_user a {
    text-decoration: none;
    color: black;
    outline: none;
  }
  </style>
  <script type="text/javascript">
	$(document).ready(function() {
	  $("#create_user > input").click(function() { 
	    $(this).next("div").slideToggle();
	  });
	});
  </script>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<div id="create_user">
  <?php if (isset($error_msg)){
    echo "<b style=\"color:red\">" . $error_msg . "</b><br />";
  }?>
  <input id="create_user" name="create_user" class="btn btn-primary" onclick="window.location.href = '#'" value="Neuen Nutzer erstellen" type="submit">
  <div>
    <form method="post">
    <b>E-Mail-Adresse des Nutzers:</b> <input name="email" type="text" maxlength="256"?><br />
    <b>E-Mail-Adresse des Nutzers bestätigen:</b> <input name="email_retype" type="text" maxlength="256"?><br />
    <b>Vorname des Nutzers:</b> <input name="vorname" type="text" maxlength="256"?><br />
    <b>Nachname des Nutzers:</b> <input name="nachname" type="text" maxlength="256"?><br />
    <b>Rolle des Nutzers:</b> <select size="1" name="rolle">
    <option value="1">Nutzer</option>
    <option value="2">Admin</option>
  </select> <a href="#"><i>Hilfe: Wer hat welche Rechte?</i></a><br />
  <input class="btn btn-primary" type="submit" value="Nutzer erstellen" name="create_user">
  </form>
  </div>
  </div>
<br />
<table class="table" id="tabelle">
  <tbody>
    <tr>
      <td style="vertical-align: top;"><b>Vorname</b>
      </td>
      <td style="vertical-align: top;"><b>Nachname</b>
      </td>
      <td style="vertical-align: top;"><b>Email</b>
      </td>
      <td style="vertical-align: top;"><b>Status</b>
      </td>
      <td style="vertical-align: top;"><b>Rolle</b>
      </td>
      <td style="vertical-align: top;">
      </td>
      <td style="vertical-align: top;">
      </td>
      <td style="vertical-align: top;">
      </td>
    </tr>
    <?php
    while ($row = mysql_fetch_array($query)){
    ?>
    <tr>
      <td style="vertical-align: top;"><?php echo $row["vorname"];?>
      </td>
      <td style="vertical-align: top;"><?php echo $row["nachname"];?>
      </td>
      <td style="vertical-align: top;"><?php echo $row["email"];?>
      </td>
      <td style="vertical-align: top;"><?php switch($row["aktiv"]){
  # Account ist noch nicht bestätigt
  case (0):
  echo "<img src='./img/questionmark.png'>";
  break;

  # Account ist deaktiviert
  case (1):
  echo "<img src='./img/cross.png'>";
  break;

  # Account ist aktiv
  case (2):
  echo "<img src='./img/accepted.png'>";
  break;
}?>
      </td>
      <td style="vertical-align: top;"><?php if($row["rolle"] == 1){
        echo "Nutzer";
      }
      if($row["rolle"] == 2){
        echo "Administrator";
      }?>
      </td>
      <td style="vertical-align: top;">
        <?php if ($row["aktiv"] == 1 || $row["aktiv"] == 2){ ?>
        <input <?php if ($row["aktiv"] == 1) { echo"class=\"btn btn-success\""; } if ($row["aktiv"] == 2) { echo"class=\"btn btn-danger\""; } ?> name="change_status" type="submit" onclick="window.location.href = '?cs=<?php echo $row["id"];?>';" value="Nutzer <?php if ($row["aktiv"] == 1){
        echo "aktivieren";
      }
      if ($row["aktiv"] == 2){
        echo "deaktivieren";
      }
      ?>">
      <?php } ?>
      </td>
      <td>
        <input class="btn btn-danger" name="delete_user" type="submit" onclick="window.location.href = '?del=<?php echo $row["id"];?>';" value="Nutzer löschen">
      </td>
      <td>
        <input class="btn btn-primary" name="rank_user" type="submit" onclick="window.location.href = '?ru=<?php echo $row["id"];?>';" value="Zum <?php
	# Nutzer ist Admin
        if($row["rolle"] == 2){
          echo "Nutzer";
        }
        # Nutzer ist normaler Nutzer
        if($row["rolle"] == 1){
          echo "Administrator";
        }
        ?> machen">
      </td>
    </tr>
    <?php } ?>
  </tbody>
</table><br />
<br />
<div id="legende">
Legende:<br />
<img src='./img/questionmark.png'> = Account noch nicht vom Nutzer bestätigt<br />
<img src='./img/cross.png'> = Account deaktiviert<br />
<img src='./img/accepted.png'> = Account aktiv<br />
</div>
<?php include 'templates/footer.tpl'; ?>