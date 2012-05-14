
sub check_data() {
  if ($options{data_storage_mode} == 0 ) { # flat text files
    if (!(-e "$options{calendars_file}")) {
      $fatal_error=1;$error_info .= "Calendars file $options{calendars_file} not found!\n";
    }
    if (!(-e $options{pending_actions_file})) {
      $fatal_error=1;$error_info .= "New calendars file $options{pending_actions_file} not found!\n";
    }
    if (!(-e $options{events_file})) {
      $fatal_error=1;$error_info .= "Events file $options{events_file} not found!\n";
    }
    
    if ($fatal_error == 0) {  
	    # Remember which files are writable.
	    $writable{calendars_file} = (-w $options{calendars_file});
	    $writable{pending_actions_file} = (-w $options{pending_actions_file});
	    $writable{events_file} = (-w $options{events_file});
	    $writable{email_reminders_datafile} = (-w $options{email_reminders_datafile});
 
	    # If the events file is not writable then we shouldn't
	    # show the Add/Edit events tab on the main page.
	    delete($tab_text[1]) unless $writable{events_file};
    } 
  } else { # DBI
    $writable{calendars_file} = 1;
	  $writable{pending_actions_file} = 1;
	  $writable{events_file} = 1;
	  $writable{email_reminders_datafile} = 1;
	  $writable{users_file} = 1;
  
    my $calendars_table_exists = 1;
    my $pending_actions_table_exists = 1;
    my $events_table_exists = 1;
    my $users_table_exists = 1;
      
      
    # if successful, check whether the calendars table exists  
    my $query_string="select * from $options{calendars_table}";
    $query_string .= " limit 0" if ($options{data_storage_mode} != 2);
    
    my $sth = $dbh->prepare($query_string) || ($error_info .= "Can't prepare $statement: $dbh->errstr\n");
    $sth->execute();
    if ($dbh->errstr ne "") {
      $calendars_table_exists=0;
      $error_info .= $dbh->errstr."\n";
    }
    $sth->finish();

    # check whether the pending_actions table exists  
    $query_string="select * from $options{pending_actions_table}";
    $query_string .= " limit 0" if ($options{data_storage_mode} != 2);

    $sth = $dbh->prepare($query_string) || ($error_info .= "Can't prepare $statement: $dbh->errstr\n");
    $sth->execute();
    if ($dbh->errstr ne "") {
      $pending_actions_table_exists=0;
      $error_info .= $dbh->errstr."\n";
    }
    $sth->finish();

    # check whether the events table exists  
    $query_string="select * from $options{events_table}";
    $query_string .= " limit 0" if ($options{data_storage_mode} != 2);

    $sth = $dbh->prepare($query_string) || ($error_info .= "Can't prepare $statement: $dbh->errstr\n");
    $sth->execute();
    if ($dbh->errstr ne "") {
      $events_table_exists=0;
      $error_info .= $dbh->errstr."\n";
    }
    $sth->finish();
    
    # check whether the users table exists  
    $query_string="select * from $options{users_table}";
    $query_string .= " limit 0" if ($options{data_storage_mode} != 2);
    
    $sth = $dbh->prepare($query_string) || ($error_info .= "Can't prepare $statement: $dbh->errstr\n");
    $sth->execute();
    if ($dbh->errstr ne "") {
      $users_table_exists = 0;
      $error_info .= $dbh->errstr."\n";
    }
    $sth->finish();

    if ($users_table_exists + $events_table_exists + $pending_actions_table_exists + $calendars_table_exists == 4) {
      # everything's ok
    } elsif ($users_table_exists + $events_table_exists + $pending_actions_table_exists + $calendars_table_exists > 0) {
      $fatal_error = 1;
      $error_info .= "Ok, this is a serious problem.  Some of the required tables exist, but not all.\n  Plans can't fix this automatically.\n";
    } elsif ($users_table_exists + $events_table_exists + $pending_actions_table_exists + $calendars_table_exists == 0) {
      if ($q->param('create_tables') ne "1") {
        $fatal_error = 1;
        if ((-e "$options{users_file}") && (-e "$options{calendars_file}") && (-e $options{pending_actions_file}) && (-e $options{events_file})) {    
          $error_info .= <<p1;
\nIt looks like the required tables don't exist. 
\nShall Plans create them for you?
\n<a href="$script_url/$name?create_tables=1">Yes, please create them (but don't import anything)</a>
\n<a href="$script_url/$name?create_tables=1&import_data=1">Yes, please create them, and import all all existing data from <b>$options{users_file}</b> <b>$options{calendars_file}</b>, <b>$options{pending_actions_file}</b>, and <b>$options{events_file}</b>.</a>
p1
        } else {
          $error_info .= <<p1;
\nIt looks like the required tables don't exist.  
\nShall Plans create them for you?
\n<a href="$script_url/$name?create_tables=1">Yes, please create them</a>
p1
        }
      } else { # create the tables!
        $error_info .= "\nCreating calendar and event tables...\n";
        # create the calendars table
        my $query_string="create table $options{calendars_table}(id int(5),xml_data text,update_timestamp int(15));";
        $query_string="create table $options{calendars_table}(id int,xml_data text,update_timestamp int);"  if ($options{data_storage_mode} == 2);
        
        my $sth = $dbh->prepare($query_string) || ($error_info .= "Can't prepare $statement: $dbh->errstr\n");
        $sth->execute();
        if ($dbh->errstr ne "") {
          $fatal_error = 1;
          $error_info .= "error creating table \"$options{calendars_table}\"!\n".$dbh->errstr."\n";
        }
        $sth->finish();
        
        # create the pending actions table
        $query_string="create table $options{pending_actions_table}(id int(5), xml_data text, update_timestamp int(15));";
        $query_string="create table $options{pending_actions_table}(id int, xml_data text, update_timestamp int);"  if ($options{data_storage_mode} == 2);

        $sth = $dbh->prepare($query_string) || ($error_info .= "Can't prepare $statement: $dbh->errstr\n");
        $sth->execute();
        if ($dbh->errstr ne "") {
          $fatal_error = 1;
          $error_info .= "error creating table \"$options{pending_actions_table}\"!\n".$dbh->errstr."\n";
        }
        $sth->finish();
      
        # create the events table
        $query_string="create table $options{events_table}(id int(11),series_id int(11),cal_ids text,start int(15),end int(15),xml_data text,update_timestamp int(15));";
        $query_string="create table $options{events_table}(id int,series_id int(11),cal_ids text,start int,[end] int,xml_data text,update_timestamp int);"  if ($options{data_storage_mode} == 2);
        $sth = $dbh->prepare($query_string) || ($error_info .= "Can't prepare $statement: $dbh->errstr\n");
        $sth->execute();
        if ($dbh->errstr ne "") {
          $fatal_error = 1;
          $error_info .= "error creating table \"$options{events_table}\"!\n".$dbh->errstr."\n";
        }
        $sth->finish();
        
        # create the users table
        $query_string="create table $options{users_table}(id int(5), xml_data text, update_timestamp int(15));";
        $query_string="create table $options{users_table}(id int, xml_data text, update_timestamp int);"  if ($options{data_storage_mode} == 2);

        $sth = $dbh->prepare($query_string) || ($error_info .= "Can't prepare $statement: $dbh->errstr\n");
        $sth->execute();
        if ($dbh->errstr ne "") {
          $fatal_error = 1;
          $error_info .= "error creating table \"$options{users_table}\"!\n".$dbh->errstr."\n";
        }
        $sth->finish();
        
        # either import existing text data, or create a record for the primary calendar
        if ($q->param('import_data') ne "1"  && $fatal_error != 1) { # create primary calendar
          $error_info .= "\nAdding primary calendar...\n";

          $fatal_error = 0;
          # data for the primary calendar   
          my %primary_cal = %default_cal;
          $primary_cal{id}=0;
          $primary_cal{title}="Main Calendar";
          $primary_cal{password}=crypt("12345", $options{salt}); 
          $primary_cal{details}=<<p1;
This is the primary calendar.  You can't delete it (you can only rename it).  
The password for this calendar is "12345", which you should change right away.
This calendar's password is the "master password", and can be used to override 
the password of any other calendar. 
p1
          $primary_cal{update_timestamp}=time();
          
          
          my $cal_xml = &calendar2xml(\%primary_cal);
          
          # add the primary calendar to the table
          my $query_string="insert into $options{calendars_table} (id, xml_data, update_timestamp) values (?, ?, ?);";
          my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
          $sth->execute($primary_cal{id}, $cal_xml, $primary_cal{update_timestamp});
          if ($dbh->errstr ne "") {
            $fatal_error = 1;
            $error_info .= "Error adding primary calendar!\n".$dbh->errstr."\n";
            $error_info .= "$query_string\n";
          } else {
            $fatal_error = 1;
            $error_info = <<p1;
Tables created!<br/>
(you shouldn't ever see this message again.  To prove it, refresh the page or <a href="$script_url/$name">click here</a>.)
p1
          }
          $sth->finish();
        } else { # import data
          $error_info .= "\nImporting data from flat files...\n";
          my $temp = $options{data_storage_mode};
          
          $options{data_storage_mode} = 0;
          &load_calendars();
          &load_actions();
          &load_users();
          &load_events("all");
          $options{data_storage_mode} = $temp;
          
          my @temp_cal_ids = keys %calendars;
          &add_calendars(\@temp_cal_ids);
          
          my @temp_new_cal_ids = keys %new_calendars;
          &add_new_calendars(\@temp_new_cal_ids);
          
          my @temp_event_ids = keys %events;
          &add_events(\@temp_event_ids);
          
          my @temp_user_ids = keys %users;
          foreach $temp_user_id (@temp_user_ids) {
            &add_user($temp_user_id);
          }
          
          foreach $new_cal_id (keys %new_calendars) {
            $debug_info .= "adding new calendar $new_cal_id\n";
            &add_action($new_cal_id, "event");
          }
          
          foreach $new_event_id (keys %new_events) {
            $debug_info .= "adding new event $new_cal_id\n";
            &add_action($new_event_id, "event");
          }
          
          if ($dbh->errstr ne "") {
            $fatal_error = 1;
            $error_info .= "Error importing data!\n".$dbh->errstr."\n";
            $error_info .= "$query_string\n";
          } else {
            $fatal_error = 1;
            $error_info = <<p1;
Tables created, data imported!<br/>
(you shouldn't ever see this message again.  To prove it, refresh the page or <a href="$script_url/$name">click here</a>.)
p1
          }
        }
      }
    }
    #$dbh->disconnect;
  }
}



sub load_calendars {
  my $max_update_timestamp = 0;
  my $latest_cal_id = 0;
  if ($options{data_storage_mode} == 0 ) { # flat text files
    open (FH, "$options{calendars_file}") || {$debug_info.= "unable to open file $options{calendars_file}\n"};
    flock FH,2;
    my @calendar_lines=<FH>;
    close FH;

    # For the calendars, we do "complete" xml parsing (no validation or DTD though)
    foreach $line (@calendar_lines) {
      if ($line !~ /\S/) {next;}           # ignore blank lines
      #if ($line =~ /<\/?xml>/) {next;}    # ignore <xml> and </xml lines>
      my %calendar = %{&xml2calendar($line)};
      next if ($calendar{id} eq "");                 # don't propagate corrupt data.
      $calendars{"$calendar{id}"} = \%calendar;
      
      #the calendar with id 0 is assumed to be the master calendar.
      #its password can be used to approve/edit/delete any event
      #for any calendar
      if ($calendar{id} eq "0") {$master_password = $calendar{password};}
        
      if ($calendar{update_timestamp} > $max_update_timestamp) {
        $max_update_timestamp = $calendar{update_timestamp};
        $latest_cal_id = $calendar{id};
      }
    }
  } else { # SQL database
    my $query_string="select * from  $options{calendars_table};";
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute();

    if ($dbh->errstr ne "") {
      $debug_info .= "Error loading calendars!\n".$dbh->errstr."\n";
      $debug_info .= "query string:\n$query_string\n";
    }

    while(%row = %{$sth->fetchrow_hashref( )} ) {
      my $cal_id = $row{'id'};
      my $line = $row{'xml_data'};
      
      my %calendar = %{&xml2calendar($line)};
      $calendars{$calendar{id}} = \%calendar;

      #the calendar with id 0 is assumed to be the master calendar.
      #its password can be used to approve/edit/delete any event
      #for any calendar
      if ($calendar{id} eq "0") {$master_password = $calendar{password};}
        
      if ($calendar{update_timestamp} > $max_update_timestamp) {
        $max_update_timestamp = $calendar{update_timestamp};
        $latest_cal_id = $calendar{id};
      }
    }
    $sth->finish();
  }
  
  # force all calendars to the same timezone?
  if ($options{force_single_timezone} eq "1") {
    foreach $cal_id (keys %calendars) {
      $calendars{$cal_id}{gmtime_diff} = $calendars{0}{gmtime_diff};
    }
  }
  
}

sub load_actions() {
  my $max_new_cal_timestamp = 0;
  my $max_new_event_timestamp = 0;
  my @lines;
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    open (FH, "$options{pending_actions_file}") || {$debug_info.= "unable to open file $options{pending_actions_file}\n"};
    flock FH,2;
    @lines=<FH>;
    close FH;
  } else { # SQL database
    my $query_string="select * from  $options{pending_actions_table};";
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute();
    if ($dbh->errstr ne "") {
      $debug_info .= "Error loading actions!\n".$dbh->errstr."\n";
      $debug_info .= "query string:\n$query_string\n";
    }

    while(%row = %{$sth->fetchrow_hashref( )}) {
      my $action_id = $row{'id'};
      my $line = $row{'xml_data'};
      push @lines, $line;
    }
    $sth->finish();
  }
 
  %new_events = (); 	
 
  # For the calendars, we do "complete" xml parsing (no validation or DTD though)
  foreach $line (@lines) {
    if ($line !~ /\S/) {next;}          # ignore blank lines
    
    my ($id) = &xml_quick_extract($line, "id");
    $id = &decode($id);
    
    if ($id > $max_action_id) {
      $max_action_id = $id;
    }
      
    my ($type) = &xml_quick_extract($line, "action_type");
    $type = &decode($type);
    
    if ($type eq "new_calendar") {
      my ($data) = &xml_quick_extract($line, "action_data");
      $data = &decode($data);

      my %calendar = %{&xml2calendar($data)};
      $new_calendars{$id} = \%calendar;
 
      $max_new_cal_id = ($calendar{id} > $max_new_cal_id) ? $calendar{id} : $max_new_cal_id;
      
      if ($calendar{update_timestamp} > $max_new_cal_timestamp) {
        $max_new_cal_timestamp = $calendar{update_timestamp};
        $latest_new_cal_id = $calendar{id};
      }
    } elsif ($type eq "new_event") {
      my ($data) = &xml_quick_extract($line, "action_data");
      $data = &decode($data);
    
      my %event = %{&xml2event($data)};
      $new_events{$id} = \%event;
      
      # if this is a recurring event, grab recurrence parms, slap them onto the event data structure
      my ($recurring) = &xml_quick_extract($data, "recurring");
      
      if ($recurring eq "1") {
        my %recurrence_parms;
        
        my ($duration) = &xml_quick_extract($data, "duration");
        $recurrence_parms{'duration'} = &decode($duration);
 
        my ($recurrence_type) = &xml_quick_extract($data, "recurrence_type");
        $recurrence_parms{'recurrence_type'} = &decode($recurrence_type);
        
        my ($custom_months_string) = &xml_quick_extract($data, "custom_months");
        $custom_months_string = &decode($custom_months_string);
        my @custom_months = split(/,/, $custom_months_string);
        $recurrence_parms{'custom_months'} = \@custom_months;
 
        my ($weekday_of_month_type) = &xml_quick_extract($data, "weekday_of_month_type");
        $recurrence_parms{'weekday_of_month_type'} = &decode($weekday_of_month_type);
 
        my ($every_x_days) = &xml_quick_extract($data, "every_x_days");
        $recurrence_parms{'every_x_days'} = &decode($every_x_days);
 
        my ($every_x_weeks) = &xml_quick_extract($data, "every_x_weeks");
        $recurrence_parms{'every_x_weeks'}  = &decode($every_x_weeks);
 
        my ($year_fit_type) = &xml_quick_extract($data, "year_fit_type");
        $recurrence_parms{'year_fit_type'} = &decode($year_fit_type);
 
        my ($recur_end_timestamp) = &xml_quick_extract($data, "recur_end_timestamp");
        $recurrence_parms{'recur_end_timestamp'} = &decode($recur_end_timestamp);
 
        $new_events{$id}{recurring} = \%recurrence_parms;
        $new_events{$id}{recurrence_parms} = \%recurrence_parms;
      }
      
      $max_new_event_id = ($event{id} > $max_new_event_id) ? $event{id} : $max_new_event_id;
      
      if ($event{update_timestamp} > $max_new_event_timestamp) {
        $max_new_event_timestamp = $event{update_timestamp};
        $latest_new_event_id = $event{id};
      }
    }
  }
  
  %latest_new_calendar = %{$new_calendars{$latest_new_cal_id}};
  
}

sub load_users() {
  if ($options{data_storage_mode} == 0 ) { # flat text files
    open (FH, "$options{users_file}") || {$debug_info.= "unable to open file $options{users_file}\n"};
    flock FH,2;
    my @user_lines=<FH>;
    close FH;
    
    foreach $user_line (@user_lines) {
      my %user = %{&xml2user($user_line)};
      $users{$user{id}} = \%user;
      
      if ($user{id} > $max_user_id) {$max_user_id = $user{id};}
    }
  
  } else { # SQL database
    my $query_string="select * from $options{users_table};";
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute();
    if ($dbh->errstr ne "") {
      $debug_info .= "Error loading users!\n".$dbh->errstr."\n";
      $debug_info .= "query string:\n$query_string\n";
    }

    while(%row = %{$sth->fetchrow_hashref( )}) {
      my $id = $row{'id'};
      my $xml_data = $row{'xml_data'};
      my $update_timestamp = $row{'update_timestamp'};
      
      my %user = %{&xml2user($xml_data)};
      $users{$id} = \%user;
      
      if ($id > $max_user_id) {$max_user_id = $user{id};}
    
    }
    $sth->finish();
  }
}


sub load_events() {
	$normalized_timezone = 0;
	# load events for a given number of calendars, within a given time range.
	my ($start, $end, $temp) = @_;

	my @calendar_ids;

	if ( $start eq "all" ) {
	   @calendar_ids = @{$end};
	} else {
	   @calendar_ids = @{$temp};
	}

	if ($options{data_storage_mode} == 0 ) { # flat text files
	open (FH, "$options{events_file}") || {$debug_info.= "unable to open file $options{events_file}\n"};
	flock FH,2;
	my @event_lines=<FH>;
	close FH;

	my $max_update_timestamp = 0;
	my $latest_event_id = 0;

	my $event_loaded_count = 0;
	foreach $line (@event_lines) {
		my $temp_line = substr($line,0,120);     # grab first 180 characters
		$temp_line =~ s/<title.+//;              # remove everything afer evt_label
		$temp_line =~ s/<event>//;               # remove <event>

		$temp_line =~ /<id>(\d+)/;
		my $evt_id = $1;
		next if ($evt_id eq "");

		$temp_line =~ /<start>(.+?)</;
		my $temp_start_timestamp = &decode($1);
		$temp_line =~ /<end>(.+?)</;
		my $temp_end_timestamp = &decode($1);

		if ($temp_end_timestamp < $start && $start ne "all") {next;}  # in the past
		if ($temp_start_timestamp > $end && $start ne "all") {next;}  # in the future

		my @temp_cal_ids;
		if ($temp_line =~ /<cal_ids>(.+?)</) {
			@temp_cal_ids = split(',', $1);
		}

		my $cal_valid = &intersects(\@temp_cal_ids, \@calendar_ids);
		next if ($cal_valid == 0 && $start ne "all");   # event on some other calendar that we don't care about

		$event_loaded_count++;

		# exclude event from merged calendars 
		my %event = %{&xml2event($line)};
		my @current_cal_id_array = ($current_calendar{id});
		next if ($event{block_merge} eq "1" && ! &intersects(\@temp_cal_ids, \@current_cal_id_array));

		$events{$event{id}} = \%event;
    
		$max_event_id = ($event{id} > $max_event_id) ? $event{id} : $max_event_id;
		$max_series_id = ($event{series_id} > $max_series_id) ? $event{series_id} : $max_series_id;

		if ($event{update_timestamp} > $max_update_timestamp) {
			$max_update_timestamp = $event{update_timestamp};
			$latest_event_id = $event{id};
		}
    }
          
	} elsif ($options{data_storage_mode} > 0 ) { # SQL database
		my $query_string;
		if ($start eq "all") {
			$query_string="select * from $options{events_table};";
			$loaded_all_events = 1;
		} else {
			$query_string = "select * from $options{events_table} where (start > $start and end < $end )";
			$query_string = "select * from $options{events_table} where (start > $start and [end] < $end )" if ($options{data_storage_mode} == 2);
			if ($calendar_ids[0] ne "" && $calendar_ids[0] !~ /\D/) {
        
				if ($options{data_storage_mode} == 2) {
					$query_string .= " and ( cal_ids like '$calendar_ids[0]' or cal_ids like '$calendar_ids[0],%' or cal_ids like '%,$calendar_ids[0]' or cal_ids like '%,$calendar_ids[0],%'";
				} else {
					$query_string .= " and ( cal_ids='$calendar_ids[0]' or cal_ids like '$calendar_ids[0],%' or cal_ids like '%,$calendar_ids[0]' or cal_ids like '%,$calendar_ids[0],%'";
				}

				for ($l1=1;$l1<scalar @calendar_ids;$l1++) {
					if ($options{data_storage_mode} == 2) {
						if ($calendar_ids[$l1] ne "" && $calendar_ids[$l1] !~ /\D/) {
							$query_string .= " or cal_ids like '$calendar_ids[$l1]' or cal_ids like '$calendar_ids[$l1],%' or cal_ids like '%,$calendar_ids[$l1]' or cal_ids like '%,$calendar_ids[$l1],%'";
						}
					} else {
						if ($calendar_ids[$l1] ne "" && $calendar_ids[$l1] !~ /\D/) {
							$query_string .= " or cal_ids='$calendar_ids[$l1]' or cal_ids like '$calendar_ids[$l1],%' or cal_ids like '%,$calendar_ids[$l1]' or cal_ids like '%,$calendar_ids[$l1],%'";
						}
					}
				}
				$query_string .= ")";
			}
      
			$query_string .= ";";
		}
    
		my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
		$sth->execute();
		if ($dbh->errstr ne "") {
			$debug_info .= "Error loading events!\n".$dbh->errstr."\n";
			$debug_info .= "query string:\n$query_string\n";
		}

		while(%row = %{$sth->fetchrow_hashref( )}) {
			my $evt_id = $row{'id'};
			my $series_id = $row{'series_id'};
			my $cal_ids_string = $row{'cal_ids'};
			next if ($evt_id eq "");

			my @temp_cal_ids = split(',', $cal_ids_string);

			my $cal_valid = &intersects(\@temp_cal_ids, \@calendar_ids);

			next if ($cal_valid == 0 && $start ne "all");   # event on some other calendar that we don't care about

			my $line = $row{'xml_data'};
			my %event = %{&xml2event($line)};

			# exclude event from merged calendars 
			my %event = %{&xml2event($line)};
			my @current_cal_id_array = ($current_calendar{id});

			next if ($event{block_merge} eq "1" && ! &intersects($event{cal_ids}, \@current_cal_id_array));

			$events{$event{id}} = \%event;

			$max_series_id = ($event{series_id} > $max_series_id) ? $event{series_id} : $max_series_id;
		}
    
    
		# get max event id
		my $query_string="select max(id) from $options{events_table};";
		$sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
		$sth->execute();
		if ($dbh->errstr ne "") {
			$debug_info .= "$dbh->errstr\n";
			$debug_info .= "query string:\n$query_string\n";
		}
		$max_event_id = $sth->fetchrow_array;

		# get latest event
		$query_string="select * from $options{events_table} order by update_timestamp desc limit 0, 1;";
		$query_string="select * from $options{events_table} order by update_timestamp desc, 1;" if ($options{data_storage_mode} == 2);

		$sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
		$sth->execute();
		if ($dbh->errstr ne "") {
			$debug_info .= "$dbh->errstr\n";
			$debug_info .= "query string:\n$query_string\n";
		}
    
		while(%row = %{$sth->fetchrow_hashref( )}) {
			my $evt_id = $row{'id'};
			my $series_id = $row{'series_id'};

			my $line = $row{'xml_data'};
			$line  =~ s/<\/?event>//g;      # remove <event> and </event>

			$latest_event_id = $latest_event{id};
		}
	}
	
}

sub event_exists()  {
	my ($event_id) = @_;
	
	if ( $loaded_all_events ) {
		return defined $events{$event_id};
	}

	if ($options{data_storage_mode} == 0 ) { # flat text files
		open (FH, "$options{events_file}") || {$debug_info.= "unable to open file $options{events_file}\n"};
		flock FH,2;
		my @event_lines=<FH>;
		close FH;

		foreach $line (@event_lines) {
			my $temp_line = substr($line,0,120);     # grab first 180 characters
			$temp_line =~ s/<title.+//;              # remove everything afer evt_label
			$temp_line =~ s/<event>//;               # remove <event>

			$temp_line =~ /<id>(\d+)/;
			my $evt_id = $1;
	
			if ($evt_id == $event_id) {return 1;}  #found! 
		}
	} else { # SQL database
		my $query_string;
		$query_string="select * from $options{events_table} where (id = ?);";

		my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
		$sth->execute($event_id);
		if ($dbh->errstr ne "") {
			$debug_info .= "Error loading events!\n".$dbh->errstr."\n";
			$debug_info .= "query string:\n$query_string\n";
		}

		while(%row = %{$sth->fetchrow_hashref( )}) {
			return 1;
		}  
	}

	return 0;
}

sub load_event() {
	# load a single event.
	my ($event_id) = @_;

	if ($options{data_storage_mode} == 0 ) { # flat text files
		open (FH, "$options{events_file}") || {$debug_info.= "unable to open file $options{events_file}\n"};
		flock FH,2;
		my @event_lines=<FH>;
		close FH;

		my $max_update_timestamp = 0;
		my $latest_event_id = 0;

		my $event_loaded_count = 0;
		foreach $line (@event_lines) {
			my $temp_line = substr($line,0,120);     # grab first 180 characters
			$temp_line =~ s/<title.+//;              # remove everything afer evt_label
			$temp_line =~ s/<event>//;               # remove <event>

			$temp_line =~ /<id>(\d+)/;
			my $evt_id = $1;

			if ($evt_id != $event_id) {next;}   # some other event that we don't care about      

			my %event = %{&xml2event($line)};
			$events{$event{id}} = \%event;

			if ($event{id} > $max_event_id) {$max_event_id = $event{id};}

			if ($event{update_timestamp} > $max_update_timestamp) {
				$max_update_timestamp = $event{update_timestamp};
				$latest_event_id = $event{id};
			}
			last;
		}
	} else { # SQL database
		my $query_string;
		$query_string="select * from $options{events_table} where (id = ?);";


		my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
		$sth->execute($event_id);
		if ($dbh->errstr ne "") {
			$debug_info .= "Error loading events!\n".$dbh->errstr."\n";
			$debug_info .= "query string:\n$query_string\n";
		}

		while(%row = %{$sth->fetchrow_hashref( )}) {
			my $evt_id = $row{'id'};
			my $series_id = $row{'series_id'};

			my $line = $row{'xml_data'};
			my %event = %{&xml2event($line)};
			$events{$event{id}} = \%event;
		}  
	}
}

sub load_remote_events() {
  my ($remote_events_xml, $remote_calendar_id, $remote_cal_gmtime_diff) = @_;
  
  my %remote_calendar_link = %{$current_calendar{remote_background_calendars}{$remote_calendar_id}};
  my @remote_calendars = &xml_quick_extract($remote_events_xml, "calendar");

  foreach $temp (@remote_calendars) {
    my %remote_calendar = %{&xml2calendar($temp)};
  }  

  my @remote_events = &xml_quick_extract($remote_events_xml, "event");
  foreach $temp (@remote_events) {
    my %remote_event = %{&xml2event($temp)};
    
    my $new_remote_event_id = "r".($max_remote_event_id);
    $remote_event{remote_event_id} = $remote_event{id};
    $remote_event{id} = $new_remote_event_id;
    $remote_event{remote_calendar} = \%remote_calendar_link;
    $remote_event{remote_gmtime_diff} = $remote_cal_gmtime_diff;
    
   
    $events{$new_remote_event_id} = \%remote_event;
    
    $max_remote_event_id++;
  }
}



sub get_events_in_series() {
	my ($series_id) = @_;
	my @event_ids=();

	if ( $series_id == "" ) {
		return @event_ids;
	}
  
	if ($options{data_storage_mode} == 0 ) { # flat text files
		&load_events("all") unless $loaded_all_events;
		foreach $event_id (keys %events) {
			if ($events{$event_id}{series_id} eq $series_id) {
				push @event_ids, $event_id;
			}
		}
	} else { # SQL database
		my $query_string;
		$query_string="select * from $options{events_table} where (series_id = ?);";

		my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
		$sth->execute($series_id);
		if ($dbh->errstr ne "") {
			$debug_info .= "Error loading events!\n".$dbh->errstr."\n";
			$debug_info .= "query string:\n$query_string\n";
		}

		while(%row = %{$sth->fetchrow_hashref( )}) {
			my $event_id = $row{'id'};
			my $series_id = $row{'series_id'};

			my $line = $row{'xml_data'};
			my %event = %{&xml2event($line)};
			$events{$event{id}} = \%event;
			push @event_ids, $event_id;
		}  
	}
	return @event_ids;

}



# add an event to the data file
sub add_event() {
  my ($event_id) = @_;
  # temporary copy of the event in question
  my %temp_event = %{$events{$event_id}};

  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text="";
    my $event_xml .= &event2xml($events{$event_id})."\n";
    $event_xml =~ s/(<update_timestamp>)\d*(<\/update_timestamp>)/$1$rightnow$2/;
    open (FH, ">>$options{events_file}") || {$debug_info .= "unable to open file $options{events_file} for writing!\n"};
    flock FH,2;
    print FH $event_xml;
    close FH;
  } else { # DBI
    my $event_xml = &event2xml(\%temp_event);
  
    my $cal_ids_string = "";
    foreach $cal_id (@{$temp_event{cal_ids}}) {
      $cal_ids_string .= "$cal_id";
      if ($cal_id ne @{$temp_event{cal_ids}}[-1]) {
        $cal_ids_string .= ",";
      }
    }
    $cal_ids_string =~ s/,$//;
  
    my $query_string="insert into $options{events_table} (id, series_id, cal_ids, start, end, xml_data, update_timestamp) values (?, ?, ?, ?, ?, ?, ?);";
    $query_string="insert into $options{events_table} (id, series_id, cal_ids, start, [end], xml_data, update_timestamp) values (?, ?, ?, ?, ?, ?, ?);" if ($options{data_storage_mode} == 2);

    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute($temp_event{id}, $temp_event{'series_id'}, $cal_ids_string, $temp_event{start}, $temp_event{end}, $event_xml, $temp_event{update_timestamp});
    if ($dbh->errstr ne "") {
      $fatal_error = 1;
      $debug_info .= "Error adding event!\n".$dbh->errstr."\n";
      $debug_info .= "query string:\n$query_string\n";
    }
    $sth->finish();
  }

  foreach $cal_id (@{$temp_event{cal_ids}}) {
  	&export_ical($calendars{$cal_id});
  }
}

# add multiple events to the data file
sub add_events() {
  my ($event_ids_ref) = @_;
  
  my @event_ids = @{$event_ids_ref};
  if ($options{data_storage_mode} == 0 ) {  # flat text files
    my $out_text="";
    foreach $id (sort {$a <=> $b} @event_ids) {
      $out_text .= &event2xml($events{$id})."\n";
    }
    open (FH, ">>$options{events_file}") || {$debug_info .= "unable to open file $options{events_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else {  # DBI
    foreach $id (@event_ids) {
      next if ($id eq "");
      my %temp_event = %{$events{$id}};
      my $event_xml = &event2xml(\%temp_event);
  
      my $cal_ids_string = "";
      foreach $cal_id (@{$temp_event{cal_ids}}) {
        $cal_ids_string .= "$cal_id";
        if ($cal_id ne @{$temp_event{cal_ids}}[-1]) {
          $cal_ids_string .= ",";
        }
      }
      $cal_ids_string =~ s/,$//;
      
      my $query_string;
      if ($options{data_storage_mode} == 2) {
        $query_string = "insert into $options{events_table} (id, series_id, cal_ids, start, [end], xml_data, update_timestamp) values (?,?,?,?,?,?,?);";
      } else {
        $query_string = "insert into $options{events_table} (id, series_id, cal_ids, start, end, xml_data, update_timestamp) values (?,?,?,?,?,?,?);";
      }
      
      my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
      $sth->execute($temp_event{id}, $temp_event{'series_id'}, $cal_ids_string, $temp_event{start}, $temp_event{end}, $event_xml, $temp_event{update_timestamp});
      if ($dbh->errstr ne "") {
        $fatal_error = 1;
        $debug_info .= "Error adding event!\n($query_string)\n".$dbh->errstr."\n";
        $debug_info .= "query string:\n$query_string\n";
      }
      $sth->finish();
    }
  }

  my %cal_ids_to_export = {};

  foreach $id (@event_ids) {
    next if ($id eq "");
    my %temp_event = %{$events{$id}};
    foreach $cal_id (@{$temp_event{cal_ids}}) {
      $cal_ids_to_export{$cal_id} = 1;
    }
  }
  
  foreach $cal_id (keys %cal_ids_to_export) {
  	&export_ical($calendars{$cal_id});
  }
  
}

# update an event (already present in the data file)
sub update_event() {
  my ($event_id) = @_;
  
  # temporary copy of the event in question
  my %temp_event = %{$events{$event_id}};
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text="";
    foreach $id (sort {$a <=> $b} keys %events) {
      if ($id =~ /\D/) {next};
      my $event_xml = &event2xml($events{$id})."\n";
      $out_text .= $event_xml;
      #if ($id eq $event_id)
      #  {$event_xml =~ s/(<update_timestamp>)\d*(<\/update_timestamp>)/$1$rightnow$2/;}
    }
    open (FH, ">$options{events_file}") || {$debug_info .= "unable to open file $options{events_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
    my $event_xml = &event2xml(\%temp_event);
  
    my $cal_ids_string = "";
    foreach $cal_id (@{$temp_event{cal_ids}}) {
      $cal_ids_string .= "$cal_id";
      if ($cal_id ne @{$temp_event{cal_ids}}[-1]) {
        $cal_ids_string .= ",";
      }
    }
    $cal_ids_string =~ s/,$//;
  
    my $query_string = "update $options{events_table} set cal_ids=?, start=?, end=?, xml_data=?, update_timestamp=? where id=?;";
    $query_string = "update $options{events_table} set cal_ids=?, start=?, [end]=?, xml_data=?, update_timestamp=? where id=?;" if ($options{data_storage_mode} == 2);
    
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute($cal_ids_string, $temp_event{start}, $temp_event{end}, $event_xml, $temp_event{update_timestamp}, $temp_event{id});
    if ($dbh->errstr ne "") {
      $fatal_error = 1;
      $debug_info .= "Error updating event!\n".$dbh->errstr."\n";
      $debug_info .= "query string:\n$query_string\n";
    }
    $sth->finish();
  }
  
  foreach $cal_id (@{$temp_event{cal_ids}}) {
  	&export_ical($calendars{$cal_id});
  }
  
}

# update multiple events
sub update_events() {
  my ($event_ids_ref) = @_;
  my @event_ids = @{$event_ids_ref};
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text="";
    foreach $id (sort {$a <=> $b} keys %events) {
      if ($id =~ /\D/) {next};
      my $event_xml = &event2xml($events{$id})."\n";
      $out_text .= $event_xml;
    }
    open (FH, ">$options{events_file}") || {$debug_info .= "unable to open file $options{events_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
    # temporary copy of the event in question
    foreach $event_id (@event_ids) {   
      my %temp_event = %{$events{$event_id}};
      my $event_xml = &event2xml(\%temp_event);
  
      my $cal_ids_string = "";
      foreach $cal_id (@{$temp_event{cal_ids}}) {
        $cal_ids_string .= "$cal_id";
        if ($cal_id ne @{$temp_event{cal_ids}}[-1]) {
          $cal_ids_string .= ",";
        }
      }
      $cal_ids_string =~ s/,$//;
  
      my $query_string="update $options{events_table} set cal_ids=?, start=?, end=?, xml_data=?, update_timestamp=? where id=?;";
      $query_string="update $options{events_table} set cal_ids=?, start=?, [end]=?, xml_data=?, update_timestamp=? where id=?;" if ($options{data_storage_mode} == 2);

      my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
      $sth->execute($cal_ids_string, $temp_event{start}, $temp_event{end}, $event_xml, $temp_event{update_timestamp}, $temp_event{id});
      if ($dbh->errstr ne "") {
        $fatal_error = 1;
        $debug_info .= "Error updating event!\n".$dbh->errstr."\n";
        $debug_info .= "query string:\n$query_string\n";
      }
      $sth->finish();
    }
  }


  my %cal_ids_to_export = {};

  foreach $id (@event_ids) {
    next if ($id eq "");
    my %temp_event = %{$events{$id}};
    foreach $cal_id (@{$temp_event{cal_ids}}) {
      $cal_ids_to_export{$cal_id} = 1;
    }
  }
  
  foreach $cal_id (keys %cal_ids_to_export) {
  	&export_ical($calendars{$cal_id});
  }

  
}

# delete an event
sub delete_event() {
  my ($event_id) = @_;
  my @cal_ids_to_update = @{$events{$event_id}{cal_ids}};
  
  delete $events{$event_id};
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text="";
    foreach $id (sort {$a <=> $b} keys%events) {
      if ($id =~ /\D/) {next};
      $out_text .= &event2xml($events{$id})."\n";
    }
    open (FH, ">$options{events_file}") || {$debug_info .= "unable to open file $options{events_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
    my $query_string="delete from $options{events_table} where id=?;";
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute($event_id);
    if ($dbh->errstr ne "") {
      $fatal_error = 1;
      $debug_info .= "Error deleting event!\n".$dbh->errstr."\n";
      $debug_info .= "query string:\n$query_string\n";
    }
    $sth->finish();
  }
  
  foreach $cal_id (@cal_ids_to_update) {
  	next if ($cal_id eq "");
  	&export_ical($calendars{$cal_id});
  }
  
}

# delete multiple events
sub delete_events() {
  my ($event_ids_ref) = @_;
  my @event_ids = @{$event_ids_ref};
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    foreach $event_id (@event_ids) {delete $events{$event_id};}

    my $out_text="";
    foreach $id (sort {$a <=> $b} keys%events) {
      if ($id =~ /\D/) {next};
      $out_text .= &event2xml($events{$id})."\n";
    }
    open (FH, ">$options{events_file}") || {$debug_info .= "unable to open file $options{events_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
    foreach $event_id (@event_ids) {   
      my $query_string="delete from $options{events_table} where id=$event_id;";
      my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
      $sth->execute();
      if ($dbh->errstr ne "") {
        $fatal_error = 1;
        $debug_info .= "Error deleting event!\n".$dbh->errstr."\n";
        $debug_info .= "query string:\n$query_string\n";
      }
      $sth->finish();
    }
  }
}

# delete all events
sub delete_all_events() {
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    foreach $event_id (keys %events) {delete $events{$event_id};}

    open (FH, ">$options{events_file}") || {$debug_info .= "unable to open file $options{events_file} for writing!\n"};
    flock FH,2;
    print FH "";
    close FH;
  } else { # DBI
      my $query_string="delete from $options{events_table} where 1";
      my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
      $sth->execute();
      if ($dbh->errstr ne "") {
        $fatal_error = 1;
        $debug_info .= "Error deleting all events!\n".$dbh->errstr."\n";
        $debug_info .= "query string:\n$query_string\n";
      }
      $sth->finish();
  }
}


sub add_action() {
  my ($action_id, $action_type) = @_;
  my $out_text = "";
  
  if ($options{data_storage_mode} == 0 ) {  # flat text files
    # write out the entire file!  Grossly inefficient, but that's how it goes if you don't use a DB.
    foreach $id (sort {$a <=> $b} keys %new_calendars) {
      my $xml = &calendar2xml($new_calendars{$id});
      #if ($id eq $cal_id)
      #  {$cal_xml =~ s/(<update_timestamp>)\d*(<\/update_timestamp>)/$1$rightnow$2/;}
      $out_text .= "<id>$id</id><action_type>new_calendar</action_type><action_data>".&encode($xml)."</action_data>\n";
    }
    
    foreach $id (sort {$a <=> $b} keys %new_events) {
      my $xml = &event2xml($new_events{$id});
      
      if ($new_events{$id}{recurring} ne "") { # add extra fields that will be needed if this event is approved.
        $xml .= &xml_store(1, "recurring");
        $xml .= "<recurrence_parms>";
        foreach $recurrence_parm (keys %{$new_events{$id}{recurrence_parms}}) {
          $xml .= &xml_store($new_events{$id}{recurrence_parms}{$recurrence_parm}, $recurrence_parm);
        }
        $xml .= "</recurrence_parms>";
      }
      $out_text .= "<id>$id</id><action_type>new_event</action_type><action_data>".&encode($xml)."</action_data>\n";
    }

    open (FH, ">$options{pending_actions_file}") || {$debug_info.= "unable to open file $options{pending_actions_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
  
    my $out_text = "";
    if ($action_type eq "new_calendar") {
      my $xml = &calendar2xml($new_calendars{$action_id});
      $out_text .= "<id>$action_id</id><action_type>new_calendar</action_type><action_data>".&encode($xml)."</action_data>\n";
    } elsif ($action_type eq "new_event") {
      my $xml = &event2xml($new_events{$action_id});
      
      if ($new_events{$action_id}{recurring} ne "") { # add extra fields that will be needed if this event is approved.
      
        $xml .= &xml_store(1, "recurring");
        $xml .= "<recurrence_parms>";
        foreach $recurrence_parm (keys %{$new_events{$action_id}{recurrence_parms}}) {
          $xml .= &xml_store($new_events{$action_id}{recurrence_parms}{$recurrence_parm}, $recurrence_parm);
        }
        $xml .= "</recurrence_parms>";
      }
      $out_text .= "<id>$action_id</id><action_type>new_event</action_type><action_data>".&encode($xml)."</action_data>\n";
    }

    # insert the action to the table
    my $query_string = "insert into $options{pending_actions_table} (id, xml_data, update_timestamp) values (?,?,?);";
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute($action_id, $out_text, $rightnow);
    if ($dbh->errstr ne "") {
      $fatal_error = 1;
      $error_info .= "Error adding new calendar!\n".$dbh->errstr."\n";
      $error_info .= "$query_string\n";
    }
  }
}

sub add_new_calendars() { # add multiple calendars (this is used for data conversion)
  my ($add_new_cal_ids_ref) = @_;
  my @add_new_cal_ids = @{$add_new_cal_ids_ref};
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
  } else { # DBI
    foreach $new_cal_id (@add_new_cal_ids) {
      my $new_cal_xml = &calendar2xml($new_calendars{$new_cal_id});
      my $query_string="insert into $options{calendars_table} (id, xml_data, update_timestamp) values (?, ?, ?);";
      my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
      $sth->execute($new_cal_id, $new_cal_xml, $new_calendars{$new_cal_id}{update_timestamp});
      if ($dbh->errstr ne "") {
        $debug_info .= "Error adding new calendar!\n".$dbh->errstr."\n";
        $debug_info .= "$query_string\n";
      }
    }
  }
}

sub delete_pending_actions() { # this is called after a record is transferred from new_calendars to calendars
  my ($temp1) = @_;
  
  my @pending_actions_to_delete = @{$temp1};
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    # write out the entire file!  Grossly inefficient, but that's how it goes if you don't use a DB.
    foreach $id (sort {$a <=> $b} keys %new_calendars) {
      if (&contains(\@pending_actions_to_delete, $id)) {next;}
      my $xml = &calendar2xml($new_calendars{$id});
      #if ($id eq $cal_id)
      #  {$cal_xml =~ s/(<update_timestamp>)\d*(<\/update_timestamp>)/$1$rightnow$2/;}
      $out_text .= "<id>$id</id><action_type>new_calendar</action_type><action_data>".&encode($xml)."</action_data>\n";
    }
    
    foreach $id (sort {$a <=> $b} keys %new_events) {
      if (&contains(\@pending_actions_to_delete, $id)) {next;}
      
      my $xml = &event2xml($new_events{$id});
      
      if ($new_events{$id}{recurring} ne "") # add extra fields that will be needed if this event is approved.
      {
        $xml .= &xml_store(1, "recurring_event");
        $xml .= "<recurrence_parms>";
        foreach $recurrence_parm (keys %{$new_events{$id}{recurrence_parms}}) {
          $xml .= &xml_store($new_events{$id}{recurrence_parms}{$recurrence_parm}, $recurrence_parm);
        }
        $xml .= "</recurrence_parms>";
      }
      
      #if ($id eq $cal_id)
      #  {$cal_xml =~ s/(<update_timestamp>)\d*(<\/update_timestamp>)/$1$rightnow$2/;}
      $out_text .= "<id>$id</id><action_type>new_event</action_type><action_data>".&encode($xml)."</action_data>\n";
    }

    open (FH, ">$options{pending_actions_file}") || {$debug_info.= "unable to open file $options{pending_actions_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
    foreach $action_id (@pending_actions_to_delete) {
      my $query_string="delete from $options{pending_actions_table} where id=?;";
      my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
      $sth->execute($action_id);
      if ($dbh->errstr ne "") {
        $debug_info .= "Error deleting pending calendar after approval!\n".$dbh->errstr."\n";
        $debug_info .= "$query_string\n";
      }
    }
  }
}

sub add_calendars() { # add multiple calendars (this is used for data conversion)
  my ($add_cal_ids_ref) = @_;
  my @add_cal_ids = @{$add_cal_ids_ref};
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text="";
    # write out the entire file!  Grossly inefficient, but that's how it goes if you don't use a DB.
    foreach $calendar_id (sort {$a <=> $b} keys %calendars) {
      my $cal_xml = &calendar2xml($calendars{$calendar_id})."\n";
      $out_text .= $cal_xml;
    }
    
    open (FH, ">$options{calendars_file}") || {$debug_info.= "unable to open file $options{calendars_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
    foreach $cal_id (@add_cal_ids) {
      if ($cal_id eq "") {next};

      my $cal_xml = &calendar2xml($calendars{$cal_id});
      my $query_string="insert into $options{calendars_table} (id, xml_data, update_timestamp) values (?, ?, ?);";
      my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
      $sth->execute($cal_id, $cal_xml, $calendars{$cal_id}{update_timestamp});
      if ($dbh->errstr ne "") {
        $debug_info .= "Error adding calendar!\n($query_string)\n".$dbh->errstr."\n";
        $debug_info .= "$query_string\n";
      }
    }
  }
}




sub update_calendar(){ 
  my ($cal_id) = @_;
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text="";
    # write out the entire file!  Grossly inefficient, but that's how it goes if you don't use a DB.
    foreach $calendar_id (sort {$a <=> $b} keys %calendars) {
      my $cal_xml = &calendar2xml($calendars{$calendar_id})."\n";
      $out_text .= $cal_xml;
    }
    
    open (FH, ">$options{calendars_file}") || {$debug_info.= "unable to open file $options{calendars_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
    my $cal_xml = &calendar2xml($calendars{$cal_id});
 
    # add the primary calendar to the table
    my $query_string="update $options{calendars_table} set xml_data=?, update_timestamp=? where id=?;";
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute($cal_xml, $calendars{$cal_id}{update_timestamp}, $cal_id);
    if ($dbh->errstr ne "") {
      $fatal_error = 1;
      $error_info .= "Error updating calendar!\n".$dbh->errstr."\n";
      $error_info .= "$query_string\n";
    }
  }
  $calendars{$cal_id}{'update_timestamp'} = time();
  &export_ical($calendars{$cal_id});
}


sub update_calendars() { # update multiple calendars
  my ($update_cal_ids_ref) = @_;
  my @update_cal_ids = @{$update_cal_ids_ref};
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text="";
    # write out the entire file!  Grossly inefficient, but that's how it goes if you don't use a DB.
    foreach $calendar_id (sort {$a <=> $b} keys %calendars) {
      my $cal_xml = &calendar2xml($calendars{$calendar_id})."\n";
      $out_text .= $cal_xml;
    }
    
    open (FH, ">$options{calendars_file}") || {$debug_info.= "unable to open file $options{calendars_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
    foreach $cal_id (@update_cal_ids) {
      my $cal_xml = &calendar2xml($calendars{$cal_id});
      my $query_string="update $options{calendars_table} set xml_data=?, update_timestamp=? where id=?;";
      my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
      $sth->execute($cal_xml, $calendars{$cal_id}{update_timestamp}, $cal_id);
      if ($dbh->errstr ne "") {
        $debug_info .= "Error updating calendar!\n".$dbh->errstr."\n";
        $debug_info .= "$query_string\n";
      }
    }
  }

  foreach $cal_id (@update_cal_ids) {
  	$calendars{$cal_id}{'update_timestamp'} = time();
  	&export_ical($calendars{$cal_id});
  }
}


sub delete_calendar() {
  my ($cal_id) = @_;
  delete $calendars{$cal_id};
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text ="";
    # write out the entire file!  Grossly inefficient, but that's how it goes if you don't use a DB.
    foreach $calendar_id (sort {$a <=> $b} keys %calendars) {
      next if ($calendar_id eq "");
      my $cal_xml = &calendar2xml($calendars{$calendar_id})."\n";
      $out_text .= $cal_xml;
    }
    
    open (FH, ">$options{calendars_file}") || {$debug_info.= "unable to open file $options{calendars_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI      
    my $query_string="delete from $options{calendars_table} where id=?;";
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute($cal_id);
    if ($dbh->errstr ne "") {
      $debug_info .= "Error deleting calendar!\n".$dbh->errstr."\n";
      $debug_info .= "$query_string\n";
    }
  }
}


sub add_user() {
  my ($user_id) = @_;
  # temporary copy of the event in question
  my %user = %{$users{$user_id}};

  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text="";
    # write out the entire file!  Grossly inefficient, but that's how it goes if you don't use a DB.
    foreach $user_id (sort {$a <=> $b} keys %users) {
      my $xml = &user2xml($users{$user_id})."\n";
      $xml =~ s/(<timestamp>)\d*(<\/timestamp>)/$1$rightnow$2/;
      $out_text .= $xml;
    }
    open (FH, ">$options{users_file}") || {$debug_info.= "unable to open file $options{users_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
    my $xml = &user2xml($users{$user_id})."\n";
    $xml =~ s/(<timestamp>)\d*(<\/timestamp>)/$1$rightnow$2/;
    $out_text .= $xml;
      
    my $query_string="insert into $options{users_table} (id, xml_data, update_timestamp) values (?, ?, ?);";
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute($user_id, $xml, $rightnow);
    if ($dbh->errstr ne "") {
      $debug_info .= "Error adding user!\n".$dbh->errstr."\n";
      $debug_info .= "$query_string\n";
    }

  }
}

sub update_user() {
  my ($user_id) = @_;
  
  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text="";
    # write out the entire file!  Grossly inefficient, but that's how it goes if you don't use a DB.
    foreach $user_id (sort {$a <=> $b} keys %users) {
      next if ($user_id eq "");
      my $xml = &user2xml($users{$user_id})."\n";
      $xml =~ s/(<timestamp>)\d*(<\/timestamp>)/$1$rightnow$2/;
      $out_text .= $xml;
    }
    open (FH, ">$options{users_file}") || {$debug_info.= "unable to open file $options{users_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;
  } else { # DBI
    my $xml = &user2xml($users{$user_id})."\n";
    $xml =~ s/(<timestamp>)\d*(<\/timestamp>)/$1$rightnow$2/;
    $out_text .= $xml;
    
    my $query_string="update $options{users_table} set xml_data=?, update_timestamp=? where id=?;";
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute($xml, $rightnow, $user_id);
    if ($dbh->errstr ne "") {
      $fatal_error = 1;
      $debug_info .= "Error updating user!\n".$dbh->errstr."\n";
      $debug_info .= "query string:\n$query_string\n";
    }
    $sth->finish();
  }
}

sub delete_user() {
  my ($user_id) = @_;
  
  delete $users{$user_id};

  if ($options{data_storage_mode} == 0 ) { # flat text files
    my $out_text="";
    # write out the entire file!  Grossly inefficient, but that's how it goes if you don't use a DB.
    foreach $user_id (sort {$a <=> $b} keys %users) {
      next if ($user_id eq "");
      my $xml = &user2xml($users{$user_id})."\n";
      $xml =~ s/(<timestamp>)\d*(<\/timestamp>)/$1$rightnow$2/;
      $out_text .= $xml;
    }
    
    open (FH, ">$options{users_file}") || {$debug_info.= "unable to open file $options{users_file} for writing!\n"};
    flock FH,2;
    print FH $out_text;
    close FH;

  } else { # DBI
    my $query_string="delete from $options{users_table} where id=?;";
    my $sth = $dbh->prepare($query_string) or ($error_info .= "Can't prepare $query_string:\n");
    $sth->execute($user_id);
    if ($dbh->errstr ne "") {
      $debug_info .= "Error deleting user!\n".$dbh->errstr."\n";
      $debug_info .= "$query_string\n";
    }
  }
}



sub calendar2xml() {
   my ($calendar_ref) = @_;
   
   my %calendar = %{$calendar_ref};
   
   #$error_info .= "Calendar title: $calendar{title}\n";
   
   my $xml_data = "<calendar>";
   $xml_data .= &xml_store($calendar{id}, "id");
   $xml_data .= &xml_store($calendar{type}, "type");
   $xml_data .= &xml_store($calendar{url}, "url");
   $xml_data .= &xml_store($calendar{title}, "title");
   $xml_data .= &xml_store($calendar{details}, "details");
   $xml_data .= &xml_store($calendar{link}, "link");
   $xml_data .= &xml_store($calendar{password}, "admin_password");
   
  # add local background calendars            
  foreach $local_background_calendar_id (sort {$a <=> $b} keys %{$calendar{local_background_calendars}}) {$xml_data .= "<background_calendar><id>$local_background_calendar_id</id></background_calendar>";}

  # add remote background calendars
  foreach $remote_background_calendar_id (sort {$a <=> $b} keys %{$calendar{remote_background_calendars}}) {
    my %c = %{$calendar{remote_background_calendars}{$remote_background_calendar_id}};
    if (lc $c{type} eq "plans") {
      $xml_data .= "<remote_background_calendar><id>$remote_background_calendar_id</id><type>$c{type}</type><version>$c{version}</version><remote_id>$c{remote_id}</remote_id><url>$c{url}</url><title>$c{title}</title><password>$c{password}</password></remote_background_calendar>";
    }
  }
    
  # add selectable calendars            
  foreach $selectable_calendar (sort {$a <=> $b} keys %{$calendar{selectable_calendars}}) {$xml_data .= "<selectable_calendar>$selectable_calendar</selectable_calendar>";}
    
  # make sure the calendar can select itself.
  if ($calendar{selectable_calendars}{$calendar{id}} ne "1") {$calendar{selectable_calendars}{$calendar{id}} = 1;}
    
    
  # add other fields            
  $xml_data .= &xml_store($calendar{new_calendars_automatically_selectable}, "new_calendars_automatically_selectable");
  $xml_data .= &xml_store($calendar{list_background_calendars_together}, "list_background_calendars_together");
  $xml_data .= &xml_store($calendar{calendar_events_color}, "calendar_events_color");
  $xml_data .= &xml_store($calendar{background_events_display_style}, "background_events_display_style");
  $xml_data .= &xml_store($calendar{background_events_fade_factor}, "background_events_fade_factor");
  $xml_data .= &xml_store($calendar{background_events_color}, "background_events_color");
  $xml_data .= &xml_store($calendar{default_number_of_months}, "default_number_of_months");
  $xml_data .= &xml_store($calendar{max_number_of_months}, "max_number_of_months");
  $xml_data .= &xml_store($calendar{gmtime_diff}, "gmtime_diff");
  $xml_data .= &xml_store($calendar{date_format}, "date_format");
  $xml_data .= &xml_store($calendar{week_start_day}, "week_start_day");
  $xml_data .= &xml_store($calendar{event_change_email}, "event_change_email");
  $xml_data .= &xml_store($calendar{custom_template}, "custom_template");
  $xml_data .= &xml_store($calendar{custom_stylesheet}, "custom_stylesheet");
  $xml_data .= &xml_store($calendar{update_timestamp}, "update_timestamp");
  $xml_data .= &xml_store($calendar{allow_remote_calendar_requests}, "allow_remote_calendar_requests");
  $xml_data .= &xml_store($calendar{remote_calendar_requests_require_password}, "remote_calendar_requests_require_password");
  $xml_data .= &xml_store($calendar{remote_calendar_requests_password}, "remote_calendar_requests_password");
  
  $xml_data .= "</calendar>";

  return $xml_data;
}

sub calculate_event_days() {
  my ($start, $end, $id) = @_;
  my $days = 1;
  my $duration = $end - $start;
  return 1 if ($duration < 0) ;

  $days = 0;
  if (($duration+1) % 86400 == 0)  # all-day event
    {$days = int(($duration)/86400)+1;}
  else {  # partial-day event
    # calculate days
    my $mday = 99;
    for (my $i=$start;$i<$end;$i+=3600) {
      if ((gmtime $i)[3] != $mday) {
        $days++;
        $mday = (gmtime $i)[3];
      }
    }
  }
  return $days;
}

sub xml2event() {
  my ($xml) = @_;
  my $event;
    
  $xml  =~ s/<\/?event>//g;      # remove <event> and </event>
  
  my ($id) = &xml_quick_extract($xml, "id");
  $id = &decode($id);

  my ($cal_id) = &xml_quick_extract($xml, "cal_id");
  $cal_id = &decode($cal_id);
  
  my ($cal_ids) = &xml_quick_extract($xml, "cal_ids");
  $cal_ids = &decode($cal_ids);
  
  my ($evt_start) = &xml_quick_extract($xml, "start");
  $evt_start = &decode($evt_start);
  
  my ($evt_end) = &xml_quick_extract($xml, "end");
  $evt_end = &decode($evt_end);
  
  my $evt_gmtime_start = $evt_start;
  my $evt_gmtime_end = $evt_end;

  my ($series_id) = &xml_quick_extract($xml, "series_id");
  $series_id = &decode($series_id);

  my ($evt_title) = &xml_quick_extract($xml, "title");
  $evt_title = &decode($evt_title);
  
  my ($evt_details) = &xml_quick_extract($xml, "details");
  $evt_details = &decode($evt_details);

  my ($block_merge) = &xml_quick_extract($xml, "block_merge");
  $block_merge = &decode($block_merge);
  
  my $details_url = "";
  if ($evt_details =~ /^http.*:\/\/.+\s*$/) {$details_url=1;}
  
  
  my ($evt_icon) = &xml_quick_extract($xml, "icon");
  $evt_icon = &decode($evt_icon);
  
  my ($evt_bgcolor) = &xml_quick_extract($xml, "bgcolor");
  $evt_bgcolor = &decode($evt_bgcolor);
  
  my ($evt_unit_number) = &xml_quick_extract($xml, "unit_number");
  $evt_unit_number = &decode($evt_unit_number);
  
  my $update_timestamp = 0;
  ($update_timestamp) = &xml_quick_extract($xml, "update_timestamp");

  my $event_duration = $evt_end - $evt_start;

  my $evt_days = 1; # 1 by default - recalculated later
  
  # create cal_ids hash
  my @cal_ids_array;
  
  if ($cal_id ne "") {
    push @cal_ids_array, $cal_id;
  } else {
    @cal_ids_array = split(',', $cal_ids);
  }
  
  
  my $all_day_event = "";
  my $no_end_time = "";
  if (($event_duration+1) % 86400 == 0) {
    $all_day_event = 1;
    $evt_days = &calculate_event_days($evt_start, $evt_end,  $id);
  } else {
    $no_end_time = 1 if ($event_duration == 1);
  
    my %this_calendar;
    if ($current_cal_id eq "") {
      %this_calendar = %{$calendars{$cal_ids_array[0]}};
    } else {
      %this_calendar = %{$calendars{$current_cal_id}};
    }
    
    my $timezone_offset = $this_calendar{gmtime_diff}*3600;
    
    # calculate_event_days is dependent on the timezone offset of the current calendar
    $evt_days = &calculate_event_days($evt_start+$timezone_offset, $evt_end+$timezone_offset,  $id);
  }

  $event = {id => $id, 
               cal_ids => \@cal_ids_array, 
               start => $evt_start, 
               end => $evt_end, 
               gmtime_start => $evt_gmtime_start, 
               gmtime_end => $evt_gmtime_end, 
               days => $evt_days,
               series_id => $series_id, 
               all_day_event => $all_day_event,
               no_end_time => $no_end_time,
               details_url => $details_url,
               title => $evt_title, 
               details => $evt_details,
               block_merge => $block_merge,
               icon => $evt_icon,
               bgcolor => $evt_bgcolor,
               unit_number => $evt_unit_number,
               update_timestamp => $update_timestamp};
  
  return $event;
}


sub xml2user() {
  my ($xml) = @_;
  my $user;
  
  my ($id) = &xml_quick_extract($xml, "id");
  $id = &decode($id);
  
  my ($name) = &xml_quick_extract($xml, "name");
  $name = &decode($name);
  
  my ($notes) = &xml_quick_extract($xml, "notes");
  $notes = &decode($notes);
  
  my ($password) = &xml_quick_extract($xml, "password");
  $password = &decode($password);
  
  my ($timestamp) = &xml_quick_extract($xml, "timestamp");
  $timestamp = &decode($timestamp);
  
  my %cal_refs;
  my @calendars = &xml_quick_extract($xml, "calendar");
  foreach $calendar_xml (@calendars) {
    my ($cal_id) = &xml_quick_extract($calendar_xml, "cal_id");
    $cal_id = &decode($cal_id);
    
    my ($edit_calendar) = &xml_quick_extract($calendar_xml, "edit_calendar");
    $edit_calendar = &decode($edit_calendar);
    
    my ($edit_events) = &xml_quick_extract($calendar_xml, "edit_events");
    $edit_events = &decode($edit_events);
    
    $cal_refs{$cal_id}{edit_calendar} = $edit_calendar;
    $cal_refs{$cal_id}{edit_events} = $edit_events;
  }

  $user = {id => $id, 
           name => $name, 
           notes => $notes, 
           password => $password,
           timestamp => $timestamp,
           calendars => \%cal_refs
           };
           
  return $user;
}

sub user2xml() {
  my ($user_ref) = @_;
  my %user = %{$user_ref};

  my $xml_data = "<user>";

  $xml_data .= &xml_store($user{id}, "id");
  $xml_data .= &xml_store($user{name}, "name");
  $xml_data .= &xml_store($user{notes}, "notes");
  $xml_data .= &xml_store($user{password}, "password");
  
  
  foreach $calendar_id (keys %{$user{calendars}}) {
    $xml_data .= "<calendar><cal_id>$calendar_id</cal_id>";
    #$xml_data .= "<edit_calendar>$user{calendars}{$calendar_id}{edit_calendar}</edit_calendar>";
    $xml_data .= "<edit_events>$user{calendars}{$calendar_id}{edit_events}</edit_events>";
    $xml_data .= "</calendar>";
  }
  $xml_data .= &xml_store($user{timestamp}, "timestamp");

  $xml_data .= "</user>";

  return $xml_data;
}




sub xml2calendar() {
  my ($xml) = @_;
  
  my $calendar;
  my @calendar_users;
  
  $xml =~ s/<\/?calendar>//g;      # remove <calendar> and </calendar>
  
  my ($cal_id) = &xml_quick_extract($xml, "id");
  
  my ($cal_type) = &xml_quick_extract($xml, "type");
  $cal_type = &decode($cal_type);
  $cal_type = "plans" if ($cal_type eq "");
  
  
  my ($cal_url) = &xml_quick_extract($xml, "url");
  $cal_url = &decode($cal_url);
  
  my ($cal_title) = &xml_quick_extract($xml, "title");
  $cal_title = &decode($cal_title);
  
  my ($cal_details) = &xml_quick_extract($xml, "details");
  $cal_details = &decode($cal_details);
  
  my ($cal_link) = &xml_quick_extract($xml, "link");
  $cal_link = &decode($cal_link);
  
  my ($cal_password) = &xml_quick_extract($xml, "admin_password");
  $cal_password = &decode($cal_password);
  
  
  my $update_timestamp=0;
  ($update_timestamp) = &xml_quick_extract($xml, "update_timestamp");
  $update_timestamp = 0 if ($update_timestamp eq "");
  
  # extract local background calendars
  my @temp = &xml_quick_extract($xml, "background_calendar");
  my %local_background_calendars;
  my $num_background_calendars = scalar @temp;
  foreach $background_calendar (@temp) {
    my ($id) = &xml_quick_extract($background_calendar, "id");
    $local_background_calendars{$id} = 1;
  }
  
  # extract remote background calendars
  my @temp = &xml_quick_extract($xml, "remote_background_calendar");
  my %remote_background_calendars;
  my $num_remote_background_calendars = scalar @temp;
  foreach $remote_background_calendar (@temp) {
    my ($id) = &xml_quick_extract($remote_background_calendar, "id");
    my ($type) = &xml_quick_extract($remote_background_calendar, "type");
    my ($version) = &xml_quick_extract($remote_background_calendar, "version");
    my ($remote_id) = &xml_quick_extract($remote_background_calendar, "remote_id");
    my ($title) = &xml_quick_extract($remote_background_calendar, "title");
    my ($url) = &xml_quick_extract($remote_background_calendar, "url");
    my ($password) = &xml_quick_extract($remote_background_calendar, "password");
    
    $remote_background_calendars{$id} = {id => $id, 
                                        type => $type, 
                                        version => $version, 
                                        remote_id => $remote_id, 
                                        title => $title, 
                                        url => $url,
                                        password => $password}
  }
  
  # extract selectable calendars
  my %selectable_calendars;
  @temp = &xml_quick_extract($xml, "selectable_calendar");
  foreach $selectable_calendar (@temp) {
    $selectable_calendars{$selectable_calendar} = 1;
  }
  
  my ($new_calendars_automatically_selectable) = &xml_quick_extract($xml, "new_calendars_automatically_selectable");
  $new_calendars_automatically_selectable = "no" if ($new_calendars_automatically_selectable eq "");
  
  my ($list_background_calendars_together) = &xml_quick_extract($xml, "list_background_calendars_together");
  $list_background_calendars_together = "no" if ($list_background_calendars_together eq "");

  my ($calendar_events_color) = &xml_quick_extract($xml, "calendar_events_color");
  $calendar_events_color = &decode($calendar_events_color);
  
  my ($background_events_display_style) = &xml_quick_extract($xml, "background_events_display_style");
  $background_events_display_style = "normal" if ($background_events_display_style eq "");
  
  my ($background_events_fade_factor) = &xml_quick_extract($xml, "background_events_fade_factor");
  $background_events_fade_factor = 1 if ($background_events_fade_factor eq "" || $background_events_fade_factor < 1);
  
  my ($background_events_color) = &xml_quick_extract($xml, "background_events_color");
  $background_events_color = &decode($background_events_color);
  $background_events_color = "#ffffff" if ($background_events_color eq "");

  my ($default_number_of_months) = &xml_quick_extract($xml, "default_number_of_months");
  $default_number_of_months = 1 if ($default_number_of_months eq "");
   
  my ($max_number_of_months) = &xml_quick_extract($xml, "max_number_of_months");
  $max_number_of_months = 24 if ($max_number_of_months eq "");
  
  my ($gmtime_diff) = &xml_quick_extract($xml, "gmtime_diff");
  $gmtime_diff = &decode($gmtime_diff);
  $gmtime_diff = 0 if ($gmtime_diff eq "");
  
  my ($date_format) = &xml_quick_extract($xml, "date_format");
  $date_format = &decode($date_format);
  $date_format = "mm/dd/yy" if ($date_format eq "");
  
  my ($week_start_day) = &xml_quick_extract($xml, "week_start_day");
  $week_start_day = "0" if ($week_start_day eq "");
  
  my ($event_change_email) = &xml_quick_extract($xml, "event_change_email");
  $event_change_email = &decode($event_change_email);
  
  my @emails = split(/\s+/, $event_change_email);
  my @add_emails;
  my @update_emails;
  my @delete_emails;
  
  foreach my $email (@emails) {
    next if ($email !~ /\S/); # ignore blanks
    
    push @add_emails, $1 if ($email =~ /add:(.+)/);
    push @update_emails, $1 if ($email =~ /update:(.+)/ || $email =~ /change:(.+)/);
    push @delete_emails, $1 if ($email =~ /delete:(.+)/ || $email =~ /del:(.+)/);
    
    if ($email !~ /(add:|update:|change:|delete:|del:)/) {    # if just a plain email address, add to all 3 categories
      push @add_emails, $email;
      push @update_emails, $email;
      push @delete_emails, $email;
    }
  }

  my ($custom_template) = &xml_quick_extract($xml, "custom_template");
  $custom_template = &decode($custom_template);
  
  my ($custom_stylesheet) = &xml_quick_extract($xml, "custom_stylesheet");
  $custom_stylesheet = &decode($custom_stylesheet);
  
  
  my ($allow_remote_calendar_requests) = &xml_quick_extract($xml, "allow_remote_calendar_requests");
  $allow_remote_calendar_requests = &decode($allow_remote_calendar_requests);
  
  my ($remote_calendar_requests_require_password) = &xml_quick_extract($xml, "remote_calendar_requests_require_password");
  $remote_calendar_requests_require_password = &decode($remote_calendar_requests_require_password);

  my ($remote_calendar_requests_password) = &xml_quick_extract($xml, "remote_calendar_requests_password");
  $remote_calendar_requests_password = &decode($remote_calendar_requests_password);
  
  if ($cal_id > $max_cal_id) {
    $max_cal_id = $cal_id;
  }
  
  $calendar = {id => $cal_id,
			   users => [],
               type => $cal_type, 
               url => $cal_url, 
               title => $cal_title, 
               details => $cal_details,
               link => $cal_link,
               #users => \@calendar_users,
               local_background_calendars => \%local_background_calendars,
               remote_background_calendars => \%remote_background_calendars,
               selectable_calendars => \%selectable_calendars,
               new_calendars_automatically_selectable => $options{new_calendars_automatically_selectable},
               calendar_events_color => $calendar_events_color,
               list_background_calendars_together => $list_background_calendars_together,
               background_events_display_style => $background_events_display_style,
               background_events_fade_factor => $background_events_fade_factor,
               background_events_color => $background_events_color,
               allow_remote_calendar_requests => $allow_remote_calendar_requests,
               remote_calendar_requests_require_password => $remote_calendar_requests_require_password,
               remote_calendar_requests_password => $remote_calendar_requests_password,
               default_number_of_months => $default_number_of_months,
               max_number_of_months => $max_number_of_months,
               gmtime_diff => $gmtime_diff,
               date_format => $date_format,
               week_start_day => $week_start_day,
               custom_template => $custom_template,
               custom_stylesheet => $custom_stylesheet,
               password => $cal_password,
               event_change_email => $event_change_email,
               add_emails => \@add_emails,
               update_emails => \@update_emails,
               delete_emails => \@delete_emails,
               update_timestamp => $update_timestamp};
               
  if ($cal_type eq "ical") {
    my $url_results = &get_remote_file($cal_url);
  
    # check for 404, other errors
  
    return (&parse_ical($url_results, $calendar));
  } else {
    return $calendar;
  }           
               
}


sub export_ical() {
   return if ( $options{'ical_export'} ne "1" );
   my ($calendar_ref) = @_;
   my %calendar = %{$calendar_ref};
 
	my $ical_dir = "$options{default_theme_path}/ical";

  	# make ical directory, if not present
    if (!(-d $ical_dir)) {
		mkdir($ical_dir, 0777);
	}
	
	$ical_file = $ical_dir."/plans_calendar_".$calendar{'id'}.".ics";

	$ical_file_date = 0;
	if ( -e $ical_file) {
		$ical_file_date = (stat($ical_file))[9];
	}

	$export_needed = 1;

	# check calendar's update
	$export_needed = 1 if ( $calendar{'update_timestamp'} > $ical_file_date );

	if ( !$export_needed ) {
		foreach $event_id (keys %events) {
			if (&contains($events{$event_id}{'cal_ids'}, $calendar{id})) {
				if ( $events{$event_id}{'update_timestamp'} > $ical_file_date ) {
					$export_needed = 1;
					break;
				}
			}
		}
	}

	if ( !$export_needed ) {
		return;
	} 

	$ical_contents = &icalendar_export_cal(0,1970,11,2030,$cal_id);
 
    open (FH, ">$ical_file") || {$debug_info.= "unable to open file $ical_file for writing!\n"};
    flock FH,2;
    print FH $ical_contents;
    close FH;
}


sub icalendar_export_cal {
  ($start_month, $start_year, $end_month, $end_year, $cal_id) = @_;
  my $results = "";
  
  %export_calendar = %current_calendar;
  if ( $cal_id ) {
    %export_calendar = %{$calendars{$cal_id}};
  }
 
  #calculate where to start and end the list

  #format for timegm: timegm($sec,$min,$hour,$mday,$mon,$year);
  my $list_start_timestamp = timegm(0,0,0,1,$start_month,$start_year);
  my $list_end_timestamp = &find_end_of_month($end_month, $end_year);
  # loop through all the events.

  #Create an array of events which fall
  # within the supplied dates
  my @selected_cal_events;

  #and a funky data structure for the background calendars
  # each element of this hash will be an array.
  my $shared_cal_events={};  #empty hash

  my @background_cal_ids = keys %{$export_calendar{local_background_calendars}};
  foreach $event_id (keys %events) {
    if (&time_overlap($events{$event_id}{start},$events{$event_id}{end},$list_start_timestamp,$list_end_timestamp)) {
      my $event_in_export_calendar = 0;

      foreach $temp_cal_id (@{$events{$event_id}{cal_ids}}) {
        if ($temp_cal_id eq $export_calendar{'id'}) {
			push @selected_cal_events, $event_id;
		}
        foreach $background_cal_id( @background_cal_ids ) {
          if ($temp_cal_id eq $background_cal_id) {
			push @{$shared_cal_events{$background_cal_id}}, $event_id;
		  }
        }
      }
    }
  }

  $results .=<<p1;
BEGIN:VCALENDAR
PRODID:-//Plans//EN
VERSION:2.0
METHOD:PUBLISH

p1

  #initialize loop variables
  #$current_timestamp = $list_start_timestamp;


    #display events for selected calendar
    foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @selected_cal_events) {
      my %event = %{$events{$event_id}};
      $results .= &event2ical(\%event)."\n";
    }

    foreach $background_cal_id (keys %{$export_calendar{local_background_calendars}}) {
      #list events for that calendar
      foreach $event_id (sort {$events{$a}{start} <=> $events{$b}{start}} @{$shared_cal_events{$background_cal_id}}) {
        my %event = %{$events{$event_id}};
          $results .= &event2ical(\%event)."\n";
      }
    }
  $results .=<<p1;

END:VCALENDAR
p1

  $results .= $debug_info;
  return $results;
}





