CREATE TABLE IF NOT EXISTS `thootje_phone_profiles` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(100) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `phone_number` VARCHAR(20) NOT NULL,
  `wallpaper` VARCHAR(32) NOT NULL DEFAULT 'aurora',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_identifier` (`identifier`),
  UNIQUE KEY `uniq_phone_number` (`phone_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `thootje_phone_contacts` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `owner_identifier` VARCHAR(100) NOT NULL,
  `contact_name` VARCHAR(40) NOT NULL,
  `phone_number` VARCHAR(20) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_owner_number` (`owner_identifier`,`phone_number`),
  KEY `idx_owner` (`owner_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `thootje_phone_messages` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `sender_identifier` VARCHAR(100) NOT NULL,
  `receiver_identifier` VARCHAR(100) NOT NULL,
  `sender_number` VARCHAR(20) NOT NULL,
  `receiver_number` VARCHAR(20) NOT NULL,
  `message` VARCHAR(500) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_sender` (`sender_identifier`,`id`),
  KEY `idx_receiver` (`receiver_identifier`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `thootje_phone_notes` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `owner_identifier` VARCHAR(100) NOT NULL,
  `title` VARCHAR(60) NOT NULL,
  `body` TEXT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_owner` (`owner_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
