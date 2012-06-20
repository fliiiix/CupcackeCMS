-- Adminer 3.3.3 MySQL dump

SET NAMES utf8;
SET foreign_key_checks = 0;
SET time_zone = 'SYSTEM';
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

DROP TABLE IF EXISTS `beitrag`;
CREATE TABLE `beitrag` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `titel` varchar(100) NOT NULL,
  `untertitel` varchar(100) DEFAULT NULL,
  `inhalt` text,
  `id_Owner` int(11) DEFAULT NULL,
  `Aktiv` bit(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `bild`;
CREATE TABLE `bild` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id_beitrag` int(11) DEFAULT NULL,
  `speicherName` varchar(50) NOT NULL,
  `uploadName` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `cookie_mapping`;
CREATE TABLE `cookie_mapping` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `cookie_content` bigint(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `email_verify`;
CREATE TABLE `email_verify` (
  `user_id` int(11) NOT NULL,
  `random` varchar(128) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `kalenderEintrag`;
CREATE TABLE `kalenderEintrag` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `datum` date NOT NULL,
  `titel` varchar(100) NOT NULL,
  `beschreib` longtext,
  `id_user` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `pw_forgot`;
CREATE TABLE `pw_forgot` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `link_component` varchar(128) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `rolle`;
CREATE TABLE `rolle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `beschreib` tinytext,
  `aktiv` bit(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nachname` varchar(100) NOT NULL,
  `vorname` varchar(100) NOT NULL,
  `email` tinytext NOT NULL,
  `pw_hash` varchar(128) NOT NULL,
  `aktiv` int(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

INSERT INTO `user` (`id`, `nachname`, `vorname`, `email`, `pw_hash`, `aktiv`) VALUES
(2,	'Mensch',	'Test',	'test@test.de',	'4f00a559fad352d044ebd522987580fa01611022d993fe09915b575e14841e181cfbf84cf8b148f797a6b252e9cf1d8b0f0c456b7717857ff80dba9876d9753f',	1),
(3,	'Hallo',	'Halli',	'halli@hallo.de',	'1ce87e773445695711406c8b2e3f7a92105dd9beb88b3908195011a20200aa53286e5a661426485588d4c9fa4e61a3198da1f7b913caa54483ddeb609da435f5',	0);

DROP TABLE IF EXISTS `user_rolle`;
CREATE TABLE `user_rolle` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id_user` int(11) DEFAULT NULL,
  `id_rolle` int(12) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- 2012-06-20 22:05:20
