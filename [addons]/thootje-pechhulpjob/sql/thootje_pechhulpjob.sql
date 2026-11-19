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
