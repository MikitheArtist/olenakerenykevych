# Saucedemo: SQL Data Integrity Checks

A practice project in database testing. I modeled the data of the [Saucedemo](https://www.saucedemo.com/) online store in MS SQL Server, wrote business rules based on how the site behaves, and wrote SQL queries that check the data against these rules.

- **DBMS:** MS SQL Server, SQL Server Management Studio (SSMS)
- **Date:** October 2026
- **File:** [`saucedemo_data_checks.sql`](saucedemo_data_checks.sql) (schema, test data and all checks)

## Database schema

| Table | Description |
|---|---|
| `users` | Store accounts: username, password hash, status (`active` / `locked`) |
| `products` | Catalog: 6 products with prices |
| `orders` | Checkout data: first name, last name, postal code, item total, tax, total |
| `order_items` | Products in each order with quantity (links orders and products, many-to-many) |

The tables have no constraints (FOREIGN KEY, UNIQUE, CHECK), so invalid data can be inserted and found by the checks.

## Business rules

1. Username is unique and required. Password is required.
2. A locked user (`locked_out_user`) cannot log in, so a locked user cannot have orders.
3. First Name, Last Name and Postal Code are required at checkout, so they cannot be empty in an order.
4. Product price is greater than 0.
5. Item total equals the sum of price × quantity of all products in the order.
6. Tax equals 8% of the item total (rounded to cents). Total equals item total + tax.
7. Every order belongs to an existing user and contains only existing products.

## Test data

The test data contained an unknown number of seeded defects. The data was prepared with an AI assistant; the task was to find all defects with queries, without knowing how many there were or where.

## Results

12 defects found, every rule failed at least once.

| Rule | Check | Defects found |
|---|---|---|
| 1 | Duplicate usernames | `standard_user` used by users 1 and 7 |
| 1 | Missing username | User 9: username is an empty string |
| 1 | Missing password | User 8: `password_hash` is NULL |
| 2 | Orders of locked users | Order 3 by `locked_out_user` |
| 3 | Required checkout fields | Order 4: no first name (NULL); order 5: empty postal code |
| 4 | Price > 0 | Product 6 has price 0.00 |
| 5 | Item total | Order 6: 15.99 stored, 31.98 expected (quantity of 2 not counted) |
| 6 | Tax | Order 7: 1.80 stored, 1.92 expected |
| 6 | Total | Order 8: 79.98 stored, 86.38 expected (tax not added) |
| 7 | Order with non-existent user | Order 9 refers to user 15 |
| 7 | Order item with non-existent product | Order 10 contains product 9 |

## Notes

- An empty field can be NULL or an empty string `''`, so the checks test both. `= NULL` never returns rows, only `IS NULL` works.
- Order 10 did not appear in the item total check (rule 5): its only product does not exist, and INNER JOIN removed the whole order. Because of this, the reference checks (rule 7) should run first.
- Money columns use DECIMAL, not FLOAT. With FLOAT, `total != item_total + tax` returns false mismatches because of rounding.
- Most of these defects could be prevented in the database itself: FOREIGN KEY (rule 7), UNIQUE (rule 1), NOT NULL (rules 1 and 3), CHECK (rules 4–6).

## How to run

**In SQL Server Management Studio:**

1. Create a database and switch to it:
   ```sql
   CREATE DATABASE saucedemo;
   GO
   USE saucedemo;
   GO
   ```
2. Open `saucedemo_data_checks.sql`, select part 1 (schema and data) and run it (F5).
3. Select any check from part 2 and run it.

**Online, without installing anything:** open [dbfiddle.uk](https://dbfiddle.uk), select SQL Server, paste part 1 and any check from part 2, click Run.
