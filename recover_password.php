<!DOCTYPE html>
<html>
<head>
<!--
	Seite, die es dem Nutzer ermöglicht sich einen Link zum Zurücksetzen seines Passworts an seine E-Mail-Adresse senden zu lassen
-->
<title>Passwort zurücksetzen</title>
<script type="text/javascript" src="js/jquery.js"></script>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
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
<?php
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
?>
</head>
<body>
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
<?php
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
Gebe einfach hier deine E-Mail-Adresse mit der du dich registriert hast ein und wir schicken dir einen Link zum Zurücksetzen des Passworts für deinen Account an deine E-Mail-Adresse.<br>
<br>
<form name="form1" method="post" action="">
  <table border="0">
    <tr>
      <td>&nbsp;E-Mail-Adresse:</td>
      <td>&nbsp;<input name="email" id="email "type="text" maxlength="30"></td>
    </tr>
    <tr>
    <td colspan="2" align="right"><input name="passwort_reset" type="submit" value="Passwort zurücksetzen"></td>
    </tr>
  </table>
</form>
<?php } else {?>
<b style="color:green">Die E-Mail zum Ändern deines Passworts wurde erfolgreich versandt</b>
<?php } ?>
	</body>
</html>
