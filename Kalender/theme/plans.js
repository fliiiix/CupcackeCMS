// jQuery plugin for planscalendar functions

jQuery.planscalendar = function( options ) {

}

jQuery.planscalendar.current_calendar_being_edited = null;
jQuery.planscalendar.number_of_calendars_waiting_for_approval = 0;
jQuery.planscalendar.pending_calendars = [];
jQuery.planscalendar.pending_events = [];
jQuery.planscalendar.calendar_controls ={};


// always called when the calendar page is done loading
jQuery.planscalendar.plans_page_loaded = function()  {
	jQuery.planscalendar.update_login();
	jQuery.planscalendar.map_cal_ids();

	jQuery.planscalendar.time_format = ( jQuery.planscalendar.plans_options.twentyfour_hour_format == 1 ) ? "hh:mm" : "sh:mm ampm";


	jQuery.planscalendar.highlight_current_day();

	// hook up add/edit event click
	var f = function(e, ui) {

		if ( e.target != $j('#menu_tabs')[0] ) {
			//unexpected target - ignore
			return
		}

		if (ui.index == 1) {
			if ( ! jQuery.planscalendar.edit_event_in_progress ) {
				jQuery.planscalendar.edit_event({}, false);
			}
			jQuery.planscalendar.edit_event_in_progress = false;
			return true;

		} else if (ui.index == 2) {
			jQuery.planscalendar.show_add_edit_calendar_dialog();
			return true;
		}
		return true;
	};

	menu_tabs = $j('#menu_tabs').tabs( {'selected':0});

	$j('#menu_tabs').bind( 'tabsselect', f );


	// init context menus
	$j('#day_contextmenu_add_event').html(plans_lang['add_event_on_this_day']);
	$j('#event_contextmenu_edit_event').html(plans_lang['context_menu_edit_event']);
	$j('#event_contextmenu_clone_event').html(plans_lang['context_menu_clone_event']);
	$j('#event_contextmenu_delete_event').html(plans_lang['context_menu_delete_event']);

	jQuery.planscalendar.hookup_contextmenu_events();

	// login stuff

	jQuery.planscalendar.display_pending_events();

	// setTimeout to prevent delay on page load	
	setTimeout(function() {
			jQuery.planscalendar.insert_lang_strings( null, ['controls_start_month', 'controls_num_months'] );
			jQuery.planscalendar.insert_all_lang_strings( );
		}, 100);

	jQuery.planscalendar.update_calendar_controls();
		
	if (messages != null && messages != '') jQuery.planscalendar.update_messages(messages);
	  
}

jQuery.planscalendar.update_calendar_controls = function() {

	$j('form[name=tab0_form]').attr('action', jQuery.planscalendar.plans_url);

	$j('#cal_start_month').empty();
	for (var i=0;i<plans_lang['months'].length;i++) {
		$j('#cal_start_month').append('<option value="' + i  + '">' + plans_lang['months'][i] + '</option>');
	}

	$j('#cal_start_month option[value=' + jQuery.planscalendar.calendar_controls.cal_start_month + ']').attr('selected','selected');

	$j('#cal_start_year').val(jQuery.planscalendar.calendar_controls.cal_start_year);
	$j('#cal_num_months').val(jQuery.planscalendar.calendar_controls.cal_num_months);

}

jQuery.planscalendar.map_cal_ids = function()  {
	
	jQuery.planscalendar.cal_ids = {};

	for (var i=0;i<jQuery.planscalendar.calendars.length;i++) {
		jQuery.planscalendar.cal_ids[''+jQuery.planscalendar.calendars[i].id] = jQuery.planscalendar.calendars[i];
	}
}

jQuery.planscalendar.get_cal = function(cal_id)  {
	if ( ! jQuery.planscalendar.cal_ids ) return;

	return jQuery.planscalendar.cal_ids[''+cal_id];
}

jQuery.planscalendar.calendars = [];
jQuery.planscalendar.events = {};

jQuery.planscalendar.plans_options = {};

var event_target = null;
var browser_type = null;
var cal_password = '';

var users = new Array();
var current_user = null;

var success = false;
var messages = "";

var menu_tabs = null;

jQuery.planscalendar.jgrowl_opts = {
                    theme: 'manilla',
                    sticky: true,
                    speed: 'slow',
                    easing: 'easeInOutExpo',
                    animateOpen: {
                        height: "show",
                        width: "show"
                    }
};

function info(d) {try{console.info(d)}catch(e){}};

jQuery(window).bind('load', jQuery.planscalendar.plans_page_loaded);



jQuery.planscalendar.insert_all_lang_strings = function() {
	for (key in {'controls_change':'' } ) {
		$j('input[type=submit].lang_'+key).val( $j('<div/>').html(plans_lang[key]).text() ).empty();
	}

	for (key in plans_lang) {
		/* This try/catch is needed because IE7 & IE8 do not allow jQuery.html() on certain elements (<style>, <input>)*/
		try{
			$j('.lang_'+key).html(plans_lang[key]);
		} catch (e) {
		}
	}

	$j('.help_text').html(plans_lang['help_on_this']);

}

jQuery.planscalendar.insert_lang_strings = function( el, strings ) {

	for (var i=0;i< strings.length;i++) {
		var key = strings[i];
		$j('.lang_'+key).html(plans_lang[key]);
	}

}



jQuery.planscalendar.hookup_contextmenu_events = function() {
	// hook up context menu actions for days
	var days = $j('td.day');

	days.each(function(i){
		$j(this).contextMenu('day_contextmenu', {
			bindings:{
				'day_contextmenu_add_event':function(t) {
					$j('#menu_tabs').tabs('select',1);
					$j('a[href=#menu_tab_1] span').html(plans_lang.tab_text[1]);

					jQuery.planscalendar.show_add_edit_event_dialog();
					new_event = {
						'all_day_event' : jQuery.planscalendar.plans_options.new_events_all_day
					}

					jQuery.planscalendar.populate_add_edit_event_dialog( new_event );

					// populate add_edit_event date
					var timestamp = $j(t).attr('date');
					var d = new Date( );
					d.setTime( timestamp * 1000 );
					$j('#add_edit_event_start_date').val(jQuery.planscalendar.formatDate(d, jQuery.planscalendar.date_format.replace(/mm/,'MM')));


					$j('#add_edit_event_start_time').val(jQuery.planscalendar.plans_options.default_event_start_time);
					$j('#add_edit_event_end_time').val(jQuery.planscalendar.plans_options.default_event_end_time);


				}
			}
		});
	});
	
	// hook up context menu actions for events
	var event_els = $j('.event_box');

	event_els.each(function(i){
		$j(this).contextMenu('event_contextmenu', {
			bindings:{
				'event_contextmenu_edit_event':function(t) {
					jQuery.planscalendar.edit_event(jQuery.planscalendar.events[$j(t).attr('event_id')]);
					$j('a[href=#menu_tab_1] span').html(plans_lang.tab_text[1]);
				},
				'event_contextmenu_clone_event':function(t) {
					jQuery.planscalendar.edit_event(jQuery.planscalendar.events[$j(t).attr('event_id')]);
					$j('a[href=#menu_tab_1] span').html(plans_lang.add_or_edit1);
					$j('#add_edit_event_id').val('');
				},
				'event_contextmenu_delete_event':function(t) {
					jQuery.planscalendar.delete_event(jQuery.planscalendar.events[$j(t).attr('event_id')]);
				}
			}
		});
	});


}

jQuery.planscalendar.show_add_edit_calendar_dialog = function() {

	jQuery.planscalendar.current_calendar_being_edited = null;
	
	$j('#choose_calendar').show();	
	$j('#edit_calendar').hide();

	var menu_tabs_el = $j('#menu_tabs ul');
	var c = menu_tabs_el.offset();
	c.height = menu_tabs_el.height();
	c.width = menu_tabs_el.width();

	var w = $j('#calendar_area').width();
	var c2 = $j('#calendar_area').offset();


	$j('.ui-dialog.add_edit').css({'height':'auto'});
	$j('#add_edit_calendar_dialog').css({'height':'auto'});

	// populate calendar select

	$j('#edit_calendar_cal_id').empty();
	for (var i=0;i<jQuery.planscalendar.calendars.length;i++) {
		var calendar = jQuery.planscalendar.calendars[i];
		$j('#edit_calendar_cal_id').append('<option value="' + calendar.id  + '">' + calendar.title + '</option>');
	}

	$j('#choose_calendar_link').bind('click',jQuery.planscalendar.edit_calendar);
	$j('#add_new_cal_link').bind('click',jQuery.planscalendar.add_calendar);
	$j('#add_new_ical_link').bind('click',jQuery.planscalendar.add_ical);
	$j('#view_pending_calendars_link').bind('click',jQuery.planscalendar.view_pending_calendars);

	jQuery.planscalendar.update_pending_calendars_text();


}

jQuery.planscalendar.update_pending_calendars_text = function() {
	var num_pending_calendars = jQuery.planscalendar.pending_calendars.length;

	var text = jQuery.planscalendar.get_lang('tab2_no_new_calendars');

	if (num_pending_calendars > 0 ) {
		text = jQuery.planscalendar.get_lang('tab2_some_new_calendars').replace('###num###', num_pending_calendars);
	}

	$j('#pending_calendars_status').html(text);

}

jQuery.planscalendar.view_pending_calendars = function() {

	var contents = '';

	for (var i=0;i<jQuery.planscalendar.pending_calendars.length;i++) {
		var pending_calendar = jQuery.planscalendar.pending_calendars[i];
		contents += tmpl('pending_calendar_tmpl', pending_calendar);
	}

	contents += '<br style="clear:both"/>';

	contents += '<div class="form_field">';
	contents += '<label class="required" style="width:50%" for="main_password">';
	contents += jQuery.planscalendar.get_cal('0').title + ' ' + jQuery.planscalendar.get_lang('password');
	contents += '</label>';
	contents += '<input type=password id="main_password" name = "main_password" size=10>';
	contents += '</div>';

	contents += '<div class="form_field">';
	contents += '<label style="width:50%">&nbsp</label>';
	contents += '<input id="approve_cal_button" type=submit name="approve_cal_button" value = "'+jQuery.planscalendar.get_lang('view_pending_calendars5')+'">';
	contents += '</div>';

	
	var f = function(event, ui) {
		$j('#pending_calendars_dialog').dialog('destroy');
		return false;
	}

	var w = $j('#menu_tabs').width();
	var c2 = $j('#menu_tabs').offset();

	
	$j('#pending_calendars_dialog').attr('title',jQuery.planscalendar.get_lang('view_pending_calendars1')).html(contents).dialog({'resizable':true , 'position':'center', 'beforeclose': f  }).show();

	$j('#pending_calendars_dialog').css({'width':w+'px','height':'445px','overflow-x':'hidden','overflow-y':'scroll'});
	$j('#pending_calendars_dialog').parents('.ui-dialog').css({width:w,left:c2.left,height:'500px'});

	$j('#approve_cal_button').click(jQuery.planscalendar.approve_delete_calendars_submit);

}

jQuery.planscalendar.approve_delete_calendars_submit = function() {


	var data = {
		'api_command':'approve_delete_pending_calendars',
		'main_password':$j('#main_password').val()
		};

	var approve_delete_radio_inputs = $j('.approve_delete_inputs input[type=radio]');

	approve_delete_radio_inputs.each( function(i) {
		if (this.checked) {
			data[this.name] = this.value;
		}
	} );

	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {

			jQuery.planscalendar.update_calendars(jsondata.calendars);
			jQuery.planscalendar.update_pending_calendars(jsondata.pending_calendars);
			jQuery.planscalendar.update_pending_calendars_text();
			jQuery.planscalendar.view_pending_calendars();
			jQuery.planscalendar.update_calendar_controls();

		}
	}

	$j('#approve_cal_button').throbber({
		image: jQuery.planscalendar.theme_url + "/images/throbber.gif",
		wrap: '<span>Please Wait...</span>'
	});

	$j.ajax( {'type':'POST', 'url':jQuery.planscalendar.plans_url, 'data':data, 'dataType':'json', 'success':successCallback} );


}

jQuery.planscalendar.refresh_calendar_view = function( calendar_html ) {
	var calendar_el = $j('#calendar_area table.calendar');
	var parent_el = calendar_el.parent();
	calendar_el.remove();
	parent_el.empty();
	parent_el.append(calendar_html);

	jQuery.planscalendar.highlight_current_day();
}

jQuery.planscalendar.highlight_new_events = function( event_ids ) {
	if ( ! event_ids ) return;

	for (var i=0;i<event_ids.length;i++) {
		jQuery('[event_id='+event_ids[i]+']').boxhighlight();
		break;
	}
}


jQuery.planscalendar.update_calendars = function(updated_calendars) {
	jQuery.planscalendar.calendars = updated_calendars;

	jQuery.planscalendar.map_cal_ids();

	if ( jQuery.planscalendar.current_calendar_being_edited ) {
		// reset reference to current calendar
		jQuery.planscalendar.current_calendar_being_edited = jQuery.planscalendar.get_cal(jQuery.planscalendar.current_calendar_being_edited.id);
	}


}

jQuery.planscalendar.update_pending_calendars = function(updated_pending_calendars) {
	jQuery.planscalendar.pending_calendars = updated_pending_calendars;
}

jQuery.planscalendar.update_pending_events = function(updated_pending_events) {
	jQuery.planscalendar.pending_events = updated_pending_events;
}



