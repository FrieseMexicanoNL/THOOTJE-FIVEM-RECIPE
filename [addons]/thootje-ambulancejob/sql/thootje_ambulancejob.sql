CREATE TABLE IF NOT EXISTS `thootje_ems_calls` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `caller_identifier` VARCHAR(100) NOT NULL,
  `caller_name` VARCHAR(100) NOT NULL,
  `call_type` VARCHAR(32) NOT NULL DEFAULT 'medical',
  `message` VARCHAR(240) NOT NULL,
  `x` DOUBLE NOT NULL,
  `y` DOUBLE NOT NULL,
  `z` DOUBLE NOT NULL,
  `status` ENUM('open','assigned','completed','cancelled') NOT NULL DEFAULT 'open',
  `assigned_identifier` VARCHAR(100) DEFAULT NULL,
  `assigned_name` VARCHAR(100) DEFAULT NULL,
  `assigned_source` INT DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ems_calls_status` (`status`),
  KEY `idx_ems_calls_assigned` (`assigned_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `thootje_ems_treatments` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `medic_identifier` VARCHAR(100) NOT NULL,
  `medic_name` VARCHAR(100) NOT NULL,
  `patient_identifier` VARCHAR(100) NOT NULL,
  `patient_name` VARCHAR(100) NOT NULL,
  `treatment` VARCHAR(100) NOT NULL,
  `item_name` VARCHAR(64) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ems_treatment_patient` (`patient_identifier`),
  KEY `idx_ems_treatment_medic` (`medic_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
