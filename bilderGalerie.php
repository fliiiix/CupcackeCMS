<!--<script src="assets/js/bootstrap-carousel.js"></script>

<div id="myCarousel" class="carousel slide">
    <div class="carousel-inner">
    <div class="active item">…</div>
    <div class="item">…</div>
    <div class="item">…</div>
    </div>
    <a class="carousel-control left" href="#myCarousel" data-slide="prev">&lsaquo;</a>
    <a class="carousel-control right" href="#myCarousel" data-slide="next">&rsaquo;</a>
</div>-->

<?php 
session_start();
require ('utils.php');
include 'templates/header.tpl';

if (isset($_POST["beitragTitel"]) && isset($_POST["beitragUnterTitel"]) && isset($_POST["beitragText"])){
    db_connect();
    //tofix ownder id fehlt 
    $query = 'INSERT INTO bilderBeitrag (titel, unterTitel, text, uploadFolderName, ownerId, aktiv) 
        VALUES("' . $_POST["beitragTitel"] . '","' . $_POST["beitragUnterTitel"] . '","' . $_POST["beitragText"] . '","' . $_SESSION["uploadFolder"] . '","' . 1 . '","' . 1 . '")';
    if (mysql_query($query) == FALSE) {
        die('Der Post konnte nicht gespeichert werden: ' . mysql_error());
    }
}
?>
<a href="bilderGalerie.php?neu">link</a>
<?php 
if(isset($_GET["neu"])) {
    $_SESSION["uploadFolder"] = guid();
    include 'templates/neuerBeitrag.tpl';
}
if(isset($_GET["old"])) {
    $_SESSION["uploadFolder"] = $_GET["old"];
    include 'templates/neuerBeitrag.tpl';
}
?>
<?php include 'templates/footer.tpl'; ?>