jQuery.planscalendar.add_calendar = function() {
	$j('#del_cal_button').hide();
	$j('#delete_note').hide();
	$j('#edit_calendar_password_interface').hide();
	$j('#add_calendar_password_interface').show();
	$j('#user_no_add').show();

	if (jQuery.planscalendar.logged_in) {
		$j('#add_calendar_cal_password_field').hide();
	}else {
		$j('#add_calendar_cal_password_field').show();
	}


	jQuery.planscalendar.add_edit_calendar();

	jQuery.planscalendar.populate_add_edit_calendar_dialog( {} );
}


jQuery.planscalendar.edit_calendar = function() {

	var cal_id = $j('#edit_calendar_cal_id :selected').val();
	jQuery.planscalendar.current_calendar_being_edited = jQuery.planscalendar.get_cal(cal_id);

	$j('.lang_add_calendar').html(jQuery.planscalendar.get_lang('edit_calendar') + ': ' + jQuery.planscalendar.current_calendar_being_edited.title);

	jQuery.planscalendar.populate_add_edit_calendar_dialog( jQuery.planscalendar.current_calendar_being_edited );

	$j('#del_cal_button').show();
	$j('#delete_note').show();
	$j('#edit_calendar_password_interface').show();
	$j('#add_calendar_password_interface').hide();
	$j('#user_no_add').hide();

	if (jQuery.planscalendar.logged_in) {
		$j('#edit_calendar_cal_password_field').hide();
	} else if ( jQuery.planscalendar.plans_options['disable_passwords'] == '1' ) {
		$j('#edit_calendar_cal_password_field').hide();
	} else {
		$j('#edit_calendar_cal_password_field').show();
	}



	jQuery.planscalendar.add_edit_calendar();

}


jQuery.planscalendar.add_edit_calendar = function() {

	var w = $j('#menu_tabs').width();

	$j('#choose_calendar').hide();	
	$j('#edit_calendar').show();	
	$j('.ui-dialog.add_edit').css({'height':'auto'});

	if ( jQuery.planscalendar.plans_options['users'] != 1 ) {
		//$j('#add_edit_calendar_tabs li').eq(4).hide();
	}

	$j('#add_edit_calendar_tabs').tabs({'selected':0});

	var f = function(e, ui) {
		return false;
	}

	$j('#update_cal_button').val(jQuery.planscalendar.get_lang('update_cal_button'));
	$j('#add_cal_button').val(jQuery.planscalendar.get_lang('add_calendar'));
	$j('#del_cal_button').val( $j('<div/>').html(plans_lang['del_cal_button1']).text() );

	
	$j('#update_cal_button').bind('click',jQuery.planscalendar.add_edit_calendar_submit);
	$j('#add_cal_button').bind('click',jQuery.planscalendar.add_edit_calendar_submit);
	$j('#del_cal_button').bind('click',jQuery.planscalendar.delete_calendar_submit);



}

jQuery.planscalendar.populate_add_edit_calendar_dialog = function( calendar ) {

	$j('#date_format').val(calendar.date_format || jQuery.planscalendar.date_format);

	$j('#add_edit_calendar_cal_title').val(calendar.title || '');
	$j('#add_edit_calendar_cal_link').val(calendar.link || '');
	$j('#add_edit_calendar_details').val(calendar.details || '');


	// locally merged calendars
	$j('#background_calendars').empty();
	for (var i=0;i<jQuery.planscalendar.calendars.length;i++) {
		var c = jQuery.planscalendar.calendars[i];
		$j('#background_calendars').append('<option value="' + c.id  + '">' + c.title + '</option>');
		if ( calendar.local_background_calendars && calendar.local_background_calendars[''+c.id] && calendar.local_background_calendars[''+c.id] == 1 ) {
			$j('#background_calendars option[value='+c.id+']').attr('selected','selected');
		}
	}

	if (jQuery.planscalendar.plans_options.all_calendars_selectable == 1 ) {
		$j('#some_calendars_selectable').hide();
	} else {
		$j('#all_calendars_selectable').hide();
	}

	// week start day
	$j('#week_start_day').empty();
	for (var i=0;i<plans_lang.day_names.length;i++) {
		$j('#week_start_day').append('<option value="' + i  + '">' + plans_lang.day_names[i] + '</option>');

	}
	$j('#week_start_day option[value=' + calendar.week_start_day + ']').attr('selected','selected');

	$j('#default_number_of_months').val(calendar.default_number_of_months || '');
	$j('#max_number_of_months').val(calendar.max_number_of_months || '');
	$j('#gmtime_diff').val(calendar.gmtime_diff || '');
	$j('#event_change_email').val(calendar.event_change_email || '');

	// populate background colors dropdown
	var background_colors_html = '<option style="background-color:#fff;" value="">None</option>';
	
	for( var i=0;i<jQuery.planscalendar.event_background_colors.length;i++) {
		
		var color = jQuery.planscalendar.event_background_colors[i];
		var desc = ( jQuery.planscalendar.plans_options.show_event_background_color_descriptions == 1 ) ? color.title : '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
		background_colors_html += '<option style="background-color:'+color.color+';" value="'+color.color+'">' + desc + '</option>';
	}

	background_colors_html += '<option style="background-color:#fff" class="custom" value="#ffffff">custom</option>';

	$j('#calendar_events_color').html( background_colors_html );
	$j('#calendar_events_color').change( jQuery.planscalendar.update_calendar_background_select );
	$j('#calendar_events_color').change( jQuery.planscalendar.update_merged_calendars_display_style);

	// custom color selected?
	var s = $j('#calendar_events_color option[value=' + calendar.calendar_events_color + ']').attr('selected','selected');

	if ( s.length == 0 && calendar.calendar_events_color ) {
		$j('#calendar_events_color option.custom').attr('selected','selected');
		$j('#calendar_events_color option.custom').val(calendar.calendar_events_color);
		$j('#calendar_events_color .custom').css('background-color', calendar.calendar_events_color);
		$j('#calendar_events_color').css('background-color', calendar.calendar_events_color);

	}

	// events that trigger a change in preview
	$j('.merged_calendars_display_style_click_trigger').bind('click', jQuery.planscalendar.update_merged_calendars_display_style);
	$j('.merged_calendars_display_style_change_trigger').bind('change', jQuery.planscalendar.update_merged_calendars_display_style);


	// background events color
	$j('#background_events_color').val( calendar.background_events_color );
	var f = function(hsb, hex, rgb) {
		$j('#background_events_color').val('#'+hex);
		jQuery.planscalendar.update_merged_calendars_display_style();
	}
	$j('#background_events_color_select_icon').ColorPicker({onSubmit:f});



	// populate translucency dropdown
	var background_translucency_html = '';
	for( var i=70;i>0;i-=10) {
		background_translucency_html += '<option value="'+i+'">'+i+' %</option>';
	}
	$j('#background_events_fade_factor').html( background_translucency_html );


	$j('#background_events_color').val( calendar.background_events_color );
	$j('#background_events_fade_factor option[value=' + calendar.background_events_fade_factor + ']').attr('selected','selected');
	$j('input[name=background_events_display_style][value='+calendar.background_events_display_style+']').attr('checked','checked');


	// list users
	var results = '';
	for (var i=0;i<calendar.users.length;i++) {
		var user = calendar.users[i];
    	results += user.name+' <a id="'+user.id+'_edit_user_link" href="javascript:void(0)">('+jQuery.planscalendar.get_lang('edit')+')</a><br/>';
	}
	$j('#list_users').html(results);

	for (var i=0;i<calendar.users.length;i++) {
		var user = calendar.users[i];
		$j('#'+user.id+'_edit_user_link').bind('click', function() {jQuery.planscalendar.edit_user(user)});
	}
 
	// add user link
	$j('#add_user_link').click(jQuery.planscalendar.add_user);


	jQuery.planscalendar.update_calendar_background_select(calendar.calendar_events_color);
	jQuery.planscalendar.update_merged_calendars_display_style();

	// remote calendars

	// list current remote calendars
	jQuery.planscalendar.list_remote_calendars();



}

jQuery.planscalendar.update_merged_calendars_display_style = function() {

	// same-calendar events
	if ( $j('#calendar_events_color').val() == '' ) {
		$j('#preview_e1').css('background-color', '#ffffcc');
		$j('#preview_e2').css('background-color', '#ccffcc');
	} else {
		$j('#preview_e1').css('background-color',  $j('#calendar_events_color').val());
		$j('#preview_e2').css('background-color',  $j('#calendar_events_color').val());
	}

	// background calendar events

	if ( $j('#background_events_display_style1:checked').length > 0 ) {
		$j('#bg_preview_e1').css({'background-color': '#ffffcc','opacity':'1'});
		$j('#bg_preview_e2').css({'background-color': '#ccffff','opacity':'1'});

	} else if ( $j('#background_events_display_style2:checked').length > 0 ) {
		var c = $j('#background_events_color').val();
		if ( c == '' ) {
			$j('#background_events_color').val('#ffffff');
			c = '#ffffff';
		}
		$j('#bg_preview_e1').css('background-color', c);
		$j('#bg_preview_e2').css('background-color', c);
	} else if ( $j('#background_events_display_style3:checked').length > 0 ) {
		var o = 1 - ($j('#background_events_fade_factor').val() / 100);
		$j('#bg_preview_e1').css({'background-color': '#ffffcc','opacity':o});
		$j('#bg_preview_e2').css({'background-color': '#ccffff','opacity':o});
	}

	// hook up "add new remote calendars" button
	$j('#get_remote_calendars_button').click(jQuery.planscalendar.get_remote_calendars);


}

jQuery.planscalendar.list_remote_calendars = function() {

	var remote_calendars = jQuery.planscalendar.current_calendar_being_edited.remote_background_calendars;

	if ( !remote_calendars ) return;

	var contents = '';
	for( var i=0;i<remote_calendars.length;i++ ) {

		var remote_calendar = remote_calendars[i];

		contents += tmpl('remote_calendar_tmpl', remote_calendar);

	}

	$j('#remote_calendars_list').html(contents);
	jQuery.planscalendar.insert_lang_strings( $j('#remote_calendars_list'), ['get_remote_calendars3'] );

}

jQuery.planscalendar.get_remote_calendars = function() {
	$j('#get_remote_calendars_dialog').show().dialog({title:plans_lang['get_remote_calendars'],height:600,width:700});

	$j('#check_remote_calendars_button').val(plans_lang['check_remote_calendars_button']);
	$j('#check_remote_calendars_button').click(jQuery.planscalendar.check_remote_calendars);
	$j('#remote_calendars_url').focus();
	$j('#remote_calendars_url').keypress(function(evt){if(evt.keyCode == 13){jQuery.planscalendar.check_remote_calendars()}});

}


jQuery.planscalendar.check_remote_calendars = function() {

	var data = {
		'api_command':'detect_remote_calendars',
		'remote_calendar_url': $j('#remote_calendars_url').val()
		};

	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {
			jQuery.planscalendar.current_remote_calendars = jsondata;  
			jQuery.planscalendar.display_available_remote_calendars(jsondata.public_calendars);
		}
	}

	$j('#check_remote_calendars_button').throbber({
		image: jQuery.planscalendar.theme_url + "/images/throbber.gif",
		wrap: '<span>Checking...</span>'
	});

	$j.ajax({
		'url':jQuery.planscalendar.plans_url,
		'type':'POST',
		'data':data,
		'dataType':'json',
		'success':successCallback
	});
}


jQuery.planscalendar.display_available_remote_calendars = function(available_remote_calendars) {
	if ( ! available_remote_calendars || available_remote_calendars.length == 0 || available_remote_calendars[0] == null ) {
		$j('#available_remote_calendars').html('<li>' + plans_lang['detect_remote_calendars5'] + '</li>')
		return;
	}
	
	var contents = '';
	for( var i=0;i<available_remote_calendars.length;i++ ) {

		var available_remote_calendar = available_remote_calendars[i];

		available_remote_calendar.display_class = ( i % 2 == 0 ) ? 'list_even' : 'list_odd';

		contents += tmpl('available_remote_calendar_tmpl', available_remote_calendar);

	}
	
	$j('#available_remote_calendars').html(contents);

	for( var i=0;i<available_remote_calendars.length;i++ ) {
		var available_remote_calendar = available_remote_calendars[i];
		if ( available_remote_calendar.requires_password == 'yes' ) {
			$j('#remote_calendar_password_required_' + available_remote_calendar.id).show();
		}
	}

	if (	available_remote_calendars.length > 0 ) {
		$j('#merge_selected_calendars_link').show().click(jQuery.planscalendar.merge_selected_remote_calendars);
	}


	jQuery.planscalendar.insert_lang_strings( $j('#available_remote_calendars'), ['detect_remote_calendars2', 'detect_remote_calendars3'] );


}

jQuery.planscalendar.merge_selected_remote_calendars = function() {

	var remote_calendars = jQuery.planscalendar.current_remote_calendars.public_calendars;
	
	var new_remote_calendars_xml = '';

	var n_merged = 0;
	for( var i=0;i<remote_calendars.length;i++ ) {

		var available_remote_calendar = remote_calendars[i];

		if ( $j('#merge_remote_calendar_checkbox_' + available_remote_calendar.id+':checked').length > 0 ) {

			jQuery.extend(available_remote_calendar, {
				'plans_version':jQuery.planscalendar.current_remote_calendars.remote_calendar_version,
				'url':jQuery.planscalendar.current_remote_calendars.url,
				'password':$j('#remote_calendar_password_'+available_remote_calendar.id).val()
			});

			var merge_xml = tmpl('remote_calendar_xml_tmpl', available_remote_calendar);

			n_merged++;

			new_remote_calendars_xml += merge_xml;
		}
		
	}

	new_remote_calendars_xml += '<remote_calendars>' + merge_xml + '</remote_calendars>';

	$j('#new_remote_calendars_xml').val(new_remote_calendars_xml);
	
	$j('#get_remote_calendars_dialog').dialog('close');

	if ( n_merged > 0 ) {

		var status_text = '';

		if ( n_merged == 1 ) {
			status_text = n_merged + ' ' + plans_lang['get_remote_calendar2_singular'] + ' ' + jQuery.planscalendar.current_calendar_being_edited.title;
		} else {
			status_text = n_merged + ' ' + plans_lang['get_remote_calendar2_plural'] + ' ' + jQuery.planscalendar.current_calendar_being_edited.title;
		}

		$j('#remote_background_calendars_status').html( status_text );
	}

}


