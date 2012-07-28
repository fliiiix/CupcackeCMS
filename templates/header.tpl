<?php
require_once('../utils.php');
# Überprüfen, ob der Nutzer das richtige Passwort und den richtigen Benutzernamen angegeben hat
# Wenn alle Daten stimmen zum Admin-Interface weiterleiten
if (isset($_POST["username"]) && isset($_POST["password"]) && isset($_POST["login_button"])) {
  db_connect();
  echo "zeile 7";
  setcookie("CupcackeCMS_Cookie","",-1);
    if (!$errormsg = login_user($_POST["username"],$_POST["password"])){
    header("Location: admin.php");
    exit();
  }
}
?>
<!DOCTYPE html>
<html lang="de">
  <head>
    <meta charset="utf-8">
    <title>Fliegenberg</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">

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
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>

    <!-- Le fav and touch icons
    <link rel="shortcut icon" href="/assets/ico/favicon.ico">
    <link rel="apple-touch-icon-precomposed" sizes="144x144" href="/assets/ico/apple-touch-icon-144-precomposed.png">
    <link rel="apple-touch-icon-precomposed" sizes="114x114" href="/assets/ico/apple-touch-icon-114-precomposed.png">
    <link rel="apple-touch-icon-precomposed" sizes="72x72" href="/assets/ico/apple-touch-icon-72-precomposed.png">
    <link rel="apple-touch-icon-precomposed" href="/assets/ico/apple-touch-icon-57-precomposed.png">-->
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
            <ul class="nav">
              <li><a href="index.php">Home</a></li>
              <li><a href="kalender.php">Kalender</a></li>
              <?php 
              	//if user login okey
              	echo "<li><a href=\"bilderGalerie.php\">Bilder Galerie</a></li>";
              ?>
            </ul>
	    <ul class="nav pull-right">
              <li id="login">
	         <form method="post" action="" class="navbar-form">
		    <?php if (isset($errormsg)){
		    echo $errormsg; }?>
		    <p class="navbar-text" style="float:left;">Benutzername:&nbsp;&nbsp;&nbsp;</p> 
		    <input type="text" name="username" id="username" class="span2" style="float:left; width:120px;"/>

		    <p class="navbar-text" style="float:left;">&nbsp;&nbsp;&nbsp;Passwort:&nbsp;&nbsp;&nbsp;</p> 
		    <input type="password" name="password" id="password" class="span2" style="float:left; width:100px;"/>
			
		    <div class="btn-group" style="float:left;">
                    <input type="submit" value="Einloggen" id="login_button" name="login_button" class="btn btn-primary" style="border: 0;"/>
	                <a class="btn btn-primary dropdown-toggle" data-toggle="dropdown" href="#"><span class="caret"></span></a>
	                <ul class="dropdown-menu">
	                   <li><a href="recover_password.php">Passwort vergessen</a></li>
	               </ul>
	            </div><!-- /btn-group -->
	         </form>
	      </li>
	  </ul>
          </div><!--/.nav-collapse -->
        </div>
      </div>
    </div>

<div class="container">