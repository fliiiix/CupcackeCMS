<?php
$current_site = "Termine";
include 'templates/header.tpl';
require_once('utils.php');
db_connect();

# Nicht eigeloggte User rauswerfen, sonst valide User-ID speichern
if (verify_user() == false) {
    header("Location: index.php");
    exit();
} else {
    $valid_user_id = verify_user();
}

# Nutzernamen des Nutzers feststellen
$username = current_username($valid_user_id);

# Neuen Termin speichern, wenn alle Pflicht-Felder ausgefüllt sind, wenn Pflicht-Felder fehlen eine Fehlermeldung ausgeben
// Create Mysqli object
$db = new mysqli('localhost', 'root', '', 'cupcackecms');
// Create statement object
$stmt = $db->stmt_init();
 
// Create a prepared statement
if($stmt->prepare("SELECT `name`, `vorname` FROM `user` WHERE `email` = ?")) {
 
    // Bind your variable to replace the ?
    $stmt->bind_param('i', $email);
 
    // Set your variable	
    $email = 'kon.fischer@ymail.com';
 
    // Execute query
    $stmt->execute();
    
    // Bind your result columns to variables
    $stmt->bind_result($user_email);
    
        while($stmt->fetch()) {
            echo "trolololo";
        echo $email; // John Doe - Unknown...
    }
 
    // Close statement object
   $stmt->close();
}
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
                            <input class="span2" size="16" type="text" value="<?php echo date('d\.m\.Y'); ?>" name="date">
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
                            <input type="text" class="timepicker-default input-small" name="start_time">
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
                            <input type="text" class="timepicker-default input-small" name="end_time">
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
                        <input class="btn btn-primary" name="new_event" type="submit" value="Neuen Termin eintragen">
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
                <td><b>Erstellt von</b></td>
                <td></td>
            </tr>
        </table>
    </div>
</div>
<?php
include 'templates/footer.tpl';
?>