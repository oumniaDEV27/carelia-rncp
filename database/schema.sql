-- ============================
-- CARELIA RNCP - DATABASE SCHEMA
-- PostgreSQL 16
-- ============================

BEGIN;

-- Nettoyage (pratique en dev)
DROP TABLE IF EXISTS stock_movements CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS reservation_items CASCADE;
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================
-- 1) USERS
-- ============================
CREATE TABLE users (
  id            BIGSERIAL PRIMARY KEY,
  email         VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          VARCHAR(20)  NOT NULL,
  created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE users
ADD CONSTRAINT chk_users_role
CHECK (role IN ('CLIENT', 'EMPLOYEE', 'ADMIN'));

CREATE INDEX idx_users_role ON users(role);

-- ============================
-- 2) CATEGORIES
-- ============================
CREATE TABLE categories (
  id          BIGSERIAL PRIMARY KEY,
  name        VARCHAR(120) NOT NULL UNIQUE,
  created_at  TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now()
);

-- ============================
-- 3) PRODUCTS
-- ============================
CREATE TABLE products (
  id             BIGSERIAL PRIMARY KEY,
  name           VARCHAR(200) NOT NULL,
  description    TEXT,
  price          NUMERIC(10,2) NOT NULL,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  category_id    BIGINT REFERENCES categories(id) ON UPDATE CASCADE ON DELETE SET NULL,
  created_at     TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  updated_at     TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE products
ADD CONSTRAINT chk_products_price CHECK (price >= 0);

ALTER TABLE products
ADD CONSTRAINT chk_products_stock CHECK (stock_quantity >= 0);

CREATE INDEX idx_products_category ON products(category_id);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_products_updated_at ON products;
CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================
-- 4) RESERVATIONS
-- ============================
CREATE TABLE reservations (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  status     VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE',
  created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
  handled_by BIGINT REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL
);

-- Statuts EXACTS (ceux que tu as affichés dans ta contrainte)
ALTER TABLE reservations
ADD CONSTRAINT chk_reservations_status
CHECK (status IN ('EN_ATTENTE', 'VALIDEE', 'REFUSEE', 'PRETE', 'RECUPEREE', 'ANNULEE'));

CREATE INDEX idx_reservations_user ON reservations(user_id);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_updated_at ON reservations(updated_at);

DROP TRIGGER IF EXISTS trg_reservations_updated_at ON reservations;
CREATE TRIGGER trg_reservations_updated_at
BEFORE UPDATE ON reservations
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ============================
-- 5) RESERVATION ITEMS (panier multi-produits)
-- ============================
CREATE TABLE reservation_items (
  id                 BIGSERIAL PRIMARY KEY,
  reservation_id     BIGINT NOT NULL REFERENCES reservations(id) ON UPDATE CASCADE ON DELETE CASCADE,
  product_id         BIGINT NOT NULL REFERENCES products(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  quantity           INTEGER NOT NULL,
  unit_price_snapshot NUMERIC(10,2) NOT NULL
);

ALTER TABLE reservation_items
ADD CONSTRAINT chk_reservation_items_qty CHECK (quantity > 0);

ALTER TABLE reservation_items
ADD CONSTRAINT chk_reservation_items_price CHECK (unit_price_snapshot >= 0);

CREATE INDEX idx_items_reservation ON reservation_items(reservation_id);
CREATE INDEX idx_items_product ON reservation_items(product_id);

-- ============================
-- 6) STOCK MOVEMENTS (audit stock)
-- ============================
CREATE TABLE stock_movements (
  id            BIGSERIAL PRIMARY KEY,
  product_id    BIGINT NOT NULL REFERENCES products(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  delta         INTEGER NOT NULL,
  reason        VARCHAR(120) NOT NULL,
  actor_user_id BIGINT REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL,
  created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX idx_stock_product ON stock_movements(product_id);
CREATE INDEX idx_stock_actor ON stock_movements(actor_user_id);

-- ============================
-- 7) AUDIT LOGS (traçabilité actions)
-- ============================
CREATE TABLE audit_logs (
  id            BIGSERIAL PRIMARY KEY,
  actor_user_id BIGINT NOT NULL REFERENCES users(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  action        VARCHAR(80) NOT NULL,

  -- On garde les 2 pour compat (tu as eu le bug "entity" manquant)
  entity_type   VARCHAR(40) NOT NULL DEFAULT 'UNKNOWN',
  entity_id     BIGINT,
  entity        VARCHAR(50),
  details       JSONB,
  meta          JSONB,

  created_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_actor ON audit_logs(actor_user_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);

COMMIT;
