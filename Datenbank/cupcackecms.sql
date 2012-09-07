-- Adminer 3.5.1 MySQL dump

SET NAMES utf8;
SET foreign_key_checks = 0;
SET time_zone = 'SYSTEM';
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

CREATE DATABASE `cupcackecms` /*!40100 DEFAULT CHARACTER SET latin1 */;
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
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `bild`;
CREATE TABLE `bild` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `id_beitrag` int(11) DEFAULT NULL,
  `speicherName` varchar(50) NOT NULL,
  `uploadName` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


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


-- 2012-09-07 12:40:26
