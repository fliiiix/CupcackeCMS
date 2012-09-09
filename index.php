<?php 
$current_site = "Hauptseite";
include 'templates/header.tpl'; 
if (isset($login)){
	echo "<div class=\"alert\">" . $login . " Hast du dein <a href=\"recover_password.php\">Passwort vergessen</a>?</div>";
}
?>
<p>Hier kommt irgend ein Text hin</p>
<img alt="bildhalt" src="googleWallet.png">
<hr />
<h3>Nächste Events:</h3>
<ul>
	<li>Datum, Name, <a>link</a></li>
	<li>Datum, Name, <a>link</a></li>
</ul>
<?php include 'templates/footer.tpl'; ?>