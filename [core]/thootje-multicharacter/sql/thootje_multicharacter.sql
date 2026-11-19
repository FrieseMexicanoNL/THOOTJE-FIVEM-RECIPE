CREATE TABLE IF NOT EXISTS `thootje_characters` (
  `id` int NOT NULL AUTO_INCREMENT,
  `owner` varchar(80) NOT NULL,
  `slot` int NOT NULL,
  `firstname` varchar(32) NOT NULL,
  `lastname` varchar(32) NOT NULL,
  `dateofbirth` varchar(10) NOT NULL,
  `gender` varchar(16) NOT NULL DEFAULT 'man',
  `nationality` varchar(32) NOT NULL DEFAULT 'Nederlands',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `owner_slot` (`owner`,`slot`),
  KEY `owner_index` (`owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
