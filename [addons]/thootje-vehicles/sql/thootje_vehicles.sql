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
