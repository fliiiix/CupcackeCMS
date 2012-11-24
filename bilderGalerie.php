<?php 
session_start();
require ('utils.php');
$current_site = "Bildergalerie";
include 'templates/header.tpl';

# Nicht eigeloggte User rauswerfen, sonst valide User-ID speichern
$result = verify_user();
if ($result == false) {
    header("Location: index.php");
    exit();
} else {
    $valid_user_id = $result;
}

if(!isset($_GET["neu"]) && !isset($_GET["fail"]) && !isset($_GET["old"]) && getUserRolle($valid_user_id) == 2)
{
    echo '<div class="span11">
            <a href="bilderGalerie.php?neu" class="btn btn-primary">Neuer Beitrag</a><br>
          </div>';
}

function getCarouselHead()
{
    $idGuid = guid();
    echo '<div id="'. $idGuid .'" class="carousel slide span7" data-interval="false" style="display: block; margin-left: auto; margin-right: auto">
                <div class="carousel-inner">';
    return $idGuid;
}

function getCarouselEnd($id)
{
    echo '</div>
                <a class="carousel-control left" href="#'. $id .'" data-slide="prev">&lsaquo;</a>
                <a class="carousel-control right" href="#'. $id .'" data-slide="next">&rsaquo;</a>
            </div>';
}

if (isset($_POST["beitragTitel"]) && isset($_POST["beitragUnterTitel"]) && isset($_POST["beitragText"])){
    if($_POST["beitragTitel"] != "" && $_POST["beitragText"] != "") {
        db_connect();
        if(isset($_SESSION["editOld"]) && $_SESSION["editOld"] == TRUE){
            $query = 'UPDATE bilderBeitrag SET titel="'.$_POST["beitragTitel"].'", unterTitel="'.$_POST["beitragUnterTitel"].'", text="'.$_POST["beitragText"].'", datum="'. date_to_mysql(mysql_real_escape_string($_POST['event_date'])) .'" WHERE uploadFolderName="'.$_SESSION["uploadFolder"].'"';
            $_SESSION["editOld"] = FALSE;
            if (mysql_query($query) == FALSE) {
                die('Der Post konnte nicht verändert werden werden: ' . mysql_error());
            } 
        }
        else {
            $query = 'INSERT INTO bilderBeitrag (titel, unterTitel, text, uploadFolderName, ownerId, aktiv, datum) 
            VALUES("' . mysql_real_escape_string($_POST["beitragTitel"]) . '","' .  mysql_real_escape_string($_POST["beitragUnterTitel"]) . '","' .  mysql_real_escape_string($_POST["beitragText"]) . '","' . $_SESSION["uploadFolder"] . '","' . $valid_user_id . '","' . 1 . '","' . date_to_mysql(mysql_real_escape_string($_POST['event_date'])) . '")'; 
            if (mysql_query($query) == FALSE) {
                die('Der Post konnte nicht gespeichert werden: ' . mysql_error());
            } 
        }
    }
    else {
        $_SESSION["beitragTitel"] = $_POST["beitragTitel"];
        $_SESSION["beitragUnterTitel"] = $_POST["beitragUnterTitel"];
        $_SESSION["beitragText"] = $_POST["beitragText"];
        $_SESSION["datum"] = date_to_mysql(mysql_real_escape_string($_POST['event_date']));
        header("Location: ?fail");
    }
}

if(isset($_GET["del"]) && $_GET["del"] != ""){
    db_connect();
    $query = "DELETE FROM bilderBeitrag WHERE uploadFolderName=\"" . $_GET["del"] . "\"";
    mysql_query($query);
    empty_get("bilderGalerie.php");
}

#get und session stuff
if(isset($_GET["neu"]) && getUserRolle($valid_user_id) == 2) {
    $_SESSION["uploadFolder"] = guid();
    include 'templates/neuerBeitrag.tpl';
}
if(isset($_GET["old"]) && $_GET["old"] != "" && getUserRolle($valid_user_id) == 2) {
    $_SESSION["uploadFolder"] = $_GET["old"];
    $_SESSION["editOld"] = TRUE;

    db_connect();
    $query = "SELECT * FROM bilderBeitrag WHERE uploadFolderName=\"" . $_GET["old"] . "\"";
    $ergebnis = mysql_query($query);
    if($row = mysql_fetch_array($ergebnis, MYSQL_ASSOC)){
        $beitragTitel = $row["titel"];
        $beitragUnterTitel = $row["unterTitel"];
        $beitragtext = $row["text"];
        $_SESSION["datum"] = date_format(date_create($row["datum"]), "d.m.Y");
    }
    include 'templates/neuerBeitrag.tpl';
}
if(isset($_GET["fail"]) && getUserRolle($valid_user_id) == 2) {
    $beitragTitel = isset($_SESSION["beitragTitel"]) ? $_SESSION["beitragTitel"] : "";
    $beitragUnterTitel = isset($_SESSION["beitragUnterTitel"]) ? $_SESSION["beitragUnterTitel"] : "";
    $beitragtext = isset($_SESSION["beitragText"]) ? $_SESSION["beitragText"] : "";
    echo '<div class="alert alert-error"><button data-dismiss="alert" class="close" type="button">×</button><strong>Warning!</strong> Zum Speichern muss mindestens der Titel und ein Text Vorhanden sein.</div>';
    include 'templates/neuerBeitrag.tpl';
}
?>
<script src="assets/js/bootstrap-carousel.js"></script>
<script src="assets/js/bootstrap-datepicker.js"></script>
<link href="assets/css/datepicker.css" type="text/css" rel="stylesheet" />
<?php
    $baseFolderPath = dirname($_SERVER['SCRIPT_FILENAME']).'/server/files/';
    
    db_connect();
    $query = "SELECT * FROM bilderBeitrag WHERE aktiv = \"1\" ORDER BY datum DESC";
    $ergebnis = mysql_query($query);
        
    if (!$ergebnis) {
        die('Konnte Abfrage nicht ausführen:' . mysql_error());
    }
    while ($row = mysql_fetch_array($ergebnis, MYSQL_ASSOC)) {
        echo '<div class="span7 offset2" style="margin-top:30px;">';
        echo '<h2 style="float:left">' . $row["titel"] . '</h2>';
        echo '<a style="float:right; margin-left:10px;" href="?old='. $row["uploadFolderName"] .'">edit</a>
              <a style="float:right" href="?del='. $row["uploadFolderName"] .'" onclick="return confirm(\'Das Löschen kann nicht rückgängig gemacht werden! Wollen sie wirklich löschen?\');">Löschen</a>';
        if($row["unterTitel"] != ""){
            echo '<h4 style="clear:both">'. $row["unterTitel"] .'</h4>';
        }
        echo '<p style="clear:both">' . str_replace("\r\n", "<br>", $row["text"]) . '</p><br />';
        $id = getCarouselHead();
        $folderName = $baseFolderPath . $row["uploadFolderName"] . "/";
        if ($handle = opendir($folderName)) {
            $erstesBildItem = "active";
            while (false !== ($file = readdir($handle))) {
                if($file !== '.' && $file !== '..' && !is_dir($folderName . $file)){
                  echo "<div class=\"item " . $erstesBildItem . "\">" . "<img src=\"server/files/" . $row["uploadFolderName"] . "/" . $file . "\" style=\"display: block; margin-left: auto; margin-right: auto\"></div>";
                  $erstesBildItem = "";
                }
            }
            closedir($handle);
        }
        getCarouselEnd($id);
        echo '</div>';
    }
?>
<?php include 'templates/footer.tpl'; ?>