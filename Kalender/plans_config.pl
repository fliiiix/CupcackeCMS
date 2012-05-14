########################################################################################################
###############################      Plans config file    ##############################################
########################################################################################################
# This file stores installation-specific settings for the plans calendar.   
# You may need to change them to match how your server or site is set up.
#
# Each time plans runs, it looks for this file in the same directory 
# plans.cgi is in.  If found, this file is compiled with the rest of 
# plans.  The following statements are perl code.


########################################################################################################
###############################      File Locations        #############################################
########################################################################################################
# This is the default file structure for plans:
#
# plans/
#       plans.cgi
#       plans.config
#       data/
#         *.xml
#       theme/
#             plans.template
#             plans.css
#             icons/
#             graphics/
#
#  The theme/ directory contains static files (.css, .js, .gif)
#  If your server does't allow static files be served from the same 
#  directory (or subdirectories) as scripts, 

#  You can move the theme directory to somewhere outside the plans directory. 
#  If you do this, uncomment the variable below and set it accordingly.  
#  You'll also need to change the default template file in the next section.
# $theme_url  = "http://www.yoursite.com/theme_directory";      # note there is no end slash!



########################################################################################################
###############################      Calendar URL      #################################################
########################################################################################################
# Plans tries to automatically detect (by asking your webserver) the URL of the installation.
# Some webservers don't support this, in which case, some links won't work (like the 'add event' and
# 'calendar settings' tabs.
# You can fix the problem by uncommenting the line below and setting the URL accordingly:
# $options{calendar_url} = 'http://www.yoursite.com/your_plans_directory/';



########################################################################################################
###############################    Default Template    #################################################
########################################################################################################
# All calendars use the same default template file.
#
# Each calendar in Plans can have its own custom template file, which override the default file.
# this custom template file must be an URL (plans will fetch it across the network, even 
# if it resides on the same server).  This increases security and allows template files to 
# come from other websites.
#
# If a calendar doesn't specify a custom template file, or plans is unable to fetch a calendar's custom 
# template file, it will use the default template file below.  
                                                              
$options{default_theme_path} = "theme";     # IMPORTANT -- this is not an URL.  It's a filesystem path.

                                            # On some unix hosts, you need to specify the entire path,
                                            # like: "/home/path/to/plans/theme/theme"

                                            # On a windows host, the you might need something
                                            # like: "C:/path/to/plans/theme"

$options{default_template_path} = "$options{default_theme_path}/plans.template";



########################################################################################################
###############################          Language         ##############################################
########################################################################################################
# All user-facing text is stored in a table.  When Plans runs, it sources $options{language_file}, which 
# fills the table with the appropriate stuff.
$options{language_files} = "us_english.pl";
$options{js_language_file} = "plans_lang.js";   # The first time it runs, and after each upgrade
                                                # plans automatically translates the language strings 
                                                # in its language file(s) into a javascript language file.
                                                
$options{generate_js_lang} = 0;  # this line forces plans to regenerate the javascript language file 
                                  # every time it runs.  If you are testing a translation, set this to 1.


########################################################################################################
###############################         Users & Permissions          ###################################
########################################################################################################
# If you're on an intranet or private server, you can disable 
# passwords in Plans entirely by setting this option to 1.
$options{disable_passwords} = 0;

# Set this option to 1 if you want plans to use sessions. You won't have to type passwords over and over again.
# This requires the CGI::Session perl module.
$options{sessions} = 0;

# You may want to force anyone accessing Plans
# to login before doing anything.  If so then set this to 1.
# NOTE - this requires $options{sessions} = 1
$options{force_login} = 0;

# Events added without the proper password will be stored for 
# approval by a calendar user or admin. (ignored if passwords are disabled), 
$options{anonymous_events} = 0;


# Requests for new calendars are for approval by an admin.
# Disabling this option (possibly because of spam) prevents people from submitting new calendar requests 
# unless they logged in or supply a password
$options{anonymous_calendar_requests} = 1;


# If this is 1, calendar admins will have the ability to add 'users' to their calendar.
# each user has a name & password of their own.
# users can add and edit events, but not change calendar settings.
$options{users} = 0;


$options{pending_events_display} = 0;   # display is different from approval
                                        # approval is always by logged-in user or admin
                                        #
                                        # 0 = public - everyone sees *all* pending events 
                                        # 1 = users - everyone sees pending events for the calendar they're viewing. 
                                        # 2 = users & admins - only logged-in users see pending events for the calendar they're viewing. 
                                        # 3 = admins only - only calendar admins see pending events for the calendar they're viewing. 

