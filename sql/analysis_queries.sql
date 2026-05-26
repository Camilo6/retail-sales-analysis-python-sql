-- ============================================
-- Superstore Sales Analysis - SQL Queries
-- Author: Julian Camilo Torres Rodríguez
-- DB: PostgreSQL
-- ============================================

-- 1. Create table
CREATE TABLE IF NOT EXISTS superstore (
    order_id      VARCHAR(20),
    order_date    DATE,
    ship_date     DATE,
    ship_mode     VARCHAR(30),
    customer_id   VARCHAR(20),
    customer_name VARCHAR(100),
    segment       VARCHAR(30),
    country       VARCHAR(50),
    city          VARCHAR(50),
    state         VARCHAR(50),
    region        VARCHAR(20),
    product_id    VARCHAR(20),
    category      VARCHAR(30),
    sub_category  VARCHAR(30),
    product_name  VARCHAR(200),
    sales         NUMERIC(10,2),
    quantity      INTEGER,
    discount      NUMERIC(4,2),
    profit        NUMERIC(10,2)
);

-- 2. Sales & profit summary by category
SELECT
    category,
    COUNT(DISTINCT order_id)            AS total_orders,
    ROUND(SUM(sales)::numeric, 2)       AS total_sales,
    ROUND(SUM(profit)::numeric, 2)      AS total_profit,
    ROUND(AVG(discount)*100, 1)         AS avg_discount_pct,
    ROUND((SUM(profit)/SUM(sales)*100)::numeric, 2) AS profit_margin_pct
FROM superstore
GROUP BY category
ORDER BY total_sales DESC;

-- 3. Top 10 most profitable products
SELECT
    product_name,
    sub_category,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,
    ROUND(SUM(sales)::numeric, 2)  AS total_sales,
    COUNT(*)                        AS order_lines
FROM superstore
GROUP BY product_name, sub_category
ORDER BY total_profit DESC
LIMIT 10;

-- 4. Top 10 products losing money
SELECT
    product_name,
    sub_category,
    ROUND(SUM(profit)::numeric, 2) AS total_profit,
    ROUND(AVG(discount)*100, 1)    AS avg_discount_pct
FROM superstore
GROUP BY product_name, sub_category
HAVING SUM(profit) < 0
ORDER BY total_profit ASC
LIMIT 10;

-- 5. Monthly sales trend (year over year)
SELECT
    EXTRACT(YEAR FROM order_date)  AS year,
    EXTRACT(MONTH FROM order_date) AS month,
    TO_CHAR(order_date, 'Mon')     AS month_name,
    ROUND(SUM(sales)::numeric, 2)  AS monthly_sales,
    ROUND(SUM(profit)::numeric, 2) AS monthly_profit
FROM superstore
GROUP BY 1, 2, 3
ORDER BY 1, 2;

-- 6. Region performance with YoY growth
WITH yearly AS (
    SELECT
        region,
        EXTRACT(YEAR FROM order_date) AS year,
        SUM(sales) AS total_sales
    FROM superstore
    GROUP BY 1, 2
)
SELECT
    y1.region,
    y1.year,
    ROUND(y1.total_sales::numeric, 2) AS sales,
    ROUND(
        ((y1.total_sales - y0.total_sales) / NULLIF(y0.total_sales, 0) * 100)::numeric, 2
    ) AS yoy_growth_pct
FROM yearly y1
LEFT JOIN yearly y0
    ON y1.region = y0.region AND y1.year = y0.year + 1
ORDER BY y1.year, y1.region;

-- 7. Customer segments analysis
SELECT
    segment,
    COUNT(DISTINCT customer_id)        AS unique_customers,
    COUNT(DISTINCT order_id)           AS total_orders,
    ROUND(SUM(sales)::numeric, 2)      AS total_sales,
    ROUND(AVG(sales)::numeric, 2)      AS avg_order_value,
    ROUND(SUM(profit)::numeric, 2)     AS total_profit
FROM superstore
GROUP BY segment
ORDER BY total_sales DESC;

-- 8. High-discount orders with negative profit (risk analysis)
SELECT
    order_id,
    product_name,
    category,
    discount,
    ROUND(sales::numeric, 2)  AS sales,
    ROUND(profit::numeric, 2) AS profit
FROM superstore
WHERE discount >= 0.4 AND profit < 0
ORDER BY profit ASC
LIMIT 20;