sub parse_ical() {
  my $ical_debug_info = "";
  my ($url_results, $cal_ref) = @_;
  
  my %calendar = %{$cal_ref};
  
  # start parsing ical data
  # there's a perl module for this(iCal::Parser), but it's not used 
  # because A) not everyone has it
  # and B) it doesn't do some things the plans way (for instance, multi-day events are split into multiple events)
  
  # the first BEGIN:VCALENDAR describes the calendar
  # subsequent BEGIN:VCALENDARs are ignored.
  $url_results =~ s/\r//gs;         #some servers sneak these in.
  $url_results =~ s/\f//gs;         #some servers sneak these in.
  
  my $tzone_offset = 0;
  
  my $calendar_data = $url_results;
  $calendar_data =~ s/.+(BEGIN:VCALENDAR)(.+?)(END:VCALENDAR).+/$1$2$3/si;
  $calendar_data =~ s/(\s|\n)*(:|;)(\s|\n)*/$2/sg;
  $calendar_data =~ s/BEGIN:VEVENT.+?END:VEVENT//si;
  
  if ($calendar_data =~ /BEGIN:STANDARD/) {
    my $timezone_data = $calendar_data;
    ($tzone_offset) = &ical_get($timezone_data, "TZOFFSETTO");
    $tzone_offset =~ s/00//;
    $tzone_offset = $tzone_offset * 3600;
    $ical_debug_info .= "iCal timezone offset: $tzone_offset\n";
  }
  $ical_debug_info .= "calendar_data: $calendar_data\n\n\n\n";
  
  my $temp_events_data = $url_results;
  $temp_events_data =~ s/(\s|\n)*(:|;)(\s|\n)*/$2/sg;
  
  while ($temp_events_data =~ /(BEGIN:VEVENT.+?END:VEVENT)/sgi) {
    my $event_text = $1;
    my %event;
    $event{cal_ids} = ($calendar{id});
  
    my ($uid) = &ical_get($event_text, "uid");
    $event{id} = $uid;
    my ($title) = &ical_get($event_text, "summary");
    $event{title} = $title;
    my ($timestamp) = &ical_get($event_text, "dtstamp");
    $event{timestamp} = $timestamp;
    
    my ($dtstart, $tzone) = &ical_get($event_text, "dtstart");
    $event{start} = &parse_ical_date($dtstart, $tzone);

    my ($dtend, $tzone) = &ical_get($event_text, "dtend");
    if ($dtend eq "") {
      my ($duration) = &ical_get($event_text, "duration");
      
      my $dur_d = $1 if ($duration =~ /(\d*)D/) ? $1: 0;
      my $dur_h = $1 if ($duration =~ /(\d*)H/) ? $1: 0;
      my $dur_m = $1 if ($duration =~ /(\d*)M/) ? $1: 0;
      my $dur_s = $1 if ($duration =~ /(\d*)S/) ? $1: 0;
      
      my $duration_seconds = $dur_s + (60*$dur_m) + (3600*$dur_h) + (86400*$dur_d);
	  if ( $dur_d > 0 ) { $duration_seconds--;}

      $event{end} = $event{start} + $duration_seconds;
    } else {  #DTEND found
      $event{end} = &parse_ical_date($dtend, $tzone);
    }
    
    $ical_debug_info .= "event $id ($event{id}) $event{start} - $event{end}\n";
    $event{start} -= $tzone_offset;
    $event{end} -= $tzone_offset;
    $ical_debug_info .= "event $id ($event{id}) $event{start} - $event{end}\n";
    
    my $ical_details = "";
    
    my ($location) = &ical_get($event_text, "location");
    if ($location ne "") {
      $ical_details .= "Location: $location<br/>";
    }
    my ($description) = &ical_get($event_text, "description");
    if ($description ne "") {
      $ical_details .= "$description<br/>";
    }
  
    my $event_duration = $event{end} - $event{start};
    $ical_debug_info .= "event $id ($evt_title) duration: ($event_duration)\n";
 
    my $all_day_event = "";
    my $no_end_time = "";
    
    # make an educated guess about length of events that look like this:  DTSTART;VALUE=DATE:20070202
    #  Lord, I hate the ical/vcal standard.                               DTEND;VALUE=DATE:20070203 
    
    my $evt_days;
    
    my @temp1 = gmtime $event{start};
    my @temp2 = gmtime $event{end};
    if ($temp1[0] ==0 && $temp1[1] ==0 && $temp1[2] ==0 && $temp2[0] ==0 && $temp2[1] ==0 && $temp2[2] ==0) {
      $evt_days = int(($event{end} - $event{start})/86400);
    } else {
      $evt_days = int(($event{end} - $event{start})/86400)+1;
    }
    
    if ($event_duration > 1 && (($event_duration+1) % 86400 == 0 || ($event_duration) % 86400 == 0)){
      $all_day_event = 1;
      #$ical_debug_info .= "event $id ($evt_title) is an all day event\n";
    } else {
      if ($event_duration == 1) {
        $no_end_time = 1;
      }
 
     #$ical_debug_info .= "(xml2event) event $id, timezone offset: $timezone_offset\n";
 
      $ical_debug_info .= "(xml2event) event $id start: $evt_start\n";
 
      # experimental--may cause problems.
      # used to stretch an event that crosses midnight over 2 days.
      my @temp1 = gmtime $event{start};
      my @temp2 = gmtime $event{end};
 
      if ($temp1[3] != $temp2[3]) {
        $evt_days++;
      }
    }
    $ical_debug_info .= "event $id ($event{id}) all_day_event: $all_day_event\n";

    $event{all_day_event} = $all_day_event;
    $event{no_end_time} = $no_end_time;
    $event{days} = $evt_days;
    $event{details} = $ical_details;
    $event{bgcolor} = "#ffffff";
      
    $ical_debug_info .= "Event uid: ($uid)\n";
    $ical_debug_info .= "ical event calendar id: $calendar{id}\n";
    $ical_debug_info .= "event start: $event{start}\n";

    $events_data .= "$event_text\n\n\n\n";
    
    $events{$uid} = \%event;
  }
  
  return \%calendar
}



