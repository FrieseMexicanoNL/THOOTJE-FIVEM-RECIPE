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
