<?php

//Sammlung von nützlichen Funktionen für CupcackeCMS
# Mit der Datenbank verbinden
function db_connect() {
    mysql_connect("localhost", "root", "") or die(mysql_error());
    mysql_select_db("cupcackecms") or die(mysql_error());
}

# Funktion zum Erzeugen eines Datenbank-Objekts für Prepared Statements
function new_db_o() {
    $db = @new mysqli('localhost', 'root', '', 'cupcackecms');
    return $db;
}

# Name der Webseite für das <title>-Tag
$GLOBALS["site_name"] = "CupcackeCMS";

# Login-Funktion für die Startseite
function login_user($email, $password) {
    $ergebnis = mysql_query("SELECT id FROM user WHERE email=\"" . mysql_real_escape_string($email) . "\" AND pw_hash=\"" . hash("whirlpool", $password, false) . "\" AND aktiv=" . 2);
    if ($ergebnis) {
        if ($row = mysql_fetch_array($ergebnis)) {
            $user_id = $row["id"];
            mysql_query("DELETE FROM cookie_mapping WHERE user_id=" . $user_id);
            $cookie_content = rand(0, getrandmax());
            $ergebnis = mysql_query("SELECT * FROM cookie_mapping WHERE cookie_content=" . $cookie_content);
            if ((!$ergebnis) && (mysql_num_rows($ergebnis) == 0) || true) {
                mysql_query("INSERT INTO cookie_mapping (user_id,cookie_content) VALUES (" . $user_id . "," . $cookie_content . ")");
                setcookie("CupcackeCMS_Cookie", $cookie_content, time() + 3600);
                return true;
            } else {
                return "Falscher Benutzername, falsches Passwort oder deaktivierter Account.";
            }
        } else {
            return "Falscher Benutzername, falsches Passwort oder deaktivierter Account.";
        }
    } else {
        return "Datenbank-Fehler!";
    }
}

# Logout-Funktion für alle Backend-Seiten
function logout($valid_user_id) {
    mysql_query("DELETE FROM cookie_mapping WHERE user_id=" . $valid_user_id);
    setcookie("CupcackeCMS_Cookie", "", -1);
}

# Kontrolle, ob der User, der sich momentan auf der Seite befindet eingeloggt ist
function verify_user() {
    db_connect();
    if (isset($_COOKIE["CupcackeCMS_Cookie"])) {
        $query = mysql_query("SELECT user_id FROM cookie_mapping WHERE cookie_content=" . intval($_COOKIE["CupcackeCMS_Cookie"]));
        if ($row = mysql_fetch_array($query)) {
            return $row["user_id"];
        } else {
            return false;
        }
    } else {
        return false;
    }
}

# Namen des momentan eingeloggten Users zurückgeben
function current_username($valid_user_id) {
    $query = mysql_query("SELECT vorname,nachname FROM user WHERE id=" . $valid_user_id);
    $row = mysql_fetch_array($query);
    $username = $row["vorname"] . " " . $row["nachname"];
    return $username;
}

# Kalender-Funktion
function calendar($month, $year, $db) {
    $current_m = $month;
    $current_y = $year;
    # Namen des angezeigten Monats feststellen, ersten Wochentag dieses Monats feststellen, letzten Tag dieses Monats feststellen
    $current_m_name = date("F", mktime(0, 0, 0, $current_m, 1, $current_y));
    $current_m_first_wd = date("w", mktime(0, 0, 0, $current_m, 1, $current_y));
    $current_m_last_d = date("d", mktime(0, 0, 0, $current_m + 1, 0, $current_y));
    # Tabellen-Stuff (Wochentages-Leiste)
    $output = '<table class="table" style="width: 100px; margin-bottom: 0px;">';
    $output .= '  <tr>';
    $output .= '    <td colspan="7" style="border-top: 0px solid black; font-weight:bold;">' . $current_m_name . '</td>';
    $output .= '  </tr>';
    $output .= '  <tr>';
    $output .= '    <td><b>Mo</b></td>';
    $output .= '    <td><b>Di</b></td>';
    $output .= '    <td><b>Mi</b></td>';
    $output .= '    <td><b>Do</b></td>';
    $output .= '    <td><b>Fr</b></td>';
    $output .= '    <td><b>Sa</b></td>';
    $output .= '    <td><b>So</b></td>';
    $output .= '  </tr>';
    $output .= '  <tr>';
    # Sonntags-Bugfix
    if ($current_m_first_wd == 0) {
        $current_m_first_wd = 7;
    }
    # Leere Tabellen-Felder ausgeben, wenn der erste Tag des Monats kein Montag ist
    if ($current_m_first_wd > 1) {
        $output .= '<td colspan="' . ($current_m_first_wd - 1) . '">&nbsp;</td>';
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
            $output .= '<td><a href="kalender.php?date=' . $act_day . '.' . $current_m . '.' . $current_y . '">' . $act_day . '</a></td>';
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
        $output .= '<td colspan="' . (8 - $act_wd) . '">&nbsp;</td></tr>';
    }
    $output .= '  <tr>';
    $output .= '    <td colspan="3">' . calendar_link('b', $current_m, $current_y) . '</td>';
    $output .= '    <td>&nbsp;</td>';
    $output .= '    <td colspan="3" style="text-align:right">' . calendar_link('f', $current_m, $current_y) . '</td>';
    $output .= '  </tr>';
    $output .= '</table>';
    return $output;
}

# Funktion, die die Vor- und Zurück-Buttons unter dem Kalender generiert
function calendar_link($dir, $current_m, $current_y) {
    $output = '<a href="?m=';
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

# Funktion zu Konvertierung des europäischen Datums-Formats in das von MySQL
function date_to_mysql($input) {
    $a = explode('.', $input);
    return sprintf('%04d-%02d-%02d', $a[2], $a[1], $a[0]);
}

# Funktion zur Kovertierung vom MySQL-Datum-Format in das europäische
function mysql_to_date($input) {
    $a = explode('-', $input);
    return sprintf('%02d.%02d.%04d', $a[2], $a[1], $a[0]);
}

# Funktion, die den entsprechenden Nutzernamen zu einer ID ausgibt
function get_username($id) {
    $query = mysql_query("SELECT vorname,nachname FROM user WHERE id=" . $id);
    $row = mysql_fetch_array($query);
    return $row['vorname'] . ' ' . $row['nachname'];
}

#guid halt
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

# Funktion zum Leeren von $_GET
function empty_get($site) {
    if (count($_GET) != 0) {
        header("Location: " . $site);
    }
}
?>