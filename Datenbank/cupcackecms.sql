-- Adminer 3.6.1 MySQL dump

SET NAMES utf8;
SET foreign_key_checks = 0;
SET time_zone = 'SYSTEM';
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

DROP TABLE IF EXISTS `bilderBeitrag`;
CREATE TABLE `bilderBeitrag` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `titel` mediumtext NOT NULL,
  `unterTitel` mediumtext NOT NULL,
  `text` mediumtext NOT NULL,
  `uploadFolderName` text NOT NULL,
  `ownerId` int(11) NOT NULL,
  `aktiv` bit(1) NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `change_email`;
CREATE TABLE `change_email` (
  `user_id` int(11) NOT NULL,
  `random` varchar(128) NOT NULL,
  `new_email` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `cookie_mapping`;
CREATE TABLE `cookie_mapping` (
  `user_id` int(11) DEFAULT NULL,
  `cookie_content` bigint(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `email_verify`;
CREATE TABLE `email_verify` (
  `user_id` int(11) NOT NULL,
  `random` varchar(128) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `events`;
CREATE TABLE `events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL,
  `title` varchar(100) NOT NULL,
  `description` longtext NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `last_editor` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `pw_forgot`;
CREATE TABLE `pw_forgot` (
  `link_component` varchar(128) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- 2012-11-02 23:15:42
