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
	<img alt="bildhalt" src="googleWallet.png">
</div>
<div class="span2">
	<?php
		require_once('utils.php');
		db_connect();
		if (isset($_GET['m']) && (isset($_GET['y']))) {
			$calendar = calendar(intval($_GET['m']), intval($_GET['y']));
		  echo $calendar['html'];
		} else {
			$calendar = calendar(date('m'),date('Y'));
		  echo $calendar['html'];
		}
	?>
</div>
<div class="span12">
	Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.
</div>
<?php include 'templates/footer.tpl'; ?>