jQuery.planscalendar.add_user = function() {
	
	var f = function(event, ui) {
		$j('#add_edit_user_dialog').dialog('destroy');
		return false;
	}

	$j('#add_edit_user_dialog').show().dialog({title:plans_lang['add_user'],height:400,width:500, beforeclose: f});

	$j('#user_id').val('');
	$j('#user_name').val('');
	$j('#add_edit_user_submit_button').val(jQuery.planscalendar.get_lang('add_user'));
	$j('#add_edit_user_submit_button').bind('click', function() {jQuery.planscalendar.add_edit_user_submit({})});

	$j('#delete_user_button_field').hide();
}

jQuery.planscalendar.edit_user = function(user, e) {
	
	var f = function(event, ui) {
		$j('#add_edit_user_dialog').dialog('destroy');
		return false;
	}

	$j('#add_edit_user_dialog').show().dialog({title:plans_lang['add_user'],height:600,width:500, beforeclose: f});

	$j('#user_id').val(user.id);
	$j('#user_name').val(user.name);
	$j('#add_edit_user_submit_button').val(jQuery.planscalendar.get_lang('update_user'));
	$j('#add_edit_user_submit_button').bind('click', function() {jQuery.planscalendar.add_edit_user_submit({})});
	$j('#delete_user_button').show().val(plans_lang['delete_user']).bind('click', function() {jQuery.planscalendar.add_edit_user_submit({ 'delete_user' : true})});

}

jQuery.planscalendar.add_edit_user_submit = function( options, e ) {


	var data = {
		'api_command':'add_edit_user',
		'delete': ( options.delete_user ) ? '1' : '',
		'cal_id':jQuery.planscalendar.current_calendar_being_edited.id,
		'user_id': $j('#user_id').val() || '',
		'name': $j('#user_name').val(),
		'password': $j('#user_password').val(),
		'repeat_password': $j('#user_repeat_password').val(),
		'new_password': $j('#user_new_password').val(),
		'cal_password':$j('#add_edit_user_cal_password').val()
		};


	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {

			jQuery.planscalendar.update_calendars(jsondata.calendars);

			jQuery.planscalendar.populate_add_edit_calendar_dialog( jQuery.planscalendar.current_calendar_being_edited);

			$j('#add_edit_user_dialog').dialog('close');
		}
	}

	$j('#add_edit_user_submit_button').throbber({
		image: jQuery.planscalendar.theme_url + "/images/throbber.gif",
		wrap: '<span>Please Wait...</span>'
	});

	$j.ajax({
		'url':jQuery.planscalendar.plans_url,
		'type':'POST',
		'data':data,
		'dataType':'json',
		'success':successCallback
	});



}

jQuery.planscalendar.update_calendar_background_select = function(initial_color) {

	var selected = $j('#calendar_events_color :selected');
	var color = selected.val();
	$j('#calendar_events_color').css('background-color', color);

	if ( selected.hasClass( 'custom' ) ) {
		$j('#calendar_events_color_select_icon').fadeIn();

		var f = function(hsb, hex, rgb) {
			$j('#calendar_events_color').css('background-color', '#'+hex);
			$j('#calendar_events_color .custom').css('background-color', '#'+hex);
			$j('#calendar_events_color .custom')[0].value = '#'+hex;
			$j('.colorpicker').hide();
		}

		var parms = {onSubmit:f};

		if (initial_color) {
			jQuery.extend(parms,  {
				onBeforeShow: function () {
					jQuery(this).ColorPickerSetColor(initial_color);
				}
			});
		}

		$j('#calendar_events_color_select_icon').ColorPicker(parms);
		$j('.colorpicker').css({'zIndex':10000});
	} else {
		$j('#calendar_events_color_select_icon').fadeOut();
	}

}

jQuery.planscalendar.add_edit_calendar_submit = function( ) {

	var data = {
		'api_command':'add_update_calendar',
		'cal_title':$j('#add_edit_calendar_cal_title').val(),
		'cal_link':$j('#add_edit_calendar_cal_link').val(),
		'cal_details':$j('#add_edit_calendar_details').val(),
		'date_format':$j('#date_format').val(),
		'default_number_of_months':$j('#default_number_of_months').val(),
		'max_number_of_months':$j('#max_number_of_months').val(),
		'gmtime_diff':$j('#gmtime_diff').val(),
		'event_change_email':$j('#event_change_email').val(),
		'week_start_day':$j('#week_start_day').val(),
		'calendar_events_color':$j('#calendar_events_color').val(),
		'background_calendars':$j('#background_calendars').val(),
		'background_events_display_style':$j('input[name=background_events_display_style]:checked').val(),
		'background_events_fade_factor':$j('#background_events_fade_factor').val(),
		'background_events_color':$j('#background_events_color').val(),
		'new_remote_calendars_xml':$j('#new_remote_calendars_xml').val()
	};


	if ( jQuery.planscalendar.current_calendar_being_edited == null ) {
		jQuery.extend(data, {
			'add_edit_cal_action':'add',
			'cal_password':$j('#add_calendar_cal_password').val(),
			'new_cal_password':$j('#add_calendar_new_cal_password').val(),
			'repeat_new_cal_password':$j('#add_calendar_repeat_new_cal_password').val()

		});
	} else {
		jQuery.extend(data, {
			'add_edit_cal_action':'edit',
			'cal_id':jQuery.planscalendar.current_calendar_being_edited.id,
			'cal_password':$j('#edit_calendar_cal_password').val(),
			'new_cal_password':$j('#edit_calendar_new_cal_password').val(),
			'repeat_new_cal_password':$j('#edit_calendar_repeat_new_cal_password').val()

		});

		if ( jQuery.planscalendar.current_calendar_being_edited.remote_background_calendars && 
			 jQuery.planscalendar.current_calendar_being_edited.remote_background_calendars.length > 0 ) {
			for ( var i=0;i<jQuery.planscalendar.current_calendar_being_edited.remote_background_calendars.length;i++) {
				var rbc = jQuery.planscalendar.current_calendar_being_edited.remote_background_calendars[i];

				if ( $j('#delete_remote_calendar_'+rbc.remote_id+':checked').length > 0 ) {
					data['delete_remote_calendar_'+rbc.remote_id] = 'y';
				}
			}
		} 
		

	}


	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {
			return;
		}
	}

	$j('#add_cal_button').throbber({
		image: jQuery.planscalendar.theme_url + "/images/throbber.gif",
		wrap: '<span>Please Wait...</span>'
	});

	$j.ajax({
		'url':jQuery.planscalendar.plans_url,
		'type':'POST',
		'data':data,
		'dataType':'json',
		'success':successCallback
	});

}

jQuery.planscalendar.delete_calendar_submit = function( ) {

	var data = {
		'api_command':'add_update_calendar',
		'cal_id':jQuery.planscalendar.current_calendar_being_edited.id,
		'add_edit_cal_action':'delete',
		'cal_password':$j('#edit_calendar_cal_password').val(),
		'new_calendar_controls':1
	}

	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {
			
			menu_tabs = $j('#menu_tabs > ul').tabs('select',0);
			jQuery.planscalendar.update_calendars(jsondata.calendars);
			$j('#server_supplied_calendar_controls').html(jsondata.calendar_controls);

		}
	}

	$j('#del_cal_button').throbber({
		image: jQuery.planscalendar.theme_url + "/images/throbber.gif",
		wrap: '<span>Please Wait...</span>'
	});

	$j.ajax({
		'url':jQuery.planscalendar.plans_url,
		'type':'POST',
		'data':data,
		'dataType':'json',
		'success':successCallback
	});

}



jQuery.planscalendar.reset_tabs = function( ) {
	menu_tabs = $j('#menu_tabs > ul').tabs('select',0);
}



jQuery.planscalendar.show_add_edit_event_dialog = function() {

	var menu_tabs_el = $j('#menu_tabs ul');
	var c = menu_tabs_el.offset();
	c.height = menu_tabs_el.height();
	c.width = menu_tabs_el.width();

	var w = $j('#menu_tabs').width();
	var c2 = $j('#menu_tabs').offset();

	$j('#add_edit_event_tabs').tabs();
	$j('#add_edit_event_tabs').tabs('select',0);

	$j('.ui-dialog.add_edit').css({'height':'auto'});
	$j('#add_edit_event_dialog').css({'height':'auto'});
	$j('#recurrence_already_defined').hide();
	$j('#recurrence_not_allowed').hide();

	$j('#add_edit_event_all_day_event').mouseup( function() {setTimeout( jQuery.planscalendar.update_all_day_event_checkbox,100)} );

	// populate icons dropdown
	var f = function(d, selfref){
		if (typeof(d[1]) == typeof('a')) {
			return '<option value="'+d[0]+'">'+d[1]+'</option>';
		}
		
		if (typeof(d[1]) == typeof(['a'])) {
			var results = '<optgroup label="'+d[0]+'">';
			for( var i=0;i<d[1].length;i++) {
				results += f(d[1][i], f);
			}
			results += '</optgroup>';
			return results;
		}
		return '';
	};

	icons_html = '';
	for( var i=0;i<jQuery.planscalendar.icons.length;i++) {
		icons_html += f(jQuery.planscalendar.icons[i], f);
	}

	$j('#add_edit_event_icon').html( icons_html );

	// hook up icon preview

	$j('#add_edit_event_icon').change(jQuery.planscalendar.update_icon_preview);
	jQuery.planscalendar.update_icon_preview();

	// populate background colors dropdown

	var background_colors_html = '';
	
	for( var i=0;i<jQuery.planscalendar.event_background_colors.length;i++) {
		
		var color = jQuery.planscalendar.event_background_colors[i];
		var desc = ( jQuery.planscalendar.plans_options.show_event_background_color_descriptions == 1 ) ? color.title : '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;'
		background_colors_html += '<option style="background-color:'+color.color+';" value="'+color.color+'">' + desc + '</option>';
	}

	background_colors_html += '<option style="background-color:#fff" class="custom" value="#ffffff">custom</option>';

	$j('#add_edit_event_background_color').html( background_colors_html );
	$j('#add_edit_event_background_color').change( jQuery.planscalendar.update_event_background_select );

	// populate month select for recurring event
	$j('#add_edit_event_custom_months').empty();
	for (var i=0;i<plans_lang['months'].length;i++) {
		$j('#add_edit_event_custom_months').append($j('<option value="'+i+'">'+plans_lang['months'][i]+'</option>'));
	}

	// populate calendar select 
	$j('#add_edit_event_cal_id').empty();
	for (var i=0;i<jQuery.planscalendar.calendars.length;i++) {
		var calendar = jQuery.planscalendar.calendars[i];
		$j('#add_edit_event_cal_id').append('<option value="' + calendar.id  + '">' + calendar.title + '</option>');
	}

	// hookup recurring event actions
	$j('.recurring_event_click_trigger').bind('click', jQuery.planscalendar.update_recurring_events);
	$j('.recurring_event_change_trigger').bind('click', jQuery.planscalendar.update_recurring_events);

	$j('#add_edit_event_submit_button').bind('click', jQuery.planscalendar.add_edit_event_submit);


	// enter key in password field
	$j('#add_edit_event_cal_password').bind( 'keypress', jQuery.planscalendar.add_edit_event_keypress_submit );

	$j('#add_edit_event_submit_button').throbber({
		wrap: '<div class="throbber">' + plans_lang['please_wait'] + '</div>'
	});

	jQuery.planscalendar.update_recurring_events();

	// hookup preview events
	$j('#preview_event').bind('click', jQuery.planscalendar.preview_event);
	$j('#preview_dates').bind('click', jQuery.planscalendar.preview_dates);
}



jQuery.planscalendar.add_edit_event_keypress_submit = function(evt) {

	if(evt.keyCode == 13){
		jQuery.planscalendar.add_edit_event_submit();
	}

}


jQuery.planscalendar.update_all_day_event_checkbox = function(e){
	if ($j('#add_edit_event_all_day_event')[0].checked) {
		if ( $j('#event_time_inputs:visible').length > 0 ) {
			$j('#event_time_inputs').slideUp('fast');
		}
	} else {
		$j('#event_time_inputs').slideDown('fast');
	}
}

jQuery.planscalendar.preview_event = function() {
	var event = {
		'cal_ids':[$j('#add_edit_event_cal_id').val()],
		'title':$j('#add_edit_event_title').val(),
		'details':$j('#add_edit_event_details').val(),
		'bgcolor':$j('#add_edit_event_background_color').val(),
		'icon':$j('#add_edit_event_icon').val(),
		'unit_number':'',
		'nice_date':'(date disabled for preview)',
		'nice_time':'(time disabled for preview)',
		'id':''
	}

	jQuery.planscalendar.display_local_event(event);
}

