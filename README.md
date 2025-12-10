<div align="center">
  <img src="https://raw.githubusercontent.com/PrajwalGpy/AmazonDB-SQL-/main/amazon-logo.png" alt="Amazon Logo" width="200" height="200">
</div>

# Amazon USA Sales Analysis - Advanced SQL Project

## Project Overview

This project involves analyzing a large-scale e-commerce dataset (20,000+ sales records) representing an Amazon-like ecosystem. The goal is to solve real-world business problems regarding sales trends, inventory management, and customer behavior using **PostgreSQL**.

The analysis covers 9 relational tables and utilizes advanced SQL techniques including **Joins, Window Functions (RANK, LEAD, LAG), CTEs, and Stored Procedures** for inventory automation.

## Database Schema

The database is designed with a **Snowflake Schema** architecture, consisting of 9 normalized tables.

| Table Name      | Description                                     | Key Columns                                        |
| :-------------- | :---------------------------------------------- | :------------------------------------------------- |
| **category**    | Product category classifications (Parent Table) | `category_id`, `category_name`                     |
| **customers**   | Registered user data (Parent Table)             | `customer_id`, `first_name`, `state`               |
| **sellers**     | Vendor information (Parent Table)               | `seller_id`, `seller_name`, `origin`               |
| **products**    | Product catalog linked to categories            | `product_id`, `product_name`, `price`, `cogs`      |
| **orders**      | transactional order data                        | `order_id`, `order_date`, `customer_id`, `status`  |
| **order_items** | Line-item details for each order                | `order_item_id`, `order_id`, `quantity`, `price`   |
| **payments**    | Payment transaction history                     | `payment_id`, `payment_status`, `payment_date`     |
| **shipping**    | Logistics and delivery tracking                 | `shipping_id`, `shipping_providers`, `return_date` |
| **inventory**   | Stock levels and warehouse data                 | `inventory_id`, `stock`, `last_stock_date`         |

## Database Setup & Configuration

### 1. Database Creation

Execute the following SQL command to initialize the database in PostgreSQL.

```sql
CREATE DATABASE amazon_db;
```

### 2. Table Creation

The tables must be created in a specific order (Parent $\to$ Child) to satisfy Foreign Key constraints. Run the `schemas.sql` file or execute the following hierarchy:

1.  `category`, `customers`, `sellers`
2.  `products` (links to category)
3.  `orders` (links to customers, sellers)
4.  `order_items`, `payments`, `shipping`, `inventory`

### 3. Data Import & Cleaning

Import data using PGAdmin 4's Import/Export tool. Note the following specific configurations required during import:

- **Handling Null Addresses:** The source CSV for `customers` may lack an address column. Configure the table to set a default value:
  ```sql
  ALTER TABLE customers ALTER COLUMN address SET DEFAULT 'XXX';
  ```
- **Fixing Varchar Limits:** The `sellers` dataset contains country names longer than the initial schema definition (e.g., "Canada"). Update the schema before importing:
  ```sql
  ALTER TABLE sellers ALTER COLUMN origin TYPE VARCHAR(10);
  ```
- **Feature Engineering:** After import, populate the `total_sale` column in `order_items`:
  ```sql
  UPDATE order_items
  SET total_sale = quantity * price_per_unit;
  ```

## Business Problems & Solutions

Below are key business problems solved using Advanced SQL.

## 🟢 Basic Analysis

### 1. Top 10 Selling Products

**Question:** Identify the top 10 products by total sales value.

```sql
SELECT
    p.product_name,
    SUM(oi.total_sale) as total_revenue,
    COUNT(o.order_id) as total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;
```

**Answer:** `SELECT * FROM top_products_view;`

### 2. Revenue by Category

**Question:** Calculate total revenue and percentage contribution of each product category.

```sql
SELECT
    p.category_id,
    c.category_name,
    SUM(oi.total_sale) as total_sales,
    SUM(oi.total_sale) / (SELECT SUM(total_sale) FROM order_items) * 100 as contribution
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN category c ON c.category_id = p.category_id
GROUP BY p.category_id, c.category_name
ORDER BY total_sales DESC;
```

