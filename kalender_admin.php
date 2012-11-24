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
    if(getUserRolle($valid_user_id) != 2){
        header("Location: index.php");
        exit();
    }
}

# Nutzernamen des Nutzers feststellen
$username = current_username($valid_user_id);

# $_GET leeren
# empty_get($_SERVER['PHP_SELF']);
# Termin löschen, wenn der entsprechende Button geklickt wird
if (isset($_GET['del']) && $admin) {
    $del_event_id = mysql_real_escape_string($_GET['del']);
    $sql = 'DELETE FROM `events` WHERE id = ?';
    $query = $db->prepare($sql);
    $query->bind_param('s', $del_event_id);
    $query->execute();
}

# Geänderten Termin speichern, wenn der entsprechende Button geklickt wird
if (isset($_POST['save_edited_event'])) {
    $new_date = date_to_mysql(mysql_real_escape_string($_POST['edit_event_date']));
    $new_title = mysql_real_escape_string($_POST['edit_event_title']);
    $new_description = mysql_real_escape_string($_POST['edit_event_description']);
    if (!($_POST['edit_event_startTime'] == $_POST['edit_event_endTime'])) {
        $new_startTime = mysql_real_escape_string($_POST['edit_event_startTime']);
        $new_endTime = mysql_real_escape_string($_POST['edit_event_endTime']);
    }
    $edit_event_id = intval($_GET['edit']);
    $sql = 'UPDATE events SET `date`=?, `title`=?, `description`=?, `startTime`=?, `endTime`=?, `lastEditor`=? WHERE `id`=?';
    $eintrag = $db->prepare($sql);
    $eintrag->bind_param('sssssii', $new_date, $new_title, $new_description, $new_startTime, $new_endTime, $valid_user_id, $edit_event_id);
    $eintrag->execute();
    if ($eintrag->affected_rows == 1) {
        $success_msg = 'Der Termin wurde erfolgreich editiert.';
        empty_get($_SERVER['PHP_SELF']);
    } else {
        $error_msg = 'Der Termin konnte nicht editiert werden.';
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
            $success_msg = 'Der neue Termin wurde erfolgreich hinzugef&uuml;gt.';
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
            minuteStep: 1,
            showMeridian: false
        });
        $('.timepicker-edit').timepicker({
            minuteStep: 1,
            defaultTime: 'value',
            showMeridian: false
        });
        $('.datepicker').datepicker();
    });
</script>

<div class="row">
    <div class="span12">
        <?php
        if (isset($success_msg)) {
            echo '<div class="alert alert-success"><button type="button" class="close" data-dismiss="alert">×</button>' . $success_msg . '</div>';
        }
        if (isset($error_msg)) {
            echo '<div class="alert alert-error"><button type="button" class="close" data-dismiss="alert">×</button>' . $error_msg . '</div>';
        }
        ?>
    </div>
</div>

<div class="row">
    <div class="span3">
        <h2>Neuer Termin</h2>
        <form method="post">
            <table>
                <tr>
                    <td><input class="input" style="margin-bottom:0px;" name="event_title" id="event_title" type="text" placeholder="Termin-Titel" maxlength="100"></td>
                </tr>
                <tr>
                    <td><textarea name="event_description" cols="50" rows="10" placeholder="Termin-Beschreibung"></textarea></td>
                </tr>
                <tr>
                    <td>
                        Datum:
                        <div style="margin-left: 0px; padding-left: 0px;" class="input-append date datepicker" id="dp3" data-date="<?php echo date('d\.m\.Y'); ?>" data-date-format="dd.mm.yyyy">
                            <input class="span2" size="16" type="text" value="<?php echo date('d\.m\.Y'); ?>" name="event_date">
                            <span class="add-on"><i class="icon-th"></i></span>
                        </div>
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
                </tr>
                <tr>
                    <td>
                        <input class="btn btn-primary" name="create_event" type="submit" value="Neuen Termin eintragen">
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
                    include 'templates/termin.tpl';
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