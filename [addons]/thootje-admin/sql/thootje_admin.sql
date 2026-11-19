CREATE TABLE IF NOT EXISTS `thootje_admin_bans` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `license` VARCHAR(100) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `reason` VARCHAR(250) NOT NULL,
  `banned_by` VARCHAR(100) NOT NULL,
  `expires_at` BIGINT NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