# The "salt" variable is used by the encryption algorithm that plans uses to store passwords.
#
# If you want your encrypted passwords to look different from everyone else's encrypted passwords,
# change this value to a different (random) string.
#
# However, if you change the salt, all your existing passwords (including the default calendars supplied with Plans)
# won't work!  You'll have to change them individually, by re-generate them by hand with the new salt value.
#
# If you are enough of a security guru to want to change the salt, re-generating the passwords should be no problem :)
$options{salt} = "NaCl";



########################################################################################################
###############################          Timezones         #############################################
########################################################################################################
# Each calendar in Plans can have its own timezone.  While this is handy for some folks, 
# it causes confusion if timezones are changed by accident.
# Keep this switch set at 1 to force all calendars to use the main calendar's timezone.
$options{force_single_timezone} = 1;

########################################################################################################
###############################          Event Times         ###########################################
########################################################################################################
# New events in Plans are all-day events by default
# You can set this switch to 0 to make new events have an event time by default
$options{new_events_all_day} = 0;
$options{twentyfour_hour_format} = 0;

if ($options{twentyfour_hour_format}) {
  $options{default_event_start_time} = "9:00";
  $options{default_event_end_time} = "18:00";
} else {
  $options{default_event_start_time} = "9:00 am";
  $options{default_event_end_time} = "5:00 pm";
}



########################################################################################################
###############################      Selecting Multiple Calendars     ##################################
########################################################################################################
# Each event in Plans is associated with a calendar.
# If this switch is 1, all calendars will always appear in the calendar controls dropdown.
#
# If this switch is 0, each calendar gets to choose what other calendars will be in the dropdown
# when it's the active calendar.  This can be used to manage a large hierarchy of calendars, but it
# requires more oversight, especially when creating new calendars.
 
$options{all_calendars_selectable} = 1;

# If this variable is 1, new calendars will automatically be added to all existing 
# calendars' drop-down selections at creation time.
# this option has no visible effect if $options{all_calendars_selectable} = 1.
$options{new_calendars_automatically_selectable} = 1;

# if $options{calendar_select_order} is blank (totally commented out), calendars will 
# be listed on the dropdown menu in the order they were created.  
# You can change this by setting $options{calendar_select_order} to "alpha" (sort alphabetically)
# or by explicitly ordering the calendars by id(you may have to look at the calendar data to find the id).
#$options{calendar_select_order} = "alpha";
#$options{calendar_select_order} = "0,3,4,1,6,7,8";


########################################################################################################
###############################       Multi-calendar events     ########################################
########################################################################################################
# Each event in Plans is associated with one calendar by default.
# However, individual events can be associated with multiple calendars
# (This is different from Plans' ability to merge entire calendars)
#
# 0 = single calendar (events allowed to be under only one calendar)
#
# 1 = multi-calendar, single password (events can be under multiple calendars,
#     but only the password from the original calendar can be used to modify the event)
#
# 2 = multi-calendar, multi-password (events can be under multiple calendars,
#     and any of their passwords can be used to modify the event.)
 
$options{multi_calendar_event_mode} = 0;


# if this option is set to 1, events can be excluded from merged calendars
$options{allow_merge_blocking} = 1;



########################################################################################################
###############################          View Types         ############################################
########################################################################################################
# Here you can turn on of off Plans' various view types.  
# This affects the "display" menu in the calendar controls.
# 1 to enable, 0 to disable.
$options{display_types}[0] = 1;  # calendar view
$options{display_types}[1] = 1;  # list view
$options{display_types}[2] = 0;  # daily view with event details (not implemented yet!)



########################################################################################################
###############################        Data storage        #############################################
########################################################################################################
# subdirectory beneath plans, where .xml files are kept
$options{data_directory} = "data";

# You can store calendar data in flat files or a database (like mySQL).
# The default storage mode is plain text files.
# you can switch modes at any time--plans will convert your existing data.
# 0 = flat text files
# 1 = mysql
# 2 = MS Sql server
$options{data_storage_mode} = 0;

# This is where plans keeps information that it "discovers".  See the file for more details.
$options{discovery_file} = "$options{data_directory}/plans_discovery.xml";

# This subdirectory is where plans keeps sessions files.
$options{sessions_directory} = "sessions";



################################   Flat-file mode  (mode 0)   ##########################################
########################################################################################################
$options{events_file} = "$options{data_directory}/events.xml";                 # events for all calendars.
$options{pending_actions_file} = "$options{data_directory}/pending_actions.xml";     # new (not yet approved) events
$options{calendars_file} = "$options{data_directory}/calendars.xml";           # settings for calendars
$options{users_file} = "$options{data_directory}/users.xml";       # users.

