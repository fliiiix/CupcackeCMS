CREATE DATABASE  IF NOT EXISTS CupkackeCMS;
use CupkackeCMS;

/*Create all tables (user / user_rolle / Rolle / cookie_mapping / Beitrag / Bild)*/
CREATE TABLE user
(
  id INTEGER(11) AUTO_INCREMENT,
  nachname VARCHAR(100) NOT NULL,
  vorname VARCHAR(100) NOT NULL,
  eMail VARCHAR(100) NOT NULL,
  pw_Hash VARCHAR(120) NOT NULL,
  aktiv BIT NOT NULL,
  PRIMARY KEY(id)
);

CREATE TABLE cookie_mapping
(
  id INTEGER(11) AUTO_INCREMENT,
  id_user INTEGER(11),
  cookie_content BIGINT(20) NOT NULL,
  PRIMARY KEY(id),
  FOREIGN KEY (id_user) REFERENCES user(id)
);

CREATE TABLE rolle
(
  id INTEGER(11) AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL,
  beschreib TINYTEXT,
  aktiv BIT NOT NULL,
  PRIMARY KEY(id)
);

CREATE TABLE user_rolle
(
  id INTEGER(11) AUTO_INCREMENT,
  id_user INTEGER(11),
  id_rolle INTEGER(12),
  PRIMARY KEY(id),
  FOREIGN KEY (id_user) REFERENCES user(id),
  FOREIGN KEY (id_rolle) REFERENCES rolle(id)
);

CREATE TABLE beitrag
(
  id INTEGER(11) AUTO_INCREMENT,
  titel VARCHAR(100) NOT NULL,
  untertitel VARCHAR(100),
  inhalt TEXT,
  id_Owner INTEGER(11),
  Aktiv BIT NOT NULL,
  PRIMARY KEY(id),
  FOREIGN KEY (id_Owner) REFERENCES user(id)
);

CREATE TABLE bild
(
  id INTEGER(11) AUTO_INCREMENT,
  id_beitrag INTEGER(11),
  speicherName VARCHAR(50) NOT NULL,
  uploadName VARCHAR(100) NOT NULL,
  PRIMARY KEY(id),
  FOREIGN KEY (id_beitrag) REFERENCES beitrag(id)
);

CREATE TABLE kalenderEintrag
(
  id INTEGER(11) AUTO_INCREMENT,
  datum DATE NOT NULL,
  titel VARCHAR(100) NOT NULL,
  beschreib LONGTEXT,
  id_user INTEGER(11),
  PRIMARY KEY(id),
  FOREIGN KEY(id_user) REFERENCES  user(id)
);
