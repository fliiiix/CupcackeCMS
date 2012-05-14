

# global stuff
@months_abv=("Jan.","Feb.","Mar.","Apr.","May","Jun.","Jul.","Aug.","Sept.","Oct.","Nov.","Dec.");
@months=("January","February","March","April","May","June","July","August","September","October","November","December");
@day_names = ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday");
@day_names_abv = ("Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat");

$lang{months_abv} = ["Jan.","Feb.","Mar.","Apr.","May","Jun.","Jul.","Aug.","Sept.","Oct.","Nov.","Dec."];
$lang{months} = ["January","February","March","April","May","June","July","August","September","October","November","December"];
$lang{day_names} = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
$lang{day_names_abv} = ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"];

$lang{am} = "am";
$lang{pm} = "pm";

$lang{charset} = "iso-8859-1";

$lang{custom_template_fail} = "Failed in attempt to load template file ###template###  Using default calendar template instead.";
$lang{default_template_fail} = "Default template file: ###template### does not appear to exist.";

$lang{tab_text} = ["Calendars", "Add Event", "Calendar Settings"];
             
             
$lang{logout} = "Logout";
$lang{login} = "Login";
$lang{submit} = "Submit";


# stuff on calendars controls
$lang{controls_change} = "Change!";
$lang{controls_start_month} = "Start month";
$lang{controls_num_months} = "Number of months to show:";
$lang{controls_calendar_label} = "Calendar:";
$lang{controls_display_label} = "Display:";

$lang{controls_display_type} = ["Calendar","List of events","Event details"];

# other stuff on calendars tab
$lang{previous_month} = "&lt; previous month";
$lang{previous_months} = "&lt; previous ###num### months";

$lang{next_month} = "next month &gt;";
$lang{next_months} = "next ###num### months &gt;";

$lang{add_event_on_this_day} = "Add event on this day";
$lang{add_event_to_this_calendar} = "Add an event to this calendar";
$lang{edit_calendar_options} = "Edit calendar options";
$lang{make_custom_calendar} = "Make a custom calendar";
$lang{subscribe_to_this_calendar} = "Subscribe to this calendar";

# custom calendar stuff
$lang{custom_calendar_title}  = "Custom Calendar";
$lang{custom_calendar_choose_calendar}  = "Choose Calendar";
$lang{custom_calendar_choose_bg_calendar}  = "Choose Background Calendar(s)";
$lang{custom_calendar_display_type}  = "View type?";
$lang{custom_calendar_time_range}  = "Time range:";
$lang{custom_calendar_make_calendar}  = "Make Calendar!";

# context menu stuff
$lang{context_menu_edit_event} = "Edit this event";
$lang{context_menu_clone_event} = "Clone this event";
$lang{context_menu_delete_event} = "Delete this event";

# stuff on add/edit calendars tab
$lang{tab2_view_calendar_details} = "View details for this calendar";
$lang{tab2_edit_delete} = "Edit this calendar";
$lang{tab2_view_new_calendars} = "View new calendars pending approval";
$lang{tab2_no_new_calendars} = "(none right now)";
$lang{tab2_some_new_calendars} = "(<b>###num###</b> in the file)";
$lang{tab2_select_a_calendar} = "Select a calendar:";

$lang{add_new_calendar} = "Add a New Calendar";
$lang{add_new_ical_calendar} = "Add a New iCal Calendar";
$lang{ical_url} = "iCal url";
$lang{add_ical} = "Add iCal!";   



$lang{edit} = "edit";
$lang{edit_calendar} = "Edit Calendar";
$lang{fields_text1} = "Fields";
$lang{fields_text2} = "this color";
$lang{fields_text3} = "are required.";

$lang{add_edit_calendars_tab0} = "Calendar Details";
$lang{add_edit_calendars_tab1} = "Other Calendars";
$lang{add_edit_calendars_tab2} = "Style & Appearance";
$lang{add_edit_calendars_tab3} = "Special Options";
$lang{add_edit_calendars_tab4} = "Users & Passwords";
$lang{help_on_this} = "help on this";

$lang{calendar_title} = "Calendar Title:";
$lang{calendar_link} = "Calendar Link:";
$lang{calendar_details} = "Calendar Details:";
$lang{preview_calendar_details} = "Preview Calendar Details";
$lang{preview_calendar_title} = "Calendar Preview";
$lang{preview_calendar_temp_title} = "Calendar title goes here!";
$lang{background_calendars2} = "(their events are displayed in the background)";
$lang{background_calendars3} = "Local merged calendars:";

$lang{remote_background_calendars_none} = "None!";
$lang{remote_background_calendars1} = "Remote merged calendars:";
$lang{get_remote_calendars} = "Add remote calendars";
$lang{check_remote_calendars_button} = "Check for available calendars";
$lang{get_remote_calendars_url} = "URL of plans installation to fetch remote calendar(s) from:";
$lang{get_remote_calendar2_singular} = "new remote calendar will be added to"; 
$lang{get_remote_calendar2_plural} = "new remote calendars will be added to"; 
$lang{get_remote_calendar3} = "Remove";

