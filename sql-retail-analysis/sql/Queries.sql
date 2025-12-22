-- =========================================================
-- SQL Portfolio Project: Retail Sales & Payments Analysis
-- Database: MySQL
-- File: sql/queries.sql
-- =========================================================

-- =========================================================
-- A) Data Validation & Data Quality Checks
-- =========================================================

-- A1) Count records in each table
SELECT 'customers' AS table_name, COUNT(*) AS total_rows FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;

-- A2) Find orders without matching customer or product (data quality)
SELECT o.*
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN products  p ON p.product_id = o.product_id
WHERE c.customer_id IS NULL OR p.product_id IS NULL;

-- A3) Find payments without matching orders (data quality)
SELECT pay.*
FROM payments pay
LEFT JOIN orders o ON o.order_id = pay.order_id
WHERE o.order_id IS NULL;

-- A4) Orders that have no payment record (useful for collections/unpaid tracking)
SELECT
  o.order_id,
  o.customer_id,
  o.product_id,
  o.amount
FROM orders o
LEFT JOIN payments pay ON pay.order_id = o.order_id
WHERE pay.order_id IS NULL
ORDER BY o.order_id;


-- =========================================================
-- B) Core Sales Insights
-- =========================================================

-- B1) Total sales (all orders)
SELECT SUM(amount) AS total_sales
FROM orders;

-- B2) Total sales by city
SELECT
  c.city,
  SUM(o.amount) AS total_sales
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.city
ORDER BY total_sales DESC;

-- B3) Total sales by product category
SELECT
  p.category,
  SUM(o.amount) AS total_sales
FROM products p
JOIN orders o ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY total_sales DESC;

-- B4) Top 5 customers by total spending
SELECT
  c.customer_id,
  c.customer_name,
  SUM(o.amount) AS total_spent
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC
LIMIT 5;

-- B5) Top 5 products by revenue
SELECT
  p.product_id,
  p.product_name,
  SUM(o.amount) AS total_sales
FROM products p
JOIN orders o ON o.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_sales DESC
LIMIT 5;

-- B6) Average order amount overall
SELECT ROUND(AVG(amount), 2) AS avg_order_amount
FROM orders;

-- B7) City + Category sales matrix (great “business report” query)
SELECT
  c.city,
  p.category,
  SUM(o.amount) AS total_sales
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN products  p ON p.product_id = o.product_id
GROUP BY c.city, p.category
ORDER BY c.city, total_sales DESC;

-- B8) Customers who have never placed an order (subquery / NOT EXISTS)
SELECT
  c.customer_id,
  c.customer_name,
  c.city
FROM customers c
WHERE NOT EXISTS (
  SELECT 1
  FROM orders o
  WHERE o.customer_id = c.customer_id
);


-- =========================================================
-- C) Payments Analysis
-- =========================================================

-- C1) Payments by status
SELECT
  payment_status,
  COUNT(*) AS total_payments
FROM payments
GROUP BY payment_status
ORDER BY total_payments DESC;

-- C2) Revenue by payment status
SELECT
  pay.payment_status,
  SUM(o.amount) AS total_amount
FROM payments pay
JOIN orders o ON o.order_id = pay.order_id
GROUP BY pay.payment_status
ORDER BY total_amount DESC;

-- C3) Revenue by payment method
SELECT
  pay.payment_method,
  SUM(o.amount) AS total_amount
FROM payments pay
JOIN orders o ON o.order_id = pay.order_id
GROUP BY pay.payment_method
ORDER BY total_amount DESC;

-- C4) Completed revenue only (business KPI)
SELECT
  SUM(o.amount) AS completed_revenue
FROM payments pay
JOIN orders o ON o.order_id = pay.order_id
WHERE pay.payment_status = 'Completed';

-- C5) Payment status rate (percent of total payments)
SELECT
  payment_status,
  COUNT(*) AS total_payments,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) AS pct_of_payments
