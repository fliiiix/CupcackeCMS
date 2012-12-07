<?php

session_start();
require ('utils.php');
$current_site = "Bildergalerie";
include 'templates/header.tpl';
$db = new_db_o();

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

if (!isset($_GET["neu"]) && !isset($_GET["fail"]) && !isset($_GET["old"]) && $admin) {
    echo '<div class="span11">
            <a href="bilderGalerie.php?neu" class="btn btn-primary">Neuer Beitrag</a><br>
          </div>';
}

function getCarouselHead() {
    $idGuid = guid();
    echo '<div id="' . $idGuid . '" class="carousel slide span7" data-interval="false" style="display: block; margin-left: auto; margin-right: auto">
                <div class="carousel-inner">';
    return $idGuid;
}

function getCarouselEnd($id) {
    echo '</div>
                <a class="carousel-control left" href="#' . $id . '" data-slide="prev">&lsaquo;</a>
                <a class="carousel-control right" href="#' . $id . '" data-slide="next">&rsaquo;</a>
            </div>';
}

function hasFileToDownload($guid){
    $baseFolderPath = 'server/files/';
    $folderName = $baseFolderPath . escape($guid) . "/";
    $inline_file_types = '/\.(gif|jpe?g|png)$/i';
    $counter = 0;
    
    if (($handle = opendir($folderName))) {
        while (false !== ($file = readdir($handle)) || $counter == 1) {
            if (preg_match($inline_file_types, $file)) {
                  $counter++;
            }
        }
    }
    return $counter != 0;
}

if(isset($_GET["dl"]) && $_GET["dl"] != ""){
    $baseFolderPath = 'server/files/';
    $folderName = $baseFolderPath . escape($_GET["dl"]) . "/";
    $zipFolderName = "bilder.zip";
    $inline_file_types = '/\.(gif|jpe?g|png)$/i';
    
    $zip = new ZipArchive;
    $zip->open($folderName . $zipFolderName, ZIPARCHIVE::OVERWRITE);
    
    if (($handle = opendir($folderName))) {
        while (false !== ($file = readdir($handle))) {
            if (preg_match($inline_file_types, $file)) {
                  $zip->addFile($folderName . $file, $file);  
            }
        }
    }
    
    closedir($handle);
    $zip->close();

    $zipfile = $folderName . $zipFolderName;
    header('Content-Type: application/zip');
    header('Content-disposition: attachment; filename="' . $zipFolderName . '"');
    header('Content-Length: ' . filesize($zipfile));
    ob_clean();
    flush();
    echo readfile($zipfile);
    unset($zipfile);
}

if (isset($_POST["beitragTitel"]) && isset($_POST["beitragUnterTitel"]) && isset($_POST["beitragText"]) && $admin) {
    if ($_POST["beitragTitel"] != "" && $_POST["beitragText"] != "") {
        $titel = escape($_POST["beitragTitel"]);
        $unterTitel = escape($_POST["beitragUnterTitel"]);
        $text = escape($_POST["beitragText"]);
        $datum = date_to_mysql(escape($_POST['event_date']));
        $uploadFolder = escape($_SESSION["uploadFolder"]);
        
        if (isset($_SESSION["editOld"]) && $_SESSION["editOld"] == TRUE) {
            $sql = 'UPDATE `bilderBeitrag` SET `titel`=?, `unterTitel`=?, `text`=?, `datum`=? WHERE `uploadFolderName`=?';
            $eintrag = $db->prepare($sql);
            $eintrag->bind_param('sssss', $titel, $unterTitel, $text, $datum, $uploadFolder);
            $eintrag->execute();
            $_SESSION["editOld"] = FALSE;
        } 
        else {
            $aktiv = 1;
            $sql = 'INSERT INTO `bilderBeitrag` (`titel`, `unterTitel`, `text`, `uploadFolderName`, `ownerId`, `aktiv`, `datum`) VALUES (?,?,?,?,?,?,?)';
            $eintrag = $db->prepare($sql);
            $eintrag->bind_param('ssssiis', $titel, $unterTitel, $text, $uploadFolder, $valid_user_id, $aktiv, $datum);
            $eintrag->execute();
        }
        $eintrag->close();
    } else {
        $_SESSION["beitragTitel"] = escape($_POST["beitragTitel"]);
        $_SESSION["beitragUnterTitel"] = escape($_POST["beitragUnterTitel"]);
        $_SESSION["beitragText"] = escape($_POST["beitragText"]);
        $_SESSION["datum"] = date_to_mysql(escape($_POST['event_date']));
        header("Location: ?fail");
    }
}