$lang{get_remote_calendar4} = "Remote calendar <b>###remote url###</b> id <b>###remote id###</b> <b>not</b> added (identical remote calendar already exists)";
$lang{get_remote_calendar5} = "Remote calendar <b>###remote url###</b> id <b>###remote id###</b> removed";

$lang{detect_remote_calendars1} = "Remotely mergable calendars at";
$lang{detect_remote_calendars2} = "Merge?";
$lang{detect_remote_calendars3} = "Requires Password";
$lang{detect_remote_calendars4} = "Merge selected calendars";
$lang{detect_remote_calendars5} = "No remote calendars found!";


$lang{selectable_calendars1} = "Selectable other calendars:";
$lang{selectable_calendars2} = "(dropdown list on main page)";
$lang{selectable_calendars3} = "Disabled";

$lang{new_calendars_automatically_selectable} = "Automatically make new calendars selectable ";
$lang{allow_remote_calendar_requests} = "Make this calendar available to other Plans installations";
$lang{remote_calendar_requests_password1} = "Require a password";

$lang{cal_events_display_style1} = "Calendar-wide display style:";
$lang{cal_events_display_style2} = "Calendar Color";
$lang{cal_events_display_style3} = "Calendar Icon";



$lang{bg_events_display_style1} = "Merged calendars display style:";
$lang{bg_events_display_style2} = "Normal";
$lang{bg_events_display_style3} = "Single Color";
$lang{bg_events_display_style4} = "Translucent";
$lang{bg_events_display_style5} = "Preview:";
$lang{bg_events_display_style6} = "Event";
$lang{bg_events_display_style7} = "Background Event";
$lang{bg_events_display_style8} = "All calendars together in list view";

$lang{default_number_of_months} = "Default number of months to display:";
$lang{max_months} = "Maximum number of months to display:";
$lang{timezone_offset} = "Timezone offset (in hours):";
$lang{date_format} = "Date Format:";
$lang{week_start_day} = "Week start day:";

$lang{event_change_email} = "Email on event add/change:"; 


$lang{popup_window_size1} = "Pop-up window size:";
$lang{popup_window_size2} = "(in pixels)";
$lang{custom_template} = "Custom template:";
$lang{custom_stylesheet} = "Custom stylesheet:";

$lang{existing_cal_password1} = "Valid Calendar Password:";
$lang{existing_cal_password2} = "For some existing calendar:";
$lang{cal_password} = "Calendar Password:";
$lang{change_password} = "Change Password?";
$lang{new_password} = "New Password";
$lang{repeat_new_password} = "Repeat New Password";
$lang{no_users_on_add} = "You can add other users / passwords after the calendar is created.";

$lang{user_password} = "User Password";
$lang{user_new_password} = "New User Password";
$lang{calendar_password} = "Calendar Password";


$lang{password} = "Password";
$lang{choose_password} = "Choose Password";
$lang{repeat_password} = "Repeat Password";
$lang{repeat_new_password} = "Repeat New Password";
$lang{no_password_needed} = "You are logged in - no password needed.";

$lang{edit_user} = "Edit user";
$lang{add_user} = "Add user";
$lang{update_user} = "Update user";
$lang{delete_user} = "Delete user";
$lang{add_user_name} = "Name";
$lang{permissions} = "Permissions";
$lang{permissions_edit_events} = "Add/Edit events only";
$lang{permissions_edit_calendar} = "Add/Edit events & calendar";
$lang{cancel} = "Cancel";
$lang{add_user_add} = "Add!";
$lang{user_not_added} = "User not added! (login not valid)";
$lang{user_not_deleted} = "User not deleted! (login not valid)";
$lang{user_added} = "User added!";
$lang{user_updated} = "User updated!";
$lang{user_deleted} = "User \$1 deleted!";


$lang{add_calendar} = "Add Calendar";
$lang{update_cal_button} = "Update Calendar";
$lang{preview_warning} = "(You should preview the details first!)";
$lang{del_cal_button1} = "Delete this Calendar";
$lang{del_cal_button2} = "Last Chance!  Are you sure you want to delete the entire calendar?";
$lang{del_cal_button3} = "Deleting this calendar will also delete all events associated with it.<br>This is a fairly serious thing to do, and cannot be undone.";
$lang{deleting} = "Deleting";

