<?php include 'templates/header.tpl'; ?>
<?php


if (isset($_POST["beitragTitel"]) && isset($_POST["beitragUnterTitel"]) && isset($_POST["beitragText"])){
    $beitragTitel = $_POST["beitragTitel"];
    $beitragUnterTitel = $_POST["beitragUnterTitel"];   
    $beitragText = $_POST["beitragText"];
    
    echo $beitragTitel . "+" . $beitragUnterTitel . "+" .  $beitragText;
}
?>
<a href="bilderGalerie.php?neu=true">link</a>
<?php if(isset($_GET["neu"]) && $_GET["neu"] == "true") {
    include 'templates/neuerBeitrag.tpl';
}?>
<?php include 'templates/footer.tpl'; ?>