jQuery.planscalendar.preview_dates = function() {

	var data = {
		'api_command':'preview_date',
		'cal_id':$j('#add_edit_event_cal_id').val(),
		'evt_title':$j('#add_edit_event_title').val(),
		'evt_details':$j('#add_edit_event_details').val(),
		'evt_start_date':$j('#add_edit_event_start_date').val(),
		'evt_days':$j('#add_edit_event_days').val(),
		'evt_all_day_event':$j('#add_edit_event_all_day_event').val(),
		'evt_start_time':$j('#add_edit_event_start_time').val(),
		'evt_end_time':$j('#add_edit_event_end_time').val(),
		'evt_icon':$j('#add_edit_event_icon').val(),
		'evt_bgcolor':$j('#add_edit_event_background_color').val(),
		'cal_password':$j('#add_edit_event_cal_password').val(),

		'recurring_event':( $j('#add_edit_event_recurring_event:checked').length > 0 ) ? '1' : '',
		'every_x_days':$j('#add_edit_event_every_x_days').val(),
		'every_x_weeks':$j('#add_edit_event_every_x_weeks').val(),
		'weekday_of_month_type':$j('#add_edit_event_weekday_of_month_type option:selected').val(),
		'year_fit_type':$j('input[name=add_edit_event_year_fit_type]:checked').val(),
		'custom_months':$j('#add_edit_event_custom_months').val(),
		'recurrence_type':$j('input[name=add_edit_event_recurrence_type]:checked').val(),
		'recur_end_date':$j('#add_edit_event_recur_end_date').val()
	};

	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {
			
			var f = function(event, ui) {
				$j('#preview_dates_dialog').dialog('destroy');
				return false;
			}

			var text = '';
			for (var i=0;i<jsondata.valid_dates.length;i++) {
				text += tmpl('preview_date_tmpl', {'date':jsondata.valid_dates[i]});
			}
			$j('#preview_dates_list').html(text);
			if ( $j('#add_edit_event_recurring_event:checked').length > 0 ) {
				$j('.lang_date_preview_recurring_event_falls_on').show();
				$j('.lang_date_preview_this_event_falls_on').hide();
			} else  {
				$j('.lang_date_preview_recurring_event_falls_on').hide();
				$j('.lang_date_preview_this_event_falls_on').show();
			}

			$j('#preview_dates_dialog').dialog({'width':500,'position':'center', 'beforeclose': f });
		}
	}

	$j.ajax({
		'url':jQuery.planscalendar.plans_url,
		'type':'POST',
		'data':data,
		'dataType':'json',
		'success':successCallback
	});




}


jQuery.planscalendar.display_help = function(topic, title) {
	var key = 'help_'+topic;
	var text = plans_lang[key];

	var f = function(event, ui) {
		$j('#help_dialog').dialog('destroy');
		return false;
	}

	$j('#help_dialog').html(text).dialog({'width':500,'position':'center', 'beforeclose': f });

}


jQuery.planscalendar.update_icon_preview = function() {
	var selected = $j('#add_edit_event_icon :selected');
	var icon_name = selected.val();
	$j('#icon_preview_img')[0].src = jQuery.planscalendar.theme_url + '/icons/' + icon_name + '_32x32.gif';
}

jQuery.planscalendar.update_event_background_select = function() {

	var selected = $j('#add_edit_event_background_color :selected');
	var color = selected.val();
	$j('#add_edit_event_background_color').css('background-color', color);

	if ( selected.hasClass( 'custom' ) ) {
		$j('#event_color_select_icon').fadeIn();

		var f = function(hsb, hex, rgb) {
			$j('#add_edit_event_background_color').css('background-color', '#'+hex);
			$j('#add_edit_event_background_color .custom').css('background-color', '#'+hex);
			$j('#add_edit_event_background_color .custom')[0].value = '#'+hex;
			$j('.colorpicker').hide();
		}

		$j('#event_color_select_icon').ColorPicker({onSubmit:f});
		$j('.colorpicker').css({'zIndex':10000});
	} else {
		$j('#event_color_select_icon').fadeOut();
	}

}

jQuery.planscalendar.update_recurring_events = function(evt) {
	if ( $j('#add_edit_event_recurring_event:checked').length > 0 ) {
		$j('#add_edit_event_recurrence .form_field input').attr('disabled',false);
		$j('#add_edit_event_recurrence .form_field select').attr('disabled',false);


		if ( $j('#add_edit_event_recurrence_type_same_weekday:checked').length == 0 ) {
			$j('#add_edit_event_weekday_of_month_type').attr('disabled',true);
		} else {
			$j('#add_edit_event_weekday_of_month_type').focus();
		}

		if ( $j('#add_edit_event_recurrence_type_every_x_days:checked').length == 0 ) {
			$j('#add_edit_event_every_x_days').attr('disabled',true);
		} else {
			$j('#add_edit_event_every_x_days').focus();
		}

		if ( $j('#add_edit_event_recurrence_type_every_x_weeks:checked').length == 0 ) {
			$j('#add_edit_event_every_x_weeks').attr('disabled',true);
		} else {
			$j('#add_edit_event_every_x_weeks').focus();
		}

		if ( $j('#add_edit_event_year_fit_type_custom_months:checked').length == 0 ) {
			$j('#add_edit_event_custom_months').attr('disabled',true);
		} else {
			$j('#add_edit_event_custom_months').focus();
		}

	} else {
		// recurring events disabled
		$j('#add_edit_event_recurrence .form_field input').attr('disabled',true);
		$j('#add_edit_event_recurrence .form_field select').attr('disabled',true);
		$j('#add_edit_event_recurrence .form_field input[type=checkbox]').attr('disabled',false);
	}
}


jQuery.planscalendar.populate_add_edit_event_dialog = function(event) {

	if ( jQuery.planscalendar.plans_options['allow_merge_blocking'] == '1' ) {
		$j('.block_merge_control').show();
	} else {
		$j('.block_merge_control').hide();
	}

	// if logged in, don't show password prompt
	if (jQuery.planscalendar.logged_in) {
		$j('#add_edit_event_cal_password_field').hide();
	} else if ( jQuery.planscalendar.plans_options['disable_passwords'] == '1' ) {
		$j('#add_edit_event_cal_password_field').hide();
	} else {
		$j('#add_edit_event_cal_password_field').show();
	}


	if ( jQuery.planscalendar.plans_options['multi_calendar_event_mode'] > 0 && event.id ) {
		$j('#add_edit_event_other_cal_ids_control').show();

		// other calendars
		$j('#add_edit_event_other_cal_ids').empty();
		for (var i=0;i<jQuery.planscalendar.calendars.length;i++) {
			var c = jQuery.planscalendar.calendars[i];
			
			if ( c.id == event.cal_ids[0] ) continue;

			$j('#add_edit_event_other_cal_ids').append('<option value="' + c.id  + '">' + c.title + '</option>');

		}

		$j('#add_edit_event_other_cal_ids option').attr('selected','');

		for (var i=0;i<event.cal_ids.length;i++) {
			$j('#add_edit_event_other_cal_ids option[value='+event.cal_ids[i]+']').attr('selected','selected');
		}

	} else {
		$j('#add_edit_event_other_cal_ids_control').hide();
	}

	if ( event.id ) {
		$j('#add_edit_event_submit_button').val(plans_lang['update_event']);
		if (event.series_id == null ) {
			$j('#recurrence_not_allowed').show();
		} else {
			$j('#recurrence_already_defined').show();
		}
		$j('#define_recurrence').hide();
	} else {
		$j('#define_recurrence').show();
		$j('#add_edit_event_submit_button').val(plans_lang['add_event']);
	}

	if ( event.cal_ids ) {
		$j('#add_edit_event_cal_id option[value=' + event.cal_ids[0] + ']').attr('selected','selected');
	} else {
		$j('#add_edit_event_cal_id option[value=' + jQuery.planscalendar.current_calendar_id + ']').attr('selected','selected');
	}

	$j('#add_edit_event_id').val(event.id || '');

	$j('#add_edit_event_title').val(event.title || '');
	$j('#add_edit_event_details').val(event.details || '');
	$j('#add_edit_event_days').val(event.days || '1');

	$j('#add_edit_event_all_day_event')[0].checked = ( event.all_day_event == '1' );

	$j('#add_edit_event_block_merge')[0].checked = ( event.block_merge == '1' );

	jQuery.planscalendar.update_all_day_event_checkbox();

	var date_format = jQuery.planscalendar.date_format;

	if ( event.cal_ids ) {
		date_format = jQuery.planscalendar.get_cal(event.cal_ids[0]).date_format;
	}

	var start_date = (event.start) ? new Date(event.start * 1000) : new Date(); 
	var end_date = (event.end) ? new Date(event.end * 1000) : new Date(); 
	$j('#add_edit_event_start_date').val(jQuery.planscalendar.formatDate(start_date, date_format.replace(/mm/,'MM')) || '');

	$j('#add_edit_event_start_time').val(jQuery.planscalendar.formatDate(start_date,jQuery.planscalendar.time_format));
	if (event.no_end_time == '1') {
		$j('#add_edit_event_end_time').val('');
	} else {
		$j('#add_edit_event_end_time').val(jQuery.planscalendar.formatDate(end_date,jQuery.planscalendar.time_format));
	}

	$j('#add_edit_event_icon option[value=' + event.icon + ']').attr('selected','selected');
	jQuery.planscalendar.update_icon_preview();

	$j('#add_edit_event_background_color option[value=' + event.bgcolor + ']').attr('selected','selected');
	jQuery.planscalendar.update_event_background_select();

	// clear password
	$j('#add_edit_event_cal_password').val('');

	$j('#add_edit_event_start_date').datepicker({ 
		showOn: 'button', 
		buttonImage: jQuery.planscalendar.theme_url + "/images/calendar.gif", 
		buttonImageOnly: true,
		dateFormat:date_format.replace('yyyy','yy'),
		firstDay:jQuery.planscalendar.calendars[0].week_start_day
	});

	$j('#add_edit_event_recur_end_date').datepicker({ 
		showOn: 'button', 
		buttonImage: jQuery.planscalendar.theme_url + "/images/calendar.gif", 
		buttonImageOnly: true ,
		dateFormat:date_format.replace('yyyy','yy'),
		firstDay:jQuery.planscalendar.calendars[0].week_start_day
	});

	$j('#ui-datepicker-div').css({'zIndex':10000});
	
	$j.scrollTo(document.body);

}


jQuery.planscalendar.add_edit_event_submit = function( ) {

	var event_id = $j('#add_edit_event_id').val();

	var data = {
		'api_command':'add_update_event',
		'evt_id': event_id,
		'add_edit_event': (event_id != '') ? 'edit' : 'add',
		'cal_id':$j('#add_edit_event_cal_id').val(),
		'evt_title':$j('#add_edit_event_title').val(),
		'evt_details':$j('#add_edit_event_details').val(),
		'evt_start_date':$j('#add_edit_event_start_date').val(),
		'evt_days':$j('#add_edit_event_days').val(),
		'evt_all_day_event':( $j('#add_edit_event_all_day_event:checked').length > 0 ) ? '1' : '',
		'evt_block_merge':( $j('#add_edit_event_block_merge:checked').length > 0 ) ? '1' : '',
		'evt_start_time':$j('#add_edit_event_start_time').val(),
		'evt_end_time':$j('#add_edit_event_end_time').val(),
		'evt_icon':$j('#add_edit_event_icon').val(),
		'evt_bgcolor':$j('#add_edit_event_background_color').val(),
		'evt_other_cal_ids': ( $j('#add_edit_event_other_cal_ids option').length > 0 ) ? $j('#add_edit_event_other_cal_ids').val() : '',
		'cal_password':$j('#add_edit_event_cal_password').val(),
		'recurring_event':( $j('#add_edit_event_recurring_event:checked').length > 0 ) ? '1' : '',
		'every_x_days':$j('#add_edit_event_every_x_days').val(),
		'every_x_weeks':$j('#add_edit_event_every_x_weeks').val(),
		'weekday_of_month_type':$j('#add_edit_event_weekday_of_month_type option:selected').val(),
		'year_fit_type':$j('input[name=add_edit_event_year_fit_type]:checked').val(),
		'custom_months':$j('#add_edit_event_custom_months').val(),
		'recurrence_type':$j('input[name=add_edit_event_recurrence_type]:checked').val(),
		'recur_end_date':$j('#add_edit_event_recur_end_date').val(),
		'all_in_series':( $j( '#add_edit_event_recurring_event_change_all:checked').length > 0 ) ? '1' : ''
	};

	if ( data.all_in_series == '1' ) {
		data.recurring_event = '1';
	}

	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {
			jQuery.planscalendar.refresh_calendar_view( jsondata.calendar_html );
			jQuery.planscalendar.hookup_contextmenu_events();
			$j.extend(jQuery.planscalendar.events, jsondata.new_events);
			$j('#menu_tabs').tabs('select',0);

			jQuery.planscalendar.highlight_new_events( jsondata.new_event_ids );
		}
		$j.throbberHide();
	}

	$j.ajax({
		'url':jQuery.planscalendar.plans_url,
		'type':'POST',
		'data':data,
		'dataType':'json',
		'success':successCallback
	});

}



jQuery.planscalendar.rawResponseCallback = function(data, type) {
	return data;
}