$lang{Warning} = "Warning!";
$lang{Error} = "Error!";
$lang{update_cal_error0} = "Password not valid.  A new calendar request requires login or password";
$lang{update_cal_error1} = "The given password does not match the password for";
$lang{update_cal_error2} = "You are attempting to delete the primary calendar.  This is not allowed.";
$lang{update_cal_error3} = "Calendar ###title### successfully deleted!";
$lang{update_cal_error5} = "The required field <b>Calendar Title</b> was blank!";
$lang{update_cal_error6} = "The <b>Calendar Title </b> field contained html. It was removed.";
$lang{update_cal_error6_5} = "The <b>Date Format </b> field isn't legal!.";
$lang{update_cal_error7} = "This appears to be an update of an calendar that does not exist!";
$lang{update_cal_error8} = "Mismatch between the new password and the repeated new password!";
$lang{update_cal_success} = "calendar settings successfully updated!";
$lang{update_cal_failure} = "Calendar <b>not</b> updated!";
$lang{update_cal_error9} = "Mismatch between the password and the repeated password!";
$lang{update_cal_error10} = "Blank password not allowed!";
$lang{update_cal_dup} = " This add/edit appears to be a duplicate! (Perhaps due to a browser refresh?)";

$lang{add_cal_success1} = "Calendar successfully added!";
$lang{add_cal_success2} = "Please be aware that new calendars must be approved by the administrator for this website.  This is a one-time thing.";
$lang{add_cal_success3} = "View calendars waiting for approval.";
$lang{add_cal_success4} = "Calendar successfully updated!";
$lang{add_cal_fail1} = "Calendar <b>not</b> added!";
$lang{add_cal_email_notify1} = "New Calendar Request:";                     
$lang{add_cal_email_notify2} = "A request was made for a new calendar:";    

$lang{notify_subj} = "Automatic notice from \$1";    
$lang{event_delete_notify} = "This is an automatic notice - The event \$1 was deleted from the \$2 calendar.";    
$lang{event_add_notify} = <<p1;
This is an automatic notice - The event \$1 was added to the \$2 calendar.

You can view it here:
\$3
p1
  
$lang{event_pending_notify} = <<p1;
This is an automatic notice - The event \$1 was submitted to the \$2 calendar for approval.

You can view it here:
\$3
p1

$lang{event_update_notify} = <<p1;
This is an automatic notice - The event \$1 was updated (on the \$2 calendar).

You can view it here:
\$3
p1

$lang{view_pending_calendars1} = "View Pending Calendars";
$lang{view_pending_calendars2} = "At this time, there are no calendars waiting to be approved!";
$lang{view_pending_calendars3} = "Approve";
$lang{view_pending_calendars4} = "Delete";
$lang{view_pending_calendars5} = "Approve/Delete marked calendars";
$lang{view_pending_calendars6} = "Approve/Delete Results";
$lang{view_pending_calendars7} = "The given password does not match the administrator password.";
$lang{view_pending_calendars8} = "Approved!";
$lang{view_pending_calendars9} = "Deleted!";
$lang{view_pending_calendars10} = "No action taken.";

$lang{logged_in1} = "You are logged in.";
$lang{logged_in2} = "You are logged out.";
$lang{logged_in3} = "Unable to log in.";
$lang{log_in_first} = "Please log in first";
$lang{pending_event2} = "pending events to approve.";
$lang{pending_event1} = "pending event to approve.";
$lang{no_pending_events_checked} = "No pending events checked!";
$lang{pending_event_deleted} = "Pending event \$1 deleted.";
$lang{pending_event_approved} = "Pending event \$1 approved.";
$lang{invalid_password} = "Invalid password!.";

# other calendar stuff
$lang{calendar_add_edit} = "Edit / Delete this calendar";
$lang{calendar_direct_link} = "Link directly to this calendar:";


# stuff relating to exporting events
$lang{export} = "Export";
$lang{these_events_to} = "these events to:";
$lang{plain_text} = "plain text";
$lang{csv_file} = "csv (Outlook format)";
$lang{csv_file_palm} = "csv (Palm format)";
$lang{export} = "Export";
$lang{this_event_to} = "this event as:";
$lang{text_option} = "plain text";
$lang{icalendar_option} = "iCalendar (MS Outlook)";
$lang{vcalendar_option} = "vcalendar";

# other event stuff
$lang{delete_event} = "Delete Event";
$lang{event_preview_title} = "Event Preview";
$lang{date_preview_title} = "Date Preview";
$lang{event_preview_computing} = "Computing Event Dates...";

