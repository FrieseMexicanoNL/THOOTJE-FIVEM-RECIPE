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
