<?php
$current_site = "Termine";
include 'templates/header.tpl';
require_once('utils.php');
db_connect();

# Nicht eigeloggte User rauswerfen, sonst valide User-ID speichern
if (verify_user() == false){
  header("Location: index.php");
  exit();
}
else
{
    $valid_user_id = verify_user();
}

# Nutzernamen des Nutzers feststellen
$username = current_username($valid_user_id);
?>
<script src="assets/js/bootstrap-datepicker.js"></script>
<script src="assets/js/bootstrap-timepicker.js"></script>
<link href="assets/css/timepicker.css" type="text/css" rel="stylesheet" />
<link href="assets/css/datepicker.css" type="text/css" rel="stylesheet" />

<script>
      /* Update datepicker plugin so that MM/DD/YYYY format is used. */
      $.extend($.fn.datepicker.defaults, {
        parse: function (string) {
          var matches;
          if ((matches = string.match(/^(\d{2,2})\.(\d{2,2})\.(\d{4,4})$/))) {
            return new Date(matches[3], matches[2] - 1, matches[1]);
          } else {
            return null;
          }
        },
        format: function (date) {
          var
            month = (date.getMonth() + 1).toString(),
            dom = date.getDate().toString();
          if (month.length === 1) {
            month = "0" + month;
          }
          if (dom.length === 1) {
            dom = "0" + dom;
          }
          return dom + "." + month + "." + date.getFullYear();
        }
      });  
    </script>

<script type="text/javascript">
$(document).ready(function(){ 
    $('.timepicker-default').timepicker({
        showMeridian: false
    });
});
</script>
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
            <input class="small" type="text" value="Datum" data-datepicker="datepicker">
        </td>
        <td>
            <i class="icon-asterisk"></i>
        </td>
    </tr>
    <tr>
        <td>
            Startzeit:
            <div class="input-append bootstrap-timepicker-component">
                <input type="text" class="timepicker-default input-small">
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
                <input type="text" class="timepicker-default input-small">
                <span class="add-on">
                    <i class="icon-time"></i>
                </span>
            </div>
        </td>
        <td>&nbsp;</td>
    </tr>
    <tr>
        <td>
            <input class="btn btn-primary" name="new_event" type="submit" value="Neuen Termin eintragen">
            <td>&nbsp;</td>
        </td>
    </tr>
</table>
<?php 
include 'templates/footer.tpl';
?>