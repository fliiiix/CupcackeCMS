-- Adminer 3.6.1 MySQL dump

SET NAMES utf8;
SET foreign_key_checks = 0;
SET time_zone = 'SYSTEM';
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

DROP DATABASE IF EXISTS `cupcackecms`;
CREATE DATABASE `cupcackecms` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `cupcackecms`;

DROP TABLE IF EXISTS `beitrag`;
CREATE TABLE `beitrag` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `titel` varchar(100) NOT NULL,
  `untertitel` varchar(100) DEFAULT NULL,
  `inhalt` text,
  `id_Owner` int(11) DEFAULT NULL,
  `Aktiv` bit(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `bild`;
CREATE TABLE `bild` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id_beitrag` int(11) DEFAULT NULL,
  `speicherName` varchar(50) NOT NULL,
  `uploadName` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `bilderBeitrag`;
CREATE TABLE `bilderBeitrag` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `titel` mediumtext NOT NULL,
  `unterTitel` mediumtext NOT NULL,
  `text` mediumtext NOT NULL,
  `uploadFolderName` text NOT NULL,
  `datum` date NOT NULL,
  `ownerId` int(11) NOT NULL,
  `aktiv` bit(1) NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `change_email`;
CREATE TABLE `change_email` (
  `user_id` int(11) NOT NULL,
  `random` varchar(128) NOT NULL,
  `new_email` tinytext NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `cookie_mapping`;
CREATE TABLE `cookie_mapping` (
  `user_id` int(11) NOT NULL,
  `cookie_content` bigint(20) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `cookie_mapping` (`user_id`, `cookie_content`) VALUES
(5,	737514459);

DROP TABLE IF EXISTS `email_verify`;
CREATE TABLE `email_verify` (
  `user_id` int(11) NOT NULL,
  `random` varchar(128) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `email_verify` (`user_id`, `random`) VALUES
(6,	'1fd3d08ea9d614fd3de6dcaa76f0123f');

DROP TABLE IF EXISTS `events`;
CREATE TABLE `events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` varchar(8000) NOT NULL,
  `startTime` varchar(5) NOT NULL,
  `endTime` varchar(5) NOT NULL,
  `lastEditor` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `events` (`id`, `date`, `title`, `description`, `startTime`, `endTime`, `lastEditor`) VALUES
(1,	'2012-11-30',	'Felix',	'test',	'17:34',	'17:15',	5),
(2,	'2012-11-17',	'sdf',	'',	'0',	'0',	5);

DROP TABLE IF EXISTS `pw_forgot`;
CREATE TABLE `pw_forgot` (
  `link_component` varchar(128) CHARACTER SET latin1 NOT NULL,
  `user_id` int(11) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nachname` varchar(100) NOT NULL,
  `vorname` varchar(100) NOT NULL,
  `rolle` int(1) NOT NULL,
  `email` tinytext NOT NULL,
  `pw_hash` varchar(128) NOT NULL,
  `aktiv` int(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

INSERT INTO `user` (`id`, `nachname`, `vorname`, `rolle`, `email`, `pw_hash`, `aktiv`) VALUES
(3,	'Hallo',	'Halli',	2,	'halli@hallo.de',	'1ce87e773445695711406c8b2e3f7a92105dd9beb88b3908195011a20200aa53286e5a661426485588d4c9fa4e61a3198da1f7b913caa54483ddeb609da435f5',	2),
(4,	'Testmensch',	'Dieter',	2,	'dieter@test.de',	'd7b784d5dd5a950223102a439bfeca948c1c1c25c7215c41b110e01a7d7d05d5b2845fc87b0cf2c84ecafff5bad24732e942d6b804a21855ef9691df9ae7e652',	2),
(5,	'1234',	'1234',	2,	'1234@user.com',	'2f9959b230a44678dd2dc29f037ba1159f233aa9ab183ce3a0678eaae002e5aa6f27f47144a1a4365116d3db1b58ec47896623b92d85cb2f191705daf11858b8',	2);

-- 2012-11-24 00:24:31

