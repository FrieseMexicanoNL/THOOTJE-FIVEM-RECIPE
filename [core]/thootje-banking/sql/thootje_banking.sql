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
