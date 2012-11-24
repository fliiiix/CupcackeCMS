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


// MySQL-Vorbereitung für die Termin-Ausgabe
$sql = 'SELECT `date`, `title`, `description`, `startTime`, `endTime`  FROM `events` WHERE `date` = ? ORDER BY `date`';
$ergebnis = $db->prepare($sql);
$ergebnis->bind_param('s', $date);
$ergebnis->execute();
$ergebnis->bind_result($output_date, $output_title, $output_description, $output_startTime, $output_endTime);
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
        $output = '<tr><td>' . mysql_to_date($output_date);
        if ($output_startTime != 0 && $output_endTime != 0) {
            $output .= '<br />von ' . $output_startTime . ' Uhr bis ' . $output_endTime . ' Uhr';
        }
        $output .= '</td><td>' . $output_title . '</td><td>';
        if (isset($output_description)) {
            $output .= $output_description;
        } else {
            $output .= '&nbsp;';
        }
        $output .= '</td>';
        echo $output;
    }
    ?>
</table>
<?php
include 'templates/footer.tpl';
?>
