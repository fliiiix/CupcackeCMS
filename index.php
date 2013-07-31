<?php 
$current_site = "Hauptseite";
require_once('utils.php');
include 'templates/header.tpl'; 
if (isset($login)){
	echo '<div class="alert alert-error"> <button type="button" class="close" data-dismiss="alert">×</button>' . $login . ' Hast du dein <a href="recover_password.php">Passwort vergessen</a>?</div>';
}
?>
<div class="span12"><h1>Fliegenberg</h1></div>
<div class="span8">
	<br>
	<img class="img-polaroid" src="http://media.fliegenberg.ch/fliegenberg.jpg">
</div>
<div class="span2">
	<?php
		if (isset($_GET['m']) && (isset($_GET['y']))) {
			$calendar = calendar(intval($_GET['m']), intval($_GET['y']));
		    echo $calendar;
		} else {
			$calendar = calendar(date('m'),date('Y'));
		    echo $calendar;
		}
	?>
</div>
<?php include 'templates/footer.tpl'; ?>