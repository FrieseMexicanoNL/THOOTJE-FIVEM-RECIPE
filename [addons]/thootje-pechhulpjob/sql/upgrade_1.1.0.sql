-- THOOTJE-PECHHULPJOB 1.1.0 database upgrade
ALTER TABLE thootje_pch_vehicles
  ADD COLUMN IF NOT EXISTS scrapped TINYINT(1) NOT NULL DEFAULT 0;
ALTER TABLE thootje_pch_invoices
  ADD COLUMN IF NOT EXISTS billing_status VARCHAR(30) NOT NULL DEFAULT 'local_only';
