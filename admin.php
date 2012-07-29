<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<?php
require_once('utils.php');
db_connect();

// Nutzer ohne Cookie rauswerfen
if (!isset($_COOKIE["CupcackeCMS_Cookie"])){
  header("Location: index.php");
  exit;
} else {
  setcookie("CupcackeCMS_Cookie",$_COOKIE["CupcakeCMS_Cookie"],time()+3600);
}

// Cookie des Nutzers überprüfen
$ergebnis = mysql_query("SELECT user_id,rolle FROM cookie_mapping WHERE cookie_content=" . intval($_COOKIE["CupcakeCMS_Cookie"]));
$row = mysql_fetch_array($ergebnis);
if ($row["rolle"] == 3){
  $userid = $row["user_id"];
} else {
  header("Location: index.php");
  exit();
}

// Logout
if (isset($_GET["logout"])){
  mysql_query("DELETE FROM cookie_mapping WHERE user_id=" . $userid);
  setcookie("CupcackeCMS_Cookie","",-1);
  header("Location: index.php");
  exit();
}
# Nutzer löschen, falls der entsprechende Button geklickt wird
if (isset($_GET["del"])){
  mysql_query("DELETE FROM user WHERE id=" . mysql_real_escape_string($_GET["del"]));
}

# Bestätigungs-Mail versenden, wenn das Neuen-Nutzer-Erstellen-Formular richtig ausgefüllt wurde
if (isset($_POST["email"]) && isset($_POST["email_retype"]) && isset($_POST["rolle"]) && isset($_POST["create_user"])){
  $email = mysql_real_escape_string($_POST["email"]);
  $email_retype = mysql_real_escape_string($_POST["email_retype"]);
  $nachname = mysql_real_escape_string($_POST["nachname"]);
  $vorname = mysql_real_escape_string($_POST["vorname"]);
  if ($email != $email_retype){
    $error_msg = "Bitte übereinstimmende E-Mail-Adressen eingeben";
  } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $error_msg = "Bitte eine valide E-Mail-Adresse eingeben";
  } else {
    $query = mysql_query("SELECT * FROM user WHERE email=\"" . mysql_real_escape_string($email) . "\"");
    if (mysql_num_rows($query) > 0){
      $error_msg = "Diese E-Mail-Adresse existiert leider schon";
    } else {
      mysql_query("INSERT INTO user (vorname, nachname, email, rolle) VALUES(\"" . $vorname . "\",\"" . $nachname  . "\",\"" .  $email . "\"," . 0 . ")");
      $query = mysql_query("SELECT id FROM user WHERE email =" . $email);
      $row = mysql_fetch_array($query);
      $repeat = true;
      do{
        $link_component = hash("haval128,3",rand(0,getrandmax()),false);
        $ergebnis = mysql_query("SELECT * FROM email_verify WHERE link_component=\"" . $link_component . "\"");
        if (mysql_num_rows($ergebnis) == 0){
          $repeat = false;
          mysql_query("INSERT INTO email_verify (user_id, random) VALUES(" . $row["id"] . ",\"" . $link_component . "\")");
        }
      }while($repeat);
      $headers = "From: noreply@fliegenberg.de" . "\n" .
      "X-Mailer: PHP/" . phpversion() . "\n" .
      "Mime-Version: 1.0" . "\n" . 
      "Content-Type: text/plain; charset=UTF-8" . "\n" .
      "Content-Transfer-Encoding: 8bit" . "\r\n";
      $message = "Hallo " . $vorname . " " . $nachname . ", \r\n" .
      "\r\n" .
      "ein Administrator hat dir einen Account für Fliegenberg.de erstellt." . "\r\n" . 
      "Klicke auf den folgenden Link, um dein Passwort zu setzen und den Account zu aktivieren: \r\n".
      "\r\n".
      "https://fliegenberg.de/create_account.php?key=" . $link_component . "\r\n" . 
      "Wenn du dir keinen Account erstellen möchtest lasse diesen Link einfach verfallen. \r\n".
      "Mit freundlichen Grüßen\r\n".
      "Dein Fliegenberg-Team";
      mail($email, "Account für Fliegenberg.de", $message, $headers);
    }
  }
}

# Nutzer (de)aktivieren, falls der entsprechende Button geklickt wird
if (isset($_GET["cs"])){
  $query = mysql_query("SELECT aktiv FROM user WHERE id=" . mysql_real_escape_string($_GET["cs"]));
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
  mysql_query("UPDATE user SET aktiv=" . $new . " WHERE id=" . mysql_real_escape_string($_GET["cs"]));
}

# Query für die ganze Tabelle
$query = mysql_query("SELECT id,vorname,nachname,rolle,aktiv FROM user");
?>
<html>
<head>
  <title>CupcackeCMS - Admin-Interface</title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <script type="text/javascript" src="../js/jquery.min.js"></script>
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
  $("#create_user > a").click(function() { 
    $(this).next("div").slideToggle();
  });
});
  </script>
</head><body>
<div id="create_user">
  <a href="#">Neuen Nutzer erstellen</a>
  <div>
    <form>
    <b>E-Mail-Adresse des Nutzers:</b> <input name="email" type="text" maxlength="256"?><br />
    <b>E-Mail-Adresse des Nutzers bestätigen:</b> <input name="email_retype" type="text" maxlength="256"?><br />
    <b>Rolle des Nutzers:</b> <select size="1" name="rolle">
    <option>Nutzer</option>
    <option>Admin</option>
  </select> <a href="#"><i>Hilfe: Wer hat welche Rechte?</i></a><br />
  <input type="submit" value="Nutzer erstellen" name="create_user">
  </form>
  </div>
  </div>
<br />
<table style="text-align: left; width: 100%;" border="1" cellpadding="2" cellspacing="2" id="tabelle">
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
  echo "<div style='color:orange'><b>?</b></div>";
  break;

  # Account ist deaktiviert
  case (1):
  echo "<div style='color:red'>✘</div>";
  break;

  # Account ist aktiv
  case (2):
  echo "<div style='color:green'>✔</div>";
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
        <input name="change_status" type="submit" onclick="window.location.href = '?cs=<?php echo $row["id"];?>';" value="Nutzer <?php if ($row["aktiv"] == 1){
        echo "aktivieren";
      }
      if ($row["aktiv"] == 2){
        echo "deaktivieren";
      }
      ?>">
      <?php } ?>
      </td>
      <td>
        <input name="delete_user" type="submit" onclick="window.location.href = '?del=<?php echo $row["id"];?>';" value="Nutzer löschen">
      </td>
    </tr>
    <?php } ?>
  </tbody>
</table><br />
<br />
<div id="legende">
Legende:<br />
<span style='color:orange'><b>?</b></span> = Account noch nicht vom Nutzer bestätigt<br />
<span div style='color:red'>✘</span> = Account deaktiviert<br />
<span style='color:green'>✔</span> = Account aktiv<br />
</div>
</body>
</html>