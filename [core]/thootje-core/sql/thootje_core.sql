CREATE TABLE IF NOT EXISTS `thootje_players` (
  `identifier` varchar(80) NOT NULL,
  `name` varchar(64) NOT NULL,
  `accounts` longtext NOT NULL,
  `job` longtext NOT NULL,
  `inventory` longtext NOT NULL,
  `group_name` varchar(32) NOT NULL DEFAULT 'user',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
