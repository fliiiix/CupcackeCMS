<?php
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

?>

<html>
<head>
  <title>Passwort ändern</title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <script type="text/javascript" src="/CupcackeCMS/assets/js/jquery.js"></script>
  <!-- Le styles -->
  <link href="assets/css/bootstrap.min.css" rel="stylesheet">
  <link href="assets/css/bootstrap-responsive.css" rel="stylesheet">
  <link href="assets/css/jquery.fileupload-ui.css" rel="stylesheet">
  <style>
    body {
      padding-top: 90px; /* 90px to make the container go all the way to the bottom of the topbar */
    }
  </style>

  <!-- Le HTML5 shim, for IE6-8 support of HTML5 elements -->
  <!--[if lt IE 9]>
    <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
  <![endif]-->

  <!-- Le fav and touch icons -->
  <link rel="shortcut icon" href="/assets/ico/favicon.ico">
  <link rel="apple-touch-icon-precomposed" sizes="144x144" href="/assets/ico/apple-touch-icon-144-precomposed.png">
  <link rel="apple-touch-icon-precomposed" sizes="114x114" href="/assets/ico/apple-touch-icon-114-precomposed.png">
  <link rel="apple-touch-icon-precomposed" sizes="72x72" href="/assets/ico/apple-touch-icon-72-precomposed.png">
  <link rel="apple-touch-icon-precomposed" href="/assets/ico/apple-touch-icon-57-precomposed.png">
</head><body>
    <div class="navbar navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </a>
          <a class="brand" href="index.php">Fliegenberg</a>
          <div class="nav-collapse">
    </ul>
          </div><!--/.nav-collapse -->
        </div>
      </div>
    </div>
</body>
<?php
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
?>
</html>