sub parse_ical_date {
  my ($ical_date, $tzone) = @_;
  
  #my $date_portion = substr($ical_date, 0,8);
  my $time_portion = substr($ical_date, 8);

  my $year = substr($ical_date,0,4);
  my $month = substr($ical_date,4,2) - 1;
  my $mday = substr($ical_date,6,2);
  
  
  my $hour = substr($ical_date,9,2);
  my $minute = substr($ical_date,11,2);
  my $second = substr($ical_date,13,2);
  
  my $timestamp = timegm($second,$minute,$hour,$mday,$month,$year);
  return $timestamp;
}



sub ical_get {
  my ($text, $field) = @_;
  my $value = "";
  my $comment = "";
  
  if ($text =~ /$field(;.+?)?:(.+?)\n/si) {
    $value = $2;
    $comment = $1;
  }

  return ($value, $comment);
}


sub normalize_timezone() {
  return if ($normalized_timezone == 1);

  $normalized_timezone = 1;
  foreach $event_id (keys %events) {
    next if ($events{$event_id}{all_day_event} eq "1");
    my %event = %{$events{$event_id}};
    
    $events{$event_id}{start} += $calendars{$current_cal_id}{gmtime_diff} * 3600;
    $events{$event_id}{end} += $calendars{$current_cal_id}{gmtime_diff} * 3600;
  }
}