jQuery.planscalendar.update_messages = function(messages) {
	if (typeof(messages) == typeof([]) && messages.length == 0 ) {
		return;
	}

	if (typeof(messages) == typeof('') ) {
		messages = [messages];
	}

	var formatted_messages = jQuery.planscalendar.format_messages(messages);
	var text = formatted_messages.join('<br/>');

	local_opts = {};
	jQuery.extend( local_opts, jQuery.planscalendar.jgrowl_opts );

	// non-error messages disappear on their own
	if ( ! messages.join('').match( /\[error\]/ ) ) {
		local_opts.sticky = false;
		local_opts.life = 1500;
	}

	$j.jGrowl(text, local_opts);

}

jQuery.planscalendar.format_messages = function(messages) {

	formatted_messages = [];

	for( var i=0;i<messages.length;i++) {

		if ( !messages[i] ) continue;

		var formatted_message = messages[i];
		formatted_message = formatted_message.replace(/\[status\]/, "");
		formatted_message = formatted_message.replace(/\[warning\]/, '<span class="warning">Warning:</span> ');
		formatted_message = formatted_message.replace(/\[error\](.+)/, function($1, $2){return '<span class="error_message">' + $2 + '</span> ';});

		formatted_messages.push( formatted_message );

	}

	return formatted_messages;
}


jQuery.planscalendar.update_login = function() {
	var login_el = $j('#login_logout');

	if ( login_el.length ==0 ) return;

	if (!jQuery.planscalendar.plans_options['sessions']) {
		login_el.hide();
    	return;
  	}

	if (jQuery.planscalendar.logged_in) {
		$j('#logout_link').show();
		$j('#login_link').hide();
		$j('#logout_link').click(jQuery.planscalendar.logout_submit);
	}
	else {
		$j('#logout_link').hide();
		$j('#login_link').show();
		$j('#login_link').click(jQuery.planscalendar.show_login_dialog);
	}

}

jQuery.planscalendar.show_login_dialog = function() {


	var f = function(event, ui) {
		$j('#login_dialog').dialog('destroy');
		return false;
	}
	$j('#login_submit_button').val(plans_lang['login']);

	$j('#login_dialog').dialog({'title':plans_lang['login'], 'width':500,'position':'center', 'beforeclose': f });
	

	$j('#login_submit_button').click(jQuery.planscalendar.login_submit);

}

jQuery.planscalendar.login_submit = function(args) {
  
 
	var pwd = '';
	if ( $j('#login_password').length > 0 ) {
		pwd = $j('#login_password').val();
	}


	var data = {
		'api_command':'js_login',
		'cal_id':jQuery.planscalendar.current_calendar_id,
		'cal_password':pwd
	};

	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {
			jQuery.planscalendar.logged_in = true;
			$j.cookie('plans_sid', jsondata.session_id, { path: jsondata.cookie_path, expires: 1000 });
			jQuery.planscalendar.update_login();
			$j('#login_dialog').dialog('destroy');
		}
	}

	$j('#login_submit_button').throbber({
		image: jQuery.planscalendar.theme_url + "/images/throbber.gif",
		wrap: '<span>Logging in...</span>'
	});


	$j.ajax({
		'url':jQuery.planscalendar.plans_url,
		'type':'POST',
		'data':data,
		'dataType':'json',
		'success':successCallback
	});

}

jQuery.planscalendar.logout_submit = function(args) {

	var data = {
		'api_command':'js_login',
		'logout': '1',
		'cal_id':jQuery.planscalendar.current_calendar_id
	};

	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {
			jQuery.planscalendar.logged_in = false;
			$j.cookie('plans_sid', jsondata.session_id, { path: jsondata.cookie_path, expires: 1000 });
			jQuery.planscalendar.update_login();
		}
	}

	jQuery.planscalendar.update_messages(['Logging out...']);

	$j.ajax({
		'url':jQuery.planscalendar.plans_url,
		'type':'POST',
		'data':data,
		'dataType':'json',
		'success':successCallback
	});
}




jQuery.planscalendar.add_ical = function( ) {

	$j('#add_ical_dialog').show().dialog({title:plans_lang['add_new_ical_calendar'],height:180,width:750});
	$j('#add_ical_submit_button').val(jQuery.planscalendar.get_lang('add_ical'));
	$j('#add_ical_submit_button').click(jQuery.planscalendar.add_ical_submit);

};

jQuery.planscalendar.add_ical_submit = function( ) {

	var data = {
		'api_command':'add_ical',
		'ical_url': $j('#ical_url').val() || '',
		'cal_password':$j('#add_ical_cal_password').val()
		};


	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {

			jQuery.planscalendar.update_calendars(jsondata.calendars);

			jQuery.planscalendar.populate_add_edit_calendar_dialog( jQuery.planscalendar.current_calendar_being_edited);

			$j('#add_edit_user_dialog').dialog('close');
		}
	}

	$j('#add_ical_submit_button').throbber({
		image: jQuery.planscalendar.theme_url + "/images/throbber.gif",
		wrap: '<span>Please Wait...</span>'
	});

	$j.ajax({
		'url':jQuery.planscalendar.plans_url,
		'type':'POST',
		'data':data,
		'dataType':'json',
		'success':successCallback
	});

};



jQuery.planscalendar.delete_event = function (event) {

	
	var text = ''
	if (jQuery.planscalendar.logged_in || jQuery.planscalendar.plans_options['disable_passwords'] == 1) {
		if ( event.series_id ) {
			text += '<div class="leftcol"><span class="required_field">'+plans_lang['recurring_event_delete_all1']+'</span></div>';
			text += '<div class="rightcol"><a id="delete_event_series_submit" href="javascript:{}">'+jQuery.planscalendar.get_lang('recurring_event_delete_all2')+'</a>';
			text += '<br/><a id="delete_event_submit" href="javascript:{}">'+jQuery.planscalendar.get_lang('recurring_event_delete_all3')+'</a></div>';
		} else {
			text += '<div class="leftcol"><span class="required_field">'+plans_lang['event_delete1']+'</span></div>';
			text += '<div class="rightcol"><a id="delete_event_submit" href="javascript:{}">'+jQuery.planscalendar.get_lang('event_delete2')+'</a></div>';
		}
	} else {
		text += '<div class="leftcol"><span class="required_field">'+plans_lang['password']+':</span></div>';
		text += '<div class="rightcol"><input type="password" id="delete_event_cal_password" value="'+''+'"/></div>';
		if ( event.series_id ) {
			text += '<div class="leftcol"><span class="required_field">'+plans_lang['recurring_event_delete_all1']+'</span></div>';
			text += '<div class="rightcol"><a id="delete_event_series_submit" href="javascript:{}">'+jQuery.planscalendar.get_lang('recurring_event_delete_all2')+'</a>';
			text += '<br/><a id="delete_event_submit" href="javascript:{}">'+jQuery.planscalendar.get_lang('recurring_event_delete_all3')+'</a></div>';
		} else {
			text += '<div class="leftcol"><span class="required_field">'+plans_lang['event_delete1']+':</span></div>';
			text += '<a id="delete_event_submit" href="javascript:{}">'+jQuery.planscalendar.get_lang('event_delete2')+'</a>';
		}
	}

	var f = function(event, ui) {
		$j('#delete_event_dialog').dialog('destroy');
		return false;
	}

	$j('#delete_event_dialog').attr('title',jQuery.planscalendar.get_lang('delete_event')).html(text).show().dialog({height:'auto',width:500, 'beforeclose' : f });

	$j('#delete_event_cal_password').focus();

	$j('a#delete_event_submit').bind('click', function() {jQuery.planscalendar.delete_event_submit({'event':event})});
	$j('a#delete_event_series_submit').bind('click', function() {jQuery.planscalendar.delete_event_submit({'event':event,'all_in_series':true})});

	// enter key in password field
	var f = function(evt){if(evt.keyCode == 13){jQuery.planscalendar.delete_event_submit({'event':event})}};
	$j('#delete_event_cal_password').keypress(f);

}

jQuery.planscalendar.delete_event_submit = function(options, e) {
	if (!options) options = {};
	options.all_in_series = options.all_in_series || false;
	var event = options.event;

	var cal_password = ($j('#delete_event_cal_password').length > 0) ? $j('#delete_event_cal_password')[0].value : '';
  
	var parms = {api_command : 'delete_event',
				output_format : 'json',
				evt_id : event.id
				};
  
	if (cal_password != '')
		parms.cal_password = cal_password;
	
    
	if (options.all_in_series && event.series_id != '') {
		parms.all_in_series = 1;
		parms.series_id = event.series_id;
	}

	var successCallback = function(jsondata, statusText) {
        jQuery.planscalendar.update_messages(jsondata.messages);
  		$j('#delete_event_dialog').dialog('close');
	
		if (jsondata.success) {
			jQuery.planscalendar.refresh_calendar_view( jsondata.calendar_html );
			jQuery.planscalendar.hookup_contextmenu_events();
		}
		
	}

	$j('#delete_event_submit').html('<div class="throbber">' + jQuery.planscalendar.get_lang('deleting') + '...</div>');
	$j('#delete_event_series_submit').hide();
	
	$j.ajax({
		'url':jQuery.planscalendar.plans_url,
		'type':'POST',
		'data':parms,
		'dataType':'json',
		'success':successCallback
		//'dataFilter':jQuery.planscalendar.rawResponseCallback
	});

}

jQuery.planscalendar.display_pending_events = function() {
	if ( $j('#pending_events').length == 0 ) return;
	
	$j('#pending_events').html( tmpl('pending_events_tmpl', $j.extend(plans_lang, {'theme_url':jQuery.planscalendar.theme_url}) ) );
	var results = '';
 
	for (var i=0;i<jQuery.planscalendar.pending_events.length;i++) {
		var pending_event = jQuery.planscalendar.pending_events[i];
		results += jQuery.planscalendar.draw_pending_event(pending_event);
	}

	$j('#pending_events_list').html(results);
 
	for (var i=0;i<jQuery.planscalendar.pending_events.length;i++) {
		var pending_event = jQuery.planscalendar.pending_events[i];
		$j('#pending_event_'+pending_event.id +' a').click(function() {jQuery.planscalendar.view_pending_event(pending_event)});
	}

	$j('#pending_events_display_toggle_button').click(jQuery.planscalendar.pending_events_display_toggle);
	$j('#pending_events_check_all_button').click(function() {jQuery.planscalendar.pending_events_toggle_events(1)} );
	$j('#pending_events_trash_all_button').click(function() {jQuery.planscalendar.pending_events_toggle_events(2)} );

	$j('#pending_events_submit_button').click(jQuery.planscalendar.pending_events_submit );

	if ( jQuery.planscalendar.pending_events.length == 0 ) {
		$j('#pending_events').hide();
	}

}

jQuery.planscalendar.pending_events_display_toggle = function() {

	if ( jQuery.planscalendar.pending_events.length == 0 ) {
		$j('#pending_events').hide();
	} else {
		$j('#pending_events').toggle();
	}
}



jQuery.planscalendar.pending_events_toggle_events = function(mode) {
 
	for (var i=0;i<jQuery.planscalendar.pending_events.length;i++) {
		var pending_event = jQuery.planscalendar.pending_events[i];
		var approve_checkbox = $j('#pending_event_approve_'+pending_event.id)[0];
		var delete_checkbox = $j('#pending_event_delete_'+pending_event.id)[0];

		if (mode == 1) {
			if (!approve_checkbox.checked && !delete_checkbox.checked) {
				approve_checkbox.checked = true;
				continue;
			} else if (approve_checkbox.checked && !delete_checkbox.checked) {
				approve_checkbox.checked = false;
				continue;
			}

		} else if (mode == 2) {
			if (!approve_checkbox.checked && !delete_checkbox.checked) {
				delete_checkbox.checked = true;
				continue;
			} else if (delete_checkbox.checked && !approve_checkbox.checked) {
				delete_checkbox.checked = false;
				continue;
			}
		} 
	}
}



jQuery.planscalendar.pending_events_submit = function() {

	if ( ! jQuery.planscalendar.logged_in ) {
		jQuery.planscalendar.update_messages(jQuery.planscalendar.get_lang('log_in_first'));
		return;
	}


	var data = {
		'api_command':'manage_pending_events'
		};

	var pending_events_to_approve = [];
	var pending_events_to_delete = [];

	var approve_radio_inputs = $j('#pending_events_list input.approve_button');

	approve_radio_inputs.each( function(i) {
		if (this.checked) {
			pending_events_to_approve.push(this.value)
		}
	} );
	
	var delete_radio_inputs = $j('#pending_events_list input.delete_button');

	delete_radio_inputs.each( function(i) {
		if (this.checked) {
			pending_events_to_delete.push(this.value)
		}
	} );

	$j.extend(data, { 'approve' : pending_events_to_approve.join(','),
					  'delete'  : pending_events_to_delete.join(',') } );


	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {

			jQuery.planscalendar.update_calendars(jsondata.calendars);
			jQuery.planscalendar.update_pending_events(jsondata.pending_events);
			$j('#logged_in_stuff').html(jsondata.pending_events_area_html);
			jQuery.planscalendar.display_pending_events();

			jQuery.planscalendar.refresh_calendar_view( jsondata.calendar_html );
		}
	}

	$j('#approve_cal_button').throbber({
		image: jQuery.planscalendar.theme_url + "/images/throbber.gif",
		wrap: '<span>Please Wait...</span>'
	});

	$j.ajax( {'type':'POST', 'url':jQuery.planscalendar.plans_url, 'data':data, 'dataType':'json', 'success':successCallback} );


}



function display_event(evt_id) {

	// remote event
	if (evt_id.match(/^r/)) {
		var URL_string = remote_event_details[evt_id].url;
		info_window = this.open(URL_string, "info_window", "resizable=yes,status=yes,scrollbars=yes,top="+info_window_y+",left="+info_window_x+",width=400,height=500");
		return;
	}

	// local event
	var event = jQuery.planscalendar.events[evt_id];

	jQuery.planscalendar.display_local_event(event);
}

