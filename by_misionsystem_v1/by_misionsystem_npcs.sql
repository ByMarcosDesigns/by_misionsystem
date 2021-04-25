USE `es_extended`;

DROP TABLE IF EXISTS `by_missionsystem_npcs`;
CREATE TABLE `by_missionsystem_npcs` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `coords` varchar(255) NOT NULL,
  `bytype` longtext NOT NULL,
  PRIMARY KEY (`id`)
);