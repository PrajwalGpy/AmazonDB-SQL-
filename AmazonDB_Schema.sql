-- DROP tables if exist (reverse order to satisfy FK dependencies)
DROP TABLE IF EXISTS order_items CASCADE;

DROP TABLE IF EXISTS payments CASCADE;

DROP TABLE IF EXISTS shippings CASCADE;

DROP TABLE IF EXISTS inventory CASCADE;

DROP TABLE IF EXISTS orders CASCADE;

DROP TABLE IF EXISTS products CASCADE;

DROP TABLE IF EXISTS sellers CASCADE;

DROP TABLE IF EXISTS customers CASCADE;

DROP TABLE IF EXISTS category CASCADE;

-- 1. category (parent)
CREATE TABLE category (
    category_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL
);

-- 2. customers (parent)
CREATE TABLE customers (
    customer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50),
    state VARCHAR(50),
    address VARCHAR(255) NOT NULL DEFAULT 'XXX'
);

-- 3. sellers (parent)
CREATE TABLE sellers (
    seller_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_name VARCHAR(100) NOT NULL,
    origin VARCHAR(50)
);

-- 4. products (child -> category)
CREATE TABLE products (
    product_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    cogs NUMERIC(10, 2) CHECK (cogs >= 0),
    category_id INTEGER NOT NULL,
    CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES category (category_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX idx_products_category_id ON products(category_id);

-- 5. orders (references customers, sellers)
CREATE TABLE orders (
    order_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_date DATE NOT NULL,
    customer_id INTEGER NOT NULL,
    seller_id INTEGER NOT NULL,
    order_status VARCHAR(30) NOT NULL,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers (customer_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_orders_seller FOREIGN KEY (seller_id) REFERENCES sellers (seller_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX idx_orders_customer_id ON orders(customer_id);

CREATE INDEX idx_orders_seller_id ON orders(seller_id);

CREATE INDEX idx_orders_order_date ON orders(order_date);

-- 6. order_items (child -> orders, products)
CREATE TABLE order_items (
    order_item_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price_at_purchase NUMERIC(10, 2) NOT NULL CHECK (price_at_purchase >= 0),
    total_sale NUMERIC(12, 2) GENERATED ALWAYS AS (quantity * price_at_purchase) STORED,
    CONSTRAINT fk_orderitems_order FOREIGN KEY (order_id) REFERENCES orders (order_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_orderitems_product FOREIGN KEY (product_id) REFERENCES products (product_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX idx_orderitems_order_id ON order_items(order_id);

CREATE INDEX idx_orderitems_product_id ON order_items(product_id);

-- 7. payments (child -> orders)
CREATE TABLE payments (
    payment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INTEGER NOT NULL,
    payment_date DATE NOT NULL,
    payment_status VARCHAR(30) NOT NULL,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders (order_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX idx_payments_order_id ON payments(order_id);

CREATE INDEX idx_payments_payment_date ON payments(payment_date);

-- 8. shippings (child -> orders)
CREATE TABLE shippings (
    shipping_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id INTEGER NOT NULL,
    shipping_date DATE,
    return_date DATE,
    shipping_providers VARCHAR(50),
    delivery_status VARCHAR(30),
    CONSTRAINT fk_shippings_order FOREIGN KEY (order_id) REFERENCES orders (order_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX idx_shippings_order_id ON shippings(order_id);

CREATE INDEX idx_shippings_shipping_date ON shippings(shipping_date);

-- 9. inventory (child -> products)
CREATE TABLE inventory (
    inventory_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id INTEGER NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    warehouse_id INTEGER,
    last_stock_date DATE,
    CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES products (product_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX idx_inventory_product_id ON inventory(product_id);

-- Optional helpful constraints / sample checks (uncomment if needed)
-- ALTER TABLE payments ADD CONSTRAINT chk_payment_status CHECK (payment_status IN ('confirmed','failed','refunded','pending'));
-- ALTER TABLE orders ADD CONSTRAINT chk_order_status CHECK (order_status IN ('delivered','shipped','processing','cancelled','returned'));
-- End of DDL