sub normalize_timezone_pending_events() {
  return if ($normalized_timezone_pending_events == 1);

  $normalized_timezone_pending_events = 1;
  
  foreach $new_event_id (keys %new_events) {
    next if ($new_events{$new_event_id}{all_day_event} eq "1");
    my %new_event = %{$new_events{$new_event_id}};
    
    $new_events{$new_event_id}{start} += $calendars{$current_cal_id}{gmtime_diff} * 3600;
    $new_events{$new_event_id}{end} += $calendars{$current_cal_id}{gmtime_diff} * 3600;
    
  }
}

sub events2json() {
	my ($events_ref) = @_;
	my %events = %{$events_ref};

	my %json_events = {};
	foreach $event_id (keys %events) {
		$json_events{$event_id} = &event_json_ready( $events{$event_id} );
	}
	return encode_json \%json_events;

}

sub events_json_ready() {
	my ($events_ref) = @_;
	my %events = %{$events_ref};

	my %json_events = {};
	foreach $event_id (keys %events) {
		$json_events{$event_id} = &event_json_ready( $events{$event_id} );
	}
	return \%json_events;
}

sub event_json_ready() {
	my ($event_ref) = @_;
	my %event = %{$event_ref};


	if (ref $event{'cal_ids'} ne "ARRAY")  {
		$event{'cal_ids'} = ( $event{'cal_ids'} );
	}

	my $date_string = $lang{event_details_date_goes_here};
	my $event_time = "";

	if ($event{start} ne "") {
		if ($event{all_day_event} eq "1") {
			$date_string = &nice_date_range_format($event{start}, $event{start}+86400*($event{days}-1), " - ");
		} else {
			$date_string = &nice_date_range_format($event{start}, $event{end}, " - ");
			$event_time = &nice_time_range_format($event{start},$event{end});
		}
	}
	$event{nice_date} = $date_string;
	$event{nice_time} = $event_time;

	return \%event;

}