**Answer:** `SELECT * FROM category_revenue_view;`

### 3. Average Order Value (AOV)

**Question:** Compute the average order value for customers who have placed more than 5 orders.

```sql
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) as full_name,
    SUM(oi.total_sale) / COUNT(o.order_id) as aov
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY 1, 2
HAVING COUNT(o.order_id) > 5;
```

**Answer:** `SELECT * FROM customer_aov_view;`

### 4. Customers with No Purchases

**Question:** Identify customers who have registered but never placed an order.

```sql
-- Approach 1: Using Subquery
SELECT * FROM customers
WHERE customer_id NOT IN (SELECT DISTINCT customer_id FROM orders);

-- Approach 2: Using LEFT JOIN
SELECT * FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
```

**Answer:** `SELECT * FROM inactive_customers_view;`

---

## 🟡 Intermediate Analysis

### 5. Monthly Sales Trend

**Question:** Query monthly total sales for the past year and compare with the previous month (Month-over-Month).

```sql
SELECT
    year, month, total_sale as current_month_sale,
    LAG(total_sale, 1) OVER(ORDER BY year, month) as last_month_sale
FROM (
    SELECT
        EXTRACT(YEAR FROM order_date) as year,
        EXTRACT(MONTH FROM order_date) as month,
        SUM(total_sale) as total_sale
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE order_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 1, 2
) as t1;
```

**Answer:** `SELECT * FROM monthly_trend_view;`

### 6. Best Selling Category by State

**Question:** Determine the highest-selling product category for each state.

```sql
WITH ranking_table AS (
    SELECT
        c.state,
        cat.category_name,
        SUM(oi.total_sale) as total_sales,
        RANK() OVER(PARTITION BY c.state ORDER BY SUM(oi.total_sale) DESC) as rank
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN category cat ON p.category_id = cat.category_id
    GROUP BY 1, 2
)
SELECT * FROM ranking_table WHERE rank = 1;
```

**Answer:** `SELECT * FROM state_best_category_view;`

### 7. Customer Lifetime Value (CLTV)

**Question:** Rank customers based on their total lifetime purchase value.

```sql
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) as full_name,
    SUM(total_sale) as CLTV,
    DENSE_RANK() OVER(ORDER BY SUM(total_sale) DESC) as customer_rank
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY 1, 2;
```

**Answer:** `SELECT * FROM cltv_view;`

### 8. Inventory Stock Alert

**Question:** Query products with stock levels below 10 units.

```sql
SELECT
    i.inventory_id,
    p.product_name,
    i.stock as current_stock_left
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.stock < 10;
```

**Answer:** `SELECT * FROM low_stock_alert_view;`

### 9. Shipping Delays

**Question:** Identify orders where the shipping date is 3+ days after the order date.

```sql
SELECT
    c.*,
    o.order_id,
    o.order_date,
    s.shipping_date,
    s.shipping_providers
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN shipping s ON o.order_id = s.order_id
WHERE s.shipping_date - o.order_date > 3;
```

**Answer:** `SELECT * FROM shipping_delay_view;`

### 10. Payment Success Rate

**Question:** Calculate the percentage of successful payments across all orders.

```sql
SELECT
    p.payment_status,
    COUNT(*) as total_count,
    COUNT(*)::numeric / (SELECT COUNT(*) FROM payments)::numeric * 100 as ratio
FROM orders o
JOIN payments p ON o.order_id = p.order_id
GROUP BY 1;
```

**Answer:** `SELECT * FROM payment_analysis_view;`

### 11. Most Returned Products

**Question:** Find the top 10 products with the highest return rate.

```sql
SELECT
    p.product_id,
    p.product_name,
    COUNT(o.order_id) as total_orders,
    SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) as returned_orders,
    (SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::numeric / COUNT(o.order_id)::numeric) * 100 as return_percentage
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
GROUP BY 1, 2
ORDER BY 5 DESC
LIMIT 10;
```

**Answer:** `SELECT * FROM high_return_products_view;`

---

## 🔴 Advanced Analysis

### 12. Product Profit Margin