#################################    SQL DBI mode (modes > 0)  ########################################
# Perl's database abstraction layer (DBI) can talk to most SQL database types.
########################################################################################################
if ($options{data_storage_mode} > 0) {
  $dbh;                                                   # define global database handle
  
  require DBD::mysql if ($options{data_storage_mode} == 1); # The driver for the database type you'll be using.
  require DBD::ODBC if ($options{data_storage_mode} == 2);  
  
  
  $options{db_name} = "db_name";                          # The name of the database (you have to create it on your own first)
  $options{db_hostname} = "db_host.domain.com:port";      # The database hostname and port
  $options{db_username} = "db_user";                      # The username you'll use to connect
  $options{db_password_file} = "../plans_mysql.pwd";      # Put the DB password in this file.
                                                          #   Make sure this file is *not* publically
                                                          #   readable (chmod 400 on unix)
                                          
  # You don't have to create these tables.
  # Plans will do it for you.
  $options{calendars_table} = "calendars";                # Table for storing calendar settings.
  $options{events_table} = "events";                      # Table for storing event data.
  $options{pending_actions_table} = "pending_actions";    # Table for storing pending events & calendars.
  $options{users_table} = "users";                        # Table for storing calendar users.
  
  
  
  # open the password file
  open (FH, "$options{db_password_file}") || {$debug_info.= "unable to open file $options{db_password_file}\n"};
  flock FH,2;
  $options{mysql_password}=<FH>;
  close FH;
  chomp $options{mysql_password};
  
  # connect to the db host
  if ($options{data_storage_mode} == 1) {
    if (!($dbh = DBI->connect("DBI:mysql:database=$options{db_name};host=$options{db_hostname}","$options{db_username}","$options{mysql_password}"))) {
      $fatal_error=1;
      $error_info.= "DB connect error! $DBI::errstr";
      return 1;
    }
  } elsif ($options{data_storage_mode} == 2) {
    if (!($dbh = DBI->connect("DBI:ODBC:database=$options{db_name};host=$options{db_hostname}","$options{db_username}","$options{mysql_password}",{LongReadLen=>1040000, LongTruncOk=>1}))) {
      $fatal_error=1;
      $error_info.= "DB connect error! $DBI::errstr";
      return 1;
    }
  }
}


########################################################################################################
###############################            Email           #############################################
########################################################################################################
# Plans can send email reminders to visitors
# If this is turned on, an email reminder link will appear in the event details.
# If a user clicks on it, a record will be added to $options{email_reminders_datafile}
# This file is read by email_reminders.cgi, which is what actually sends the email.
#
# email_reminders.cgi does not run automatically when Plans runs.  You have to run it 
# as a cron job (unix) or a scheduled task (windows).  You can also run email_reminders.cgi 
# manually from the command line, or by pointing your browser at it.

$options{email_mode} = 1;  # 0 = off
                  # 1 = sendmail (unix)
                  # 2 = STMP (windows)      
                            
if ($options{email_mode} == 1) {
  $options{sendmail_location} = "/usr/sbin/sendmail";
} elsif ($options{email_mode} == 2) {
  require Net::SMTP;
  $options{mail_server}="127.0.0.1";
  $smtp = Net::SMTP->new($options{mail_server});
}

$options{reply_address} = "your\@address.com";   # used for the "reply-to" field of reminder emails
$options{from_address} = "your\@address.com";   # used for the "from"field of reminder emails
$options{email_reminders_datafile} = "$options{data_directory}/email_reminders.xml";         # xml file where email reminder data is kept.


$options{new_calendar_request_notify} = "your\@address.com";   # send an email here when someone requests a new calendar

########################################################################################################
###############################        Proxy Server      ###############################################
########################################################################################################
# Plans sometimes makes network requests of its own, usually to access
# iCal calendars on some other website.  Most of the time this just works, but sometimes,
# the machine that Plans runs on is behind a proxy server.  In this case, Plans needs to know the 
# proxy server's name and port in order to make remote requests.
$options{proxy_server} = "";
$options{proxy_port} = "";
      
########################################################################################################
###############################            Tabs            #############################################
########################################################################################################
# You can disable tabs by uncommenting the array below
# Specify the numbers of the tabs not to be shown (numbers start with 0)
#@disabled_tabs = (0,1,2);

# If you want to remove all the tabs, an easier 
# way is to remove the ###tab menu stuff### 
# tag from the plans.template file.

             
########################################################################################################
############################         Right-click menus         #########################################
########################################################################################################
# If you right-click on a day or event, you get a drop-down menu
# with entries like "add event on this day". 
# To disable these menus, set the following variable to 0.
$options{right_click_menus_enabled} = 1;