# add/edit event stuff
$lang{add_edit_events_tab0} = "Event Info";
$lang{add_edit_events_tab1} = "Recurrence";
$lang{add_or_edit1} = "Add an event";
$lang{add_or_edit2} = "Edit event";
$lang{event_calendar} = "Calendar:";
$lang{block_merge} = "Block Merges";
$lang{event_other_calendars} = "Other Calendars:";
$lang{event_title} = "Event Title:";
$lang{event_details} = "Event Details:";
$lang{event_start} = "Start Date:";
$lang{event_start_warn1} = "Warning - not a valid date!";
$lang{event_start_warn2} = "Note - this date is in the past!";
$lang{all_day_event} = "All-Day Event:";
$lang{event_start_time} = "Start Time:";
$lang{event_end_time} = "End Time:";
$lang{event_length} = "Length (in Days):";
$lang{event_icon} = "Event Icon:";
$lang{event_unit_number} = "Unit Number:";
$lang{event_background_color} = "Background Color:";
$lang{event_background_colorcustom} = "custom";
$lang{recurrence_not_allowed} = "This event was created as a non-recurring event.  Recurrence can only be set when an event is first added";   # changed in version 5.6
$lang{recurring_event_edit1} = "This event is part of a recurring event series."; 
$lang{recurring_event_change_all1} = "Apply changes to all events in the series."; 
$lang{recurring_event_change_all2} = "(Does not work with date changes)"; 
$lang{recurring_event_update_all1} = "Update all events in the series."; 
$lang{recurring_event_delete_all1} = "This event is part of a recurring series."; 
$lang{recurring_event_delete_all2} = "Delete the whole series!"; 
$lang{recurring_event_delete_all3} = "Delete only this event.";
$lang{event_delete1} = "Are you sure?";
$lang{event_delete2} = "Yes, delete this event.";


$lang{recurring_event} = "Recurring event";
$lang{recurrence_type} = "Recurrence type";
$lang{same_day_of_month} = "On the same day of each month.";
$lang{same_weekday} = "Or on the same weekday,";
$lang{every_x_days} = "Daily, every ###x### days";
$lang{every_x_weeks} = "Weekly, every ###x### weeks";
$lang{days} = "Weekly, every ###x### weeks";

$lang{daily_every} = "Daily, every";
$lang{weekly_every} = "Weekly, every";
$lang{days} = "days";
$lang{weeks} = "weeks";



$lang{on_every_week} = "on every week";
$lang{on_first_week} = "on the first week";
$lang{on_second_week} = "on the second week";
$lang{on_third_week} = "on the third week";
$lang{on_fourth_week} = "on the fourth week";
$lang{on_fifth_week} = "on the fifth week";
$lang{on_last_week} = "on the last week";
$lang{of_the_month} = "of the month";
$lang{every_month} = "Every month";
$lang{fit_into_year} = "Fit event into year";
$lang{certain_months1} = "Only in certain months";
$lang{certain_months2} = "(You can choose multiple months)";
$lang{recurring_event_ends} = "Repeat until:";
$lang{generating_preview}  = "Generating Preview...";  
$lang{preview_event1}  = "Preview Event";
$lang{preview_event2}  = "(This shows what the event will look like)";
$lang{preview_dates1}  = "Preview Dates";
$lang{preview_dates2}  = "This shows the date(s) the event will fall on.<br/>(Highly recommended when adding recurring events)";
$lang{update_event}  = "Update Event";
$lang{delete_event1}  = "Delete this event";
$lang{delete_event2}  = "(This cannot be undone.)";
$lang{add_event1}  = "Add Event!";
$lang{add_event2}  = "(Please preview first!)";
$lang{add_event2_update}  = "(Please preview the event before updating it!)";
$lang{please_wait}  = "Please wait...";


$lang{update_event_delete_successful}  = "Event successfully deleted!";
$lang{update_event_delete_successful_recurring}  = "Recurring event series successfully deleted!";   
$lang{update_event_add_successful}  = "Event successfully added!";
$lang{update_event_add_pending_successful}  = "Event successfully submitted for approval!";
$lang{update_event_update_successful}  = "Event successfully updated!";
$lang{update_event_update_successful_recurring}  = "Recurring event series successfully updated!";  
$lang{update_event_add_successful_recurring}  = "Event successfully added to the following dates:";
$lang{update_event_add_successful_add_new}  = "Add a new event";
$lang{update_event_back_to_calendar}  = "Back to calendar";
$lang{update_event_err1}  = "The given password does not match the password for ";
$lang{update_event_err2}  = "The event does not match any existing event!";
$lang{update_event_err3}  = "The required field 'Calendar Title' was blank!";
$lang{update_event_err4}  = "The required field 'Event Title' was blank!";
$lang{update_event_err5}  = "The required field 'Event icon' was blank!  How on earth did that happen?";
$lang{update_event_err6}  = "The required field 'Calendar password' was blank!";
$lang{update_event_err7}  = "The 'Event title' field contained html. It was removed.";
$lang{update_event_err8}  = "The calendar does not match any known calendar.";
$lang{update_event_err9}  = "Invalid Date:";
$lang{update_event_err10}  = "Recurring date error:";
$lang{update_event_err11}  = "The event start date is in the past.";
$lang{update_event_err12}  = " This add/edit appears to be a duplicate! (Perhaps from a browser refresh?)";
$lang{update_event_err13}  = "This appears to be an update of an event that does not exist!";
$lang{update_event_err14}  = "Invalid start time";
$lang{update_event_err15}  = "Invalid end time";
$lang{update_event_err16}  = "The given password does not match the password for ###calendar###.  Event placed in the approval queue.";

