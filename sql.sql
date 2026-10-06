SET datestyle = 'DMY';
SELECT COUNT(*) FROM customers;

ALTER DATABASE ecommerce_analysis
SET datestyle = 'ISO, DMY';

CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    product_name VARCHAR(150),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    brand VARCHAR(100),
    list_price_usd NUMERIC(12,2),
    unit_cost_usd NUMERIC(12,2),
    weight_kg NUMERIC(10,3),
    launch_date DATE,
    is_active BOOLEAN
);

select count(*) from products

CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    order_date DATE,
    order_month VARCHAR(10),
    sales_channel VARCHAR(30),
    device_type VARCHAR(30),
    payment_method VARCHAR(30),
    shipping_country VARCHAR(50),
    shipping_region VARCHAR(50),
    currency_code VARCHAR(10),
    fx_rate_to_usd NUMERIC(12,6),
    items_count INTEGER,
    gross_amount_local NUMERIC(14,2),
    discount_local NUMERIC(14,2),
    shipping_fee_local NUMERIC(14,2),
    tax_local NUMERIC(14,2),
    order_total_local NUMERIC(14,2),
    order_total_usd NUMERIC(14,2),
    order_status VARCHAR(20),
    delivery_days INTEGER
);

select count(*) from orders

CREATE TABLE order_items (
    order_item_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    product_id VARCHAR(20),
    quantity INTEGER,
    unit_price_local NUMERIC(14,2),
    line_discount_local NUMERIC(14,2),
    line_total_local NUMERIC(14,2),
    line_total_usd NUMERIC(14,2),
    unit_cost_usd NUMERIC(14,2),
    line_profit_usd NUMERIC(14,2),
    currency_code VARCHAR(10)
);

select count(*) from order_items

CREATE TABLE returns (
    return_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(20),
    order_item_id VARCHAR(20),
    product_id VARCHAR(20),
    customer_id VARCHAR(20),
    return_date DATE,
    return_month VARCHAR(10),
    days_to_return INTEGER,
    quantity_returned INTEGER,
    return_reason VARCHAR(100),
    item_condition VARCHAR(30),
    refund_amount_local NUMERIC(14,2),
    refund_amount_usd NUMERIC(14,2),
    restocked BOOLEAN,
    currency_code VARCHAR(10)
);

select count(*) from returns


--Q1)- What is the total number of customers, orders, products, order items, and returns?

SELECT
    (SELECT COUNT(*) FROM customers) AS total_customers,
    (SELECT COUNT(*) FROM orders) AS total_orders,
    (SELECT COUNT(*) FROM products) AS total_products,
    (SELECT COUNT(*) FROM order_items) AS total_order_items,
    (SELECT COUNT(*) FROM returns) AS total_returns;

--Q2)- What is the breakdown of orders by order status?

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

--Q3)- What are the total orders and total revenue by month?

SELECT
    TO_CHAR(DATE_TRUNC('month', order_date), 'DD-MM-YYYY') AS month,
    COUNT(*) AS total_orders,
    SUM(order_total_usd) AS total_revenue
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY DATE_TRUNC('month', order_date);

--Q4)- What is the Average Order Value (AOV) for delivered orders?

SELECT
    ROUND(AVG(order_total_usd),2) AS avg_order_value
FROM orders
WHERE order_status = 'Delivered';

--Q5)- Show each order with the customer name, country, order date, status, and order value.

--SELECT * from orders;
--SELECT * from customers;

SELECT
    o.order_id,
    c.customer_name,
    c.country,
    o.order_date,
    o.order_status,
    o.order_total_usd
FROM orders AS o
JOIN customers AS c
    ON o.customer_id = c.customer_id
ORDER BY o.order_date;

--Q6)- Who are the top 10 customers by total spending?

SELECT
    c.customer_id,
    c.customer_name,
    SUM(o.order_total_usd) AS total_spending
FROM customers AS c
JOIN orders AS o
    ON c.customer_id = o.customer_id
WHERE o.order_status <> 'Cancelled'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 10;

--Q7)- Which customers have placed the most orders?

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) AS total_orders
FROM customers AS c
JOIN orders AS o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_orders DESC;

--Q8)- Which customers have never had a successful/non-cancelled order?

SELECT
    c.customer_id,
    c.customer_name
FROM customers AS c
LEFT JOIN orders AS o
    ON c.customer_id = o.customer_id
    AND o.order_status <> 'Cancelled'
WHERE o.order_id IS NULL;

--Q9)- What are the total quantity sold and revenue for each product category?

SELECT
    p.category,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.line_total_usd) AS total_revenue
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY p.category
ORDER BY total_revenue DESC;

--Q10)- What are the top 10 products by revenue?

SELECT
    p.product_id,
    p.product_name,
    SUM(oi.line_total_usd) AS total_revenue
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

--Q11)- What are the top 10 products by quantity sold?

SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY total_quantity_sold DESC
LIMIT 10;

--Q12)- Which product categories generate the highest total profit?

SELECT
    p.category,
    SUM(oi.line_profit_usd) AS total_profit
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY p.category
ORDER BY total_profit DESC;

--Q13)- What is the overall return rate?

SELECT
    ROUND(
        SUM(r.quantity_returned)::NUMERIC/ NULLIF(SUM(oi.quantity), 0) * 100,
        2
    ) AS return_rate_percent
FROM returns AS r
JOIN order_items AS oi
    ON r.order_item_id = oi.order_item_id
JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_status <> 'Cancelled';

--Q14)- What is the return rate for each product category?

