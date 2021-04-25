USE `es_extended`;

DROP TABLE IF EXISTS `by_missionsystem`;
CREATE TABLE `by_missionsystem` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `coords` varchar(255) NOT NULL,
  `name` longtext NOT NULL,
  `bytype` longtext NOT NULL,
  PRIMARY KEY (`id`)
);