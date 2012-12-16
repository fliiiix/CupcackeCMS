<?php
#Sammlung von nützlichen Funktionen für CupcackeCMS


/**
 * Erzeugt ein neues Datenbank-Objekt
 * @return mysqli connection
 */
function new_db_o() {
    $db = @new mysqli('localhost', 'root', '', 'cupcackecms');
    return $db;
}

/**
 * Name der Webseite für das <title>-Tag
 * @global string $GLOBALS['site_name']
 * @name $site_name 
 */
$GLOBALS["site_name"] = "CupcackeCMS";

/**
 * Login-Funktion für die Startseite
 * @param type $email ist der 'eindeutige' username
 * @param type $password ist das passwort im klartext
 * @return boolean|string true wenn der user verifiziert ist oder ein Fehlertext wenn nicht
 */
function login_user($email, $password) {
    $db = new_db_o();
    $escaped_email = escape($email);
    $hashed_password = hash("whirlpool", $password, false);
    $sql = 'SELECT `id` FROM `user` WHERE `email`=? AND `pw_hash`=? AND `aktiv`=2';
    $ergebnis = $db->prepare($sql);
    $ergebnis->bind_param('ss', $escaped_email, $hashed_password);
    $ergebnis->execute();
    $ergebnis->bind_result($user_id);
    $ergebnis->fetch();
    if (!$ergebnis->affected_rows == 0) {
        $ergebnis->bind_result($user_id);
        $ergebnis->fetch();
        $ergebnis->close();
        
        $sql = 'DELETE FROM `cookie_mapping` WHERE `user_id` = ?';
        $eintrag = $db->prepare($sql);
        $eintrag->bind_param('i', $user_id);
        $eintrag->execute();
        $ergebnis->close();

        $cookie_content = rand(0, getrandmax());
        $sql = 'SELECT * FROM `cookie_mapping` WHERE `cookie_content`=?';
        $ergebnis = $db->prepare($sql);
        $ergebnis->bind_param($cookie_content);
        $ergebnis->execute();
        $ergebnis->fetch();
        $ergebnis->close();
        
        if ($ergebnis->affected_rows == 0) {
            $sql = 'INSERT INTO `cookie_mapping` (`user_id`, `cookie_content`) VALUES (?,?)';
            $eintrag = $db->prepare($sql);
            $eintrag->bind_param('is', $user_id, $cookie_content);
            $eintrag->execute();
            $ergebnis->close();
            setcookie("CupcackeCMS_Cookie", $cookie_content, time() + 7200);
            return true;
        } else {
            return "Falscher Benutzername, falsches Passwort oder deaktivierter Account. 51";
        }
    } else {
        return "Falscher Benutzername, falsches Passwort oder deaktivierter Account. 54";
    }
}

/**
 * Logout löscht das Cookie
 * @param type $valid_user_id ist die datenbank id des users
 */
function logout($valid_user_id) {
    $db = new_db_o();
    $sql = 'DELETE FROM `cookie_mapping` WHERE `user_id`=?';
    $eintrag = $db->prepare($sql);
    $eintrag->bind_param('i',$valid_user_id);
    $eintrag->execute();
    $eintrag->close();
    setcookie("CupcackeCMS_Cookie", "", -1);
}

/**
 * Kontrolle, ob der User, der sich momentan auf der Seite befindet eingeloggt ist
 * @return boolean|int gibt entweder die userid aus oder False
 */
function verify_user() {
    $db = new_db_o();
    if (isset($_COOKIE["CupcackeCMS_Cookie"])) {
        $cookie_content = intval($_COOKIE["CupcackeCMS_Cookie"]);
        $sql = 'SELECT `user_id` FROM `cookie_mapping` WHERE `cookie_content`=?';
        $ergebnis = $db->prepare($sql);
        $ergebnis->bind_param('i', $cookie_content);
        $ergebnis->execute();
        if (!$ergebnis->affected_rows == 0) {
            $ergebnis->bind_result($user_id);
            $ergebnis->fetch();
            return $user_id;
        } else {
            return false;
        }
    } else {
        return false;
    }
}

/**
 * gibt die rolle des users zurück
 * @param type $valid_user_id ist die datenbank id des users
 * @return int user rollen Id aus der Datenbank
 */
