-- ============================================================
-- Restoran İşletim Sistemi - PostgreSQL Veritabanı Şeması
-- QR Tabanlı Sipariş ve Yönetim Platformu
-- ============================================================

-- ------------------------------------------------------------
-- 0. EXTENSIONS
-- ------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto"; -- gen_random_uuid() için

-- ------------------------------------------------------------
-- 1. ENUM TİPLERİ
-- ------------------------------------------------------------
CREATE TYPE user_role AS ENUM ('ADMIN', 'YONETICI', 'GARSON', 'MUTFAK');

CREATE TYPE order_status AS ENUM (
    'PENDING',      -- Alındı
    'APPROVED',     -- Onaylandı (garson onaylı sipariş modunda)
    'PREPARING',    -- Hazırlanıyor
    'READY',        -- Hazır
    'DELIVERED',    -- Teslim Edildi / Servis Edildi
    'CANCELLED'     -- İptal
);

CREATE TYPE product_status AS ENUM ('AVAILABLE', 'OUT_OF_STOCK');

CREATE TYPE order_mode AS ENUM ('DIRECT', 'WAITER_APPROVAL'); -- Direkt sipariş / Garson onaylı sipariş

CREATE TYPE staff_call_type AS ENUM ('CALL_WAITER', 'REQUEST_BILL', 'REQUEST_WATER_NAPKIN');

-- ------------------------------------------------------------
-- 2. RESTORANLAR (çok kiracılı yapı için temel tablo)
-- ------------------------------------------------------------
CREATE TABLE restaurants (
    id          BIGSERIAL PRIMARY KEY,
    name        VARCHAR(150) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- 3. KULLANICILAR (Admin, Yönetici, Garson, Mutfak)
-- ------------------------------------------------------------
CREATE TABLE users (
    id              BIGSERIAL PRIMARY KEY,
    restaurant_id   BIGINT NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    role            user_role NOT NULL,
    full_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_restaurant ON users(restaurant_id);

-- ------------------------------------------------------------
-- 4. MASALAR (QR Oturum Mimarisi)
-- ------------------------------------------------------------
CREATE TABLE tables (
    id                  BIGSERIAL PRIMARY KEY,
    restaurant_id       BIGINT NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    table_number        VARCHAR(20) NOT NULL,
    qr_code             VARCHAR(100) NOT NULL UNIQUE,
    current_session_id  UUID, -- aktif "Ortak QR Oturumu" (group ordering) - oturum kapanınca NULL
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (restaurant_id, table_number)
);

CREATE INDEX idx_tables_restaurant ON tables(restaurant_id);
CREATE INDEX idx_tables_session ON tables(current_session_id);

-- ------------------------------------------------------------
-- 5. AYARLAR (Settings)
-- ------------------------------------------------------------
CREATE TABLE settings (
    id              BIGSERIAL PRIMARY KEY,
    restaurant_id   BIGINT NOT NULL UNIQUE REFERENCES restaurants(id) ON DELETE CASCADE,
    language        VARCHAR(5) NOT NULL DEFAULT 'TR', -- TR, EN, DE, AR
    order_mode      order_mode NOT NULL DEFAULT 'DIRECT',
    extra_settings  JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------
-- 6. KATEGORİLER
-- ------------------------------------------------------------
CREATE TABLE categories (
    id              BIGSERIAL PRIMARY KEY,
    restaurant_id   BIGINT NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_categories_restaurant ON categories(restaurant_id);

-- ------------------------------------------------------------
-- 7. ÜRÜNLER
-- ------------------------------------------------------------
CREATE TABLE products (
    id              BIGSERIAL PRIMARY KEY,
    category_id     BIGINT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    name            VARCHAR(150) NOT NULL,
    description     TEXT,
    price           NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    image_url       TEXT,
    allergen_info   TEXT,
    status          product_status NOT NULL DEFAULT 'AVAILABLE',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_status ON products(status);

-- ------------------------------------------------------------
-- 8. ÜRÜN OPSİYONLARI (Boyut, Ekstralar)
-- ------------------------------------------------------------
CREATE TABLE product_options (
    id              BIGSERIAL PRIMARY KEY,
    product_id      BIGINT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    option_group    VARCHAR(50) NOT NULL, -- ör. 'Boyut', 'Ekstra', 'Sos'
    name            VARCHAR(100) NOT NULL, -- ör. 'Büyük Boy', 'Ekstra Peynir'
    price_modifier  NUMERIC(10, 2) NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_product_options_product ON product_options(product_id);

-- ------------------------------------------------------------
-- 9. SİPARİŞLER
-- ------------------------------------------------------------
CREATE TABLE orders (
    id              BIGSERIAL PRIMARY KEY,
    restaurant_id   BIGINT NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    table_id        BIGINT NOT NULL REFERENCES tables(id) ON DELETE RESTRICT,
    session_id      UUID NOT NULL,
    status          order_status NOT NULL DEFAULT 'PENDING',
    total_price     NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (total_price >= 0),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_table_session ON orders(table_id, session_id);

-- ------------------------------------------------------------
-- 10. SİPARİŞ KALEMLERİ
-- ------------------------------------------------------------
CREATE TABLE order_items (
    id                  BIGSERIAL PRIMARY KEY,
    order_id            BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id          BIGINT NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity            INTEGER NOT NULL CHECK (quantity > 0),
    unit_price          NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0), -- sipariş anındaki fiyat, backend'de products.price'tan doldurulur
    selected_options    JSONB NOT NULL DEFAULT '[]'::jsonb, -- [{ "name": "Ekstra Peynir", "price_modifier": 10.0 }, ...]
    note                TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- ------------------------------------------------------------
-- 11. GARSON ÇAĞRI / HIZLI AKSİYONLAR
-- ------------------------------------------------------------
CREATE TABLE staff_calls (
    id              BIGSERIAL PRIMARY KEY,
    restaurant_id   BIGINT NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
    table_id        BIGINT NOT NULL REFERENCES tables(id) ON DELETE CASCADE,
    call_type       staff_call_type NOT NULL,
    is_resolved     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at     TIMESTAMPTZ
);

CREATE INDEX idx_staff_calls_table ON staff_calls(table_id);
CREATE INDEX idx_staff_calls_unresolved ON staff_calls(restaurant_id, is_resolved) WHERE is_resolved = FALSE;

-- ------------------------------------------------------------
-- 12. updated_at OTOMATİK GÜNCELLEME (trigger)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_restaurants_updated_at
    BEFORE UPDATE ON restaurants
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