jQuery.planscalendar.display_local_event = function( event ) {

	var cal = jQuery.planscalendar.get_cal(event.cal_ids[0]);

	if ( ! cal ) return;

	event.event_calendar_name = cal.title;

	var results = tmpl('event_details_tmpl', event);

	var f = function(event, ui) {
		$j('#event_details_dialog').dialog('destroy');
		return false;
	}


	$j('#event_details_dialog').html(results).dialog({'width':500,'position':'center', 'beforeclose': f });
	$j('#event_details_dialog').css( {'background-color':event.bgcolor});
	
	jQuery.planscalendar.insert_lang_strings( $j('#event_details_dialog'), ['context_menu_edit_event','email_reminder_link'] );

	$j('#event_details_dialog .edit_event_link').click(function(e){info(e);jQuery.planscalendar.edit_event(jQuery.planscalendar.events[$j(e.target).attr('event_id')])})

	$j('#event_details_dialog .email_reminder_link').click(function(e){jQuery.planscalendar.email_reminder(jQuery.planscalendar.events[$j(e.target).attr('event_id')])})

	$j('#event_details_dialog .export_event_link').click(function(e){jQuery.planscalendar.export_event(jQuery.planscalendar.events[$j(e.target).attr('event_id')])})

}

jQuery.planscalendar.edit_event = function(event) {

	$j('#event_details_dialog').dialog('destroy');

	jQuery.planscalendar.edit_event_in_progress = true;
	$j('#menu_tabs').tabs('select',1);

	jQuery.planscalendar.show_add_edit_event_dialog();
	jQuery.planscalendar.populate_add_edit_event_dialog(event);

}



jQuery.planscalendar.email_reminder = function(event) {

	var results = tmpl('email_reminder_tmpl', event);

	var f = function(event, ui) {
		$j('#email_reminder_dialog').dialog('destroy');
		return false;
	}

	$j('#email_reminder_dialog').html(results)

	$j('#email_reminder_dialog').attr('title',jQuery.planscalendar.get_lang('email_reminder_link'));

	jQuery.planscalendar.insert_lang_strings( $j('#email_reminder_dialog'), ['email_reminder_text1','email_reminder_text2','email_reminder_text3','email_reminder_text4','email_reminder_text5','email_reminder_text6','email_reminder_text7','email_reminder_option1','email_reminder_option2','email_reminder_option3','email_reminder_option4','email_reminder_option5','email_reminder_option6'] );

	$j('#email_reminder_dialog input[type=submit]').val(plans_lang['email_reminder_text5']);

	if ( event.series_id == null ) {
		$j('#email_reminder_dialog .series_event_reminder').hide();
	} else {
		$j('#email_reminder_dialog .series_event_reminder').show();
	}

	$j('#email_reminder_dialog').dialog({'width':500,'position':'center', 'beforeclose': f });


	$j('#email_reminder_dialog input[type=submit]').click(function(){jQuery.planscalendar.email_reminder_submit(event)});
	$j('#email_reminder_email_address').focus(function(){this.value='';});
}

jQuery.planscalendar.email_reminder_submit = function(event) {

	var data = {
		'api_command':'set_email_reminder',
		'evt_id':event.id,
		'reminder_seconds':$j('#email_reminder_reminder_time :selected').val(),
		'reminder_time':$j('#email_reminder_reminder_time :selected').html(),
		'email_address': $j('#email_reminder_email_address').val(),
		'extra_text': $j('#email_reminder_extra_text').val(),
		'send_test_now':$j('input[name=email_reminder_send_test_now]:checked').val()
		};

	var approve_delete_radio_inputs = $j('.approve_delete_inputs input[type=radio]');

	approve_delete_radio_inputs.each( function(i) {
		if (this.checked) {
			data[this.name] = this.value;
		}
	} );

	var successCallback = function(jsondata, statusText) {
		jQuery.planscalendar.update_messages(jsondata.messages);
		if (jsondata.success == true) {
			$j('#email_reminder_dialog').dialog('close');
		}
	}

	$j('#approve_cal_button').throbber({
		image: jQuery.planscalendar.theme_url + "/images/throbber.gif",
		wrap: '<span>Please Wait...</span>'
	});

	$j.ajax( {'type':'POST', 'url':jQuery.planscalendar.plans_url, 'data':data, 'dataType':'json', 'success':successCallback} );



}


jQuery.planscalendar.export_event = function(event) {
	info(event);
}


jQuery.planscalendar.view_pending_event = function( event ) {


	$j.extend(event, {'nice_date':jQuery.planscalendar.nice_date(event.start, event.end)});
	$j.extend(event, {'nice_time':jQuery.planscalendar.nice_time(event.start, event.end)});

	jQuery.planscalendar.display_local_event(event);

	$j('.event_details_menu_links').hide();
}



jQuery.planscalendar.draw_pending_event = function(event) {
	var results = "";

	results += "<div id=\"pending_event_"+event.id+"\" class=\"small_note\">";
	results += jQuery.planscalendar.generate_list_event(event);
	results +="<input name=\"approve_delete_pending_event_"+event.id+"\" value=\""+event.id+"\" id=\"pending_event_approve_"+event.id+"\" class=\"approve_button\" type=\"radio\"/>";
	results += "<input name=\"approve_delete_pending_event_"+event.id+"\" value=\""+event.id+"\" id=\"pending_event_delete_"+event.id+"\" class=\"delete_button\" type=\"radio\"/>";
	results += "</div>"

	return results;
}

jQuery.planscalendar.generate_list_event = function(event) {
	var results = "";

	var date_string;
	var weekday_string;

	var nice_start_date = jQuery.planscalendar.nice_date(event.start, event.end);

	results += "<span>"+nice_start_date;
	if (event.icon && event.icon != "blank") results += "<img src=\""+jQuery.planscalendar.theme_url+"/icons/"+event.icon+"_16x16.gif\"/>";

	results += " <a href=\"javascript:void(0)\">"+event.title+"</a>";
	results += "</span>"
	return results;

};


jQuery.planscalendar.nice_date = function(start, end, abbreviate_months, include_year) {

	if ( start.constructor != Date ) {
		start = new Date( start * 1000 );
	}

	if ( end.constructor != Date ) {
		end = new Date( end * 1000 );
	}

	var results = "";
	var separator_string = " - ";
	var rightnow = new Date();
  
	var start_display_year = (include_year || start.getUTCFullYear() != rightnow.getUTCFullYear()) ? ', '+start.getUTCFullYear() : '';
	var end_display_year = (include_year || end.getUTCFullYear() != rightnow.getUTCFullYear()) ? ', '+end.getUTCFullYear() : '';
  
	var start_display_month = (abbreviate_months) ? plans_lang['months_abv'][start.getUTCMonth()] : plans_lang['months'][start.getUTCMonth()];
	var end_display_month = (abbreviate_months) ? plans_lang['months_abv'][end.getUTCMonth()] : plans_lang['months'][end.getUTCMonth()];
  

  if (jQuery.planscalendar.date_format == 'dd/mm/yyyy' || jQuery.planscalendar.date_format == 'dd/mm/yy') {
    if (start.getUTCMonth() == end.getUTCMonth() && start.getUTCFullYear() == end.getUTCFullYear() && start.getUTCDate() == end.getUTCDate())
    { //same year, same month, same day
      results = start.getUTCDate()+' '+start_display_month+start_display_year;
    }
    else if (start.getUTCMonth() == end.getUTCMonth() && start.getUTCFullYear() == end.getUTCFullYear())
    { //same year, same month
      results = start.getUTCDate()+separator_string+end.getUTCDate()+' '+start_display_month+start_display_year;
    }
    else if (start.getUTCFullYear() != end.getUTCFullYear())
    { //different year
      results = start.getUTCDate()+start_display_month+start_display_year+separator_string+end.getUTCDate()+end_display_month+end_display_year;
    }
    else 
    { //same year, different months
      results = start.getUTCDate()+start_display_month+separator_string+end.getUTCDate()+end_display_month+end_display_year;
    }
  }
  else
  {
    if (start.getUTCMonth() == end.getUTCMonth() && start.getUTCFullYear() == end.getUTCFullYear() && start.getUTCDate() == end.getUTCDate())
    { //same year, same month, same day
      results = start_display_month+' '+start.getUTCDate()+start_display_year;
    }
    else if (start.getUTCMonth() == end.getUTCMonth() && start.getUTCFullYear() == end.getUTCFullYear())
    { //same year, same month
      results = start_display_month+''+start.getUTCDate()+separator_string+end.getUTCDate()+start_display_year;
    }
    else if (start.getUTCFullYear() != end.getUTCFullYear())
    { //different year
      results = start_display_month+' '+start.getUTCDate()+start_display_year+separator_string+end_display_month+' '+end.getUTCDate()+end_display_year;
    }
    else 
    { //same year, different months
      results = start_display_month+' '+start.getUTCDate()+separator_string+end_display_month+' '+end.getUTCDate()+end_display_year;
    }
  
  }
  return results;
};

jQuery.planscalendar.nice_time = function(start, end, days)  {

	var start_date = start;
	if ( start.constructor != Date ) {
		start_date = new Date( start * 1000);
	}

	var end_date = end;
	if ( end.constructor != Date ) {
		end_date = new Date( end * 1000 );
	}
  
  var temp = (start_date.getUTCDay() == end_date.getUTCDay()) ? '':'dna ';

  var results = '';
  results = jQuery.planscalendar.formatDate(start_date,temp+jQuery.planscalendar.time_format)+" - "+jQuery.planscalendar.formatDate(end_date,temp+jQuery.planscalendar.time_format);
  
  // if times are the same, remove the second one.
  if (end - start <=1)
  {
    results = results.replace(/s*-.+/,'');
    return results;
  }
  
  // if both times are am or pm, remove the first one (it's redundant!)
  //$results =~ s/(.*) $lang{am}(.*$lang{am}.*)/$1$2/;
  //$results =~ s/(.*) $lang{pm}(.*$lang{pm}.*)/$1$2/;
  
  var reg1 = new RegExp('(.*) am(.*am.*)');
  var reg2 = new RegExp('(.*) pm(.*pm.*)');
  results = results.replace(reg1,'$1$2');
  results = results.replace(reg2,'$1$2');
  results = results.replace(/am/,plans_lang['am']);
  results = results.replace(/pm/,plans_lang['pm']);
  
  return results;
};

jQuery.planscalendar.blink = function(el) {
	el = jQuery(el);
	el.pulse({
		backgroundColors: ['#eeae00','#ffdf5e'],
		speed: 200
	});

	setTimeout(function(){el.recover()},800);
};


jQuery.planscalendar.addZero = function(vNumber){
    return ((vNumber < 10) ? "0" : "") + vNumber * 1;
};
        
jQuery.planscalendar.formatDate = function(vDate, vFormat){
    var vDay              = jQuery.planscalendar.addZero(vDate.getUTCDate()); 
    var vMonth            = jQuery.planscalendar.addZero(vDate.getUTCMonth()+1); 
    var vMonthName        = plans_lang['months'][vDate.getUTCMonth()]; 
    var vMonthNameAbv     = plans_lang['months_abv'][vDate.getUTCMonth()]; 
    var vDayName          = plans_lang['day_names'][vDate.getUTCDay()]; 
    var vDayNameAbv       = plans_lang['day_names_abv'][vDate.getUTCDay()]; 
    var vYearLong         = jQuery.planscalendar.addZero(vDate.getFullYear()); 
    var vYearShort        = jQuery.planscalendar.addZero(vDate.getFullYear().toString().substring(2,4)); 
    var vYear             = (vFormat.indexOf("yyyy")>-1?vYearLong:vYearShort) 
    var vHour             = jQuery.planscalendar.addZero(vDate.getUTCHours());
    var ampm              = (vHour < 12) ? 'am': 'pm';
    
    var vShortHour = vHour;
  
    if (vHour > 12)
       vShortHour -= 12;
 
    if (vShortHour == 0)
       vShortHour = 12;

    
    var vMinute           = jQuery.planscalendar.addZero(vDate.getUTCMinutes()); 
    var vSecond           = jQuery.planscalendar.addZero(vDate.getUTCSeconds()); 
    var vDateString       = vFormat.replace(/dd/g, vDay).replace(/MM/g, vMonth).replace(/MNA/g, vMonthNameAbv).replace(/MN/g, vMonthName).replace(/y{1,4}/g, vYear);
    vDateString           = vDateString.replace(/hh/g, vHour).replace(/sh/g, vShortHour).replace(/mm/g, vMinute).replace(/ss/g, vSecond).replace(/ampm/g, ampm);
    vDateString           = vDateString.replace(/dna/g, vDayNameAbv).replace(/dn/g, vDayName);
    return vDateString 
};



// highlight current day
jQuery.planscalendar.highlight_current_day = function() {
	var d = new Date();
	var timestamp = Math.floor((d.getTime() - d.getMilliseconds() - d.getSeconds() *1000 - d.getMinutes() * 60000 - d.getHours() * 3600000)/1000) - d.getTimezoneOffset() * 60;

	$j('td[date='+timestamp+']').addClass('today');
	$j('td[date='+timestamp+'] .date').addClass('today');
}

jQuery.planscalendar.get_lang = function(key) {
  if (plans_lang[key]) return plans_lang[key];
  return '';
};

