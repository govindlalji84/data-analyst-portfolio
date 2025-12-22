-- =========================================================
-- SQL Portfolio Project: Retail Sales & Payments Analysis
-- Database: MySQL
-- File: schema.sql
-- =========================================================

-- (Optional) Create and use a dedicated database
-- CREATE DATABASE IF NOT EXISTS retail_sql_portfolio;
-- USE retail_sql_portfolio;

-- Clean start
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================
-- 1) customers
-- =========================
CREATE TABLE customers (
  customer_id   INT          NOT NULL,
  customer_name VARCHAR(50)  NULL,
  city          VARCHAR(50)  NULL,
  PRIMARY KEY (customer_id)
);

-- =========================
-- 2) products
-- =========================
CREATE TABLE products (
  product_id    INT          NOT NULL,
  product_name  VARCHAR(50)  NULL,
  category      VARCHAR(50)  NULL,
  PRIMARY KEY (product_id)
);

-- =========================
-- 3) orders
-- =========================
CREATE TABLE orders (
  order_id     INT           NOT NULL,
  customer_id  INT           NULL,
  product_id   INT           NULL,
  amount       DECIMAL(10,2) NULL,
  PRIMARY KEY (order_id),
  CONSTRAINT fk_orders_customers
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_orders_products
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- =========================
-- 4) payments
-- =========================
CREATE TABLE payments (
  payment_id      INT          NOT NULL,
  order_id        INT          NULL,
  payment_method  VARCHAR(30)  NULL,
  payment_date    DATE         NULL,
  payment_status  VARCHAR(20)  NULL,
  PRIMARY KEY (payment_id),
  CONSTRAINT fk_payments_orders
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- =========================================================
-- INSERT SAMPLE DATA
-- =========================================================

-- customers (10)
INSERT INTO customers (customer_id, customer_name, city) VALUES
(1,  'Noah Smith',     'Rochester Hills'),
(2,  'Olivia Johnson',     'Troy'),
(3,  'Liam Williams',     'Auburn Hills'),
(4,  'Amelia Brown',     'Detroit'),
(5,  'Vikram Joshi',    'Sterling Heights'),
(6,  'Oliver Jones',    'Bloomfield Hills'),
(7,  'Kunal Bhatt',     'Warren'),
(8,  'Isha Sharma',     'Farmington Hills'),
(9,  'Rahul Mehta',      'Novi'),
(10, 'Sophia Garcia',      'Ann Arbor');

-- products (8)
INSERT INTO products (product_id, product_name, category) VALUES
(101, 'Wireless Mouse',        'Electronics'),
(102, 'Mechanical Keyboard',   'Electronics'),
(103, 'USB-C Charger',         'Electronics'),
(104, 'Notebook A5',           'Stationery'),
(105, 'Gel Pen Pack',          'Stationery'),
(106, 'Water Bottle 1L',       'Home & Kitchen'),
(107, 'Desk Lamp',             'Home & Kitchen'),
(108, 'Backpack 20L',          'Accessories');

-- orders (20)
-- (amount is kept simple; you can treat it as "order total")
INSERT INTO orders (order_id, customer_id, product_id, amount) VALUES
(1001, 1,  101, 25.99),
(1002, 1,  104,  6.49),
(1003, 2,  102, 89.99),
(1004, 2,  103, 19.99),
(1005, 3,  108, 39.99),
(1006, 3,  105,  8.99),
(1007, 4,  107, 29.99),
(1008, 4,  106, 14.99),
(1009, 5,  102, 94.99),
(1010, 5,  101, 22.99),
(1011, 6,  103, 21.99),
(1012, 6,  107, 34.99),
(1013, 7,  104,  5.99),
(1014, 7,  108, 44.99),
(1015, 8,  106, 12.99),
(1016, 8,  105,  9.49),
(1017, 9,  101, 24.99),
(1018, 9,  102, 92.49),
(1019, 10, 103, 18.49),
(1020, 10, 107, 31.49);

-- payments (18)
-- Some orders intentionally have no payment to support "unpaid orders" analysis.
-- payment_status values: Completed, Pending, Failed, Refunded
INSERT INTO payments (payment_id, order_id, payment_method, payment_date, payment_status) VALUES
(5001, 1001, 'Credit Card',   '2025-01-05', 'Completed'),
(5002, 1002, 'Cash',          '2025-01-06', 'Completed'),
(5003, 1003, 'Debit Card',    '2025-01-07', 'Completed'),
(5004, 1004, 'Credit Card',   '2025-01-07', 'Completed'),
(5005, 1005, 'PayPal',        '2025-01-10', 'Completed'),
(5006, 1006, 'Cash',          '2025-01-10', 'Completed'),
(5007, 1007, 'Credit Card',   '2025-02-02', 'Completed'),
(5008, 1008, 'Debit Card',    '2025-02-02', 'Completed'),
(5009, 1009, 'Credit Card',   '2025-02-15', 'Pending'),
(5010, 1010, 'Cash',          '2025-02-16', 'Completed'),
(5011, 1011, 'Credit Card',   '2025-03-03', 'Completed'),
(5012, 1012, 'PayPal',        '2025-03-04', 'Failed'),
(5013, 1013, 'Cash',          '2025-03-10', 'Completed'),
(5014, 1014, 'Credit Card',   '2025-03-11', 'Completed'),
(5015, 1015, 'Debit Card',    '2025-04-01', 'Completed'),
(5016, 1016, 'Credit Card',   '2025-04-02', 'Refunded'),
(5017, 1017, 'PayPal',        '2025-04-10', 'Completed'),
(5018, 1018, 'Credit Card',   '2025-04-12', 'Completed');

-- Quick sanity checks
SELECT 'customers' AS table_name, COUNT(*) AS rows_count FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'payments', COUNT(*) FROM payments;

-- Helpful check: orders with no payment (should return a few rows)
SELECT o.order_id, o.customer_id, o.product_id, o.amount
FROM orders o
LEFT JOIN payments p ON p.order_id = o.order_id
WHERE p.order_id IS NULL;