########################################################################################################
############################          Upcoming Events         #########################################
########################################################################################################
# You can adjust the value used for the "Cache-control" http header 
# that is sent back when upcoming events are fetched.
# This causes the client browser to use its cached copy of the upcoming events data, 
# so it won't hit the server for each page load.
$options{upcoming_events} = {
	"output_filename" => "upcoming_events.html",
	"cache_seconds" => 30,
#	"calendar_url" => 'http://www.yoursite.com/your_plans_directory',
	"calendar_url" => 'http://www.planscalendar.com/svntest',
	"timeframe" => 30,
	"included_calendars" => [0,1,2],
	"background_calendars_mode" => "merge",
	"one_big_list" => 0

};



########################################################################################################
#############################     Event Background Colors    ###########################################
########################################################################################################
# set this to 1 to have the descriptions in the 
# second column appear on the colors in the dropdown menu.
$options{show_event_background_color_descriptions} = 0;

# You can change these or add more.
$event_background_colors = <<p1;
#ffffff   White        
#eeeeee   Off-white    
#66cc66   Dark Green
#99ffcc   Sea Green
#ccffcc   Pastel Green        
#ccffff   Blue         
#99ccff   Darker blue  
#addadd
#ffaa99   Red-orange
#ffcc99   Orange       
#ffddbb   Peach
#ffccff   Pink         
#eeddff   Light Pink
#efe7de   Tan  
#fffbba   Light orange 
#ffffcc   Yellow       
#daddad
#cabcab
p1


# Make sure there are no spaces or tab characters 
# after the "p1", on the same line.  This is a 
# source of errors for those who aren't familiar with perl :)

########################################################################################################
#############################         Default Details        ###########################################
#############################       (for new calendars)      ###########################################
########################################################################################################
# You may want some boilerplate text in the "details" section of a 
# new calendar.

$new_calendar_default_details = "You must include a contact email address for the calendar to be approved.";


########################################################################################################
################################        Event Icons        #############################################
########################################################################################################
# If you want to add your own icons, 
# you'll need:
# -  three copies of your icon in the $theme_url/icons/ directory
#    - a 50 x 50 version, named my_icon_50x50.gif
#    - a 32 x 32 version, named my_icon_32x32.gif
#    - a 16 x 16 version, named my_icon_16x16.gif
# - a new entry in the menu structure below 
#
# The icon menu structure looks like HTML, but it's not really.  It's an XML
# format that is translated by plans into html.  Most browsers display nested submenus 
# in "flattened" groups, which looks ok.  Someday, browsers will support real 
# nested menus.  It's possible to use javascript to fake this, but it's flaky 
# and has problems with browser form elements.
# see http://www.brainjar.com/css/positioning/default5.asp for technical details.


$event_icons_menu =<<p1;
<menuitem value="blank">Blank (no icon)</menuitem>
<menu name="General Icons">
 <menuitem value="clipboard">Clipboard & pencil</menuitem>
 <menuitem value="bullet_point">Bullet point</menuitem>
 <menuitem value="exclamation">Exclamation point</menuitem>
 <menuitem value="clock">Clock</menuitem>
 <menuitem value="church">Church</menuitem>
 <menuitem value="us_flag">Stars & Stripes</menuitem>
 <menuitem value="news">News</menuitem>
 <menuitem value="1st_aid">First Aid</menuitem>
</menu>
<menu name="Outdoor Icons">
 <menuitem value="bike">Bike</menuitem>
 <menuitem value="fire">Campfire</menuitem>
 <menuitem value="axe">Axe</menuitem>
 <menuitem value="canoe">Canoe</menuitem>
 <menuitem value="compass">Compass</menuitem>
 <menuitem value="fish">Fish</menuitem>
 <menuitem value="e_frame_pack">Pack (ext. frame)</menuitem>
 <menuitem value="i_frame_pack">Pack (int. frame)</menuitem>
 <menuitem value="snowflake">Snowflake</menuitem>
 <menuitem value="tent">Tent</menuitem>
</menu>
p1
# Again, be careful to avoid putting any characters 
# (normal or whitespace) after the "p1", on the same line.  This is a 
# source of errors for those who aren't familiar with perl :)



########################################################################################################
################################     Other options         #############################################
########################################################################################################

# Plans was originally devloped as a calendar for a scout troop.  This 
# feature is a holdover from those days.  For it to work correctly, 
# the graphics for unit number icons must be present in the $graphics_url.
$options{unit_number_icons} = 0;


# if this option is set to 1, you'll be able to add iCal calenars from the "Calendar Settings" tab.
$options{ical_import} = 1;

# if this option is set to 1 static .ics files will automatically be created for each calendar, 
# under the theme/ical directory
$options{ical_export} = 1;

# you may want to change this to "webcal://" if you prefer the Apple iCal standard.
$options{ical_prefix} = "http://";  
return 1;