// Simple JavaScript Templating
// John Resig - http://ejohn.org/ - MIT Licensed
(function(){
  var cache = {};
 
  this.tmpl = function tmpl(str, data){
    // Figure out if we are getting a template, or if we need to
    // load the template - and be sure to cache the result.
    var fn = !/\W/.test(str) ?
      cache[str] = cache[str] ||
        tmpl(document.getElementById(str).innerHTML) :
     
      // Generate a reusable function that will serve as a template
      // generator (and which will be cached).
      new Function("obj",
        "var p=[],print=function(){p.push.apply(p,arguments);};" +
       
        // Introduce the data as local variables using with(){}
        "with(obj){p.push('" +
       
        // Convert the template into pure JavaScript
        str
          .replace(/[\r\t\n]/g, " ")
          .split("<%").join("\t")
          .replace(/((^|%>)[^\t]*)'/g, "$1\r")
          .replace(/\t=(.*?)%>/g, "',$1,'")
          .split("\t").join("');")
          .split("%>").join("p.push('")
          .split("\r").join("\\'")
      + "');}return p.join('');");
   
    // Provide some basic currying to the user
    return data ? fn( data ) : fn;
  };
})();


function getCoords(el) {
	var o = el.offset();
	var h = el.outerHeight();
	var w = el.outerWidth();
	var c = {'x':Math.floor(o.left),'y':Math.floor(o.top),'w':w,'h':h};
	return c;
}

function setCoords(el, c) {
	el.css({'top':c.y+'px','left':c.x+'px'});
	if (c.w) {
		el.css({'width':c.w+'px'})
		el.css({'height':c.h+'px'})
	}
}

(function($) {
	$.fn.boxhighlight = function(options)
	{
		// Set the options.
		var options = $.extend({}, $.fn.boxhighlight.defaults, options);
		
		var box = $('.boxhighlight');
		if ( box.length == 0 ) {
			$j(document.body).append('<div class="boxhighlight"></div>')	
			var box = $('.boxhighlight');
		}

		// Go through the matched elements and return the jQuery object.
		return this.each(function()
		{
			var el = $(this);

			var c2 = getCoords( el );
			setCoords( box, {'x':0,'y':$(window).scrollTop(),'w':$(document.body).width(),'h':$(window).height()} );
			
			var c1 = getCoords( box );
					
			box.show().animate({ 
				width: c2.w,
				height: c2.h,
				top: c2.y,
				left: c2.x
			  }, 700, null, function(){box.fadeOut()} );

			//return false;  //only one element
		});
	};

	// Public defaults.
	$.fn.boxhighlight.defaults = {
		property: 'value'
	};

	// Private functions.
	function func()
	{
		return;
	};

	// Public functions.
	$.fn.boxhighlight.func = function()
	{
		return;
	};
})(jQuery);




/**
 * Cookie plugin
 *
 * Copyright (c) 2006 Klaus Hartl (stilbuero.de)
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 *
 */

/**
 * Create a cookie with the given name and value and other optional parameters.
 *
 * @example $.cookie('the_cookie', 'the_value');
 * @desc Set the value of a cookie.
 * @example $.cookie('the_cookie', 'the_value', { expires: 7, path: '/', domain: 'jquery.com', secure: true });
 * @desc Create a cookie with all available options.
 * @example $.cookie('the_cookie', 'the_value');
 * @desc Create a session cookie.
 * @example $.cookie('the_cookie', null);
 * @desc Delete a cookie by passing null as value. Keep in mind that you have to use the same path and domain
 *       used when the cookie was set.
 *
 * @param String name The name of the cookie.
 * @param String value The value of the cookie.
 * @param Object options An object literal containing key/value pairs to provide optional cookie attributes.
 * @option Number|Date expires Either an integer specifying the expiration date from now on in days or a Date object.
 *                             If a negative value is specified (e.g. a date in the past), the cookie will be deleted.
 *                             If set to null or omitted, the cookie will be a session cookie and will not be retained
 *                             when the the browser exits.
 * @option String path The value of the path atribute of the cookie (default: path of page that created the cookie).
 * @option String domain The value of the domain attribute of the cookie (default: domain of page that created the cookie).
 * @option Boolean secure If true, the secure attribute of the cookie will be set and the cookie transmission will
 *                        require a secure protocol (like HTTPS).
 * @type undefined
 *
 * @name $.cookie
 * @cat Plugins/Cookie
 * @author Klaus Hartl/klaus.hartl@stilbuero.de
 */

/**
 * Get the value of a cookie with the given name.
 *
 * @example $.cookie('the_cookie');
 * @desc Get the value of a cookie.
 *
 * @param String name The name of the cookie.
 * @return The value of the cookie.
 * @type String
 *
 * @name $.cookie
 * @cat Plugins/Cookie
 * @author Klaus Hartl/klaus.hartl@stilbuero.de
 */
jQuery.cookie = function(name, value, options) {
    if (typeof value != 'undefined') { // name and value given, set cookie
        options = options || {};
        if (value === null) {
            value = '';
            options.expires = -1;
        }
        var expires = '';
        if (options.expires && (typeof options.expires == 'number' || options.expires.toUTCString)) {
            var date;
            if (typeof options.expires == 'number') {
                date = new Date();
                date.setTime(date.getTime() + (options.expires * 24 * 60 * 60 * 1000));
            } else {
                date = options.expires;
            }
            expires = '; expires=' + date.toUTCString(); // use expires attribute, max-age is not supported by IE
        }
        // CAUTION: Needed to parenthesize options.path and options.domain
        // in the following expressions, otherwise they evaluate to undefined
        // in the packed version for some reason...
        var path = options.path ? '; path=' + (options.path) : '';
        var domain = options.domain ? '; domain=' + (options.domain) : '';
        var secure = options.secure ? '; secure' : '';
        document.cookie = [name, '=', encodeURIComponent(value), expires, path, domain, secure].join('');
    } else { // only name given, get cookie
        var cookieValue = null;
        if (document.cookie && document.cookie != '') {
            var cookies = document.cookie.split(';');
            for (var i = 0; i < cookies.length; i++) {
                var cookie = jQuery.trim(cookies[i]);
                // Does this cookie string begin with the name we want?
                if (cookie.substring(0, name.length + 1) == (name + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                    break;
                }
            }
        }
        return cookieValue;
    }
};

/**
 * jQuery.pulse
 * Copyright (c) 2008 James Padolsey - jp(at)qd9(dot)co.uk | http://james.padolsey.com / http://enhance.qd-creative.co.uk
 * Dual licensed under MIT and GPL.
 * Date: 05/11/08
 *
 * @projectDescription Applies a continual pulse to any element specified
 * http://enhance.qd-creative.co.uk/demos/pulse/
 * Tested successfully with jQuery 1.2.6. On FF 2/3, IE 6/7, Opera 9.5 and Safari 3. on Windows XP.
 *
 * @author James Padolsey
 * @version 1.11
 * 
 * @id jQuery.pulse
 * @id jQuery.recover
 * @id jQuery.fn.pulse
 * @id jQuery.fn.recover
 */
(function($){
    $.fn.recover = function() {
        /* Empty inline styles - i.e. set element back to previous state */
        /* Note, the recovery might not work properly if you had inline styles set before pulse initiation */
        return this.each(function(){$(this).stop().css({backgroundColor:'',color:'',borderLeftColor:'',borderRightColor:'',borderTopColor:'',borderBottomColor:'',opacity:1});});
    }
    $.fn.pulse = function(options){
        var defaultOptions = {
            textColors: [],
            backgroundColors: [],
            borderColors: [],
            opacityPulse: true,
            opacityRange: [],
            speed: 1000,
            duration: false,
            runLength: false
        }, o = $.extend(defaultOptions,options);
        /* Validate custom options */
        if(o.textColors.length===1||o.backgroundColors.length===1||o.borderColors.length===1) {return false;}
        /* Begin: */
        return this.each(function(){
            var $t = $(this), pulseCount=1, pulseLimit = (o.runLength&&o.runLength>0) ? o.runLength*largestArrayLength([o.textColors.length,o.backgroundColors.length,o.borderColors.length,o.opacityRange.length]) : false;
            clearTimeout(recover);
            if(o.duration) {
                setTimeout(recover,o.duration);
            }
            function nudgePulse(textColorIndex,bgColorIndex,borderColorIndex,opacityIndex) {
                if(pulseLimit&&pulseCount===pulseLimit) {
                    return $t.recover();
                }
                pulseCount++;
                /* Initiate color change - on callback continue */
                return $t.animate(getColorsAtIndex(textColorIndex,bgColorIndex,borderColorIndex,opacityIndex),o.speed,function(){
                    /* Callback of each step */
                    nudgePulse(
                        getNextIndex(o.textColors,textColorIndex),
                        getNextIndex(o.backgroundColors,bgColorIndex),
                        getNextIndex(o.borderColors,borderColorIndex),
                        getNextIndex(o.opacityRange,opacityIndex)
                    );
                });
            }
            /* Set CSS to first step (no animation) */
            $t.css(getColorsAtIndex(0,0,0,0));
            /* Then animate to second step */
            nudgePulse(1,1,1,1);
            function getColorsAtIndex(textColorIndex,bgColorIndex,borderColorIndex,opacityIndex) {
                /* Prepare animation object - get's all property names/values from passed indexes */
                var params = {};
                if(o.backgroundColors.length) {
                    params['backgroundColor'] = o.backgroundColors[bgColorIndex];
                }
                if(o.textColors.length) {
                    params['color'] = o.textColors[textColorIndex];
                }
                if(o.borderColors.length) {
                    params['borderLeftColor'] = o.borderColors[borderColorIndex];
                    params['borderRightColor'] = o.borderColors[borderColorIndex];
                    params['borderTopColor'] = o.borderColors[borderColorIndex];
                    params['borderBottomColor'] = o.borderColors[borderColorIndex];
                }
                if(o.opacityPulse&&o.opacityRange.length) {
                    params['opacity'] = o.opacityRange[opacityIndex];
                }
                return params;
            }
            function getNextIndex(property,currentIndex) {
                if (property.length>currentIndex+1) {return currentIndex+1;}
                else {return 0;}
            }
            function largestArrayLength(arrayOfArrays) {
                return Math.max.apply( Math, arrayOfArrays ); 
            }
            function recover() {
                $t.recover();
            }
        });
    }
})(jQuery);

/* The below code extends the animate function so that it works with color animations */
/* By John Resig */
(function(jQuery){
jQuery.each(['backgroundColor','borderBottomColor','borderLeftColor','borderRightColor','borderTopColor','color','outlineColor'],function(i,attr){jQuery.fx.step[attr]=function(fx){if(fx.state==0){fx.start=getColor(fx.elem,attr);fx.end=getRGB(fx.end)}fx.elem.style[attr]="rgb("+[Math.max(Math.min(parseInt((fx.pos*(fx.end[0]-fx.start[0]))+fx.start[0]),255),0),Math.max(Math.min(parseInt((fx.pos*(fx.end[1]-fx.start[1]))+fx.start[1]),255),0),Math.max(Math.min(parseInt((fx.pos*(fx.end[2]-fx.start[2]))+fx.start[2]),255),0)].join(",")+")"}});
function getRGB(color){var result;if(color&&color.constructor==Array&&color.length==3)return color;if(result=/rgb\(\s*([0-9]{1,3})\s*,\s*([0-9]{1,3})\s*,\s*([0-9]{1,3})\s*\)/.exec(color)){return[parseInt(result[1]),parseInt(result[2]),parseInt(result[3])]}if(result=/rgb\(\s*([0-9]+(?:\.[0-9]+)?)\%\s*,\s*([0-9]+(?:\.[0-9]+)?)\%\s*,\s*([0-9]+(?:\.[0-9]+)?)\%\s*\)/.exec(color)){return[parseFloat(result[1])*2.55,parseFloat(result[2])*2.55,parseFloat(result[3])*2.55]}if(result=/#([a-fA-F0-9]{2})([a-fA-F0-9]{2})([a-fA-F0-9]{2})/.exec(color)){return[parseInt(result[1],16),parseInt(result[2],16),parseInt(result[3],16)]}if(result=/#([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])/.exec(color)){return[parseInt(result[1]+result[1],16),parseInt(result[2]+result[2],16),parseInt(result[3]+result[3],16)]}return colors[jQuery.trim(color).toLowerCase()]}
function getColor(elem,attr){var color;do{color=jQuery.curCSS(elem,attr);if(color!=''&&color!='transparent'||jQuery.nodeName(elem,"body")){break}attr="backgroundColor"}while(elem=elem.parentNode);return getRGB(color)};
var colors={aqua:[0,255,255],azure:[240,255,255],beige:[245,245,220],black:[0,0,0],blue:[0,0,255],brown:[165,42,42],cyan:[0,255,255],darkblue:[0,0,139],darkcyan:[0,139,139],darkgrey:[169,169,169],darkgreen:[0,100,0],darkkhaki:[189,183,107],darkmagenta:[139,0,139],darkolivegreen:[85,107,47],darkorange:[255,140,0],darkorchid:[153,50,204],darkred:[139,0,0],darksalmon:[233,150,122],darkviolet:[148,0,211],fuchsia:[255,0,255],gold:[255,215,0],green:[0,128,0],indigo:[75,0,130],khaki:[240,230,140],lightblue:[173,216,230],lightcyan:[224,255,255],lightgreen:[144,238,144],lightgrey:[211,211,211],lightpink:[255,182,193],lightyellow:[255,255,224],lime:[0,255,0],magenta:[255,0,255],maroon:[128,0,0],navy:[0,0,128],olive:[128,128,0],orange:[255,165,0],pink:[255,192,203],purple:[128,0,128],violet:[128,0,128],red:[255,0,0],silver:[192,192,192],white:[255,255,255],yellow:[255,255,0]};
})(jQuery);


/* jquery.throbber */

(function($){var defaultOptions={ajax:true,delay:0,image:"throbber.gif",parent:"",wrap:""};$().ajaxStop(function(){_throbberHide($(".throbber_ajax"));});_throbberShow=function(options,jelement){var jparent;if(options.parent){jelement=null;jparent=$(options.parent);}else{jparent=(jelement?jelement.parent():$("body"));}
if(jparent.find(".throbber").length==0){window.clearTimeout(jparent.data("throbber_timeout"));jparent.data("throbber_timeout",window.setTimeout(function(){var throbber=$('<img src="'+options.image+'" class="throbber" />');if(options.ajax){throbber.addClass("throbber_ajax");}
if(jelement){throbber.data("throbber_element",jelement);jelement.hide().after(throbber);}else{jparent.children().hide().end().append(throbber);}
if(options.wrap!=""){throbber.wrap(options.wrap);}},options.delay));}};_throbberHide=function(throbbers){throbbers.each(function(){var throbber=$(this);var jelement=throbber.data("throbber_element");if(jelement){jelement.show();}else{throbber.siblings().show();}
window.clearTimeout(throbber.parent().data("throbber_timeout"));throbber.remove();});}
$.fn.throbber=function(event,options){if(typeof event=="undefined"){event="click";options={};}else if(typeof event=="object"){options=event;event="click";}else if(typeof options=="undefined"){options={};}
options=$.extend({},defaultOptions,options);$(this).each(function(){var jtarget=$(this);jtarget.bind(event,function(){_throbberShow(options,jtarget);});});return $(this);};$.throbberShow=function(options){options=$.extend({},defaultOptions,options);_throbberShow(options,null);return $;};$.throbberHide=function(){_throbberHide($(".throbber"));return $;};})(jQuery);


/* 
 * jGrowl 1.2
*/


(function($){$.jGrowl=function(m,o){if($('#jGrowl').size()==0)$('<div id="jGrowl"></div>').addClass($.jGrowl.defaults.position).appendTo('body');$('#jGrowl').jGrowl(m,o);};$.fn.jGrowl=function(m,o){if($.isFunction(this.each)){var args=arguments;return this.each(function(){var self=this;if($(this).data('jGrowl.instance')==undefined){$(this).data('jGrowl.instance',new $.fn.jGrowl());$(this).data('jGrowl.instance').startup(this);}
if($.isFunction($(this).data('jGrowl.instance')[m])){$(this).data('jGrowl.instance')[m].apply($(this).data('jGrowl.instance'),$.makeArray(args).slice(1));}else{$(this).data('jGrowl.instance').create(m,o);}});};};$.extend($.fn.jGrowl.prototype,{defaults:{pool:0,header:'',group:'',sticky:false,position:'top-right',glue:'after',theme:'default',corners:'10px',check:250,life:3000,speed:'normal',easing:'swing',closer:true,closeTemplate:'&times;',closerTemplate:'<div>[ close all ]</div>',log:function(e,m,o){},beforeOpen:function(e,m,o){},open:function(e,m,o){},beforeClose:function(e,m,o){},close:function(e,m,o){},animateOpen:{opacity:'show'},animateClose:{opacity:'hide'}},notifications:[],element:null,interval:null,create:function(message,o){var o=$.extend({},this.defaults,o);this.notifications[this.notifications.length]={message:message,options:o};o.log.apply(this.element,[this.element,message,o]);},render:function(notification){var self=this;var message=notification.message;var o=notification.options;var notification=$('<div class="jGrowl-notification'+((o.group!=undefined&&o.group!='')?' '+o.group:'')+'"><div class="close">'+o.closeTemplate+'</div><div class="header">'+o.header+'</div><div class="message">'+message+'</div></div>').data("jGrowl",o).addClass(o.theme).children('div.close').bind("click.jGrowl",function(){$(this).parent().trigger('jGrowl.close');}).parent();(o.glue=='after')?$('div.jGrowl-notification:last',this.element).after(notification):$('div.jGrowl-notification:first',this.element).before(notification);$(notification).bind("mouseover.jGrowl",function(){$(this).data("jGrowl").pause=true;}).bind("mouseout.jGrowl",function(){$(this).data("jGrowl").pause=false;}).bind('jGrowl.beforeOpen',function(){o.beforeOpen.apply(self.element,[self.element,message,o]);}).bind('jGrowl.open',function(){o.open.apply(self.element,[self.element,message,o]);}).bind('jGrowl.beforeClose',function(){o.beforeClose.apply(self.element,[self.element,message,o]);}).bind('jGrowl.close',function(){$(this).trigger('jGrowl.beforeClose').animate(o.animateClose,o.speed,o.easing,function(){$(this).remove();o.close.apply(self.element,[self.element,message,o]);});}).trigger('jGrowl.beforeOpen').animate(o.animateOpen,o.speed,o.easing,function(){$(this).data("jGrowl").created=new Date();}).trigger('jGrowl.open');if($.fn.corner!=undefined)$(notification).corner(o.corners);if($('div.jGrowl-notification:parent',this.element).size()>1&&$('div.jGrowl-closer',this.element).size()==0&&this.defaults.closer!=false){$(this.defaults.closerTemplate).addClass('jGrowl-closer').addClass(this.defaults.theme).appendTo(this.element).animate(this.defaults.animateOpen,this.defaults.speed,this.defaults.easing).bind("click.jGrowl",function(){$(this).siblings().children('div.close').trigger("click.jGrowl");if($.isFunction(self.defaults.closer))self.defaults.closer.apply($(this).parent()[0],[$(this).parent()[0]]);});};},update:function(){$(this.element).find('div.jGrowl-notification:parent').each(function(){if($(this).data("jGrowl")!=undefined&&$(this).data("jGrowl").created!=undefined&&($(this).data("jGrowl").created.getTime()+$(this).data("jGrowl").life)<(new Date()).getTime()&&$(this).data("jGrowl").sticky!=true&&($(this).data("jGrowl").pause==undefined||$(this).data("jGrowl").pause!=true)){$(this).trigger('jGrowl.close');}});if(this.notifications.length>0&&(this.defaults.pool==0||$(this.element).find('div.jGrowl-notification:parent').size()<this.defaults.pool)){this.render(this.notifications.shift());}
if($(this.element).find('div.jGrowl-notification:parent').size()<2){$(this.element).find('div.jGrowl-closer').animate(this.defaults.animateClose,this.defaults.speed,this.defaults.easing,function(){$(this).remove();});};},startup:function(e){this.element=$(e).addClass('jGrowl').append('<div class="jGrowl-notification"></div>');this.interval=setInterval(function(){jQuery(e).data('jGrowl.instance').update();},this.defaults.check);if($.browser.msie&&parseInt($.browser.version)<7&&!window["XMLHttpRequest"])$(this.element).addClass('ie6');},shutdown:function(){$(this.element).removeClass('jGrowl').find('div.jGrowl-notification').remove();clearInterval(this.interval);}});$.jGrowl.defaults=$.fn.jGrowl.prototype.defaults;})(jQuery);



/* jquery.contextmenu
 * http://www.trendskitchens.co.nz/jquery/contextmenu/
*/

(function($){var menu,shadow,trigger,content,hash,currentTarget;var defaults={menuStyle:{listStyle:'none',padding:'1px',margin:'0px',backgroundColor:'#fff',border:'1px solid #999'},itemStyle:{margin:'0px',color:'#000',display:'block',cursor:'default',padding:'3px',border:'1px solid #fff',backgroundColor:'transparent'},itemHoverStyle:{border:'1px solid #0a246a',backgroundColor:'#b6bdd2'},eventPosX:'pageX',eventPosY:'pageY',shadow:true,onContextMenu:null,onShowMenu:null};$.fn.contextMenu=function(id,options){if(!menu){menu=$('<div id="jqContextMenu"></div>').hide().css({position:'absolute',zIndex:'500'}).appendTo('body').bind('click',function(e){e.stopPropagation();});}
if(!shadow){shadow=$('<div></div>').css({backgroundColor:'#000',position:'absolute',opacity:0.2,zIndex:499}).appendTo('body').hide();}
hash=hash||[];hash.push({id:id,menuStyle:$.extend({},defaults.menuStyle,options.menuStyle||{}),itemStyle:$.extend({},defaults.itemStyle,options.itemStyle||{}),itemHoverStyle:$.extend({},defaults.itemHoverStyle,options.itemHoverStyle||{}),bindings:options.bindings||{},shadow:options.shadow||options.shadow===false?options.shadow:defaults.shadow,onContextMenu:options.onContextMenu||defaults.onContextMenu,onShowMenu:options.onShowMenu||defaults.onShowMenu,eventPosX:options.eventPosX||defaults.eventPosX,eventPosY:options.eventPosY||defaults.eventPosY});var index=hash.length-1;$(this).bind('contextmenu',function(e){if(e.shiftKey)return true;var bShowContext=(!!hash[index].onContextMenu)?hash[index].onContextMenu(e):true;if(bShowContext)display(index,this,e,options);return false;});return this;};function display(index,trigger,e,options){var cur=hash[index];content=$('#'+cur.id).find('ul:first').clone(true);content.css(cur.menuStyle).find('li').css(cur.itemStyle).hover(function(){$(this).css(cur.itemHoverStyle);},function(){$(this).css(cur.itemStyle);}).find('img').css({verticalAlign:'middle',paddingRight:'2px'});menu.html(content);if(!!cur.onShowMenu)menu=cur.onShowMenu(e,menu);$.each(cur.bindings,function(id,func){$('#'+id,menu).bind('click',function(e){hide();func(trigger,currentTarget);});});menu.css({'left':e[cur.eventPosX],'top':e[cur.eventPosY]}).show();if(cur.shadow)shadow.css({width:menu.width(),height:menu.height(),left:e.pageX+2,top:e.pageY+2}).show();$(document).one('click',hide);}
function hide(){menu.hide();shadow.hide();}
$.contextMenu={defaults:function(userDefaults){$.each(userDefaults,function(i,val){if(typeof val=='object'&&defaults[i]){$.extend(defaults[i],val);}
else defaults[i]=val;});}};})(jQuery);jQuery(function(){jQuery('div.contextMenu').hide();});


/**
 * jQuery.ScrollTo - Easy element scrolling using jQuery.
 * Copyright (c) 2007-2009 Ariel Flesler - aflesler(at)gmail(dot)com | http://flesler.blogspot.com
 * Dual licensed under MIT and GPL.
 * Date: 5/25/2009
 * @author Ariel Flesler
 * @version 1.4.2
 *
 * http://flesler.blogspot.com/2007/10/jqueryscrollto.html
 */
;(function(d){var k=d.scrollTo=function(a,i,e){d(window).scrollTo(a,i,e)};k.defaults={axis:'xy',duration:parseFloat(d.fn.jquery)>=1.3?0:1};k.window=function(a){return d(window)._scrollable()};d.fn._scrollable=function(){return this.map(function(){var a=this,i=!a.nodeName||d.inArray(a.nodeName.toLowerCase(),['iframe','#document','html','body'])!=-1;if(!i)return a;var e=(a.contentWindow||a).document||a.ownerDocument||a;return d.browser.safari||e.compatMode=='BackCompat'?e.body:e.documentElement})};d.fn.scrollTo=function(n,j,b){if(typeof j=='object'){b=j;j=0}if(typeof b=='function')b={onAfter:b};if(n=='max')n=9e9;b=d.extend({},k.defaults,b);j=j||b.speed||b.duration;b.queue=b.queue&&b.axis.length>1;if(b.queue)j/=2;b.offset=p(b.offset);b.over=p(b.over);return this._scrollable().each(function(){var q=this,r=d(q),f=n,s,g={},u=r.is('html,body');switch(typeof f){case'number':case'string':if(/^([+-]=)?\d+(\.\d+)?(px|%)?$/.test(f)){f=p(f);break}f=d(f,this);case'object':if(f.is||f.style)s=(f=d(f)).offset()}d.each(b.axis.split(''),function(a,i){var e=i=='x'?'Left':'Top',h=e.toLowerCase(),c='scroll'+e,l=q[c],m=k.max(q,i);if(s){g[c]=s[h]+(u?0:l-r.offset()[h]);if(b.margin){g[c]-=parseInt(f.css('margin'+e))||0;g[c]-=parseInt(f.css('border'+e+'Width'))||0}g[c]+=b.offset[h]||0;if(b.over[h])g[c]+=f[i=='x'?'width':'height']()*b.over[h]}else{var o=f[h];g[c]=o.slice&&o.slice(-1)=='%'?parseFloat(o)/100*m:o}if(/^\d+$/.test(g[c]))g[c]=g[c]<=0?0:Math.min(g[c],m);if(!a&&b.queue){if(l!=g[c])t(b.onAfterFirst);delete g[c]}});t(b.onAfter);function t(a){r.animate(g,j,b.easing,a&&function(){a.call(this,n,b)})}}).end()};k.max=function(a,i){var e=i=='x'?'Width':'Height',h='scroll'+e;if(!d(a).is('html,body'))return a[h]-d(a)[e.toLowerCase()]();var c='client'+e,l=a.ownerDocument.documentElement,m=a.ownerDocument.body;return Math.max(l[h],m[h])-Math.min(l[c],m[c])};function p(a){return typeof a=='object'?a:{top:a,left:a}}})(jQuery);
