<?php
require_once('utils.php');
// Schauen, ob in der URL ein Datum angegeben ist und den Seitentitel entsprechend ändern und danach Date in ein MySQL-kompatibles Format umwandeln
if (isset($_GET['date'])) {
    $date = $_GET['date'];
    $current_site = 'Termine am ' . $date;
    $date = date_to_mysql($date);
} else {
    $current_site = 'Termine Übersicht';
}
include 'templates/header.tpl';
$db = new_db_o();

if (isset($date)) {
    $sql = 'SELECT `date`, `title`, `description`, `startTime`, `endTime`  FROM `events` WHERE `date` = ? ORDER BY `date`, `startTime`';
    $ergebnis = $db->prepare($sql);
    $ergebnis->bind_param('s', $date);
    $ergebnis->execute();
    $ergebnis->bind_result($output_date, $output_title, $output_description, $output_startTime, $output_endTime);
} else {
    $sql = 'SELECT `date`, `title`, `description`, `startTime`, `endTime`  FROM `events` WHERE `date` + 1 >= CURDATE()  ORDER BY `date`, `startTime`';
    $ergebnis = $db->prepare($sql);
    $ergebnis->execute();
    $ergebnis->bind_result($output_date, $output_title, $output_description, $output_startTime, $output_endTime);
}
?>
<h1><? echo $current_site; ?></h1>

<?php
$vorhergehendesDatum = NULL;
while ($ergebnis->fetch()) {
    if($vorhergehendesDatum != $output_date){
        if($vorhergehendesDatum != NULL){
            echo '</table>';
        }
        echo '<h3>' . mysql_to_date($output_date) . '</h3>';
        echo '<table class="table" style="margin-bottom: 20px;">
                <tr>
                    <td class="span2"><b>Titel</b></td>
                    <td class="span4"><b>Beschreibung</b></td>
                    <td class="span2"><b>Zeit</b></td>
                </tr>';
    }
    
    $output = '<tr><td>' . $output_title . '</td><td>';
    if (isset($output_description)) {
        $output .= str_replace("\\r\\n", "<br />", $output_description);
    } 
    else {
        $output .= '&nbsp;';
    }
    $output .= '</td>'; 
    
    if ($output_startTime != 0 && $output_endTime != 0) {
        $output .= '<td>von ' . $output_startTime . ' Uhr bis ' . $output_endTime . ' Uhr</td>';
    }
    else {
        $output .= '<td>&nbsp;</td>';
    }
    $output .= '</tr>';
    echo $output;
    
    $vorhergehendesDatum = $output_date;
}
?>
<?php include 'templates/footer.tpl'; ?>
