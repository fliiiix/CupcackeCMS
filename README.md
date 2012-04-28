CupcackeCMS
===========
#Schwerpunkte der Seite:
* EASY TO USE
* Kalender
* Bilderverwaltung (Upload, anzeigen)
#TO-DO
1. welche lizenz?
2. Zeitplan
3. Pflichtenheft
#Ziel Bestimmung
##Musskriterien
1. Benutzer Authentifizierung
2. Bilderupload von mehrern Bildern Gleichzeitig
2. Bilder anzeigen in Animation (siehe XYZ)
3. Kalender wo angemeldete Benutzer Termine eintragen können
4. Administartor kann User anlegen und Rechte vergeben
5. Rechte verwaltung für User
##Sollkriteren
1. Auf der Startseite einige der Neusten Termin anzeigen
2. Bilder Posts in Kalender ersichtlich machen für angemeldete Benuzer
##Kannkriteren
1. Cooles Layout ;)
#Farben
http://www.colourlovers.com/palette/148712/www.gamebookers.com
Für Farben sind diese Faben zu verwenden ausser es geht nicht anderst!
#Produktfunktionen
##Sitemap
Hauptseite                    Kalender
,----------,                ,-----------,
'          '                '           '
'          '................'           '
'----------'     .          '-----------'
                 .
                 .nur für angemeldete
                 .Benuzer mit genügend Rechten
                 .
                 .   Bilder Gallerie
                 ... ,----------,
                 .   '          '
                 .   '          '
                 .   '----------'
                 .    
                 .    AdminPanel
                 ... ,----------,
                     '          '
                     '          '
                     '----------'
#Rechte:
-------------Kalender--BilderGallerie- AdminPanel-
|jeder     | Ansehen | darf nichts   |darf nichts|
|user      | *       | *             |darf nichts|
|admin     | *       | *             |*          |
|betrachter| Ansehen | Ansehen       |darf nichts|
--------------------------------------------------
* Bearbeiten, Löschen, Editieren
###Haubtseite
Funktionen:
- Login
- Neuste Termine aus Kalender werden Angezeigt (als link damit man zum Beitrag Kommt)
###Funktionen für eingelogte User/Betrachter
- Neuste Bilder Posts werden angezeigt (in Form von Links)
###Kalender
Funktionen:
- Login
- Kalender mit allen Eingetragenen Terminen wird angezeigt
- Die Kalendereinträge können Geklickt werden um zur vollbeschreibung zu kommen (eventuel Pop-up??)
###Funktionen für eingelogte User/Betrachter/Admin
- Neuer Eintrag anlegen / Löschen / Editieren
- Neuste Bilder Posts werden angezeigt (in Form von Links)
###Bildergalerie
Funktionen:
nicht sichtbar
###Funktionen für eingelogte User/Betrachter/Admin
- Neuer Eintrag anlegen / Löschen / Editieren (Probleme: Multifile Uploade, gleichzeitigkeit Optimistic/pesimistic Concurrency)
- Bilder ansehen
####Wie sollte so ein Bilder Post aussehen:
Titel
Untertitel       //optional wird nur angezeigt wenn vorhanden
Textbeschreibung //optional wird nur angezeigt wenn vorhanden
    |--------------------------------------------|
    |                                            |
    |                                            |
    |                                            |
    |                                            |
 <  |                 Bild                       |  >
    |                                            |
    |                                            |
    |                                            |
    |                                            |
    |--------------------------------------------|
Die < und > Pfeile sollen irgend wie die Möglichkeit zeigen ein Bild vor oder zurück zu springen (eventuell mit JavaScript oder ähndlichem)
###Adminpanel
Nur für den Admin :P sichtbar.
Funktionen:
- Useranlegen
- Rechte vergeben
- Algemeine eistellungen (was auch immer :P)
#Linksammlung:
http://www.drweb.de/magazin/css-layouts-und-templates/
