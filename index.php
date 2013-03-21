<?php 
$current_site = "Hauptseite";
include 'templates/header.tpl'; 
if (isset($login)){
	echo '<div class="alert alert-error"> <button type="button" class="close" data-dismiss="alert">×</button>' . $login . ' Hast du dein <a href="recover_password.php">Passwort vergessen</a>?</div>';
}
?>
<div class="span12"><h1>Titel</h1></div>
<div class="span9">
	<p>Hier kommt irgend ein Text hin</p>
</div>
<div class="span2">
	<?php
		require_once('utils.php');
		if (isset($_GET['m']) && (isset($_GET['y']))) {
			$calendar = calendar(intval($_GET['m']), intval($_GET['y']));
		  echo $calendar;
		} else {
			$calendar = calendar(date('m'),date('Y'));
		  echo $calendar;
		}
	?>
</div>
<div class="span12">
	<img src="media.fliegenberg.ch/fliegenberg.jpg">
</div>
<?php include 'templates/footer.tpl'; ?>