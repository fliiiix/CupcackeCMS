<?php
require_once("utils.php");

# Wenn der Logout-Button gerückt wird den Nutzer ausloggen
if(isset($_GET['logout'])){
  logout(verify_user());
}

// Überprüfen, ob der Nutzer das richtige Passwort und den richtigen Benutzernamen angegeben hat
// Wenn alle Daten stimmen zum Admin-Interface weiterleiten
if (isset($_POST["email"]) && isset($_POST["password"]) && isset($_POST["login_button"])) {
  setcookie("CupcackeCMS_Cookie","",0);

  $login = login_user(($_POST["email"]),($_POST["password"]));
  if ($login == "true"){
    header("Location: index.php");
    exit();
  }
}
?>
<!DOCTYPE html>
<html lang="de">
  <head>
   <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title><?php echo $GLOBALS["site_name"] . " | " . $current_site;?></title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">

    <!-- Le styles -->
    <link href="assets/css/bootstrap.min.css" rel="stylesheet">
    <link href="assets/css/bootstrap-responsive.css" rel="stylesheet">
    <link href="assets/css/jquery.fileupload-ui.css" rel="stylesheet">
     <link href="assets/css/docs.css" rel="stylesheet">

    <!-- Le HTML5 shim, for IE6-8 support of HTML5 elements -->
    <!--[if lt IE 9]>
      <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->
    <script src="assets/js/jquery.js"></script>
    <script src="assets/js/bootstrap.min.js"></script>
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
          <a class="brand" style="float:left; margin-left: 0px;" href="index.php">Fliegenberg</a>
          <div class="nav-collapse">
            <ul class="nav">
              <li><a href="index.php">Startseite</a></li>
              <?php
              $userId = verify_user();
              if($userId != false){
                    $userRollenId = getUserRolle($userId);
                    echo '<li><a href="kalender.php">Termine</a></li>';
                    if($userRollenId == 2){
                        echo "<li><a href=\"kalender_admin.php\">Terminverwaltung</a></li>";
                        
                    }
                    echo "<li><a href=\"bilderGalerie.php\">Bildergalerie</a></li>";
                    if($userRollenId == 2){
                        echo "<li><a href=\"admin.php\">Nutzerverwaltung</a></li>";
                    }
		            }
              ?>
            </ul>
      	    <ul class="nav pull-right">
            <?php
              $result =  verify_user();
              if($result == false)
              {
                  include 'templates/login.tpl'; 
              }
              else
              {
                  echo("Hallo " . current_username($result));
                  echo "<a class=\"btn btn-primary\" href=\"account_settings.php\"><i class=\"icon-wrench icon-white\"></i></a>";
                  echo "<a class=\"btn btn-primary\" href=\"assets/doc/Dokumentation.pdf\"><i class=\"icon-file icon-white\"></i></a>";
                  echo "<a class=\"btn btn-primary\" href=\"?logout\"><i class=\"icon-off icon-white\"></i></a>";
              }
            ?>
      	  </ul>
          </div><!--/.nav-collapse -->
        </div>
      </div>
    </div>
<div class="container">
