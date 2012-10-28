<?php
require_once('utils.php');
// Schauen, ob in der URL ein Datum angegeben ist und den Seitentitel entsprechend ändern und danach Date in ein MySQL-kompatibles Format umwandeln
if (isset($_GET['date'])) {
    $date = mysql_real_escape_string($_GET['date']);
    $current_site = 'Termine am ' . $date;
    $date = date_to_mysql($date);
} else {
    $current_site = 'Keine Termine';
}
include 'templates/header.tpl';
$db = new_db_o();


// MySQL-Vorbereitung für die Termin-Vorbereitung
$sql = 'SELECT `date`, `title`, `description`, `start_time`, `end_time`  FROM `events` WHERE `date` = ? ORDER BY `date`';
$ergebnis = $db->prepare($sql);
$ergebnis->bind_param('s', $date);
$ergebnis->execute();
$ergebnis->bind_result($output_date, $output_title, $output_description, $output_start_time, $output_end_time);
?>
<h2><? echo $current_site; ?></h2>
<table class="table">
    <tr>
        <td><b>Datum und Zeit</b></td>
        <td><b>Titel</b></td>
        <td><b>Beschreibung</b></td>
    </tr>
    <?php
    while ($ergebnis->fetch()) {
        echo '<tr><td>' . mysql_to_date($output_date);
        if (!$output_start_time == '00:00:00' && !$output_end_time == '00:00:00') {
            echo '<br />von ' . $output_start_time . ' Uhr bis ' . $output_end_time . ' Uhr';
        }
        echo '</td><td>' . $output_title . '</td><td>';
        if (isset($output_description)) {
            echo $output_description;
        } else {
            echo '&nbsp;';
        }
        echo '</td></tr>';
    }
    ?>
</table>
<?php
include 'templates/footer.tpl';
?>
