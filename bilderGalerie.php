
<?php 
session_start();
error_reporting(E_ALL | E_STRICT);

//sesion für beitrags id setzten
if (isset($_GET["id"])) {
	$beitragsID = $_GET["id"];
}
else { $beitragsID = 0; }
$_SESSION['id_beitrag'] = $beitragsID;

include 'templates/header.tpl'; 
echo($beitragsID);

/*echo "<br \>ding<br \>";
print_r($info);  
echo count($info);*/

if (isset($_POST["beitragTitel"]) && isset($_POST["beitragUnterTitel"]) && isset($_POST["beitragText"])){
    db_connect();
    $beitragTitel = $_POST["beitragTitel"];
    $beitragUnterTitel = $_POST["beitragUnterTitel"];   
    $beitragText = $_POST["beitragText"];
    
    $createStatement = "INSERT INTO beitrag (titel, untertitel, inhalt, id_Owner, Aktiv)";
    //echo $beitragTitel . "+" . $beitragUnterTitel . "+" .  $beitragText . "++" . $_SESSION['result'];
}
?>
<a href="bilderGalerie.php?neu=true">link</a>
<?php if(isset($_GET["neu"]) && $_GET["neu"] == "true") {
    include 'templates/neuerBeitrag.tpl';
}?>
<?php include 'templates/footer.tpl'; ?>