function getUserRolle($valid_user_id) {
    $db = new_db_o();
    $rolle = 0;
    if (isset($_COOKIE["CupcackeCMS_Cookie"])) {
        $sql = 'SELECT `rolle` FROM user WHERE Id=?';
        $ergebnis = $db->prepare($sql);
        $ergebnis->bind_param('i', $valid_user_id);
        $ergebnis->execute();
        if (!$ergebnis->affected_rows == 0) {
            $ergebnis->bind_result($rolle);
            $ergebnis->fetch();
        }
        $ergebnis->close();
        return $rolle;
    }
}

/**
 * Gibt den Namen eines Users zurück
 * @param type $valid_user_id ist die datenbank id des users
 * @return string gibt den Vor und Nachnamen zurück
 */
function current_username($valid_user_id) {
    $db = new_db_o();
    $vorname = "";
    $nachname = "";
    
    $sql = 'SELECT `vorname`,`nachname` FROM `user` WHERE id=?';
    $ergebnis = $db->prepare($sql);
    $ergebnis->bind_param('i', $valid_user_id);
    $ergebnis->execute();
    if (!$ergebnis->affected_rows == 0) {
        $ergebnis->bind_result($vorname, $nachname);
        $ergebnis->fetch();
    }
    $ergebnis->close();
    return $vorname . " " . $nachname;
}

/**
 * Baut einen HTML Kalender
 * @param type $month
 * @param type $year
 * @param type $db
 * @return string html kalender
 */
function calendar($month, $year, $db) {
    #monats array damit die monate immer auf deutsch ausgegeben werden können
    $monate = array(1=>"Januar",
                2=>"Februar",
                3=>"M&auml;rz",
                4=>"April",
                5=>"Mai",
                6=>"Juni",
                7=>"Juli",
                8=>"August",
                9=>"September",
                10=>"Oktober",
                11=>"November",
                12=>"Dezember");
    $monat = date("n");
    
    $current_m = $month;
    $current_y = $year;
    # Namen des angezeigten Monats feststellen, ersten Wochentag dieses Monats feststellen, letzten Tag dieses Monats feststellen
    $current_m_name = date("F", mktime(0, 0, 0, $current_m, 1, $current_y));
    $current_m_first_wd = date("w", mktime(0, 0, 0, $current_m, 1, $current_y));
    $current_m_last_d = date("d", mktime(0, 0, 0, $current_m + 1, 0, $current_y));
    # Tabellen-Stuff (Wochentages-Leiste)
    $output = '<table class = "table" style = "width: 100px; margin-bottom: 0px;">';
    $output .= ' <tr>';
    $output .= ' <td colspan = "7" style = "border-top: 0px solid black; font-weight:bold;">' . $monate[$monat] . '</td>';
    $output .= ' </tr>';
    $output .= ' <tr>';
    $output .= ' <td><b>Mo</b></td>';
    $output .= ' <td><b>Di</b></td>';
    $output .= ' <td><b>Mi</b></td>';
    $output .= ' <td><b>Do</b></td>';
    $output .= ' <td><b>Fr</b></td>';
    $output .= ' <td><b>Sa</b></td>';
    $output .= ' <td><b>So</b></td>';
    $output .= ' </tr>';
    $output .= ' <tr>';
    # Sonntags-Bugfix
    if ($current_m_first_wd == 0) {
        $current_m_first_wd = 7;
    }
    # Leere Tabellen-Felder ausgeben, wenn der erste Tag des Monats kein Montag ist
    if ($current_m_first_wd > 1) {
        $output .= '<td colspan = "' . ($current_m_first_wd - 1) . '">&nbsp;</td>';
    }

    # Query, für die Termin-Hyperlinks zu den entsprechenden Daten
    $sql = 'SELECT `date` FROM `events` WHERE `date` BETWEEN "' . $current_y . '-' . $current_m . '-01" AND "' . $current_y . '-' . $current_m . '-' . $current_m_last_d . '"';
    $ergebnis = $db->prepare($sql);
    $ergebnis->execute();
    $ergebnis->bind_result($date_with_event);
    # Für jeden Tag, an dem es ein Event gibt im event_dates_array eine 1 setzen
    while ($ergebnis->fetch()) {
        $explode_array = explode("-", $date_with_event);
        $event_dates_array[$explode_array[2]] = 1;
    }
    # Die einzelnen Tabellen-Felder mit den Tages-Daten generieren
    for ($act_day = 1, $act_wd = $current_m_first_wd; $act_day <= $current_m_last_d; $act_day++, $act_wd++) {
        # Wenn am ausgegebenen Tag ein Event ist einen Link auf zur kalender.php auf das Datum legen
        if (isset($event_dates_array[$act_day])) {
            $output .= '<td><b><a href = "kalender.php?date=' . $act_day . '.' . $current_m . '.' . $current_y . '">' . $act_day . '</a></b></td>';
            # Wenn kein Event am ausgegebenen Tag ist den Tag ganz normal ausgeben
        } else {
            $output .= '<td>' . $act_day . '</td>';
        }
        # Zeile nach einem Sonntag beenden
        if ($act_wd == 7) {
            $output .= '</tr>';
            # Wenn der Monat noch nicht zu Ende ist noch eine neue Zeile öffnen
            if ($act_day < $current_m_last_d) {
                $output .= '<tr>';
            }
            $act_wd = 0;
        }
    }
    # Wenn der letzte Tag des Monats kein Sonntag ist am Ende der Tabellen-Zeile noch leere Zellen einfügen
    if ($act_wd > 1) {
        $output .= '<td colspan = "' . (8 - $act_wd) . '">&nbsp;</td></tr>';
    }
    $output .= ' <tr>';
    $output .= ' <td colspan = "3">' . calendar_link('b', $current_m, $current_y) . '</td>';
    $output .= ' <td>&nbsp;</td>';
    $output .= ' <td colspan = "3" style = "text-align:right">' . calendar_link('f', $current_m, $current_y) . '</td>';
    $output .= ' </tr>';
    $output .= '</table>';
    return $output;
}

