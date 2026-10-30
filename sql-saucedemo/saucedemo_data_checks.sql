-- Saucedemo: SQL data integrity checks
-- Author: Olena Kerenykevych
-- DBMS: MS SQL Server (tested on dbfiddle.uk)
-- Part 1 creates the database and test data, part 2 contains the checks.

-- =========================================================
-- PART 1. Schema and test data
-- =========================================================

CREATE TABLE users (
  id INT PRIMARY KEY,
  username NVARCHAR(50),
  password_hash NVARCHAR(255),
  status NVARCHAR(20),
  created_at DATE
);

INSERT INTO users VALUES
(1, 'standard_user',           'a8f5f167f44f4964e6c998dee827110c', 'active', '2026-01-10'),
(2, 'locked_out_user',         'a8f5f167f44f4964e6c998dee827110c', 'locked', '2026-01-12'),
(3, 'problem_user',            'a8f5f167f44f4964e6c998dee827110c', 'active', '2026-02-01'),
(4, 'performance_glitch_user', 'a8f5f167f44f4964e6c998dee827110c', 'active', '2026-02-15'),
(5, 'error_user',              'a8f5f167f44f4964e6c998dee827110c', 'active', '2026-03-03'),
(6, 'visual_user',             'a8f5f167f44f4964e6c998dee827110c', 'active', '2026-03-20'),
(7, 'standard_user',           'a8f5f167f44f4964e6c998dee827110c', 'active', '2026-04-08'),
(8, 'test_user',               NULL,                               'active', '2026-05-11'),
(9, '',                        'a8f5f167f44f4964e6c998dee827110c', 'active', '2026-06-02');

CREATE TABLE products (
  id INT PRIMARY KEY,
  name NVARCHAR(100),
  price DECIMAL(10,2)
);

INSERT INTO products VALUES
(1, 'Sauce Labs Backpack', 29.99),
(2, 'Sauce Labs Bike Light', 9.99),
(3, 'Sauce Labs Bolt T-Shirt', 15.99),
(4, 'Sauce Labs Fleece Jacket', 49.99),
(5, 'Sauce Labs Onesie', 7.99),
(6, 'Test.allTheThings() T-Shirt (Red)', 0.00);

CREATE TABLE orders (
  id INT PRIMARY KEY,
  user_id INT,
  first_name NVARCHAR(100),
  last_name NVARCHAR(100),
  postal_code NVARCHAR(10),
  item_total DECIMAL(10,2),
  tax DECIMAL(10,2),
  total DECIMAL(10,2),
  order_date DATE
);

INSERT INTO orders VALUES
(1,  1,  'Anna',   'Koval',     '01001', 29.99, 2.40, 32.39, '2026-03-05'),
(2,  3,  'Ivan',   'Melnyk',    '79000', 27.97, 2.24, 30.21, '2026-03-18'),
(3,  2,  'Oksana', 'Bondar',    '65000', 15.99, 1.28, 17.27, '2026-04-02'),
(4,  4,  NULL,     'Shevchuk',  '61000', 49.99, 4.00, 53.99, '2026-04-20'),
(5,  5,  'Petro',  'Tkachenko', '',      39.98, 3.20, 43.18, '2026-05-07'),
(6,  6,  'Iryna',  'Lysenko',   '49000', 15.99, 1.28, 17.27, '2026-05-25'),
(7,  1,  'Anna',   'Koval',     '01001', 23.97, 1.80, 25.77, '2026-06-14'),
(8,  3,  'Ivan',   'Melnyk',    '79000', 79.98, 6.40, 79.98, '2026-07-01'),
(9,  15, 'Taras',  'Hrytsenko', '21000',  9.99, 0.80, 10.79, '2026-07-19'),
(10, 4,  'Olha',   'Shevchuk',  '61000', 12.99, 1.04, 14.03, '2026-08-08'),
(11, 1,  'Anna',   'Koval',     '01001', 65.97, 5.28, 71.25, '2026-09-12');

