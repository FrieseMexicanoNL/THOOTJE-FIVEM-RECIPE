CREATE TABLE IF NOT EXISTS `thootje_police_reports` (
 `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
 `officer_identifier` VARCHAR(100) NOT NULL,
 `officer_name` VARCHAR(100) NOT NULL,
 `suspect_name` VARCHAR(100) DEFAULT NULL,
 `title` VARCHAR(80) NOT NULL,
 `description` TEXT NOT NULL,
 `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (`id`), KEY `idx_police_report_officer` (`officer_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `thootje_police_fines` (
 `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
 `officer_identifier` VARCHAR(100) NOT NULL,
 `officer_name` VARCHAR(100) NOT NULL,
 `suspect_identifier` VARCHAR(100) NOT NULL,
 `suspect_name` VARCHAR(100) NOT NULL,
 `amount` INT UNSIGNED NOT NULL,
 `reason` VARCHAR(120) NOT NULL,
 `status` ENUM('open','paid','cancelled') NOT NULL DEFAULT 'open',
 `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (`id`), KEY `idx_police_fine_suspect` (`suspect_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `thootje_police_jail_logs` (
 `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
 `officer_identifier` VARCHAR(100) NOT NULL,
 `officer_name` VARCHAR(100) NOT NULL,
 `suspect_identifier` VARCHAR(100) NOT NULL,
 `suspect_name` VARCHAR(100) NOT NULL,
 `minutes` INT UNSIGNED NOT NULL,
 `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY (`id`), KEY `idx_police_jail_suspect` (`suspect_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