/**
 * die Vor- und Zurück-Buttons unter dem Kalender generiert
 * @param type $dir
 * @param type $current_m
 * @param type $current_y
 * @return string
 */
function calendar_link($dir, $current_m, $current_y) {
    $output = '<a href = "?m=';
    if ($dir == 'f') {
        $arrows = '<i class="icon-circle-arrow-right"></i>';
        if ($current_m == 12) {
            $next_m = 1;
            $next_y = $current_y + 1;
        } else {
            $next_m = $current_m + 1;
            $next_y = $current_y;
        }
    }
    if ($dir == 'b') {
        $arrows = '<i class="icon-circle-arrow-left"></i>';
        if ($current_m == 1) {
            $next_m = 12;
            $next_y = $current_y - 1;
        } else {
            $next_m = $current_m - 1;
            $next_y = $current_y;
        }
    }
    $output .= $next_m . '&y=' . $next_y . '">' . $arrows . '</a>';
    return $output;
}

/**
 * Konvertierung des europäischen Datums-Formats in das von MySQL
 * @param type $input datum welches umgewandelt werden soll
 * @return type umgewandeltes Datum
 */
function date_to_mysql($input) {
    $a = explode('.', $input);
    return sprintf('%04d-%02d-%02d', $a[2], $a[1], $a[0]);
}

/**
 * Kovertierung vom MySQL-Datum-Format in das europäische
 * @param type $input datum welches umgewandelt werden soll
 * @return type umgewandeltes Datum
 */
function mysql_to_date($input) {
    $a = explode('-', $input);
    return sprintf('%02d.%02d.%04d', $a[2], $a[1], $a[0]);
}

/**
 * erzeugt eine guid
 * @return type eine Neue GUID
 */
function guid() {
    if (function_exists('com_create_guid')) {
        return com_create_guid();
    } else {
        mt_srand((double) microtime() * 10000); //optional for php 4.2.0 and up.
        $charid = strtoupper(md5(uniqid(rand(), true)));
        $hyphen = chr(45); // "-"
        $uuid = chr(123)// "{"
                . substr($charid, 0, 8) . $hyphen
                . substr($charid, 8, 4) . $hyphen
                . substr($charid, 12, 4) . $hyphen
                . substr($charid, 16, 4) . $hyphen
                . substr($charid, 20, 12)
                . chr(125); // "}"
        return str_replace("{", "", str_replace("}", "", $uuid));
    }
}

/**
 * Leeren von $_GET
 * @param type $site target seite vo der das GET gelöscht werden soll
 */
function empty_get($site) {
    if (count($_GET) != 0) {
        header("Location: " . $site);
    }
}

/**
 * escapet daten für die db
 * @param type $value wert der escapet werden muss
 * @return type escaper wert
 */
function escape($value)
{
    $search = array("\\",  "\x00", "\n",  "\r",  "'",  '"', "\x1a");
    $replace = array("\\\\","\\0","\\n", "\\r", "\'", '\"', "\\Z");
    return str_replace($search, $replace, (string)$value);
}
?>