CREATE TABLE order_items (
  id INT PRIMARY KEY,
  order_id INT,
  product_id INT,
  quantity INT
);

INSERT INTO order_items VALUES
(1, 1, 1, 1),
(2, 2, 2, 2),
(3, 2, 5, 1),
(4, 3, 3, 1),
(5, 4, 4, 1),
(6, 5, 1, 1),
(7, 5, 2, 1),
(8, 6, 3, 2),
(9, 7, 5, 3),
(10, 8, 4, 1),
(11, 8, 1, 1),
(12, 9, 2, 1),
(13, 10, 9, 1),
(14, 11, 4, 1),
(15, 11, 5, 2);

-- =========================================================
-- PART 2. Checks
-- =========================================================

-- =========================================================
-- Rule 1. Username is unique and required. Password is required.
-- =========================================================

-- 1.1 Duplicate usernames
SELECT id, username
FROM users
WHERE username IN (
    SELECT username
    FROM users
    GROUP BY username
    HAVING COUNT(*) > 1
)
ORDER BY username, id;

-- 1.2 Missing username (NULL or empty string)
SELECT id, username
FROM users
WHERE username IS NULL OR username = '';

-- 1.3 Missing password
SELECT id, username
FROM users
WHERE password_hash IS NULL;

-- =========================================================
-- Rule 2. A locked user cannot have orders.
-- =========================================================
SELECT o.id AS order_id, o.order_date, u.id AS user_id, u.username, u.status
FROM orders AS o
INNER JOIN users AS u ON u.id = o.user_id
WHERE u.status = 'locked';

-- =========================================================
-- Rule 3. First Name, Last Name and Postal Code are required in an order.
-- =========================================================
SELECT id AS order_id, first_name, last_name, postal_code
FROM orders
WHERE (first_name IS NULL OR first_name = '')
   OR (last_name IS NULL OR last_name = '')
   OR (postal_code IS NULL OR postal_code = '');

-- =========================================================
-- Rule 4. Product price is greater than 0.
-- =========================================================
SELECT id, name, price
FROM products
WHERE price <= 0 OR price IS NULL;

-- =========================================================
-- Rule 7. Every order belongs to an existing user and contains existing products.
-- Run before rules 5 and 6: rows with broken references are dropped by INNER JOIN.
-- =========================================================

-- 7.1 Orders with a non-existent user
SELECT o.id AS order_id, o.user_id
FROM orders AS o
LEFT JOIN users AS u ON o.user_id = u.id
WHERE u.id IS NULL;

-- 7.2 Order items with a non-existent product
SELECT o_i.id AS order_item_id, o_i.order_id, o_i.product_id
FROM order_items AS o_i
LEFT JOIN products AS p ON o_i.product_id = p.id
WHERE p.id IS NULL;

-- =========================================================
-- Rule 5. Item total = sum of (price x quantity) of all order items.
-- =========================================================
SELECT o_i.order_id, o.item_total, SUM(p.price * o_i.quantity) AS expected_item_total
FROM orders AS o
INNER JOIN order_items AS o_i ON o.id = o_i.order_id
INNER JOIN products AS p ON o_i.product_id = p.id
GROUP BY o_i.order_id, o.item_total
HAVING o.item_total != SUM(p.price * o_i.quantity)
ORDER BY o_i.order_id;

-- =========================================================
-- Rule 6. Tax = 8% of item total. Total = item total + tax.
-- =========================================================

-- 6.1 Tax
SELECT id AS order_id, item_total, tax, ROUND(item_total * 0.08, 2) AS expected_tax
FROM orders
WHERE tax != ROUND(item_total * 0.08, 2);

-- 6.2 Total
SELECT id AS order_id, item_total, tax, total, (item_total + tax) AS expected_total
FROM orders
WHERE total != (item_total + tax);
