
<?php 
session_start();
error_reporting(E_ALL | E_STRICT);

if (isset($_GET["id"])) {
	$beitragsID = $_GET["id"];
}
else
{
	$beitragsID = 0;
}
$_SESSION['id_beitrag'] = $beitragsID;
include 'templates/header.tpl'; 
echo($beitragsID);

/*echo "<br \>ding<br \>";
print_r($info);  
echo count($info);*/

if (isset($_POST["beitragTitel"]) && isset($_POST["beitragUnterTitel"]) && isset($_POST["beitragText"])){
    /*$beitragTitel = $_POST["beitragTitel"];
    $beitragUnterTitel = $_POST["beitragUnterTitel"];   
    $beitragText = $_POST["beitragText"];
    
    echo $beitragTitel . "+" . $beitragUnterTitel . "+" .  $beitragText . "++" . $_SESSION['result'];//. "**" . $_SESSION['ding'];
    echo "ist die session =\"" . $_SESSION['dings'];*/
    //$_SESSION['folderName'] = "neu";
}
?>
<a href="bilderGalerie.php?neu=true">link</a>
<?php if(isset($_GET["neu"]) && $_GET["neu"] == "true") {
    include 'templates/neuerBeitrag.tpl';
}?>
<?php include 'templates/footer.tpl'; ?>