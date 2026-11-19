-- THOOTJE RP - gecombineerde database-installatie
-- Gegenereerd uit de meegeleverde resource SQL-bestanden.

-- ===== thootje-core :: thootje_core.sql =====
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

-- ===== thootje-multicharacter :: thootje_multicharacter.sql =====
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

-- ===== thootje-inventory :: thootje_inventory.sql =====
-- Inventory is stored in thootje_players.inventory by THOOTJE-CORE.
-- This resource does not require a separate inventory table.
-- This SQL file is intentionally provided as a schema note / migration placeholder.
SELECT 'THOOTJE-INVENTORY uses the inventory JSON column in thootje_players.' AS information;

-- ===== thootje-banking :: thootje_banking.sql =====
CREATE TABLE IF NOT EXISTS `thootje_bank_accounts` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `owner_identifier` VARCHAR(100) NOT NULL,
  `account_number` VARCHAR(32) NOT NULL,
  `account_name` VARCHAR(64) NOT NULL DEFAULT 'Mijn betaalrekening',
  `balance` BIGINT NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_owner_identifier` (`owner_identifier`),
  UNIQUE KEY `uniq_account_number` (`account_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `thootje_bank_transactions` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `account_id` INT NOT NULL,
  `transaction_type` VARCHAR(24) NOT NULL,
  `amount` BIGINT NOT NULL,
  `balance_after` BIGINT NOT NULL,
  `counterparty` VARCHAR(100) DEFAULT NULL,
  `counterparty_account` VARCHAR(32) DEFAULT NULL,
  `description` VARCHAR(120) NOT NULL DEFAULT '',
  `reference` VARCHAR(48) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_account_created` (`account_id`, `created_at`),
  KEY `idx_reference` (`reference`),
  CONSTRAINT `fk_thootje_bank_account` FOREIGN KEY (`account_id`) REFERENCES `thootje_bank_accounts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== thootje-jobs :: thootje_jobs.sql =====
CREATE TABLE IF NOT EXISTS `thootje_jobs_players` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(100) NOT NULL,
  `job_name` VARCHAR(50) NOT NULL DEFAULT 'unemployed',
  `grade` INT NOT NULL DEFAULT 0,
  `onduty` TINYINT(1) NOT NULL DEFAULT 0,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_identifier` (`identifier`),
  KEY `idx_job_grade` (`job_name`, `grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== thootje-billing :: thootje_billing.sql =====
CREATE TABLE IF NOT EXISTS `thootje_billing_invoices` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `invoice_number` VARCHAR(32) DEFAULT NULL,
  `sender_identifier` VARCHAR(100) NOT NULL,
  `sender_name` VARCHAR(100) NOT NULL,
  `recipient_identifier` VARCHAR(100) NOT NULL,
  `recipient_name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(120) NOT NULL,
  `amount` INT UNSIGNED NOT NULL,
  `fee` INT UNSIGNED NOT NULL DEFAULT 0,
  `total` INT UNSIGNED NOT NULL,
  `status` ENUM('open','paid','rejected','expired') NOT NULL DEFAULT 'open',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` DATETIME NOT NULL,
  `paid_at` DATETIME DEFAULT NULL,
  `paid_by` VARCHAR(100) DEFAULT NULL,
  `rejected_at` DATETIME DEFAULT NULL,
  `no_payout` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_invoice_number` (`invoice_number`),
  KEY `idx_sender_status` (`sender_identifier`,`status`),
  KEY `idx_recipient_status` (`recipient_identifier`,`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `thootje_billing_payouts` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(100) NOT NULL,
  `amount` INT UNSIGNED NOT NULL,
  `invoice_id` BIGINT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_invoice_payout` (`invoice_id`),
  KEY `idx_payout_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== thootje-garage :: thootje_garage.sql =====
CREATE TABLE IF NOT EXISTS thootje_garage_vehicles (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  owner VARCHAR(100) NOT NULL,
  plate VARCHAR(12) NOT NULL UNIQUE,
  model VARCHAR(80) NOT NULL,
  vehicle_label VARCHAR(100) NOT NULL,
  vehicle_type VARCHAR(24) NOT NULL DEFAULT 'car',
  vehicle_data LONGTEXT NOT NULL,
  garage VARCHAR(64) NOT NULL DEFAULT 'legion',
  stored TINYINT(1) NOT NULL DEFAULT 1,
  impounded TINYINT(1) NOT NULL DEFAULT 0,
  nickname VARCHAR(64) DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_owner (owner),
  INDEX idx_owner_garage (owner, garage),
  INDEX idx_plate (plate)
);

-- ===== thootje-vehicles :: thootje_vehicles.sql =====
CREATE TABLE IF NOT EXISTS thootje_vehicle_keys (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    plate VARCHAR(12) NOT NULL,
    owner_identifier VARCHAR(100) NOT NULL,
    holder_identifier VARCHAR(100) NOT NULL,
    holder_name VARCHAR(100) NOT NULL,
    granted_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uniq_plate_holder (plate, holder_identifier),
    INDEX idx_holder (holder_identifier),
    INDEX idx_plate (plate)
);

-- ===== thootje-admin :: thootje_admin.sql =====
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

-- ===== thootje-phone :: thootje_phone.sql =====
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

-- ===== thootje-politiejob :: thootje_politiejob.sql =====
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

-- ===== thootje-ambulancejob :: thootje_ambulancejob.sql =====
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