sub event2json() {
	my ($event_ref) = @_;
	%event = %{&event_json_ready( $event_ref ) };
	$results = encode_json \%event;
}

sub event2javascript() {
  my ($event_ref) = @_;
  my %event = %{$event_ref};
  my $results = "";
  $results .= "'id':'".javascript_cleanup($event{id})."',";
  $results .= "'cal_ids':'".javascript_cleanup(join ",", @{$event{cal_ids}})."',";
  $results .= "'title':'".javascript_cleanup($event{title})."',";
  $results .= "'details':'".javascript_cleanup($event{details})."',";
  
  my $details_url = ($event{details_url} eq "1") ? "true":"false";
  $results .= "'details_url':$details_url,";
  $results .= "'icon':'".javascript_cleanup($event{icon})."',";
  $results .= "'bgcolor':'".javascript_cleanup($event{bgcolor})."',";
  $results .= "'start':'".javascript_cleanup($event{start})."',";
  $results .= "'end':'".javascript_cleanup($event{end})."',";
  $results .= "'days':".javascript_cleanup($event{days}).",";
  
  if ($event{all_day_event} eq "1") {
    $results .= "'all_day_event':true,";
  } else { 
    $results .= "'all_day_event':false,";
  }
  
  if ($event{no_end_time} eq "1") {
    $results .= "'no_end_time':true";
  } else { 
    $results .= "'no_end_time':false";
  }

  return $results;
}

