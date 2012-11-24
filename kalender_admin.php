<?php
$current_site = "Terminverwaltung";
include 'templates/header.tpl';
require_once('utils.php');
$db = new_db_o();

# Nicht eigeloggte User rauswerfen, sonst valide User-ID speichern
$result = verify_user();
if ($result == false) {
    header("Location: index.php");
    exit();
} else {
    $valid_user_id = $result;
}

# Nutzernamen des Nutzers feststellen
$username = current_username($valid_user_id);

# $_GET leeren
# empty_get($_SERVER['PHP_SELF']);

# Termin löschen, wenn der entsprechende Button geklickt wird
if (isset($_GET['del'])) {
    $del_event_id = mysql_real_escape_string($_GET['del']);
    $sql = 'DELETE FROM `events` WHERE id = ?';
    $query = $db->prepare($sql);
    $query->bind_param('s', $del_event_id);
    $query->execute();
}

# Geänderten Termin speichern, wenn der entsprechende Button geklickt wird
# Erst überprüfen, welche Felder sich überhaupt geändert haben um nur diese dann in die Datenbank zu schreiben
if (isset($_POST['edit_event'])){
    $sql = 'UPDATE events SET';
    $new_values = 0;
    if ($_POST['edit_event_date'] != $old_date){
        $new_date = date_to_mysql(mysql_real_escape_string($_POST['edit_event_title']));
        $sql .= ' date=';
    }
    if ($_POST['edit_event_title'] != $old_title){
        $new_title = mysql_real_escape_string($_POST['edit_event_title']);
        $sql .= ' title="' . $new_title . '",';
    }
    if ($_POST['edit_event_description'] != $old_description){
        $new_description = mysql_real_escape_string($_POST['edit_event_description']);
        $sql .= ' description="' . $new_description . '",';
    }
    
}

# Neuen Termin speichern, wenn alle Pflicht-Felder ausgefüllt sind, wenn Pflicht-Felder fehlen eine Fehlermeldung ausgeben
if (isset($_POST['create_event'])) {
    if (isset($_POST['event_title']) && $_POST['event_title'] != "" && isset($_POST['event_date']) && $_POST['event_date'] != "") {
        $event_title = mysql_real_escape_string($_POST['event_title']);
        $event_date = date_to_mysql(mysql_real_escape_string($_POST['event_date']));

        if (!($_POST['startTime'] == $_POST['endTime'])) {
            $event_startTime = mysql_real_escape_string($_POST['startTime']);
            $event_endTime = mysql_real_escape_string($_POST['endTime']);
        } else {
            $event_startTime = '0';
            $event_endTime = '0';
        }

        if (isset($_POST['event_description'])) {
            $event_description = mysql_real_escape_string($_POST['event_description']);
        }
        $sql = 'INSERT INTO `events` (`date`, `title`, `description`, `startTime`, `endTime`, `lastEditor`) VALUES (?, ?, ?, ?, ?, ?)';
        $eintrag = $db->prepare($sql);
        $eintrag->bind_param('sssssi', $event_date, $event_title, $event_description, $event_startTime, $event_endTime, $valid_user_id);

        $eintrag->execute();

        // Prüfen ob der Eintrag efolgreich war
        if ($eintrag->affected_rows == 1) {
            $success_msg = 'Der neue Eintrag wurde hinzugef&uuml;gt.';
        } else {
            $error_msg = 'Der Eintrag konnte nicht hinzugef&uuml;gt werden.';
        }
    } else {
        $error_msg = 'Bitte alle Pflichtfelder ausfüllen';
    }
}

// MySQL-Vorbereitung für die Termine-Tabelle
$sql = 'SELECT `id`, `date`, `title`, `description`, `startTime`, `endTime`, `lastEditor` FROM `events` ORDER BY `date`';
$ergebnis = $db->prepare($sql);
$ergebnis->execute();
$ergebnis->bind_result($output_id, $output_date, $output_title, $output_description, $output_startTime, $output_endTime, $output_lastEditor);
?>
<script src="assets/js/bootstrap-datepicker.js"></script>
<script src="assets/js/bootstrap-timepicker.js"></script>
<link href="assets/css/timepicker.css" type="text/css" rel="stylesheet" />
<link href="assets/css/datepicker.css" type="text/css" rel="stylesheet" />

<script type="text/javascript">
    $(document).ready(function(){ 
        $('.timepicker-default').timepicker({
            showMeridian: false
        });
        $('.datepicker').datepicker();
    });
</script>