# date verify stuff
$lang{date_verify_err0}  = "The date (###date###) appears to be formatted incorrectly.  It should be in the format ###format###!";
$lang{date_verify_err1}  = "The event date was blank!";
$lang{date_verify_err2}  = "The event length was blank!";
$lang{date_verify_err3}  = "The event length (\$1) must be a positive number!";
$lang{date_verify_err4}  = "The month <b>###month###</b> is not valid.";
$lang{date_verify_err5}  = "The day-of-month <b>###day###</b> is not valid.";
$lang{date_verify_err6}  = "The year <b>###year###</b> is not valid.";
$lang{date_verify_err7}  = "The every-X-days value is not valid.";
$lang{date_verify_err8}  = "The every-X-weeks value is not valid.";

# time verify stuff
$lang{time_verify_err0}  = "The time (<b>{0}</b>) is not formatted correctly! It should be in the format \"hh:mm $lang{am}\" or \"hh:mm $lang{pm}\"";
$lang{time_verify_err1}  = "The hours (<b>{0}</b>) are invalid! ";
$lang{time_verify_err2}  = "The minutes (<b>{0}</b>) are invalid! ";



# date preview stuff
$lang{date_preview_for_recurring_end_date}  = "For the recurring event end date,";
$lang{date_preview_this_event_falls_on}  = "This event falls on:";
$lang{date_preview_recurring_event_falls_on}  = "This recurring event falls on:";

# event details stuff
$lang{event_details_export_disable}  = "Export this event <i>(disabled for preview)</i>";
$lang{event_details_edit_disable}  = "Edit this event <i>(disabled for preview)</i>";
$lang{event_details_date_goes_here}  = "Date goes here";
$lang{event_email_reminder_disable}  = "Email reminder <i>(disabled for preview)</i>"; 
$lang{event_email_reminder_disable2}  = "Email reminder <i>(disabled)</i>"; 

# email reminder stuff
$lang{email_reminder_link} = "Email a reminder for this event";   
$lang{email_reminder_title} = " - Email reminder";   
$lang{email_reminder_text1} = "This event falls on:";   
$lang{email_reminder_text2} = " Email a reminder to:";   
$lang{email_reminder_option1} = "A week before";   
$lang{email_reminder_option2} = "2 days before";   
$lang{email_reminder_option3} = "1 day before";   
$lang{email_reminder_option4} = "1 hour before";   
$lang{email_reminder_option5} = "1/2 hour before";   
$lang{email_reminder_option6} = "15 minutes before";   
$lang{email_reminder_text3} = "the event occurs.";   
$lang{email_reminder_text4} = "Send a reminder right now, to make sure it works.";   
$lang{email_reminder_text5} = "Do it!";   
$lang{email_reminder_text6} = "This event is part of a series.<br/>Add this reminder to all future events in the series?";   
$lang{email_reminder_text7} = "Extra text:";   
$lang{email_reminder_invalid_address} = "Invalid email address (###address###).  Email reminder cancelled!";   
$lang{email_reminder_test_success} = "Test reminder sent successfully to <i>###address###</i>!";   
$lang{email_reminder_test_fail} = "Test reminder not sent:<br/><br/><i>###results###</i>!";   
$lang{send_email_reminder1} = "Invalid email address ";   
$lang{send_email_reminder2} = "Email reminders are disabled.";   
$lang{send_email_reminder3} = "Unsupported email reminder mode";   
$lang{send_email_reminder_subject} = "Reminder - ###title###";   


$lang{email_reminder_results1} = <<p1; 
An email reminder will be sent to
<br/><i>###address###</i>
<br/>###reminder time### 
p1
$lang{email_reminder_results2} = "the event occurs."; 
$lang{email_reminder_results3} = "each event occurs."; 



$lang{email_reminder_test_text} = <<p1; 

This is a test for the automatic event reminder:
###title###
on ###date###
###time###.
Another reminder will be sent ###reminder_time### the event occurs.

Details:
###details###

###extra text###

The event is listed here:
###link###

p1


$lang{email_reminder_text} = <<p1; 

This is an automatic event reminder:
###title###
on ###date###
###time###.

Details:
###details###

###extra text###

The event is listed here:
###link###

p1


# Online help for add/edit events
$lang{help_box_title} = "Plans Help";

$lang{help_evt_cal_id} = <<p1;
<p>
All events are associated with a calendar.  There are two reasons for this:
</p><p>
1.  The event can then link to information about the calendar.  This is an easy way to get quick basic contact information.
</p><p>
2.  It is part of the security model--each event must be authenticated somehow.  An calendar's password allows the appropriate folks 
to add/update events for that calendar.
</p>
p1

