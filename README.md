CupcackeCMS
===========
by fliiiix and linux4ever([Twitter](http://twitter.com/linux4ever2), [Homepage](http://l3r.de))
#Schwerpunkte der Seite:
* EASY TO USE
* Kalender
* Bilderverwaltung (Upload, anzeigen)

#TO-DO
1. welche lizenz?

#Ziel Bestimmung

##Musskriterien##
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
1. Cooles Layout ;) (darum Bootstrap)

#Produktfunktionen
                     
#Rechte:
	| Wer      |Kalender      |BilderGallerie |  AdminPanel|
	|:--------:|:------------:|:-------------:|:----------:|
	|jeder     | Ansehen      | darf nichts   |darf nichts |
	|user      | X            | X             |darf nichts |
	|admin     | X            | X             |X           |
	|betrachter| Ansehen      | Ansehen       |darf nichts |
	X Bearbeiten, Löschen, Editieren

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

//TODO eventuell mach ich mal n bild ;)

----
#Quellen
* https://github.com/twitter/bootstrap/ - Layout Grundlagen
* http://bootswatch.com/ - fürs Layout
* http://glyphicons.com/