-- THOOTJE-BILLING 1.1.0 migration for existing databases.
-- Run once if thootje_billing_invoices already exists.
ALTER TABLE `thootje_billing_invoices`
  ADD COLUMN `no_payout` TINYINT(1) NOT NULL DEFAULT 0;
