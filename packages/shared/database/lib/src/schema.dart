/// Schema DDL, version 1.
///
/// Each statement is executed separately in `onCreate`. Migrations for
/// future versions are applied in `MarketDatabase._onUpgrade`.
class Schema {
  const Schema._();

  static const int version = 1;

  static const List<String> createStatements = <String>[
    '''
CREATE TABLE users (
  id            TEXT PRIMARY KEY,
  full_name     TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE,
  phone         TEXT,
  avatar_path   TEXT,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  created_at    INTEGER NOT NULL
)''',
    '''
CREATE TABLE categories (
  id    TEXT PRIMARY KEY,
  code  TEXT NOT NULL UNIQUE,
  name  TEXT NOT NULL
)''',
    '''
CREATE TABLE products (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  description  TEXT NOT NULL,
  price        REAL NOT NULL CHECK (price >= 0),
  stock        INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  category_id  TEXT NOT NULL REFERENCES categories(id),
  image_path   TEXT,
  condition    TEXT NOT NULL DEFAULT 'NEW',
  status       TEXT NOT NULL DEFAULT 'ACTIVE',
  owner_id     TEXT NOT NULL REFERENCES users(id),
  created_at   INTEGER NOT NULL,
  updated_at   INTEGER NOT NULL
)''',
    'CREATE INDEX idx_products_category ON products(category_id)',
    'CREATE INDEX idx_products_owner    ON products(owner_id)',
    '''
CREATE TABLE favorites (
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, product_id)
)''',
    '''
CREATE TABLE cart_items (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity   INTEGER NOT NULL CHECK (quantity > 0),
  added_at   INTEGER NOT NULL,
  UNIQUE (user_id, product_id)
)''',
    'CREATE INDEX idx_cart_user ON cart_items(user_id)',
    '''
CREATE TABLE addresses (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label      TEXT NOT NULL,
  line1      TEXT NOT NULL,
  city       TEXT NOT NULL,
  state      TEXT NOT NULL,
  notes      TEXT,
  is_default INTEGER NOT NULL DEFAULT 0
)''',
    '''
CREATE TABLE coupons (
  code            TEXT PRIMARY KEY,
  discount_pct    REAL NOT NULL CHECK (discount_pct > 0 AND discount_pct <= 50),
  min_amount      REAL NOT NULL DEFAULT 0,
  valid_until     INTEGER NOT NULL,
  is_active       INTEGER NOT NULL DEFAULT 1
)''',
    '''
CREATE TABLE orders (
  id             TEXT PRIMARY KEY,
  user_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  address_id     TEXT REFERENCES addresses(id),
  coupon_code    TEXT REFERENCES coupons(code),
  subtotal       REAL NOT NULL,
  discount       REAL NOT NULL DEFAULT 0,
  tax            REAL NOT NULL,
  total          REAL NOT NULL,
  payment_method TEXT NOT NULL,
  status         TEXT NOT NULL,
  created_at     INTEGER NOT NULL
)''',
    'CREATE INDEX idx_orders_user ON orders(user_id)',
    '''
CREATE TABLE order_items (
  id          TEXT PRIMARY KEY,
  order_id    TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id  TEXT NOT NULL REFERENCES products(id),
  name        TEXT NOT NULL,
  unit_price  REAL NOT NULL,
  quantity    INTEGER NOT NULL CHECK (quantity > 0)
)''',
    '''
CREATE TABLE reviews (
  id         TEXT PRIMARY KEY,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating     INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment    TEXT,
  created_at INTEGER NOT NULL,
  UNIQUE (product_id, user_id)
)''',
    '''
CREATE TABLE notifications (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       TEXT NOT NULL,
  title_key  TEXT NOT NULL,
  body_key   TEXT NOT NULL,
  payload    TEXT,
  is_read    INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
)''',
    '''
CREATE TABLE search_history (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  term       TEXT NOT NULL,
  created_at INTEGER NOT NULL
)''',
  ];
}