FROM payments
GROUP BY payment_status
ORDER BY total_payments DESC;

-- C6) Customers who have orders but NO payments (unpaid customers)
SELECT DISTINCT
  c.customer_id,
  c.customer_name,
  c.city
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE NOT EXISTS (
  SELECT 1
  FROM payments pay
  WHERE pay.order_id = o.order_id
);


-- =========================================================
-- D) Time Trends
-- =========================================================

-- D1) Monthly revenue trend (Completed only)
SELECT
  YEAR(pay.payment_date)  AS year,
  MONTH(pay.payment_date) AS month,
  SUM(o.amount) AS total_sales
FROM payments pay
JOIN orders o ON o.order_id = pay.order_id
WHERE pay.payment_status = 'Completed'
GROUP BY YEAR(pay.payment_date), MONTH(pay.payment_date)
ORDER BY year, month;

-- D2) Monthly payments count by status (trend of issues like Failed/Pending)
SELECT
  YEAR(payment_date) AS year,
  MONTH(payment_date) AS month,
  payment_status,
  COUNT(*) AS total_payments
FROM payments
GROUP BY YEAR(payment_date), MONTH(payment_date), payment_status
ORDER BY year, month, total_payments DESC;


-- =========================================================
-- E) Advanced Window Function Insights
-- =========================================================

-- E1) Top 2 customers per city by spending
SELECT *
FROM (
  SELECT
    c.city,
    c.customer_id,
    c.customer_name,
    SUM(o.amount) AS total_spent,
    ROW_NUMBER() OVER (
      PARTITION BY c.city
      ORDER BY SUM(o.amount) DESC
    ) AS rn
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
  GROUP BY c.city, c.customer_id, c.customer_name
) t
WHERE rn <= 2
ORDER BY city, total_spent DESC;

-- E2) Each customer’s % contribution to total sales
SELECT
  c.customer_id,
  c.customer_name,
  SUM(o.amount) AS customer_total,
  ROUND(
    100.0 * SUM(o.amount) / SUM(SUM(o.amount)) OVER (),
    2
  ) AS pct_of_total_sales
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY customer_total DESC;

-- E3) Rank categories by revenue
SELECT
  category,
  total_sales,
  RANK() OVER (ORDER BY total_sales DESC) AS category_rank
FROM (
  SELECT
    p.category,
    SUM(o.amount) AS total_sales
  FROM products p
  JOIN orders o ON o.product_id = p.product_id
  GROUP BY p.category
) t;

-- E4) Running total of completed revenue over time (by payment date)
SELECT
  pay.payment_date,
  SUM(o.amount) AS daily_sales,
  SUM(SUM(o.amount)) OVER (ORDER BY pay.payment_date) AS running_total_sales
FROM payments pay
JOIN orders o ON o.order_id = pay.order_id
WHERE pay.payment_status = 'Completed'
GROUP BY pay.payment_date
ORDER BY pay.payment_date;

-- E5) Identify “repeat customers” (customers with 2+ orders) and rank by spending
SELECT
  customer_id,
  customer_name,
  total_orders,
  total_spent,
  DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM (
  SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.amount) AS total_spent
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
  GROUP BY c.customer_id, c.customer_name
  HAVING COUNT(o.order_id) >= 2
) t
ORDER BY spending_rank;


-- =========================================================
-- F) Executive Summary Report
-- =========================================================

-- F1) City totals + grand total (ROLLUP)
SELECT
  IFNULL(c.city, 'ALL CITIES') AS city,
  SUM(o.amount) AS total_sales
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.city WITH ROLLUP;

-- F2) Category totals + grand total (ROLLUP)
SELECT
  IFNULL(p.category, 'ALL CATEGORIES') AS category,
  SUM(o.amount) AS total_sales
FROM products p
JOIN orders o ON o.product_id = p.product_id
GROUP BY p.category WITH ROLLUP;
