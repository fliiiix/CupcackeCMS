use CupkackeCMS;
/*Erzeugen der testdaten*/

INSERT INTO user(nachname, vorname, pw_Hash, aktiv) VALUES("User", "test", "-", TRUE);

INSERT INTO rolle(name, beschreib, aktiv) VALUES("Admin", "Admin der Seite.", TRUE);

INSERT INTO user_rolle(id_user,id_rolle) VALUES(1 , 1);
