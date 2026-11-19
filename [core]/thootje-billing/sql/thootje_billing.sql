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