**Question:** Rank products by their profit margin ((Price - COGS) / Price).

```sql
SELECT
    product_id,
    product_name,
    profit_margin,
    DENSE_RANK() OVER(ORDER BY profit_margin DESC) as product_rank
FROM (
    SELECT
        p.product_id,
        p.product_name,
        SUM(total_sale - (p.cogs * oi.quantity)) / SUM(total_sale) * 100 as profit_margin
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY 1, 2
) as t1;
```

**Answer:** `SELECT * FROM profit_margin_view;`

### 13. Top Performing Sellers

**Question:** Identify the top 5 sellers by revenue and categorize their order status (Completed vs. Cancelled).

```sql
WITH top_sellers AS (
    SELECT s.seller_id, s.seller_name, SUM(oi.total_sale) as total_sale
    FROM orders o
    JOIN sellers s ON o.seller_id = s.seller_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY 1, 2
    ORDER BY 3 DESC
    LIMIT 5
),
seller_reports AS (
    SELECT
        o.seller_id,
        ts.seller_name,
        o.order_status,
        COUNT(*) as total_orders
    FROM orders o
    JOIN top_sellers ts ON ts.seller_id = o.seller_id
    WHERE o.order_status NOT IN ('Inprogress', 'Returned')
    GROUP BY 1, 2, 3
)
SELECT
    seller_id,
    seller_name,
    SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END) as completed_orders,
    SUM(CASE WHEN order_status = 'Cancelled' THEN total_orders ELSE 0 END) as cancelled_orders,
    SUM(total_orders) as total_orders,
    SUM(CASE WHEN order_status = 'Completed' THEN total_orders ELSE 0 END)::numeric / SUM(total_orders)::numeric * 100 as success_ratio
FROM seller_reports
GROUP BY 1, 2;
```

**Answer:** `SELECT * FROM top_sellers_performance_view;`

### 14. Inactive Sellers

**Question:** Identify sellers who haven't made any sales in the last 6 months.

```sql
SELECT * FROM sellers
WHERE seller_id NOT IN (
    SELECT seller_id FROM orders
    WHERE order_date >= CURRENT_DATE - INTERVAL '6 month'
);
```

**Answer:** `SELECT * FROM inactive_sellers_view;`

### 15. Categorize Customers (Returning vs New)

**Question:** Categorize customers as 'Returning' if they have more than 5 returns, else 'New'.

```sql
SELECT
    customer_name,
    total_orders,
    total_returns,
    CASE
        WHEN total_returns > 5 THEN 'Returning'
        ELSE 'New'
    END as customer_category
FROM (
    SELECT
        CONCAT(first_name, ' ', last_name) as customer_name,
        COUNT(o.order_id) as total_orders,
        SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) as total_returns
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    GROUP BY 1
) as t1;
```

**Answer:** `SELECT * FROM customer_segmentation_view;`

### 16. Top 5 Customers by Orders in Each State

**Question:** Find the top 5 customers with the highest number of orders for each state.

```sql
SELECT * FROM (
    SELECT
        c.state,
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        COUNT(o.order_id) as total_orders,
        SUM(total_sale) as total_sale,
        DENSE_RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id) DESC) as rank
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c ON c.customer_id = o.customer_id
    GROUP BY 1, 2
) as t1
WHERE rank <= 5;
```

**Answer:** `SELECT * FROM state_top_customers_view;`

### 17. Revenue by Shipping Provider

**Question:** Calculate total revenue handled by each shipping provider and their average delivery time.

```sql
SELECT
    s.shipping_providers,
    COUNT(o.order_id) as total_orders,
    SUM(oi.total_sale) as total_revenue,
    COALESCE(AVG(s.return_date - s.shipping_date), 0) as avg_days_to_return
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN shipping s ON s.order_id = o.order_id
GROUP BY 1;
```

**Answer:** `SELECT * FROM shipping_revenue_view;`

### 18. Highest Decreasing Revenue Ratio

**Question:** Find the top 10 products with the highest revenue decrease ratio from 2022 to 2023.

