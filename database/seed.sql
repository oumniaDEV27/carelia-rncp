-- ============================
-- CARELIA RNCP - SEED DATA
-- ============================

BEGIN;

-- Nettoyage (ordre important à cause des FK)
DELETE FROM reservation_items;
DELETE FROM reservations;
DELETE FROM stock_movements;
DELETE FROM audit_logs;
DELETE FROM products;
DELETE FROM categories;
DELETE FROM users;

-- Reset des séquences (optionnel mais propre en dev)
SELECT setval(pg_get_serial_sequence('users','id'), 1, false);
SELECT setval(pg_get_serial_sequence('categories','id'), 1, false);
SELECT setval(pg_get_serial_sequence('products','id'), 1, false);
SELECT setval(pg_get_serial_sequence('reservations','id'), 1, false);
SELECT setval(pg_get_serial_sequence('reservation_items','id'), 1, false);
SELECT setval(pg_get_serial_sequence('audit_logs','id'), 1, false);
SELECT setval(pg_get_serial_sequence('stock_movements','id'), 1, false);

-- Catégories
INSERT INTO categories (name) VALUES
('Soins'),
('Beauté'),
('Santé'),
('Bébé');

-- Users
-- ✅ Remplace __BCRYPT_HASH__ par le hash bcrypt généré
INSERT INTO users (email, password_hash, role) VALUES
('admin@carelia.local',    '__BCRYPT_HASH__', 'ADMIN'),
('employee@carelia.local', '__BCRYPT_HASH__', 'EMPLOYEE'),
('client@carelia.local',   '__BCRYPT_HASH__', 'CLIENT');

-- Produits
INSERT INTO products (name, description, price, stock_quantity, category_id) VALUES
('Crème hydratante', 'Crème visage hydratante', 12.90, 50, 2),
('Gel douche', 'Gel douche doux', 4.50, 100, 2),
('Sérum vitamine C', 'Sérum anti-oxydant', 19.90, 30, 2),
('Désinfectant', 'Spray désinfectant', 6.99, 60, 3),
('Coton', 'Coton démaquillant', 2.50, 200, 2),
('Thermomètre', 'Thermomètre digital', 9.99, 25, 3);

-- Audit init (actor_user_id obligatoire => on prend l'admin)
INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, entity, details, meta)
VALUES (
  (SELECT id FROM users WHERE email = 'admin@carelia.local' LIMIT 1),
  'SEED_INIT',
  'SYSTEM',
  NULL,
  'SYSTEM',
  '{"message":"Initialisation des données de démonstration"}'::jsonb,
  '{"source":"seed.sql"}'::jsonb
);

COMMIT;
