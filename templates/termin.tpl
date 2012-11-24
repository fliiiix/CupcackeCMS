<tr>
<form method="post">
    <td style="min-width: 210px;">
        <div style="margin: 0px; padding: 0px;" class="input-append date datepicker" id="dp4" data-date="<?php if(isset($output_date)){ echo mysql_to_date($output_date); } ?>" data-date-format="dd.mm.yyyy">
            <input class="span2" size="16" type="text" value="<?php if(isset($output_date)){ echo mysql_to_date($output_date); } ?>" name="edit_event_date">
            <span class="add-on"><i class="icon-th"></i></span>
        </div><br />
        Start:
        <div class="input-append bootstrap-timepicker-component">
            <input type="text" class="timepicker-edit input-small" name="edit_event_startTime" value="<?php if(isset($output_startTime)){ echo $output_startTime; } ?>">
            <span class="add-on">
                <i class="icon-time"></i>
            </span>
        </div>
        Ende:
        <div class="input-append bootstrap-timepicker-component">
            <input type="text" class="timepicker-edit input-small" name="edit_event_endTime" value="<?php if(isset($output_endTime)){ echo $output_endTime; } ?>">
            <span class="add-on">
                <i class="icon-time"></i>
            </span>
        </div>
    </td>
    <td>
        <input class="input" name="edit_event_title" id="edit_event_title" type="text" value="<?php if(isset($output_title)){ echo $output_title; } ?>" maxlength="100">
    </td>
    <td>
        <textarea name="edit_event_description" cols="80" rows="7"><?php if(isset($output_description)){ echo $output_description; } ?></textarea>
    </td>
    <td>
        <?php if(isset($username)){ echo $username; } ?>
    </td>
    <td>
        <input class="btn btn-primary" name="save_edited_event" id="save_edited_event" type="submit" value="Termin ändern">
    </td>
</form>
</tr>