sub calendar_json_ready() {
	my ($calendar_ref) = @_;

	my %calendar = %{$calendar_ref};

	$calendar{admin_password} = '';
	$calendar{remote_calendar_requests_password} = '';
	$calendar{'password'} = '';

	#add users
	foreach $user_id (keys %users) {
		my %user = %{$users{$user_id}};

		foreach $calendar_id (keys %{$user{calendars}}) {
			if ($calendar_id eq $calendar{'id'}) {

				push @{$calendar{'users'}}, {'id' => $user{'id'},
											'name' => $user{'name'},
											'edit_calendar' => $user{'calendars'}{$calendar_id }{'edit_calendar'} 
										    };
				last;
			}
		}
	}

	#add remote caleendars
	$calendar{remote_background_calendars} = &hash2array( $calendar{remote_background_calendars} );

	return \%calendar;

}

sub hash2array() {
	my ($hash_ref) = @_;
	my $hash = %{$hash_ref};

	my @a;
    while( my ($k, $v) = each %$hash_ref ) {
		push @a, $v;
	}

	return \@a;
}


sub calendars2json() {
	my ($calendars_ref, $force_array) = @_;
	my %calendars = %{$calendars_ref};

	my %json_calendars;
	foreach $calendar_id (keys %calendars) {
		$json_calendars{$calendar_id} = &calendar_json_ready( $calendars{$calendar_id} );
	}

	if ( $force_array ) {
		my @json_calendars_array;

		foreach $calendar_id (keys %calendars) {
			push @json_calendars_array, $json_calendars{$calendar_id};
		}
		return encode_json \@json_calendars_array;
	} else {
		return encode_json \%json_calendars;
	}

}


sub calendar2json() {
	my ($calendar_ref) = @_;

	my %calendar = %{&calendar_json_ready( $calendar_ref )}; 

	return encode_json \%calendar;
}

sub calendars_as_array() {
	my ($calendars_ref) = @_;
	my %calendars = %{$calendars_ref};

	my %json_calendars;
	foreach $calendar_id (keys %calendars) {
		$json_calendars{$calendar_id} = &calendar_json_ready( $calendars{$calendar_id} );
	}

	my @json_calendars_array;

	foreach $calendar_id (keys %calendars) {
		push @json_calendars_array, $json_calendars{$calendar_id};
	}
	return \@json_calendars_array;
}

sub calendar2javascript() {
  my ($calendar_ref) = @_;
  my %calendar = %{$calendar_ref};
  my $results = "";
  $results .= "'id':'".javascript_cleanup($calendar{id})."',";
  $results .= "'title':'".javascript_cleanup($calendar{title})."',";
  $results .= "'local_background_calendars':'".javascript_cleanup(join ",", keys %{$calendar{local_background_calendars}})."'";

  return $results;
}




sub javascript_cleanup() {
  my ($text) = @_;
  $text =~ s/\n/\\n/g;
  $text =~ s/"/\\"/g;
  $text =~ s/'/\\'/g;
  $text =~ s/\//\\\//g;
  return $text;
}



sub event2xml() {
  my ($event_ref, $cal_id) = @_;
  my %event = %{$event_ref};

  my $xml_data = "<event>";
  $xml_data .= &xml_store($event{id}, "id");
  my $cal_ids_string = "";
  foreach $cal_id (@{$event{cal_ids}}) {
    $cal_ids_string .= "$cal_id";
    if ($cal_id ne @{$event{cal_ids}}[-1]) {
      $cal_ids_string .= ",";
    }
  }
  $cal_ids_string =~ s/,$//;
  
  my $event_start_timestamp = $event{start};
  my $event_end_timestamp = $event{end};
  
  # denormalize event time
  if ($event{all_day_event} ne "1" && ($normalized_timezone == 1 || $normalized_timezone_pending_events == 1)) {
    $event_start_timestamp -= $calendars{$current_cal_id}{gmtime_diff} * 3600;
    $event_end_timestamp -= $calendars{$current_cal_id}{gmtime_diff} * 3600;    
  }
  
  $xml_data .= "<cal_ids>$cal_ids_string</cal_ids>";
  $xml_data .= &xml_store($event_start_timestamp, "start");
  $xml_data .= &xml_store($event_end_timestamp, "end");
  $xml_data .= &xml_store($event{series_id}, "series_id");
  $xml_data .= &xml_store($event{title}, "title");
  $xml_data .= &xml_store($event{details}, "details");
  $xml_data .= &xml_store($event{icon}, "icon");
  $xml_data .= &xml_store($event{block_merge}, "block_merge");
  $xml_data .= &xml_store($event{bgcolor}, "bgcolor");
  $xml_data .= &xml_store($event{unit_number}, "unit_number");
  $xml_data .= &xml_store($event{update_timestamp}, "update_timestamp");
  $xml_data .= "</event>";
  return $xml_data;
}

sub event2ical() {
  my ($event_ref) = @_;
  my %event = %{$event_ref};
  my $results;
  
  my $start_timestamp = $event{start} - $calendars{$event{cal_ids}[0]}{gmtime_diff}*3600;
  my $end_timestamp = $event{end} - $calendars{$event{cal_ids}[0]}{gmtime_diff}*3600;

  my $cal_title = $calendars{$event{cal_ids}[0]}{title};  # need to add titles for all other cal_ids

  my $dtstart_string = "";
  my $dtend_string = "";
  
  my $rightnow_date = &outlook_date_time($rightnow) . 'Z';

  if ($event{all_day_event} eq "1") {
    $dtstart_string = ";VALUE=DATE:".&outlook_date($event{start});
    $dtend_string = ";VALUE=DATE:".&outlook_date($event{end}+86400);
  } else {
    $dtstart_string = ":".&outlook_date_time($event{start}) . 'Z';
    $dtend_string = ":".&outlook_date_time($event{end}) . 'Z';
  }
  
  # replace newlines with carraige-returns (otherwise two newlines in a row
  # causes errors.  Not sure whether this is an outlook error or an IE error.
  $event{details} =~ s/\n/\\n/g;
  $event{title} =~ s/\n/\\n/g;

  $results =<<p1;
BEGIN:VEVENT
DTSTART$dtstart_string
DTEND$dtend_string
TRANSP:OPAQUE
SEQUENCE:0
UID:$script_url/$name?view_event=1&evt_id=$event{id}
DTSTAMP:$rightnow_date
DESCRIPTION:$event{details}
SUMMARY:$event{title} ($cal_title)
PRIORITY:5
CLASS:PUBLIC
END:VEVENT
p1

  return $results;
}



sub event2vcal() {
  my ($event_ref) = @_;
  my %event = %{$event_ref};
  my $results;
  
  my $start_timestamp = $event{start};
  my $end_timestamp = $event{end};
  my $cal_name=$calendars{$event{cal_ids}[0]}{title};

  my $dtstart_string = &outlook_date_time($event{start});
  my $dtend_string = &outlook_date_time($event{end});
  
  $cal_title = $calendars{$event{cal_ids}[0]}{title};

  # replace newlines with carraige-returns (otherwise two newlines in a row
  # causes errors.  Not sure whether this is an outlook error or an IE error.
  $event{details} =~ s/\n/\r/g;
  $event{title} =~ s/\n/\r/g;

  $results =<<p1;
BEGIN:VEVENT
DTSTART:$dtstart_string
DTEND:$dtend_string
TRANSP:0
SEQUENCE:0
DTSTAMP:20020322T043444Z
DESCRIPTION:$event{details}
SUMMARY:$event{title} ($cal_title)
PRIORITY:5
CLASS:PUBLIC
p1

  if ($event{days} > 1) {
    $results .=<<p1;
RRULE:D$event{days} $dtend_string
p1
  }
  $results .=<<p1;
END:VEVENT
p1

  return $results;

}

sub outlook_date {
  my ($timestamp) = @_;
  
  my @timestamp_array = gmtime($timestamp);
  my $year_string = 1900 + $timestamp_array[5];
  
  my $month_string = $timestamp_array[4]+1;
  if ($month_string < 10) {$month_string="0".$month_string;}
  
  my $mday_string = $timestamp_array[3];
  if ($mday_string < 10) {$mday_string="0".$mday_string;}
  
  my $dt_string="$year_string$month_string$mday_string";
  return $dt_string;
}

sub outlook_date_time {
  my ($timestamp) = @_;
  
  my @timestamp_array = gmtime($timestamp);
  my $year_string = 1900 + $timestamp_array[5];
  
  my $month_string = $timestamp_array[4]+1;
  if ($month_string < 10) {$month_string="0".$month_string;}
  
  my $mday_string = $timestamp_array[3];
  if ($mday_string < 10) {$mday_string="0".$mday_string;}
    
  my $hour_string = $timestamp_array[2];
  if ($hour_string < 10) {$hour_string="0".$hour_string;}
    
  $hour_string="$timestamp_array[2]";
  $hour_string = "0$hour_string" if (length $hour_string == 1);
  $minute_string="$timestamp_array[1]";
  $minute_string = "0$minute_string" if (length $minute_string == 1);
  $second_string="$timestamp_array[0]";
  $second_string = "0$second_string" if (length $second_string == 1);
  
  my $dt_string="$year_string$month_string$mday_string";
  $dt_string .= "T".$hour_string.$minute_string.$second_string;
  return $dt_string;
}

sub event2palmcsv() {
  my ($event_ref) = @_;
  my %event = %{$event_ref};
  my $results;
  
  
  my $palm_begin = &formatted_time($event{start}, "yy mo md  hh:mm");
  my $palm_end = &formatted_time($event{end}, "yy mo md  hh:mm");
  
  if ($event{days} == 1) {
  $results .= "\"\"";     # category
  $results .= ",\"0\"";   # private
  $results .= ",\"$event{title}\"";   # description
  $results .= ",\"$event{details}\""; # note
  $results .= ",\"1\"";               # event
  $results .= ",\"$palm_begin\"";     # begin time
  $results .= ",\"$palm_end\"";       # end time
  $results .= ",\"\"";    # alarm
  $results .= ",\"\"";    # advance
  $results .= ",\"\"";    # advance units
  $results .= ",\"0\"";   # repeat type
  $results .= ",\"\"";    # repeat forever
  $results .= ",\"\"";    # repeat end
  $results .= ",\"\"";    # repeat freq.
  $results .= ",\"\"";    # repeat day.
  $results .= ",\"\"";    # repeat days.
  $results .= ",\"\"";    # week start.
  $results .= ",\"\"";    # number of exceptions.
  $results .= ",\"\"";    # exceptions
  } else { # multi-day event.
  $results .= "\"\"";     # category
  $results .= ",\"0\"";   # private
  $results .= ",\"$event{title}\"";   # description
  $results .= ",\"$event{details}\""; # note
  $results .= ",\"1\"";               # event
  $results .= ",\"$palm_begin\"";     # begin time
  $results .= ",\"$palm_begin\"";       # end time
  $results .= ",\"\"";    # alarm
  $results .= ",\"\"";    # advance
  $results .= ",\"\"";    # advance units
  $results .= ",\"1\"";   # repeat type
  $results .= ",\"\"";    # repeat forever
  $results .= ",\"$palm_end\"";    # repeat end
  $results .= ",\"1\"";    # repeat freq.
  $results .= ",\"\"";    # repeat day.
  $results .= ",\"\"";    # repeat days.
  $results .= ",\"\"";    # week start.
  $results .= ",\"\"";    # number of exceptions.
  $results .= ",\"\"";    # exceptions
  }
  
  $results =~ s/\n/ /g;
  
  return $results;
}




sub find_end_of_month {
  my ($month, $year) = @_;

  my $next_month = $month+1;
  if ($next_month > 11) {
    $next_month=0;
    $year++;
  }
  return timegm(0,0,0,1,$next_month,$year);
}

sub xml_store {
  my ($data_ref, $tag_name) = @_;
  my $data_string;
  
  if (ref $data_ref eq "ARRAY")  {
    my $i=0;
    my $max = scalar @{$data_ref} - 1;
    foreach $val (@{$data_ref}) {
      $data_string .= $val;
      if ($i != $max) {$data_string .= ',';}
      $i++;
    }
  } else {$data_string = $data_ref;}
  
  $data_string = &encode($data_string);
  return "<$tag_name>$data_string</$tag_name>";
}

sub xml_quick_extract  { # it doesn't get any dumber than this.  ignores attributes, element order, fooled by duplicate tag names at different depths.
  my ($data, $tag_name) = @_;
  my @results_array = ();
                           
  while  ($data =~ /<$tag_name>(.+?)<\/$tag_name>/gs) {
    push @results_array, $1;
  }
  return @results_array;
}