-- ===== thootje-drugs :: thootje_drugs.sql =====
CREATE TABLE IF NOT EXISTS `thootje_drugs_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(80) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `action` VARCHAR(40) NOT NULL,
  `details` LONGTEXT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_identifier` (`identifier`),
  KEY `idx_action` (`action`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== thootje-pechhulpjob :: thootje_pechhulpjob.sql =====
CREATE TABLE IF NOT EXISTS thootje_pch_calls (
 id INT AUTO_INCREMENT PRIMARY KEY, caller_identifier VARCHAR(100) NOT NULL, caller_name VARCHAR(100), phone VARCHAR(30),
 plate VARCHAR(20), problem VARCHAR(120), details TEXT, x DOUBLE, y DOUBLE, z DOUBLE,
 status VARCHAR(20) DEFAULT 'open', staff_identifier VARCHAR(100), staff_name VARCHAR(100),
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, closed_at DATETIME NULL,
 INDEX(status), INDEX(plate), INDEX(caller_identifier)
);
CREATE TABLE IF NOT EXISTS thootje_pch_vehicles (
 plate VARCHAR(20) PRIMARY KEY, owner_identifier VARCHAR(100), model VARCHAR(80), mileage INT DEFAULT 0,
 last_service_km INT DEFAULT 0, next_service_km INT DEFAULT 5000, apk_expires DATETIME NULL,
 roadworthy TINYINT(1) DEFAULT 1, inspection_note TEXT, scrapped TINYINT(1) DEFAULT 0
);
CREATE TABLE IF NOT EXISTS thootje_pch_maintenance (
 id INT AUTO_INCREMENT PRIMARY KEY, plate VARCHAR(20), staff_identifier VARCHAR(100), staff_name VARCHAR(100),
 service_type VARCHAR(40), result VARCHAR(40), mileage INT DEFAULT 0, note TEXT,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, INDEX(plate)
);
CREATE TABLE IF NOT EXISTS thootje_pch_subscriptions (
 owner_identifier VARCHAR(100) PRIMARY KEY, plan VARCHAR(20) NOT NULL, expires_at DATETIME NOT NULL
);
CREATE TABLE IF NOT EXISTS thootje_pch_invoices (
 id INT AUTO_INCREMENT PRIMARY KEY, customer_identifier VARCHAR(100), customer_name VARCHAR(100),
 staff_identifier VARCHAR(100), staff_name VARCHAR(100), amount INT NOT NULL, description VARCHAR(180),
 status VARCHAR(20) DEFAULT 'open', created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== thootje-clothing :: thootje_clothing.sql =====
CREATE TABLE IF NOT EXISTS thootje_clothing_outfits (
  id INT NOT NULL AUTO_INCREMENT,
  owner_identifier VARCHAR(100) NOT NULL,
  name VARCHAR(32) NOT NULL,
  appearance LONGTEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_clothing_owner (owner_identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===== thootje-housing :: thootje_housing.sql =====
CREATE TABLE IF NOT EXISTS `thootje_housing_ownership` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `property_id` VARCHAR(64) NOT NULL,
  `owner_identifier` VARCHAR(100) NOT NULL,
  `owner_name` VARCHAR(100) NOT NULL,
  `purchase_type` ENUM('buy','rent') NOT NULL DEFAULT 'buy',
  `rent_until` BIGINT NULL DEFAULT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_property` (`property_id`),
  KEY `idx_owner` (`owner_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `thootje_housing_keys` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `property_id` VARCHAR(64) NOT NULL,
  `owner_identifier` VARCHAR(100) NOT NULL,
  `holder_identifier` VARCHAR(100) NOT NULL,
  `holder_name` VARCHAR(100) NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_property_holder` (`property_id`,`holder_identifier`),
  KEY `idx_holder` (`holder_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ===== thootje-shops :: thootje_shops.sql =====
CREATE TABLE IF NOT EXISTS `thootje_shop_transactions` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(100) NOT NULL,
  `player_name` VARCHAR(100) NOT NULL,
  `shop_id` VARCHAR(80) NOT NULL,
  `action` ENUM('buy','sell') NOT NULL,
  `item` VARCHAR(100) NOT NULL,
  `amount` INT NOT NULL,
  `total` INT NOT NULL,
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_identifier` (`identifier`),
  INDEX `idx_shop_id` (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ===== thootje-society :: thootje_society.sql =====
CREATE TABLE IF NOT EXISTS thootje_society_accounts (
  society VARCHAR(64) NOT NULL PRIMARY KEY,
  account_number VARCHAR(32) NOT NULL UNIQUE,
  balance BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS thootje_society_employees (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  society VARCHAR(64) NOT NULL,
  identifier VARCHAR(100) NOT NULL,
  player_name VARCHAR(100) NOT NULL,
  grade INT NOT NULL DEFAULT 0,
  salary INT NOT NULL DEFAULT 0,
  hired_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY unique_society_employee (society, identifier),
  INDEX idx_society (society)
);

CREATE TABLE IF NOT EXISTS thootje_society_transactions (
  id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  society VARCHAR(64) NOT NULL,
  actor_identifier VARCHAR(100) NOT NULL,
  actor_name VARCHAR(100) NOT NULL,
  transaction_type VARCHAR(24) NOT NULL,
  amount BIGINT NOT NULL,
  description VARCHAR(255) NOT NULL,
  balance_after BIGINT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_society_history (society, id)
);
