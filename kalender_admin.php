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

# Neuen Termin speichern, wenn alle Pflicht-Felder ausgefüllt sind, wenn Pflicht-Felder fehlen eine Fehlermeldung ausgeben
if (isset($_POST['create_event'])) {
    if (!isset($_POST['event_title']) || !isset($_POST['event_date'])) {
        $error_msg = 'Bitte alle Pflichtfelder ausfüllen';
    } else {
        $event_title = mysql_real_escape_string($_POST['event_title']);
        $event_date = date_to_mysql(mysql_real_escape_string($_POST['event_date']));

        // Start- und Endzeit sind zusätzlich zu den Pflichtfeldern angegeben
        if (isset($_POST['start_time']) && $_POST['end_time']) {
            $event_start_time = mysql_real_escape_string($_POST['start_time']) . ':00';
            $event_end_time = mysql_real_escape_string($_POST['end_time']) . ':00';

            // Zusätzlich ist noch die Beschreibung angegeben
            if (isset($_POST['event_description'])) {
                $event_description = mysql_real_escape_string($_POST['event_description']);
                $sql = 'INSERT INTO `events` (`date`, `title`, `description`, `start_time`, `end_time`, `last_editor`) VALUES (?, ?, ?, ?, ?, ?)';
                $eintrag = $db->prepare($sql);
                $eintrag->bind_param('sssssi', $event_date, $event_title, $event_description, $event_start_time, $event_end_time, $valid_user_id);

                // oder auch nicht
            } else {
                $sql = 'INSERT INTO `events` (`date`, `title`, `start_time`, `end_time`, `last_editor`) VALUES (?, ?, ?, ?, ?)';
                $eintrag = $db->prepare($sql);
                $eintrag->bind_param('ssssi', $event_date, $event_title, $event_start_time, $event_end_time, $valid_user_id);
            }
        }

        //Nur die Beschreibung ist zusätzlich zu den Pflichtfeldern angegeben
        if (isset($_POST['event_description'])) {
            $event_description = mysql_real_escape_string($_POST['event_description']);
            $sql = 'INSERT INTO `events` (`date`, `title`, `description`,  `last_editor`) VALUES (?, ?, ?, ?)';
            $eintrag = $db->prepare($sql);
            $eintrag->bind_param('sssi', $event_date, $event_title, $event_description, $valid_user_id);
        }
        $eintrag->execute();

        // Prüfen ob der Eintrag efolgreich war
        if ($eintrag->affected_rows == 1) {
            $success_msg = 'Der neue Eintrag wurde hinzugef&uuml;gt.';
        } else {
            $error_msg = 'Der Eintrag konnte nicht hinzugef&uuml;gt werden.';
        }
    }
}

// MySQL-Vorbereitung für die Termine-Tabelle
$sql = 'SELECT `date`, `title`, `description`, `start_time`, `end_time`, `last_editor` FROM `events` ORDER BY `date`';
$ergebnis = $db->prepare($sql);
$ergebnis->execute();
$ergebnis->bind_result($output_date, $output_title, $output_description, $output_start_time, $output_end_time, $output_last_editor);
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
                            <input type="text" class="timepicker-default input-small" name="start_time" id="start_time">
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
                            <input type="text" class="timepicker-default input-small" name="end_time" id="end_time">
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
                echo '</td><td>' . get_username($output_last_editor) . '</td></tr>';
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