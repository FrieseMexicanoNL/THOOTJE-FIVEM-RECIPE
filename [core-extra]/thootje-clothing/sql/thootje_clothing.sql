CREATE TABLE IF NOT EXISTS thootje_clothing_outfits (
  id INT NOT NULL AUTO_INCREMENT,
  owner_identifier VARCHAR(100) NOT NULL,
  name VARCHAR(32) NOT NULL,
  appearance LONGTEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_clothing_owner (owner_identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
