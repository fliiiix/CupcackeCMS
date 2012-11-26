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
    $admin = FALSE;
    $admin = getUserRolle($valid_user_id) == 2;
}

if(!isset($_GET["neu"]) && !isset($_GET["fail"]) && !isset($_GET["old"]) && $admin)
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

if (isset($_POST["beitragTitel"]) && isset($_POST["beitragUnterTitel"]) && isset($_POST["beitragText"]) && $admin){
    if($_POST["beitragTitel"] != "" && $_POST["beitragText"] != "") {
        $db = new_db_o();
        if(isset($_SESSION["editOld"]) && $_SESSION["editOld"] == TRUE){
            $titel = mysql_real_escape_string($_POST["beitragTitel"]);
            $unterTitel = mysql_real_escape_string($_POST["beitragUnterTitel"]);
            $text = mysql_real_escape_string($_POST["beitragText"]);
            $datum = date_to_mysql(mysql_real_escape_string($_POST['event_date']));
            $uploadFolder = mysql_real_escape_string($_SESSION["uploadFolder"]);
            
            $sql = 'UPDATE `bilderBeitrag` SET `titel`=?, `unterTitel`=?, `text`=?, `datum`=? WHERE `uploadFolderName`=?';
            $eintrag = $db->prepare($sql);
            $eintrag->bind_param('sssss', $titel, $unterTitel, $text, $datum, $uploadFolder);
            $eintrag->execute();
            $_SESSION["editOld"] = FALSE;
            if ($eintrag->affected_rows == 0) {
                # Sollte in der finalen Version raus, keine Debug-Ausgaben für Nutzer!
                die('Der Post konnte nicht verändert werden werden: ' . mysql_error());
            } 
        }
        else {
            $titel = mysql_real_escape_string($_POST["beitragTitel"]);
            $unterTitel = mysql_real_escape_string($_POST["beitragUnterTitel"]);
            $text = mysql_real_escape_string($_POST["beitragText"]);
            $uploadFolder = mysql_real_escape_string($_SESSION["uploadFolder"]);
            $aktiv = 1;
            $datum = date_to_mysql(mysql_real_escape_string($_POST['event_date']));
            
            $sql = 'INSERT INTO `bilderBeitrag` (`titel`, `unterTitel`, `text`, `uploadFolderName`, `ownerId`, `aktiv`, `datum`) VALUES (?,?,?,?,?,?,?)';
            $eintrag = $db->prepare($sql);
            $eintrag->bind_param('ssssiis', $titel, $unterTitel, $text, $uploadFolder, $valid_user_id, $aktiv, $datum);
            $eintrag->execute();
            if ($eintrag->affected_rows == 0) {
                # Siehe oben
                die('Der Post konnte nicht gespeichert werden: ' . mysql_error());
            } 
        }
    }
    else {
        $_SESSION["beitragTitel"] = mysql_real_escape_string($_POST["beitragTitel"]);
        $_SESSION["beitragUnterTitel"] = mysql_real_escape_string($_POST["beitragUnterTitel"]);
        $_SESSION["beitragText"] = mysql_real_escape_string($_POST["beitragText"]);
        $_SESSION["datum"] = date_to_mysql(mysql_real_escape_string($_POST['event_date']));
        header("Location: ?fail");
    }
}

if(isset($_GET["del"]) && $_GET["del"] != "" && $admin){
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
if(isset($_GET["fail"]) && $admin) {
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
        if($admin) {
            echo '<a style="float:right; margin-left:10px;" href="?old='. $row["uploadFolderName"] .'">edit</a>
                  <a style="float:right" href="?del='. $row["uploadFolderName"] .'" onclick="return confirm(\'Das Löschen kann nicht rückgängig gemacht werden! Wollen sie wirklich löschen?\');">Löschen</a>';
        }
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