SELECT
    p.category,
    ROUND(
        SUM(r.quantity_returned)::NUMERIC
        / NULLIF(SUM(oi.quantity), 0) * 100,
        2
    ) AS return_rate_percent
FROM products AS p
JOIN order_items AS oi
    ON p.product_id = oi.product_id
JOIN orders AS o
    ON oi.order_id = o.order_id
LEFT JOIN returns AS r
    ON oi.order_item_id = r.order_item_id
WHERE o.order_status <> 'Cancelled'
GROUP BY p.category
ORDER BY return_rate_percent DESC;

--Q15)- Which 10 products have the highest number of returned units?

SELECT
    p.product_id,
    p.product_name,
    SUM(r.quantity_returned) AS returned_units
FROM returns AS r
JOIN products AS p
    ON r.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY returned_units DESC
LIMIT 10;

--Q16)- Which products have high sales but also unusually high return rates?

WITH product_metrics AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS units_sold,
        COALESCE(SUM(r.quantity_returned), 0) AS returned_units,
        COALESCE(SUM(r.quantity_returned), 0)::NUMERIC
        / NULLIF(SUM(oi.quantity), 0) * 100 AS return_rate
    FROM products AS p
    JOIN order_items AS oi
        ON p.product_id = oi.product_id
    JOIN orders AS o
        ON oi.order_id = o.order_id
    LEFT JOIN returns AS r
        ON oi.order_item_id = r.order_item_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY p.product_id, p.product_name
)
SELECT *
FROM product_metrics
WHERE units_sold > (
    SELECT AVG(units_sold)
    FROM product_metrics
)
AND return_rate > (
    SELECT AVG(return_rate)
    FROM product_metrics
)
ORDER BY return_rate DESC;

--Q17)- What are the most common return reasons?

SELECT
    return_reason,
    COUNT(*) AS total_returns
FROM returns
GROUP BY return_reason
ORDER BY total_returns DESC;

--Q18)- What is the average number of days customers take to return an item, by return reason?

SELECT
    return_reason,
    ROUND(AVG(days_to_return), 1) AS avg_days_to_return
FROM returns
GROUP BY return_reason
ORDER BY avg_days_to_return DESC;

--Q19)- What is the total refund amount by product category?

SELECT
    p.category,
    SUM(r.refund_amount_usd) AS total_refund
FROM returns AS r
JOIN products AS p
    ON r.product_id = p.product_id
GROUP BY p.category
ORDER BY total_refund DESC;

--Q20)- Which categories have the highest percentage of non-restocked returns?

SELECT
    p.category,
    ROUND(
        COUNT(*) FILTER (WHERE r.restocked = FALSE)::NUMERIC
        / COUNT(*) * 100,
        2
    ) AS non_restocked_percent
FROM returns AS r
JOIN products AS p
    ON r.product_id = p.product_id
GROUP BY p.category
ORDER BY non_restocked_percent DESC;

--Q21)- Rank products by revenue within each category.

SELECT
    p.category,
    p.product_name,
    SUM(oi.line_total_usd) AS revenue,
    RANK() OVER (
        PARTITION BY p.category
        ORDER BY SUM(oi.line_total_usd) DESC
    ) AS category_rank
FROM products AS p
JOIN order_items AS oi
    ON p.product_id = oi.product_id
JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE o.order_status <> 'Cancelled'
GROUP BY p.category, p.product_id, p.product_name;

--Q22)- Find the top 3 products by revenue within each category.

WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        SUM(oi.line_total_usd) AS revenue
    FROM products AS p
    JOIN order_items AS oi
        ON p.product_id = oi.product_id
    JOIN orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY p.category, p.product_id, p.product_name
),
ranked_products AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS category_rank
    FROM product_revenue
)
SELECT *
FROM ranked_products
WHERE category_rank <= 3
ORDER BY category, category_rank;

--Q23)- Calculate monthly revenue and compare it with the previous month's revenue.

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(order_total_usd) AS revenue
    FROM orders
    WHERE order_status <> 'Cancelled'
    GROUP BY month
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (
        ORDER BY month
    ) AS previous_month_revenue,
    revenue - LAG(revenue) OVER (
        ORDER BY month
    ) AS revenue_change
FROM monthly_revenue
ORDER BY month;

--Q24)- What percentage of total revenue does each product category contribute?

WITH category_revenue AS (
    SELECT
        p.category,
        SUM(oi.line_total_usd) AS revenue
    FROM products AS p
    JOIN order_items AS oi
        ON p.product_id = oi.product_id
    JOIN orders AS o
        ON oi.order_id = o.order_id
    WHERE o.order_status <> 'Cancelled'
    GROUP BY p.category
)
SELECT
    category,
    revenue,
    ROUND(
        revenue / SUM(revenue) OVER () * 100,
        2
    ) AS revenue_percentage
FROM category_revenue
ORDER BY revenue_percentage DESC;

--Q25)- Which customers have both high total spending and a high number of returns?

WITH customer_metrics AS (
    SELECT
        c.customer_id,
        c.customer_name,
        COALESCE(SUM(o.order_total_usd), 0) AS total_spending,
        COUNT(DISTINCT r.return_id) AS total_returns
    FROM customers AS c
    LEFT JOIN orders AS o
        ON c.customer_id = o.customer_id
        AND o.order_status <> 'Cancelled'
    LEFT JOIN returns AS r
        ON c.customer_id = r.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT *
FROM customer_metrics
WHERE total_spending > (
    SELECT AVG(total_spending)
    FROM customer_metrics
)
AND total_returns > (
    SELECT AVG(total_returns)
    FROM customer_metrics
)
ORDER BY total_spending DESC;