<?php
$current_site = "Kalender";
include 'templates/header.tpl';
require_once('utils.php');
db_connect();
if (isset($_GET['m']) && (isset($_GET['y']))) {
	$calendar = calendar(intval($_GET['m']), intval($_GET['y']));
  echo $calendar['html'];
} else {
	$calendar = calendar(date('m'),date('Y'));
  echo $calendar['html'];
}
include 'templates/footer.tpl';
?>