```sql
WITH last_year_sale AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(oi.total_sale) as revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2022
    GROUP BY 1, 2
),
current_year_sale AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(oi.total_sale) as revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2023
    GROUP BY 1, 2
)
SELECT
    cs.product_id,
    ls.revenue as last_year_revenue,
    cs.revenue as current_year_revenue,
    ls.revenue - cs.revenue as revenue_diff,
    ROUND((ls.revenue - cs.revenue)::numeric / ls.revenue::numeric * 100, 2) as revenue_decrease_ratio
FROM last_year_sale ls
JOIN current_year_sale cs ON ls.product_id = cs.product_id
WHERE ls.revenue > cs.revenue
ORDER BY 5 DESC
LIMIT 10;
```

**Answer:** `SELECT * FROM declining_products_view;`

### 19. Cross-Selling Opportunities

**Question:** Identify customers who bought product A (e.g., AirPods) but not product B (e.g., iPhone) to target for cross-selling. (Note: Logic depends on specific product IDs).

```sql
SELECT DISTINCT c.customer_id, c.first_name, c.last_name
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE oi.product_id = 1 -- Example: AirPods
AND c.customer_id NOT IN (
    SELECT DISTINCT o2.customer_id
    FROM orders o2
    JOIN order_items oi2 ON o2.order_id = oi2.order_id
    WHERE oi2.product_id = 2 -- Example: iPhone
);
```

### 20. Store Procedure (Automated Inventory Update)

**Question:** Create a stored procedure that updates inventory counts automatically when a sale occurs.

```sql
CREATE OR REPLACE PROCEDURE add_sales(
    p_order_id INT,
    p_customer_id INT,
    p_seller_id INT,
    p_order_item_id INT,
    p_product_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT;
    v_price FLOAT;
BEGIN
    -- 1. Check if product exists and stock is sufficient
    SELECT price, COUNT(*) INTO v_price, v_count
    FROM products
    WHERE product_id = p_product_id;

    -- Check stock in inventory
    SELECT count(*) INTO v_count
    FROM inventory
    WHERE product_id = p_product_id AND stock >= p_quantity;

    IF v_count > 0 THEN
        -- 2. Insert into Orders Table
        INSERT INTO orders (order_id, order_date, customer_id, seller_id)
        VALUES (p_order_id, CURRENT_DATE, p_customer_id, p_seller_id);

        -- 3. Insert into Order Items Table
        INSERT INTO order_items (order_item_id, order_id, product_id, quantity, price_per_unit, total_sale)
        VALUES (p_order_item_id, p_order_id, p_product_id, p_quantity, v_price, v_price * p_quantity);

        -- 4. Update Inventory
        UPDATE inventory
        SET stock = stock - p_quantity
        WHERE product_id = p_product_id;

        RAISE NOTICE 'Sale added and inventory updated successfully';
    ELSE
        RAISE NOTICE 'Insufficient stock for product ID: %', p_product_id;
    END IF;
END;
$$;
```

## 📂 Project Files Description

- **`AmazonDB`**: Database file containing all CSV files.
- **`AmazonDB.sql`**: Main SQL database setup and configuration.
- **`AmazonDB_SQL_Project_Questions.sql`**: Comprehensive SQL queries for all project questions.
- **`AmazonDB_Schema.sql`**: Database schema definition and table structures.

## Dataset Details

The dataset consists of 9 files representing the Amazon ecosystem.

| File Name         | Size   | Link           |
| :---------------- | :----- | :------------- |
| `category.csv`    | 1 KB   | [View File](#) |
| `customers.csv`   | 55 KB  | [View File](#) |
| `sellers.csv`     | 2 KB   | [View File](#) |
| `products.csv`    | 320 KB | [View File](#) |
| `orders.csv`      | 1.5 MB | [View File](#) |
| `order_items.csv` | 1.2 MB | [View File](#) |
| `payments.csv`    | 900 KB | [View File](#) |
| `shipping.csv`    | 1.1 MB | [View File](#) |
| `inventory.csv`   | 45 KB  | [View File](#) |

---

_Note: This dataset is for educational purposes and contains synthetic data simulating real-world e-commerce scenarios._
