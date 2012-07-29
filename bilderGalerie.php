
<?php 
session_start();
include 'templates/header.tpl'; 
?>
<?php
error_reporting(E_ALL | E_STRICT);

$_SESSION['id_beitrag'] = 1;
if (isset($_POST["beitragTitel"]) && isset($_POST["beitragUnterTitel"]) && isset($_POST["beitragText"])){
    $beitragTitel = $_POST["beitragTitel"];
    $beitragUnterTitel = $_POST["beitragUnterTitel"];   
    $beitragText = $_POST["beitragText"];
    
    echo $beitragTitel . "+" . $beitragUnterTitel . "+" .  $beitragText . "++" . $_SESSION['result'];//. "**" . $_SESSION['ding'];

    //$_SESSION['folderName'] = "neu";
}
?>
<a href="bilderGalerie.php?neu=true">link</a>
<?php if(isset($_GET["neu"]) && $_GET["neu"] == "true") {
    include 'templates/neuerBeitrag.tpl';
}?>
<?php include 'templates/footer.tpl'; ?>