-- =========================================
-- Carelia - Seed data
-- Password for seeded users: Password123!
-- (bcrypt hash)
-- =========================================

-- Nettoyage soft (si tu relances le seed)
DELETE FROM audit_logs;
DELETE FROM stock_movements;
DELETE FROM reservation_items;
DELETE FROM reservations;
DELETE FROM products;
DELETE FROM categories;
DELETE FROM users;

-- Catégories
INSERT INTO categories (name) VALUES
  ('Soins du visage'),
  ('Soins du corps'),
  ('Cheveux'),
  ('Bébé'),
  ('Compléments alimentaires'),
  ('Hygiène');

-- Produits (exemples)
INSERT INTO products (name, description, brand, price, stock_quantity, stock_threshold, is_active, category_id)
VALUES
  ('Gel nettoyant doux', 'Nettoie sans agresser, peau sensible.', 'Carelia', 9.90, 25, 5, TRUE, (SELECT id FROM categories WHERE name='Soins du visage')),
  ('Crème hydratante', 'Hydratation 24h, texture légère.', 'Carelia', 14.50, 18, 5, TRUE, (SELECT id FROM categories WHERE name='Soins du visage')),
  ('Shampooing fortifiant', 'Renforce et protège la fibre capillaire.', 'Carelia', 11.20, 12, 3, TRUE, (SELECT id FROM categories WHERE name='Cheveux')),
  ('Baume réparateur', 'Répare les zones sèches.', 'Carelia', 8.70, 7, 3, TRUE, (SELECT id FROM categories WHERE name='Soins du corps')),
  ('Liniment bébé', 'Nettoyant doux pour le change.', 'Carelia', 6.90, 10, 2, TRUE, (SELECT id FROM categories WHERE name='Bébé')),
  ('Vitamine C 1000', 'Complément alimentaire vitamine C.', 'Carelia', 12.90, 5, 2, TRUE, (SELECT id FROM categories WHERE name='Compléments alimentaires')),
  ('Gel hydroalcoolique', 'Hygiène des mains.', 'Carelia', 3.50, 30, 10, TRUE, (SELECT id FROM categories WHERE name='Hygiène'));

-- Utilisateurs (3 comptes tests)
-- Mot de passe: Password123!
-- Hash bcrypt (Password123!)
INSERT INTO users (first_name, last_name, email, password_hash, role, is_active)
VALUES
  ('Admin', 'Carelia', 'admin@carelia.local',
   '$2b$10$SLoJ.34wF1b6Cc8x7PMJKuKtmG24OiUlRbOJiVZ1JqhUfU2PsrFBy',
   'ADMIN', TRUE),

  ('Emma',  'Client',  'client@carelia.local',
   '$2b$10$SLoJ.34wF1b6Cc8x7PMJKuKtmG24OiUlRbOJiVZ1JqhUfU2PsrFBy',
   'CLIENT', TRUE),

  ('Karim', 'Employe', 'employe@carelia.local',
   '$2b$10$SLoJ.34wF1b6Cc8x7PMJKuKtmG24OiUlRbOJiVZ1JqhUfU2PsrFBy',
   'EMPLOYEE', TRUE);

-- Exemple d'audit (optionnel)
INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, meta)
VALUES (
  (SELECT id FROM users WHERE email='admin@carelia.local'),
  'SEED_INIT',
  'SYSTEM',
  NULL,
  '{"message":"Initialisation des données de démonstration"}'::jsonb
);
