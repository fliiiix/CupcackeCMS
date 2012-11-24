-- Adminer 3.5.1 MySQL dump

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


DROP TABLE IF EXISTS `email_verify`;
CREATE TABLE `email_verify` (
  `user_id` int(11) NOT NULL,
  `random` varchar(128) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;


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
(5,	'1234',	'1234',	2,	'1234@user.com',	'2f9959b230a44678dd2dc29f037ba1159f233aa9ab183ce3a0678eaae002e5aa6f27f47144a1a4365116d3db1b58ec47896623b92d85cb2f191705daf11858b8',	2);

-- 2012-11-24 16:29:14