$lang{help_evt_title} = <<p1;
<p>
This is the event's headline--it should be descriptive, yet very short 
(it will likely share a calendar square with other events).
</p><p>
Events are automatically associated with calendars, so you don't need 
this information in the event title.
</p>
p1

$lang{help_evt_details} = <<p1;
<p>
This is where all the details go--this can be as much information as you want.
</p><p>
Email addresses and URLs will automatically be converted to links.  In addition, 
you can also write html in the event details.
</p><p>
If the details field contains <i>only</i> an URL (starting with http://), that URL will 
be the target of the event title link (in other words, the pop-up window) is replaced with a 
direct link to the target URL.
</p><p>
If you write html, make sure you properly quote things.
<br/><br/>This is wrong:
<br/><i>&lt;a href=www.planscalendar.com&gt;link&lt;a&gt;</i>
<br/><br/>This is right:
<br/><i>&lt;a href=&quot;www.planscalendar.com&quot;&gt;link&lt;a&gt;</i>
<br/>
The same thing applies to the &lt;img&gt; src attribute
</p><p>
Here's a template  you can copy & paste.  It has html for nice-looking formatting:
</p><p style="margin-top:2em;">
<span class=highlight><i>
Details Details Details.
<br/>
&lt;ul&gt;<br/>
&lt;li&gt; What<br/>
&lt;li&gt; Where<br/>
&lt;li&gt; Why<br/>
&lt;li&gt; How<br/>
&lt;li&gt; Who to contact<br>
&lt;/ul&gt;<br/>
</i></span>
</p>

</p>
p1

$lang{help_recurring_event} = <<p1;
<p>
A recurring event is slightly more complicated, but not much.  Both single and 
multiple-day events can be recurring. 
</p><p>
When you add a recurring event, Plans makes copies of the 
event for successive days, weeks, or months, according to the pattern 
you specify.
</p><p>
<strong>Take care when creating a recurring event!</strong>
<br/><br/>
<strong>Use the "Preview Dates" link!</strong>
<br/><br/>
If you make a mistake, you must 
edit or delete each copy of the event individually.</b>
</p><p>
After adding a recurring event, you can modify or delete the copies individually.
You cannot manage them as a group.  Once created, they are not tied together in any way.
</p><p>
Basically, recurring events are for speeding up data entry.
</p>
p1

$lang{help_recurrence_type} = <<p1;
<p>
You can choose how the event will repeat in within each month.
</p>
<ul>
<li><strong>On the same day of each month</strong><p>
If this is selected, the event will occur only once a month, on the same day (or range of days).
Most of the events that follow this kind of pattern are holidays.</p></li>
<li><strong>On the same weekday</strong><p>
Most meetings follow this type of pattern.  Events can be scheduled to occur on every week of the 
month, or on certain weeks.</p></li>
</ul>
<p>
Once Again, use the "Preview Dates" button!
</p><p>
<strong>Note</strong>--Some events occur on more than one week of every month (the first and third week, 
for instance).  This type of pattern cannot be selected, but can be created by adding the event 
twice--once for the first week and once for third week, for the above example.  Of course, then you have two 
event series instead of just one...
</p>
p1

$lang{help_fit_into_year} = <<p1;
<p>
You can choose how the event will repeat within the year(s).
</p>
<ul>
<li><strong>Every month</strong><p>
If this is selected, the event will repeat each month.</p></li>
<li><strong>Only during certain months</strong><p>
Here you can choose which months the event will occur in.  This is useful for 
events that stop for a period (like during the summer).</p></li>
</ul>
p1

$lang{help_cal_password} = <<p1;
<p>
Each calendar has its own password.  This password must be entered 
each time an event is added or changed.  There is a "master" 
password, which can be used to add/edit events for any calendar.
</p>
p1


$lang{help_recurring_event_change_all} = <<p1;
<p>
When you change all events in a series, the current event title, details, icon, background color, etc. 
will be applied to each event in the series.
</p><p>
The dates of the events in the series will not change.  These are computed when the series is first created.  Individual 
events in the series can be deleted or have their dates changed.  But the only things you can 
do to an entire series are change the details or delete the series.
</p>
p1






# Online help for add/edit calendars

$lang{help_cal_title} = <<p1;
<p>
The name of the calendar.  Keep it short and sweet.
</p>
p1

$lang{help_cal_link} = <<p1;
<p>
You can supply an URL (web address) that will be applied to the calendar title, 
in the event details window.
</p><p>
If the calendar is for an organization 
with a homepage, this provides a 1-click connection between the 
event and the homepage.
</p>
p1


$lang{help_cal_details} = <<p1;
<p>
You can supply additional details--some calendars won't 
use this field at all&#151;leting the <b>Calendar Link</b> field 
point users to the calendar's homepage instead.  But you may want to include 
some details that users might need immediately--a contact email address, for 
instance.
</p><p>
email addresses and URLs will automatically be converted to links.
</p><p>
Here is a handy template  you can copy & paste.  It has html for nice-looking formatting:
</p><p>
<span class="highlight">
General Description
<br/>
&lt;ul&gt;<br/>
&lt;li&gt; Contact information<br/>
&lt;li&gt; Meeting Time<br/>
&lt;li&gt; Meeting Location<br/>
&lt;/ul&gt;<br/>
</span>
</p>
p1




$lang{help_cal_new_password} = <<p1;
<p>
Oh no! Another password to remember!
</p><p>
Oh yes.
</p><p>
The calendar password should be easy to remember and easy to tell to others.  Not 
much need for passwords like "Dxk&2+15^N" or "p\$\$9EM}L". 
We're not talking about national security here--just enough to keep out the rifraff.
</p><p>
When entering a password for the first time or changing it, you are asked to type it twice. 
This guards against typos (if you make a typo when entering a new password, it's tough to 
fix).
</p>

p1
$lang{help_cal_current_password} = <<p1;
<p>
This password allows people to add or change events 
on the calendar, and to modify calendar settings.  
If you know the master password for this installation 
of Plans, you can use it in place of any other calendar password.
</p>
p1

$lang{help_cal_change_password} = <<p1;
<p>
You can change the calendar password if you like.  Enter it twice, just like 
when the calendar was first added.
</p>
p1

$lang{help_cal_background_calendars} = <<p1;
<p>
You can show other calendars' events in the "background" of 
the calendar. 
</p><p>
Hold the <b>Ctrl</b> key while clicking to toggle the 
calendars on/off individually.
</p>
p1

$lang{help_cal_selectable_calendars} = <<p1;
<p>
Each calendar can choose what other users can select from 
the dropdown on the main page.  If no calendars are selected, 
the dropdown won't be displayed.
</p><p>
Sometimes, you might want to let the user select from just a few 
(or none) of the calendars hosted by an installation of plans.
</p><p>
Note that when you add a new calendar, it is <b>not</b> automatically 
added to other calendars' drop-down lists.  This must be done manually.
</p><p>
Hold the <b>Ctrl</b> key while clicking to toggle the 
calendars on/off individually.
</p>
p1


$lang{help_cal_remote_background_calendars} = <<p1;
<p>
You can merge calendars from other installations of Plans.
</p><p>
This is a bit more tricky than merging calendars hosted by the same installation 
of Plans as this server.  Whenever your calendar is displayed, Plans makes a http 
request to the remote server, and fetches its calendar data.
</p><p>
To merge a remote calendar, you'll need to know the address (URL) of that calendar.
Plans will send a request to that calendar site, asking it what calendars are available 
for remote merging (the remote site's calendar owners can disallow this).
</p><p>
If all goes well, you'll get a list of calendars to choose from.  Check the boxes by the 
ones you want to merge, and click "Merge Selected Calendars".
</p><p>
When you update your calendar, the remote calendars will be added.
</p><p>
In summary, it's a <b>three-step process:</b><br/>
(1) Click "Add remote calendars", and find the remote calendars (using the URL)<br/>
(2) Select the ones you want, and click the "Merge" link<br/>
(3) Update your calendar.  Don't forget this step!
</p><p>
Note:  If you have too many remote merged calendars, you may notice slower performance from your calendar.
</p><p>

</p>
p1

$lang{help_cal_background_events_display_style} = <<p1;
<p>
The color of background events can be changed:
</p><p>
<b>Normal--</b>In this style, background events will look just like events for the selected calendar.
</p><p>
<b>Single color--</b>All background events will show up with this color (white or grey are popular choices). 
This can help if you have a great many background events.
</p><p>
<b>Faded--</b>This is just fanciness for fanciness' sake :)  Background events will have their colors faded by 
the percent you choose.  If the colors are light to begin with, they'll appear white.
</p>
p1


$lang{help_cal_events_display_style} = <<p1;
<p>
You can specify a color to apply to all events in this calendar:
</p><p>
This will override any event-specific colors.
</p>
p1



$lang{help_cal_list_background_calendars_together} = <<p1;
<p>
This option affects the list view.  If selected, plans will not draw 
separate boxes each calendar. 
All the background events will be listed with the main calendar events in one big list.
</p>
p1

$lang{help_cal_default_number_of_months} = <<p1;
<p>
When someone first visits the calendar page, how many months should be shown?
</p>
p1

$lang{help_cal_max_months} = <<p1;
<p>
The calendar can display dates from  1902 to 2037.  You may want to limit the range 
of dates a user can display with a single request.
</p>
p1

$lang{help_cal_gmtime_diff} = <<p1;
<p>
How many hours is this calendar away from Greenwich Mean Time?
</p><p>
<a target="_blank" href="http://www.worldtimezone.com/">www.worldtimezone.com</a> is a good reference.
</p><p>
If you have multiple calendars with different timezones on a single instance of Plans, and they 
include each other&apos;s events, the event times will be adjusted accordingly.
</p>
p1


$lang{help_cal_date_format} = <<p1;
<p>
This option controls how dates are entered for adding or editing events. 
</p><p>
It must contain "mm", "dd", and "yyyy", in any order, separated by "/" characters.
</p>
p1


$lang{help_cal_week_start_day} = <<p1;
<p>
Select the day of the week you'd like the calendar to start with.
</p>
p1

$lang{help_cal_event_change_email} = <<p1;
<p>
Sends a notification when an event is added, updated, or deleted for this calendar.  Leave blank to send no notification emails.
</p><p>
You can supply multiple email addresses.  Separate them with spaces:
<blockquote style="white-space:nowrap;">
abc\@xyz.com fgh\@jkl.com
</blockquote>
</p><p>
If you want to send to emails for <b>only</b> adds or updates or deletes, you can do this:
<blockquote style="white-space:nowrap;">
add:abc\@xyz.com update:jim\@bob.com delete:hey\@howdy.com
</blockquote>
</p>
p1

$lang{help_cal_new_calendars_automatically_selectable} = <<p1;
<p>
If this option is checked, future calendars will automatically 
appear on this calendar's calendar select dropdown on the main calendar view.
</p>
p1


$lang{help_cal_allow_remote_calendar_requests} = <<p1;
<p>
If this option is checked, other installations of Plans (running on other websites than yours) can include 
this calendar as a background calendar.
</p><p>
This is done using an http request.  It can add additional bandwidth and processing 
load to your server, but not much.
</p><p>
It's useful if you're (for example) a school, and you would like outside websites (sports leagues, community programs, 
youth groups) to be able to display your events on their calendars.
</p>
p1

$lang{help_cal_remote_calendar_requests_password} = <<p1;
<p>
You may want to share your calendar with some outside websites, but not the whole world.  Here, you can specify 
a password that other calendar admins will need in order to merge your calendar with theirs.
</p><p>
Note that this does <b>not</b> apply to normal calendar viewing.  People can still look at your calendars with 
their web browser.  They just can't make requests to get the raw data. 
</p><p>
This is only useful if a really popular calendar happens to remotely include yours, and your server bogs down as a 
result.  Until this happens, it is reccommended you don't require a password (it just adds hassle.)
</p><p>
Actually, the password isn't really the best solution for the above problem.  The best solution would be to block 
the offending server's IP address.  But if you don't have that type of control over your own server, the password 
may help.
</p>
p1


$lang{help_cal_popup_window_size} = <<p1;
<p>
Set the size of the popup window (used for event details, calendar details, 
previews, and other things).
</p><p>
Units are pixels, default is 400x400.
</p>
p1


$lang{help_cal_custom_stylesheet} = <<p1;
<p>
You can define a custom .css file for each calendar.
</p><p>
This lets you customize the calendar's fonts, colors and backgrounds.
</p><p>
This .css file must be publicly accessible through the internet 
(in other words, you should be able to access it by pointing your browser at an URL).
</p><p>
A good place to start is with a copy of this calendar's default css file:
</p><p>
<b><a href="###css file###">###css file###</a></b>
</p>
p1

$lang{help_cal_custom_template} = <<p1;
<p>
Similar to a custom css file, you can also define a custom template for each calendar.
</p><p>
The template file gives you greater control over the layout and structure of the calendar page.
</p><p>
A template file is just an html file with some ###special tags### that plans recognizes.
</p><p>
Your custom template file must be publicly accessuble through the internet 
(in other words, you should be able to access it file by pointing your browser at an URL).
</p><p>
A good place to start is with a copy of this calendar's default tempate file.
</p><p>
If you make a typo in the template address, plans will simply use its default template and print a warning at 
the very bottom of the calendar.
</p>
p1

$lang{help_cal_add_new_ical} = <<p1;
<p>
iCalendar support is not fully implemented yet, but you can try it out.  To add a new iCalendar, enter its URL.
</p><p>
To disable the "add iCal calendar" link, set the \$options{ical_import} option to 0 in plans_config.pl.
</p><p>
Dates will be pulled from the iCal and displayed in Plans.  If the dates are incorrect or things look wrong, 
<a href="mailto:daltonlp\@gmail.com">email the author</a>, and supply the URL of your iCal, the version of Plans you're using, 
and a description of what's wrong.  You can also <a target = "_blank" href="http://www.planscalendar.com/forum">post the issue on the forum.</a>
</p>
p1





