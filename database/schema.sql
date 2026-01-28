-- =========================================
-- Carelia - PostgreSQL Schema (MPD)
-- =========================================

-- (Optionnel) Recréer proprement
-- DROP TABLE IF EXISTS audit_logs, stock_movements, reservation_items, reservations, products, categories, users CASCADE;

CREATE TABLE IF NOT EXISTS users (
  id              BIGSERIAL PRIMARY KEY,
  first_name      VARCHAR(100) NOT NULL,
  last_name       VARCHAR(100) NOT NULL,
  email           VARCHAR(150) NOT NULL UNIQUE,
  password_hash   VARCHAR(255) NOT NULL,
  role            VARCHAR(20)  NOT NULL,
  is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMP    NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_users_role CHECK (role IN ('CLIENT', 'EMPLOYEE', 'ADMIN'))
);

CREATE TABLE IF NOT EXISTS categories (
  id    BIGSERIAL PRIMARY KEY,
  name  VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS products (
  id              BIGSERIAL PRIMARY KEY,
  name            VARCHAR(150) NOT NULL,
  description     TEXT,
  brand           VARCHAR(100),
  price           NUMERIC(10,2) NOT NULL DEFAULT 0,
  stock_quantity  INTEGER NOT NULL DEFAULT 0,
  stock_threshold INTEGER NOT NULL DEFAULT 0,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  category_id     BIGINT NOT NULL,
  CONSTRAINT chk_products_price CHECK (price >= 0),
  CONSTRAINT chk_products_stock CHECK (stock_quantity >= 0),
  CONSTRAINT chk_products_threshold CHECK (stock_threshold >= 0),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id)
    REFERENCES categories(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS reservations (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT NOT NULL,         -- client
  status      VARCHAR(20) NOT NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP NOT NULL DEFAULT NOW(),
  handled_by  BIGINT NULL,             -- employé qui traite (optionnel)
  CONSTRAINT chk_reservations_status CHECK (status IN (
    'EN_ATTENTE', 'VALIDEE', 'REFUSEE', 'PRETE', 'RECUPEREE', 'ANNULEE'
  )),
  CONSTRAINT fk_reservations_user FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_reservations_handled_by FOREIGN KEY (handled_by)
    REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS reservation_items (
  id                BIGSERIAL PRIMARY KEY,
  reservation_id    BIGINT NOT NULL,
  product_id        BIGINT NOT NULL,
  quantity          INTEGER NOT NULL,
  unit_price_snapshot NUMERIC(10,2) NOT NULL,
  CONSTRAINT chk_reservation_items_qty CHECK (quantity > 0),
  CONSTRAINT chk_reservation_items_price CHECK (unit_price_snapshot >= 0),
  CONSTRAINT fk_items_reservation FOREIGN KEY (reservation_id)
    REFERENCES reservations(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_items_product FOREIGN KEY (product_id)
    REFERENCES products(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT uq_reservation_product UNIQUE (reservation_id, product_id)
);

CREATE TABLE IF NOT EXISTS stock_movements (
  id              BIGSERIAL PRIMARY KEY,
  product_id      BIGINT NOT NULL,
  quantity_change INTEGER NOT NULL,     -- +/- (ex: -2, +10)
  reason          VARCHAR(200) NOT NULL,
  created_by      BIGINT NOT NULL,      -- employé/admin
  created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_stock_movements_nonzero CHECK (quantity_change <> 0),
  CONSTRAINT fk_stock_product FOREIGN KEY (product_id)
    REFERENCES products(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_stock_created_by FOREIGN KEY (created_by)
    REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS audit_logs (
  id            BIGSERIAL PRIMARY KEY,
  actor_user_id BIGINT NOT NULL,
  action        VARCHAR(80) NOT NULL,
  entity_type   VARCHAR(40) NOT NULL,
  entity_id     BIGINT,
  meta          JSONB,
  created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
  CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id)
    REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);

-- Index utiles
CREATE INDEX IF NOT EXISTS idx_products_name ON products (name);
CREATE INDEX IF NOT EXISTS idx_products_category ON products (category_id);

CREATE INDEX IF NOT EXISTS idx_reservations_user ON reservations (user_id);
CREATE INDEX IF NOT EXISTS idx_reservations_status ON reservations (status);
CREATE INDEX IF NOT EXISTS idx_reservations_updated_at ON reservations (updated_at);

CREATE INDEX IF NOT EXISTS idx_items_reservation ON reservation_items (reservation_id);
CREATE INDEX IF NOT EXISTS idx_items_product ON reservation_items (product_id);

CREATE INDEX IF NOT EXISTS idx_stock_product ON stock_movements (product_id);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_logs (actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs (entity_type, entity_id);