sub xml_extract {   # Slow, but can handle attributes, element order, same tag names at different depths. Can't handle encodings, DTDs.
  my ($data, $tag_name, $debug) = @_;
  my @results_array = ();
  my $results = "";
  my $final_results = "";
  
  my $depth_count=0;
  my $start_index=0;
  my $end_index=0;
  my $match_index=0;

  my $attributes=();
  my $position=0;          # position is the position of the element we're looking for, with respect to all other elements
                           # under the parent element
                           
  while  ($data =~ /(<.*?>|<\/.*?>)/g) {
    my $match=$1;
    my $temp_index = $+[1];
    if ($match =~ /<$tag_name\b.*?>/ && $depth_count==0) { # the opening tag we're looking for
      $start_index = $temp_index;
      $depth_count++;
      if ($debug) {$debug_info .= "active opening tag, $match \ndepth count $depth_count\n";}
      if ($debug) {$debug_info .= "start index $start_index\n";}
      
      my $attribute_text = $match;
      $attribute_text =~ s/\s*=\s*/=/g;                # compress whitespace on either side of = sign
      $attribute_text =~ s/=([^"])(.+?\b)/="$1$2"/g;   # properly format attributes with quote marks
     
      #if ($debug) {$debug_info .= "rejiggered attribute text: $attribute_text\n";}
      
      # extract attributes
      while ($attribute_text =~ /\w+?=".+?[^\\]"/g) {
        my $a_match = $&;
        my ($name, $value)= split('=',$a_match);

        $value =~ s/\\"/"/g;
        # remove first and last characters (the quotes) from value
        $value = substr $value, 1,-1;
        
        if ($debug) {$debug_info .= "attribute: $a_match\n";}
        if ($debug) {$debug_info .= " name: $name\n";}
        if ($debug) {$debug_info .= " value: $value\n";}
        
        $attributes->{$name} = $value;
      }
    } elsif ($match =~ /<[^\/].*?>/) {  # some other opening tag
      $depth_count++;
      if ($debug) {$debug_info .= "other opening tag, $match \ndepth count $depth_count\n";}
    } elsif ($match eq "<\/$tag_name>" && $depth_count == 1) { # the closing tag we're looking for
      $depth_count--;
      if ($debug) {$debug_info .= "active closing tag, $match \ndepth count $depth_count\n";}
      if ($depth_count==0) { # done!  return results
        $end_index = $-[0];
        $results = substr $data, $start_index,($end_index-$start_index);
        
        my $results_hash=();
        $results_hash -> {data} = "".$results;
        $results_hash -> {attributes} = $attributes;
        $results_hash -> {position} = $position;
        push @results_array, $results_hash;
        
        if ($debug) {$debug_info .= "  pushing results: \"$results\" onto array\n";}
        if ($debug) {$debug_info .= "  attributes: \"$attributes\" \n";}
        if ($debug) {$debug_info .= "  position: \"$position\" \n";}
        if ($debug) {$debug_info .= "  start: $start_index end $end_index\n\n";}
        #if ($debug) {$debug_info .= " $results\n\n";}
        $start_index=0;
        $end_index=0;
        $attributes=();
      }
      $position++;
    } else { # other closing tag
      $depth_count--;
      if ($depth_count==0) {$position++;}
      
      if ($debug) {$debug_info .= "other closing tag, $match \ndepth count $depth_count\n";}
    }
    $match_index++;
  }
  return @results_array;
}   #******************** end xml_extract **********************


sub xml_tags {
  my ($data, $debug) = @_;
  my @results_array = ();
  my %tags_hash;
  
  my $depth_count=0;
                           
  while  ($data =~ /(<.*?>|<\/.*?>)/g) {
    my $match=$1;
    if ($match =~ /<[^\/].*?>/) { # any opening tag
      if ($depth_count == 0) {    # level 0 opening tag
        $tag_name = $match;
        $tag_name =~ s/<//;
        $tag_name =~ s/\b(.+)\b.+/$1/;
        if ($debug) {$debug_info .= "level 0 opening tag, $tag_name \n\n";}
      }
      $depth_count++;
    } elsif ($depth_count == 1)  { # level 1 closing tag
      $tag_name = $match;
      $tag_name =~ s/<//;
      $tag_name =~ s/\/(.+)(\b|>).+/$1/;

      $depth_count--;
      if ($debug) {$debug_info .= "level 1 closing tag, $tag_name \n";}
      $tags_hash{$tag_name}=1;
        
      if ($debug) {$debug_info .= "  pushing tag name $tag_name onto array\n\n";}
    } else { # other closing tag
      $depth_count--;
      if ($debug) {$debug_info .= "other closing tag, $match \ndepth count $depth_count\n";}
    }
  }
  return keys %tags_hash;
  
}  #******************** end xml_tags **********************


sub xml2hash {
  my ($xml_data, $debug) = @_;
  my $item;

  my @item_tags = &xml_tags($xml_data);
  
  if (scalar @item_tags == 0) {
    if ($debug) {$debug_info .= " plain text item data: ($xml_data) \n";}
    
    return $xml_data;
  } else {
    if ($debug) {$debug_info .= " xml data: ($xml_data) \n";}
    my %results_hash;
    foreach $tag (@item_tags) {
      my @tag_data = &xml_extract($xml_data,"$tag");
      
      if (scalar @tag_data == 1) {
        if ($debug) {$debug_info .= "  extracting xml for tag $tag (single data)\n";}
        $results_hash{$tag} = &xml2hash($tag_data[0]->{data},$debug);
      } else {
        if ($debug) {$debug_info .= "  extracting xml for tag $tag (array data)\n";}
        my @tag_array;
        foreach $thing (@tag_data) {
          push @tag_array, &xml2hash($thing->{data},$debug);
        }
        $results_hash{$tag}=\@tag_array;
      } 
    }
    if ($debug) {$debug_info .= "\n";}
    return \%results_hash;
  }
}  #******************** end xml2hash **********************

sub hash2xml {
  my ($temp, $parent_tag, $order_hashref) = @_;
  my $results="";
  
  my %order_hash = %{$order_hashref};
  
  if (ref $temp eq "ARRAY") { # array
    my @temp_array = @{$temp};
    foreach $element (@temp_array) {
      $results .= "<$parent_tag>";
      $results .= $element;
      $results .= "</$parent_tag>";
    }
  } elsif (ref $temp eq "HASH") { # hash
    $results .= "<$parent_tag>";
    my %temp_hash = %{$temp};
    foreach $key (sort {$order_hash{$a} <=> $order_hash{$b}} keys %temp_hash) {
      $results .= &hash2xml($temp_hash{$key}, $key, $order_hashref);
    }
    $results .= "</$parent_tag>";
  } else { # data
    $results .= "<$parent_tag>".&encode($temp)."</$parent_tag>";
  }
  
  return $results;
} #******************** end hash2xml **********************



sub init_session {
  my ($cgi, $session) = @_; # receive two args

  if ( $session->param("~logged-in") ) {
    return 1;  # if logged in, don't bother going further
  }
  
  return if ($lg_name eq "");
  return if ($lg_password eq "");

  # if we came this far, user did submit login data
  # so let's try to load his/her profile if name/psswds match
  if ( my $profile = _load_profile($lg_name, $lg_password) ) {
    $session->param("~profile", $profile);
    $session->param("~logged-in", 1);
    $session->clear(["~login-trials"]);
    return $session;
  }

  # if we came this far, the login/psswds do not match
  # the entries in the database
  my $trials = $session->param("~login-trials") || 0;
  
  return $session->param("~login-trials", ++$trials);
}

sub _load_profile {
	my ($name, $password) = @_;
	
	$password_crypt = crypt($password, $options{salt});
	
	my $password_match = 0;
	my %calendar_permissions;
	 
		# check root password
	my %calendar = %{$calendars{0}};
	if ( $calendar{password} eq $password_crypt && $password_crypt ne "") {
		$password_match = 1;
		$calendar_permissions{0}{admin} = 1;
	}

	# then check calendar passwords
	foreach $calendar_id (keys %calendars) {
		my %calendar = %{$calendars{$calendar_id}};
		if ($calendar{id} eq $name && $calendar{password} eq $password_crypt && $password_crypt ne "") {
			$password_match = 1;
			$calendar_permissions{$calendar{id}}{admin} = 1;
			#return {cal_id => $calendar{id}, user_id=>"admin"};
		}
	}

	# then check user passwords
	foreach $user_id (keys %users) {
		my %user = %{$users{$user_id}};

		if ($user{password} eq $password_crypt && $password_crypt ne "") {
			foreach $calendar_id (keys %{$user{calendars}}) {
				if ($user{calendars}{$calendar_id}{edit_events} eq "1")	{
					$password_match = 1;
					$calendar_permissions{$calendar_id}{user} = $user{id};
				}
			}
			#return {cal_id => "", user_id=>$user_id};
		}
	}
	
	
	return {calendar_permissions => \%calendar_permissions} if ($password_match);
	return undef;
}


sub delete_old_sessions {
  my ($days) = @_;

  opendir (DIR, "$options{sessions_directory}/");
  @FILES = grep(/cgisess_/,readdir(DIR));
  closedir (DIR);

  ## DELETE THE .TXT FILES THAT ARE OLDER THAN 1 DAY
  foreach $FILE (@FILES) {
    if (-M "$options{sessions_directory}/$FILE" > $days) {
      unlink("$options{sessions_directory}/$FILE");
    }
  }
}

sub get_remote_file {
  my ($url) = @_;
  if (!$options{proxy_server}) {
     $url =~ s/http:\/\///;
  }
  
  my $hostname = $url;
  $hostname =~ s/\/.+//g;

  my $document = $url;
  if (!$options{proxy_server}) {
     $document =~ s/.+?\//\//;
  }
  
  if ($hostname eq "" | $document eq "") {return;}

  if ($options{proxy_server}) {
     $remote = IO::Socket::INET->new( Proto     => "tcp",
                                   PeerAddr  => $options{proxy_server},
                                   PeerPort  => "$options{proxy_port}"
                                 );
  } else {
     $remote = IO::Socket::INET->new( Proto     => "tcp",
                                   PeerAddr  => $hostname,
                                   PeerPort  => "http(80)"
                                 );
  }
  unless ($remote)  {
    $debug_info .= "cannot connect to http daemon on $hostname <br>";
    return;
  }
  $remote->autoflush(1);
  print $remote "GET $document HTTP/1.0\r\n";
  print $remote "User-Agent: Mozilla 4.0 (compatible; I; Linux-2.0.35i586)\r\n";
  print $remote "Host: $hostname\r\n"; #without this line, virtual hosts won't work (multiple domain names on a single IP)
  
  print $remote "\r\n\r\n";

  @textbuffer=<$remote>;
  my $textstring = join "", @textbuffer;
  
  $textstring =~ s/\r//gs;         #some servers sneak these in.
  
  my $header = $textstring;
  $header =~ s/\n\n.+//si;
  my $firstline = $header;
  $firstline =~ s/\n.+//si;
  
  if ($firstline =~ /404/) {return "404 not found!";}
  
  $textstring =~ s/.+?\n\n//si;
  return $textstring;
}


sub time_overlap {
  my ($start1, $end1, $start2, $end2) = @_;
  
  my $temp1 = $end2 - $start1;
  my $temp2 = $end1 - $start2;
  
  my $range_total = $end2 - $start2;
  
  # if the event falls in or overlaps this week (there are 3 cases), the third being an event
  # that *completely* overlaps the week.
  if ( ($temp1 <= $range_total && $temp1 > 0)  || ($temp2 <= $range_total && $temp2 > 0) || ($temp1 > 0 && $temp2 > 0)) {return 1;}
  else 
    {return 0;}
}

sub make_email_link {
  my ($string) = @_;
  my $new_string = "";
  #remove all newlines
  $string =~ s/\n//g;
  
  #insert newlines after > characters
  $string =~ s/</\n</g;
  
  my @lines = split ("\n", $string);
  
  foreach $line (@lines) {
    $line .= "\n";
    my $new_line = $line;
    $new_line =~ s/([^ >]+?\@[^ <>]+)/<a href=\"mailto:$1\">$1<\/a>/g;
    
    #ignore substitution if the email address was already a link.
    if ($1 =~ /(:|")/) {$new_string .= $line;}
    else {
      $new_line =~ s/\n//g;
      $new_string .= $new_line;
    }
  }
  return $new_string;  
}

sub formatted_time {

  my ($input_time, $format_string) = @_;
  my @input_time_array = gmtime ($input_time+0);
  my $ampm = $lang{pm};
  
  if ($input_time_array[5]<1900) {$input_time_array[5]+=1900;}
  $month_name=$months[$input_time_array[4]];
  $input_time_array[4]++;

  if ($input_time_array[1]<10) {$input_time_array[1]="0".$input_time_array[1];}

  if ($input_time_array[2] < 12) {
    $ampm = $lang{am};
  }
  
  if (!$options{twentyfour_hour_format}) {
    if ($input_time_array[2] > 12)   { #convert from 24-hour to am/pm
       $input_time_array[2] = $input_time_array[2] - 12;
    }
 
    if ($input_time_array[2] == 0)  { #convert from 24-hour to am/pm
       $input_time_array[2] = 12;
    }
  }
  else {
    $format_string =~ s/ampm//g;  
  }
  
  my $day_name = @day_names[$input_time_array[6]];
  my $day_name_abv = @day_names_abv[$input_time_array[6]];
  
  $format_string =~ s/ampm/$ampm/g;  
  $format_string =~ s/wd/$day_name/g;
  $format_string =~ s/wda/$day_name_abv/g;
  $format_string =~ s/hh/$input_time_array[2]/g;
  $format_string =~ s/mm/$input_time_array[1]/g;  
  $format_string =~ s/ss/$input_time_array[0]/g;
  $format_string =~ s/mo/$input_time_array[4]/g;
  $format_string =~ s/mn/$month_name/g;
  $format_string =~ s/md/$input_time_array[3]/g;
  $format_string =~ s/yy/$input_time_array[5]/g;
  $fullyear = $input_time_array[5] + 1900;
  $format_string =~ s/yyyy/$fullyear/g;
  return $format_string;
}

sub nice_date_range_format {
  my ($timestamp1, $timestamp2, $separator_string) = @_;
  my $result_string = "";

  #make sure the timestamps are in the correct order
  if ($timestamp1 > $timestamp2) {
    $temp=$timestamp2;
    $timestamp2=$timestamp1;
    $timestamp1=$temp;
  }
  
  my @timestamp1_array = gmtime $timestamp1;
  my @timestamp2_array = gmtime $timestamp2;
  
  #format the year for humans
  $timestamp1_array[5] +=1900;
  $timestamp2_array[5] +=1900;
  
  if (lc $current_calendar{date_format} eq "dd/mm/yy") {
    if ($timestamp1_array[4] == $timestamp2_array[4] && $timestamp1_array[5] == $timestamp2_array[5] && $timestamp1_array[3] == $timestamp2_array[3]) {
      #same year, same month, same day
      $result_string = " $timestamp1_array[3] $months[$timestamp1_array[4]], $timestamp1_array[5]";
    }
    elsif ($timestamp1_array[4] == $timestamp2_array[4] && $timestamp1_array[5] == $timestamp2_array[5]) {
      #same year, same month
      $result_string = "$timestamp1_array[3]$separator_string$timestamp2_array[3] $months[$timestamp1_array[4]], $timestamp1_array[5]";
    }
    elsif ($timestamp1_array[5] != $timestamp2_array[5]) {
      #different year
      $result_string = "$timestamp1_array[3] $months[$timestamp1_array[4]], $timestamp1_array[5]$separator_string$timestamp2_array[3] $months[$timestamp2_array[4]], $timestamp2_array[5]";
    }
    else 
    { #same year, different months
      $result_string = "$timestamp1_array[3] $months[$timestamp1_array[4]]$separator_string$timestamp2_array[3] $months[$timestamp2_array[4]], $timestamp2_array[5]";
    }
  } else {
    if ($timestamp1_array[4] == $timestamp2_array[4] && $timestamp1_array[5] == $timestamp2_array[5] && $timestamp1_array[3] == $timestamp2_array[3]) { 
      #same year, same month, same day
      $result_string = "$months[$timestamp1_array[4]] $timestamp1_array[3], $timestamp1_array[5]";
    }
    elsif ($timestamp1_array[4] == $timestamp2_array[4] && $timestamp1_array[5] == $timestamp2_array[5]) { 
      #same year, same month
      $result_string = "$months[$timestamp1_array[4]] $timestamp1_array[3]$separator_string$timestamp2_array[3], $timestamp1_array[5]";
    }
    elsif ($timestamp1_array[5] != $timestamp2_array[5]) { 
      #different year
      $result_string = "$months[$timestamp1_array[4]] $timestamp1_array[3], $timestamp1_array[5]$separator_string$months[$timestamp2_array[4]] $timestamp2_array[3], $timestamp2_array[5]";
    }
    else  { 
      #same year, different months
      $result_string = "$months[$timestamp1_array[4]] $timestamp1_array[3]$separator_string$months[$timestamp2_array[4]] $timestamp2_array[3], $timestamp2_array[5]";
    }
  }
  
  return $result_string;
}

sub nice_time_range_format {
  my ($start, $end) = @_;
  my $results = "";
  $results = &formatted_time($start,"hh:mm ampm")." - ".&formatted_time($end,"hh:mm ampm");
  
  # if times are the same, remove the second one.
  if ($end - $start <=1) {
    $results =~ s/s*-.+//;
    return $results;
  }
  
  # if both times are am or pm, remove the first one (it's redundant!)
  $results =~ s/(.*) $lang{am}(.*$lang{am}.*)/$1$2/;
  $results =~ s/(.*) $lang{pm}(.*$lang{pm}.*)/$1$2/;
  return $results;
}

sub timestamp_from_datetime {
  my ($mday, $mon, $year, $days, $start_time, $end_time, $allday) = @_;
  
  my $sts = timegm(0,0,0,$mday,$mon,$year);
  my $ets = 0;
  
  
  if ($allday eq "1") { # easy case first
    $ets = $sts + ($days * 86400) - 1;
  } else {
    my $start_time_offset = &time2seconds($start_time);
    if ($end_time ne "" && $start_time ne "") {
 
      $ets = $sts + 86400 * ($days-1) + &time2seconds($end_time);
 
      $sts+= $start_time_offset;
    } elsif ($start_time ne "") { # no end time
      #$ets = $sts + 86400 * $days - 1;
      $sts += $start_time_offset;
      $ets = $sts+1;
    }
  }
  
  return ($sts, $ets);

}


sub time2seconds {
  my ($time) = @_;
  my($hours, $minutes, $seconds);
  if($options{twentyfour_hour_format})  {
    $time =~ /(\d+):(\d+)/;
    $hours = $1;
    $minutes = $2;
    $seconds = 3600*$hours + 60*$minutes;
  } else {
    $time =~ /(\d+):(\d+)\s*($lang{am}|$lang{pm})/;
    $hours = $1;
    $minutes = $2;
    my $ampm = $3;
 
    $seconds = 3600*$hours + 60*$minutes;
 
    if ($ampm eq $lang{pm} && $hours < 12) {
      $seconds += 3600*12;
    }
 
    if ($ampm eq $lang{am} && $hours == 12) {
      $seconds -= 3600*12;
    }
  }
  return $seconds;
}

sub escapequotes {
  my ($input_string) = @_;
  my $output_string = $input_string;
  $output_string =~ s/"/&quot;/g;
  return $output_string;
}

sub encode {
  my ($input_string) = @_;
  return if ($input_string eq "");
  my $output_string=$input_string;

  $output_string =~ s/(\W)/"\%".sprintf("%02x", (ord $1))/ge;
  $output_string =~ s/\%20/+/g;
  return $output_string;
}

sub decode {
  my ($input_string) = @_;
  return if ($input_string eq "");
  my $output_string = $input_string;
  
  $output_string =~ s/\+/ /g;
  $output_string =~ s/%([0-9A-Fa-f]{2})/pack("c",hex($1))/ge;
  return $output_string;
}

sub min { @_ = sort {$a <=> $b} @_; shift; }
sub max { @_ = sort {$a <=> $b} @_; pop; }

sub generate_event_details_template {
	my ($event_ref) = @_;

	my %event_tmp = {};

	foreach $key (keys %{$event_ref}) {
		$event_tmp{$key} = "<%=$key%>";
	}

	$event_tmp{nice_date} = "<%=nice_date%>";
	$event_tmp{nice_time} = "<%=nice_time%>";

	$tmp_template = $event_details_template;
	$tmp_template =~ s/###event calendar name###/<%=event_calendar_name%>/g;

	$details_template = generate_event_details( \%event_tmp, $tmp_template);
	return $details_template;
}

sub generate_event_details {
	my ($event_ref, $event_details_template ) = @_;

	my %event = %{$event_ref};

	my %previous_current_calendar = %current_calendar;
	%current_calendar = %{$calendars{$event{cal_ids}[0]}};

	my $return_text = $event_details_template;
	my @event_start_timestamp_array = gmtime $event{start};

	my $event_cal_title_text = "";
	foreach $temp_cal_id (@{$event{cal_ids}}) {
		my $event_cal_name = "$calendars{$temp_cal_id}{title}";
		if ($calendars{$temp_cal_id}{link} =~ /\S/) {
			$event_cal_name = "<a target= _blank href=\"http://$calendars{$temp_cal_id}{link}\">$calendars{$temp_cal_id}{title}</a>";
		} else {
			$event_cal_name = "<a href=\"javascript:toggle_visible('calendar_details')\">$calendars{$temp_cal_id}{title}</a>";
		}
		$event_cal_title_text .= $event_cal_name.",";
	}
	$event_cal_title_text =~ s/,$//; # remove trailing comma

	$return_text =~ s/###event calendar name###/$event_cal_title_text/g;
 
	if ( $event{nice_date} eq "" || $event{nice_time} eq "" ) {
	 
		my $date_string = $lang{event_details_date_goes_here};
		my $event_time = "";

		if ($event{start} ne "") {
			if ($event{all_day_event} eq "1") {
				$date_string = &nice_date_range_format($event{start}, $event{start}+86400*($event{days}-1), " - ");
			} else {
				$date_string = &nice_date_range_format($event{start}, $event{end}, " - ");
				$event_time = &nice_time_range_format($event{start},$event{end});
			}
		}
		$event{nice_date} = $date_string;
		$event{nice_time} = $event_time;
 
	}

	if ( $event{cal_ids}[0] && $calendars{$event{cal_ids}[0]}{type} eq "ical") {
		$return_text =~ s/###event icon###//g; # no icon
	}
  

	$return_text =~ s/###event date###/$event{nice_date}/g;
	$return_text =~ s/###event time###/$event{nice_time}/g;

	$return_text =~ s/###event title###/$event{title}/g;
	$return_text =~ s/###event id###/$event{id}/g;
	$return_text =~ s/###event calendar id###/$event{cal_id}[0]/g;
	$return_text =~ s/###event background color###/$event{bgcolor}/g;

	my $event_details = $event{details};
	#replace \n characters with <br> tags
	$event_details =~ s/\n/\n<br>\n/g;

	# check the event details, and see if there are any non-htmlified
	# links.  If so, turn them into links.
	$event_details =~ s/[^"](htt.:\/\/.+?),*\.?(\s|\n|<|$)/ <a href=\"$1\">$1<\/a>$2/g;

	# convert email addresses to links.
	$event_details = &make_email_link($event_details);

	# make sure all links open up in a new window
	$event_details =~ s/<a/<a target = "blank"/g;

	$return_text =~ s/###event details###/$event_details/g;

	my $event_icon_text = "";
	if ($event{icon} ne "blank") {
		$event_icon_text = "<img style=\"border-width:0px;\" src = \"$icons_url/$event{icon}_50x50.gif\" hspace=2 vspace=1><br>";
	}
	$return_text =~ s/###event icon###/$event_icon_text/g;

	my $unit_number_text = $event{unit_number};
	$unit_number_text =~ s/(\d)/<img src="$graphics_url\/unit_number_patch_$1_40x25.gif" alt="" border="0" vspace=0 hspace=0>/g;
	$return_text =~ s/###unit number icon###/$unit_number_text/g;

	my $edit_event_link = "<a event_id=\"$event{id}\" href=\"\">$lang{context_menu_edit_event}</a>";
	$edit_event_link = $lang{event_details_edit_disable} unless $writable{events_file};
	$return_text =~ s/###edit event link###/$edit_event_link/g;

	my $temp = &export_event_link(\%event);
	$return_text =~ s/###export event link###/$temp/g;

	if ( $event{cal_ids}[0] ) {
		my $cal_detail_text .= <<p1;
$calendars{$event{cal_ids}[0]}{details}
p1
	}

	$return_text =~ s/###event calendar details###/$cal_detail_text/g;

	%current_calendar = %previous_current_calendar;

	return $return_text;
} # generate_event_details

sub export_event_link() {
  my $results = "";
  my ($event_ref) = @_;
  my %event = %{$event_ref};
  
  $results .=<<p1;
<form name="export_event_form" id="export_event_form" target="_blank" action="$script_url/$name" method=GET>
<a href="javascript:document.export_event_form.submit();">$lang{export}</a> $lang{this_event_to}
<input type="hidden" name="export_event" value=1>
<input type="hidden" name="evt_id" value="$event{id}">
<br/>

<select name="export_type" style="font-size:x-small;">
<option value="icalendar">$lang{icalendar_option}
<option value="vcalendar">$lang{vcalendar_option}
<option value="ascii_text">$lang{text_option}
</select>
</form>
p1
} #export_event_link

sub validate_emails() {
  my ($email_string) = @_;
  
  # support multiple email addresses
  my @to_addresses = split (',', "$email_string");
  
  foreach $to_address (@to_addresses) {
    if (!($to_address =~ /^[\w\-\_\.]+\@([\w\-\_]+\.)+[a-zA-Z]{2,}$/)) {
      return $to_address;
    }  
  }
  return "";
}


sub send_email_reminder() {
  my ($event_ref, $to_address, $email_text) = @_;
  my %event = %{$event_ref};
  
  if ($options{email_mode} == 0) {return $lang{send_email_reminder2};}
    
  $date_string = &nice_date_range_format($event{start}, $event{end}, " - ");
  
  $to_address =~ s/\s//g;
  chomp $to_address;
  
  my $email_valid = &validate_emails($to_address);
  if ($email_valid ne "") {
    return "$lang{send_email_reminder1} ($email_valid).";
  }  
  my @to_addresses = split (',', "$to_address");
  
  foreach $temp (@to_addresses) {
    my $subject = $lang{send_email_reminder_subject};
    $subject =~ s/###title###/$event{title}/g;
    &send_email($temp, $options{from_address}, $options{reply_address}, $subject, $email_text);
  }
  return "1";
  #return "$lang{send_email_reminder3} ($options{email_mode}).";
  
} # send_email_reminder


sub send_email() {
  my ($to, $from, $reply_to, $subject, $body) = @_;
    
  my $content_type = "text/plain";
  
  $body =~ s/\n/\r\n/g;
  
  if ($options{html_email} eq "1") {
    $content_type = "text/html";
  
    $body = <<p1;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
<title>$subject</title>
</head>

$body
</body></html>

p1
  }
  
  if ($options{email_mode} == 1) {
    open(SENDMAIL, "| $options{sendmail_location} -t") || ($debug_info .= "Can't open sendmail at $options{sendmail_location}!\n");

    print SENDMAIL <<p1;
Reply-to: $reply_to
From: $from
Subject: $subject
To: $to
Content-type: $content_type\n
$body

p1
    close(SENDMAIL);
  } elsif ($options{email_mode} == 2) {
    $smtp->mail($reply_to);
    $smtp->to($to);
    $smtp->data();
    $smtp->datasend("To: $to\n");
    $smtp->datasend("From: $from\n");
    $smtp->datasend("Subject: $subject\n");
    $smtp->datasend("Content-type: $content_type\n\n");
    $smtp->datasend("$body\n");
    $smtp->dataend();
    $smtp->reset();
  }
}

sub extract_cookie_parms() {
	my %cd = ();
	my $cookie_text = $q->cookie('plans_view');
	$cookie_text = &decode( $cookie_text );

	try {
		%cd = %{ decode_json( $cookie_text ) };
		return \%cd;
	}
	catch Error with {
		#pass
	};

}



sub deep_copy {
  my $this = shift;
  if (not ref $this) {
    $this;
  } elsif (ref $this eq "ARRAY") {
    [map deep_copy($_), @$this];
  } elsif (ref $this eq "HASH") {
    +{map { $_ => deep_copy($this->{$_}) } keys %$this};
  } else { die "what type is $_?" }
}


sub xml2html {
	my ($xml) = @_;
	$xml =~ s/</&lt;/gs;
	$xml =~ s/>/&gt;/gs;
	return $xml;
}

sub contains {
  my ($arr_ref, $val) = @_;
  my @arr = @{$arr_ref};
  
  foreach $val2 (@arr) {
     return 1 if ($val2 eq $val);
  }
  return 0;
}

sub intersects {
  my ($arr1, $arr2) = @_;
  my @ar1 = @{$arr1};
  my @ar2 = @{$arr2};
  
  foreach $val1 (@ar1) {
    foreach $val2 (@ar2) {
      return 1 if ($val1 eq $val2);
    }
  }
  return 0;
}

sub load_templates() {
  my $custom_template_file_found=1;

  if ($current_calendar{custom_template} ne "") { # custom template
    $template_html = &get_remote_file("$current_calendar{custom_template}");

    if ($template_html !~ /###/){
      $custom_template_file_found=0;
      $lang{custom_template_fail} =~ s/###template###/$current_calendar{custom_template}/;
      $debug_info .= "$lang{custom_template_fail}\n";
    }
  }

  if ($current_calendar{custom_template} eq "" || $custom_template_file_found ==0){
    if (!(-e "$options{default_template_path}")) {
      $fatal_error=1;
      $lang{default_template_fail} =~ s/###template###/$options{default_template_path}/;
      $error_info .= "$lang{default_template_fail}\n";
      &fatal_error();
    } else {
      open (FH, "$options{default_template_path}") || ($debug_info .="<br/>Unable to open default template file $options{default_template_path} for reading<br/>");
      flock FH,2;
      @template_lines=<FH>;
      close FH;
      $template_html = join "", @template_lines;
      $local_template_file = 1;
    }
  }
  &split_templates();
}



sub split_templates {
  $event_details_template = $template_html;
  $list_item_template = $template_html;
  $calendar_item_template = $template_html;
  $upcoming_item_template = $template_html;

  # strip other templates from main template
  $template_html =~ s/<\/html>.+/<\/html>/s;
  $template_html =~ s/<event_details>.+<\/event_details>//s;
  $template_html =~ s/<event_list_item>.+<\/event_list_item>//s;
  $template_html =~ s/<calendar_item>.+<\/calendar_item>//s;
  $template_html =~ s/<upcoming_item>.+<\/upcoming_item>//s;

  if ($event_details_template =~ /<event_details>/ && $event_details_template =~ /<\/event_details>/) {
    $event_details_template =~ s/.*<event_details>//s;
    $event_details_template =~ s/<\/event_details>.+//s;
  } else {
    $debug_info .= "Warning!  No event details template found.  (The template file doesn't contain &lt;event_details&gt;...&lt;/event_details&gt;\n";
    $event_details_template = "";
  }

  if ($list_item_template =~ /<event_list_item>/ && $list_item_template =~ /<\/event_list_item>/) {
    $list_item_template =~ s/.*<event_list_item>//s;
    $list_item_template =~ s/<\/event_list_item>.+//s;
  } else {
    $debug_info .= "Warning!  No event event list item template found.  (The template file doesn't contain &lt;event_list_item&gt;...&lt;/event_list_item&gt;\n";
    $event_details_template = "";
  }

  if ($calendar_item_template =~ /<calendar_item>/ && $calendar_item_template =~ /<\/calendar_item>/) {
    $calendar_item_template =~ s/.*<calendar_item>//s;
    $calendar_item_template =~ s/<\/calendar_item>.+//s;
  } else {
    $debug_info .= "Warning!  No calendar event list item template found.  (The template file doesn't contain &lt;calendar_list_item&gt;...&lt;/calendar_list_item&gt;\n";
    $calendar_item_template = "";
  }

  if ($upcoming_item_template =~ /<upcoming_item>/ && $upcoming_item_template =~ /<\/upcoming_item>/) { 
    $upcoming_item_template =~ s/.*<upcoming_item>//s;
    $upcoming_item_template =~ s/<\/upcoming_item>.+//s;
  } else {
    $debug_info .= "Warning!  No upcoming event list item template found.  (The template file doesn't contain &lt;upcoming_list_item&gt;
...&lt;/upcoming_list_item&gt;\n";
    $upcoming_item_template = "";
  }


}


sub format2mdy() {  
	# takes a format string (which can be "dd/mm/yyyy", "yyyy,mm,dd", etc.)
	# and a date in that format, and returns the month, day, and year.
	my ($date, $format) = @_;

	my @temp_date = split (/\W+/, $date);
	my @temp_format = split (/\W+/, $format);
	my %temp_format_map;

	for (my $l1=0;$l1<3;$l1++) {
		$temp_format_map{$temp_format[$l1]} = $temp_date[$l1];
	}

	my $mon = $temp_format_map{"mm"};
	my $day = $temp_format_map{"dd"};
	my $year = $temp_format_map{"yy"};
	my $fullyear = $temp_format_map{"yyyy"};

	try {
		if ( $year ne "" ) {
			($out_year, $out_mon, $out_day) = normalize_ymd( $year, $mon, $day );
		}

		if ( $fullyear ne "" ) {
			($out_year, $out_mon, $out_day) = normalize_ymd( $fullyear, $mon, $day );
		}

		return ($out_mon+0, $out_day+0, $out_year+0);
	}
	catch Error with {
		return( -1, -1, -1 );
	};

}

sub js_string() {
  my ($string) = @_;
  $string =~ s/\//\\\//g;
  $string =~ s/\n/\\n/g;
  $string =~ s/"/\\"/g;
  $string =~ s/'/\\'/g;
  $string =~ s/\r//g;
  return $string;
}


sub rgb2hsv {
    # r,g,b values are from 0 to 255
    # h = [0..360], s = [0..100], v = [0..100]
    #    if s == 0, then h = -1 (undefined)
    
    my ($r,$g,$b) = @_;
    
    $r /= 255;
    $g /= 255;
    $b /= 255;

    my ($h, $s, $v);
    my ($min, $max, $delta);
    
    $min = &min ( $r, $g, $b );
    $max = &max ( $r, $g, $b );

    # value is just the brightest rgb value
    $v = $max;

    # account for shades of gray:
    $delta = $max - $min;
    if ($delta == 0 ) {
      $s = 0; # no hue, so it can't be saturated!
      $h = -1; # hue is really undefined, but...
      return ($h, $s, $v*100);
    }

    # saturation is intensity/blandness of color:
    $s = $delta / $max;  # max > 0 or delta would be 0

    # hue depends on the relative strengths of the colors:
    if( $r == $max ) {
      $h = ( $g - $b ) / $delta;  # between yellow & magenta
    } elsif( $g == $max ) {
      $h = 2 + (( $b - $r ) / $delta);  # between cyan & yellow
    } else {
      $h = 4 + (( $r - $g ) / $delta);  # between magenta & cyan
    }

    # it's also calculated as degrees on a color wheel
    $h *= 60;  # degrees
    $h += 360 if ($h < 0); 

    # s and v are percentages
    $s *= 100;
    $v *= 100;
    return (int( $h ), int($s), int($v));
}

sub hsv2rgb {
  my ($hue, $sat, $val) = @_;
  my @hsv_map = ('vkm', 'nvm', 'mvk', 'mnv', 'kmv', 'vmn');
  # HSV conversions from pages 401-403 "Procedural Elements for Computer 
  # Graphics", 1985, ISBN 0-07-053534-5.

  my @result;
  if ($sat <= 0) {
    return ( 255 * $val, 255 * $val, 255 * $val );
  } else {
    $val >= 0 or $val = 0;
    $val <= 1 or $val = 1;
    $sat <= 1 or $sat = 1;
    $hue >= 360 and $hue %= 360;
    $hue < 0 and $hue += 360;
    $hue /= 60.0;
    my $i = int($hue);
    my $f = $hue - $i;
    $val *= 255;
    my $m = $val * (1.0 - $sat);
    my $n = $val * (1.0 - $sat * $f);

    my $k = $val * (1.0 - $sat * (1 - $f));
    my $v = $val;
    my %fields = ( 'm'=>$m, 'n'=>$n, 'v'=>$v, 'k'=>$k, );
    return @fields{split //, $hsv_map[$i]};
  }
}


sub compatible_textcolor {
    my ($ebgc) = @_;
    my $compat;

    my $r = hex substr $ebgc,1,2;
    my $g = hex substr $ebgc,3,2;
    my $b = hex substr $ebgc,5,2;

    my $bright = ($r*299+$g*587+$b*114)/1000;

    if ($bright < 128) {$compat = "#ffffff";}
    else {$compat = "#000000";}
    return $compat;
}

sub load_file() {
  my ($file)=@_;
  if (-e $file) {
    open (FH, "$file") || (return "unable to open include file $file for reading");
    flock FH,2;
    my @lines=<FH>;
    close FH;
    $text = join "", @lines;
    return $text;
  } else {
    return "file $file does not exist";
  }
}

sub get_js_includes( ) {

	my ($theme_url) = @_;
 
	my $js_includes =<<p1;
<script  type="text/javascript" src="$theme_url/jquery-1.3.2.min.js"></script>
<script type="text/javascript">var \$j = jQuery.noConflict();</script>
<script  type="text/javascript" src="$theme_url/jquery-ui-1.7.1.custom.min.js"></script>

<script  type="text/javascript" src="$theme_url/colorpicker/js/eye.js"></script>
<script  type="text/javascript" src="$theme_url/colorpicker/js/utils.js"></script>
<script  type="text/javascript" src="$theme_url/colorpicker/js/colorpicker.js"></script>

<script type="text/javascript" src="$theme_url/plans_lang.js"></script>
<script type="text/javascript" src="$theme_url/plans.js"></script>

p1

	return $js_includes;

}

# default calendar data structure
#%default_cal;
%default_cal = (id => "", 
                title => "", 
                details => $new_calendar_default_details,
                link => "",
                local_background_calendars => {},
                selectable_calendars => {},
                make_new_calendars_selectable => $options{new_calendars_automatically_selectable},
                list_background_calendars_together => "",
                background_events_display_style => "normal",
                background_events_fade_factor => "",
                background_events_color => "#ffffff",
                default_number_of_months => 1,
                max_number_of_months => 24,
                gmtime_diff => 0,
                date_format => "mm/dd/yy",
                week_start_day => 0,
                event_change_email => "",
                custom_template => "",
                custom_stylesheet => "",
                password => "",
                update_timestamp => 0);



# If an included file contains only subroutines, perl will complain 
# that it "did not return a true value".  The "return 1;" at the end fixes this.
return 1;