if (isset($_GET["del"]) && $_GET["del"] != "" && $admin) {
    $uploadFolder = escape($_GET["del"]);
    $sql = 'DELETE FROM `bilderBeitrag` WHERE `uploadFolderName`=?';
    $eintrag = $db->prepare($sql);
    $eintrag->bind_param('s', $uploadFolder);
    $eintrag->execute();
    $eintrag->close();
    empty_get($_SERVER['PHP_SELF']);
}

#get und session stuff
if (isset($_GET["neu"]) && getUserRolle($valid_user_id) == 2) {
    $_SESSION["uploadFolder"] = guid();
    include 'templates/neuerBeitrag.tpl';
}
if (isset($_GET["old"]) && $_GET["old"] != "" && getUserRolle($valid_user_id) == 2) {
    $_SESSION["uploadFolder"] = $_GET["old"];
    $_SESSION["editOld"] = TRUE;
    
    $uploadFolder = escape($_GET["old"]);
    $sql = 'SELECT `titel`, `untertitel`, `text`, `datum` FROM `bilderBeitrag` WHERE `uploadFolderName`=?';
    $SQLAbfrage = $db->prepare($sql);
    $SQLAbfrage->bind_param('s', $uploadFolder);
    $SQLAbfrage->execute();
    if ($SQLAbfrage->affected_rows) {
        $SQLAbfrage->bind_result($beitragTitel, $beitragUnterTitel, $beitragtext, $datum);
        $SQLAbfrage->fetch();
        $datum = date_format(date_create($datum), "d.m.Y");
        $beitragtext = str_replace("\\r\\n", "\r\n", $beitragtext);
    }
    $SQLAbfrage->close();
    include 'templates/neuerBeitrag.tpl';
}
if (isset($_GET["fail"]) && $admin) {
    $beitragTitel = isset($_SESSION["beitragTitel"]) ? $_SESSION["beitragTitel"] : "";
    $beitragUnterTitel = isset($_SESSION["beitragUnterTitel"]) ? $_SESSION["beitragUnterTitel"] : "";
    $beitragtext = isset($_SESSION["beitragText"]) ? $_SESSION["beitragText"] : "";
    echo '<div class="alert alert-error"><button data-dismiss="alert" class="close" type="button">×</button>Zum Speichern muss mindestens der Titel und ein Text Vorhanden sein.</div>';
    include 'templates/neuerBeitrag.tpl';
}
?>
<script src="assets/js/bootstrap-carousel.js"></script>
<script src="assets/js/bootstrap-datepicker.js"></script>
<link href="assets/css/datepicker.css" type="text/css" rel="stylesheet" />
<?php

$baseFolderPath = 'server/files/';

$sql = 'SELECT `titel`, `uploadFolderName`, `unterTitel`, `text` FROM `bilderBeitrag` WHERE `aktiv`=1 ORDER BY `datum` DESC';
$ergebnis = $db->prepare($sql);
$ergebnis->execute();
if ($ergebnis->affected_rows == 0) {
    die('Konnte Abfrage nicht ausführen:' . mysql_error());
}
$ergebnis->bind_result($titel, $uploadFolderName, $unterTitel, $text);
while ($ergebnis->fetch()) {
    $output = "";
    echo '<div class="span7 offset2" style="margin-top:30px;">';
    echo '<h2 style="float:left">' . $titel . '</h2>';
    if(hasFileToDownload($uploadFolderName)){
        echo '<a style="float:right; margin-left:10px;" href="?dl=' . $uploadFolderName . '">Herunterladen</a>';
    }
    
    if ($admin) {
        echo '<a style="float:right; margin-left:10px;" href="?old=' . $uploadFolderName . '">edit</a>
                  <a style="float:right" href="?del=' . $uploadFolderName . '" onclick="return confirm(\'Das Löschen kann nicht rückgängig gemacht werden! Wollen sie wirklich löschen?\');">Löschen</a>';
    }
    if ($unterTitel != "") {
        echo '<h4 style="clear:both">' . $unterTitel . '</h4>';
    }
    echo '<p style="clear:both">' . str_replace("\\r\\n", "<br>", $text) . '</p><br />';
    
    $folderName = $baseFolderPath . $uploadFolderName . "/";
    if (($handle = opendir($folderName))) {
        $erstesBildItem = "active";
        while (false !== ($file = readdir($handle))) {
            if ($file !== '.' && $file !== '..' && !is_dir($folderName . $file) && $file !== ".htaccess") {
                $output .= "<div class=\"item " . $erstesBildItem . "\">" . "<img src=\"server/files/" . $uploadFolderName . "/medium/" . $file . "\" style=\"display: block; margin-left: auto; margin-right: auto;\"></div>";
                $erstesBildItem = "";
            }
        }
        closedir($handle);
    }
    
    if($output != "")
    {
        $id = getCarouselHead();
        echo $output;
        getCarouselEnd($id);
    }
    echo '</div>';
}
?>
<?php include 'templates/footer.tpl'; ?>