<div class="row">
    <div class="span4">
        <h2>Neuen Termin erstellen</h2>
        <?php
        if (isset($success_msg)) {
            echo '<div class="alert alert-success"><button type="button" class="close" data-dismiss="alert">×</button>' . $success_msg . '</div>';
        }
        if (isset($error_msg)) {
            echo '<div class="alert alert-error"><button type="button" class="close" data-dismiss="alert">×</button>' . $error_msg . '</div>';
        }
        ?>
        <form method="post">
            <table>
                <tr>
                    <td><input class="input" style="margin-bottom:0px;" name="event_title" id="event_title" type="text" placeholder="Termin-Titel" maxlength="100"></td>
                    <td><i class="icon-asterisk"></i></td>
                </tr>
                <tr>
                    <td><textarea name="event_description" cols="50" rows="10" placeholder="Termin-Beschreibung"></textarea></td>
                    <td>&nbsp;</td>
                </tr>
                <tr>
                    <td>
                        <div class="input-append date datepicker" id="dp3" data-date="<?php echo date('d\.m\.Y'); ?>" data-date-format="dd.mm.yyyy">
                            <input class="span2" size="16" type="text" value="<?php echo date('d\.m\.Y'); ?>" name="event_date">
                            <span class="add-on"><i class="icon-th"></i></span>
                        </div>
                    </td>
                    <td>
                        <i class="icon-asterisk"></i>
                    </td>
                </tr>
                <tr>
                    <td>
                        Startzeit:
                        <div class="input-append bootstrap-timepicker-component">
                            <input type="text" class="timepicker-default input-small" name="startTime" id="startTime">
                            <span class="add-on">
                                <i class="icon-time"></i>
                            </span>
                        </div>
                    </td>
                    <td>&nbsp;</td>
                </tr>
                <tr>
                    <td>
                        Endzeit:
                        <div class="input-append bootstrap-timepicker-component">
                            <input type="text" class="timepicker-default input-small" name="endTime" id="endTime">
                            <span class="add-on">
                                <i class="icon-time"></i>
                            </span>
                        </div>
                    </td>
                    <td>&nbsp;</td>
                </tr>
                <tr>
                    <td colspan="2">
                        <i class="icon-asterisk"></i> = Pflichtfeld
                    </td>
                </tr>
                <tr>
                    <td>
                        <input class="btn btn-primary" name="create_event" type="submit" value="Neuen Termin eintragen">
                    <td>&nbsp;</td>
                    </td>
                </tr>
            </table>
        </form>
    </div>
    <div class="span8">
        <h2>Termine</h2>
        <table class="table">
            <tr>
                <td><b>Datum und Zeit</b></td>
                <td><b>Titel</b></td>
                <td><b>Beschreibung</b></td>
                <td><b>Zuletzt bearbeitet von</b></td>
                <td>&nbsp;</td>
                <td>&nbsp;</td>
            </tr>
            <?php
            while ($ergebnis->fetch()) {
                if (isset($_GET['edit']) && $_GET['edit'] == $output_id) {
                    # Momentane Daten des Termins in Variablen schreiben um nachdem der Nutzer das Ändern-Fomular abgeschickt hat feststellen zu können, ob er etwas geändert hat
                    $old_date = $output_date;
                    $old_title = $output_title;
                    $old_description = $output_description;
                    $old_startTime = $output_startTime;
                    $old_endTime = $output_endTime;
                    $edit_event_id = mysql_real_escape_string($_GET['edit']);
                    
                    $edit_output ='<tr><td>';
                    $edit_output .=  '<div class="input-append date datepicker" id="dp4" data-date="' . mysql_to_date($output_date) . '" data-date-format="dd.mm.yyyy">';
                    $edit_output .=    '<input class="span2" size="16" type="text" value="' . mysql_to_date($output_date) . '" name="edit_event_date">';
                    $edit_output .=    '<span class="add-on"><i class="icon-th"></i></span>';
                    $edit_output .=  '</div><br />';
                    if ($output_startTime != 0){
                    $edit_output .=  'Start:';
                    $edit_output .=  '<div class="input-append bootstrap-timepicker-component">';
                    $edit_output .=    '<input type="text" class="timepicker-default input-small" name="edit_startTime" id="edit_startTime" value="' . $output_startTime . '">';
                    $edit_output .=    '<span class="add-on">';
                    $edit_output .=      '<i class="icon-time"></i>';
                    $edit_output .=    '</span>';
                    $edit_output .=  '</div>';
                    $edit_output .=  'Ende:';
                    $edit_output .=  '<div class="input-append bootstrap-timepicker-component">';
                    $edit_output .=    '<input type="text" class="timepicker-default input-small" name="edit_endTime" id="edit_endTime" value="' . $output_endTime . '">';
                    $edit_output .=    '<span class="add-on">';
                    $edit_output .=      '<i class="icon-time"></i>';
                    $edit_output .=    '</span>';
                    $edit_output .=  '</div>';
                    }
                    $edit_output .='</td>';
                    $edit_output .='<td>';
                    $edit_output .=  '<input class="input" name="edit_event_title" id="edit_event_title" type="text" value="' . $output_title . '" maxlength="100">';
                    $edit_output .='</td>';
                    $edit_output .='<td>';
                    $edit_output .=  '<textarea name="edit_event_description" cols="50" rows="10">' . $output_description . '</textarea>';
                    $edit_output .='</td>';
                    $edit_output .='<td>';
                    $edit_output .=  get_username($output_lastEditor) . '<br />';
                    $edit_output .=  '<input class="btn btn-primary" name="edit_event" type="submit" value="Termin ändern">';
                    $edit_output .='</td>';
                    echo $edit_output;
                } else {
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
                    $output .= '</td><td>' . get_username($output_lastEditor) . '</td>';
                    $output .= '<td><a href="?edit=' . $output_id . '" class="btn btn-inverse"><i class="icon-edit icon-white"></i></a>';
                    $output .= '<td><a href="?del=' . $output_id . '" class="btn btn-danger"><i class="icon-remove-circle"></i></a>';
                    echo $output;
                }
            }
            ?>
        </table>
    </div>
</div>
<?php
// Datenbankverbindung schliessen
$db->close();

include 'templates/footer.tpl';
?>