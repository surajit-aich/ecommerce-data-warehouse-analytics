-- ============================================================
-- Script   : 08_eda_analysis.sql
-- Project  : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose  : Explore the Gold layer to see what data the warehouse
--            holds and to answer the first business questions about
--            sales, customers, products, suppliers, shipping and reviews.
-- Schema   : gold (views)
-- Views    : dim_customers, dim_products, dim_suppliers, dim_payment,
--            dim_shipments, dim_rating, fact_sales, fact_reviews
-- Note     : The script is organised in seven groups, from simple
--            exploration to rankings. Each query starts with a comment
--            that states the question it answers. All queries only read
--            data, so nothing in the warehouse is changed.
-- Author   : Surajit
-- Date     : 2026-10-27
-- ============================================================


-- ============================================================
-- Group 1: Database Exploration
-- What data does the warehouse hold?
-- ============================================================

-- List the objects in the gold schema.
SELECT * 
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold';

-- List the columns and data types of every gold view.

SELECT * 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold';

-- ============================================================
-- Group 2: Dimension Exploration
-- What do the descriptive columns look like: customers, products, shipping, payments and suppliers?
-- ============================================================

-- How many different states and cities do our customers come from
SELECT
	COUNT(DISTINCT state_code) AS total_states,
	COUNT(DISTINCT city) AS total_cities
FROM gold.dim_customers;

-- How many customers does each state and city have, starting with the biggest

SELECT 
	state_code,
	city,
	COUNT(customer_id) AS total_customers
FROM gold.dim_customers
GROUP BY state_code,
	city
ORDER BY total_customers DESC;

-- How many products does each category have, and what is the price range inside it

SELECT 
	category,
	MIN(listed_price) AS lowest_price,
	MAX(listed_price) AS highest_price,
	COUNT(*) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;

-- How many different categories and products do we have

SELECT 
	COUNT(DISTINCT category) AS unique_category,
	COUNT(DISTINCT product_name) AS unique_product_names,
	COUNT(DISTINCT product_id) AS unique_products
FROM gold.dim_products;

-- Which carriers deliver our orders, and how many shipments does each one handle

SELECT 
	carrier,
	COUNT(*) AS total_shipments
FROM gold.dim_shipments
GROUP BY carrier
ORDER BY  total_shipments DESC;

-- What statuses can a shipment have, and how many shipments are in each

SELECT 
	shipment_status,
	COUNT(*) AS total_shipments
FROM gold.dim_shipments
GROUP BY shipment_status
ORDER BY  total_shipments DESC;

-- Which payment methods do customers use

SELECT 
	payment_method,
	COUNT(*) AS total_payments
FROM gold.dim_payment
GROUP BY payment_method;

-- What statuses can a payment have, and how many payments are in each

SELECT 
	payment_status,
	COUNT(*) AS total_payments
FROM gold.dim_payment
GROUP BY payment_status
ORDER BY total_payments DESC;

-- How many suppliers does each state have, starting with the biggest

SELECT 
	state_code,
	COUNT(*) AS total_suppliers
FROM gold.dim_suppliers
GROUP BY state_code
ORDER BY total_suppliers DESC;

-- How many suppliers do we have, and how many states and cities are they in

SELECT 
	COUNT(DISTINCT state_code) AS total_states,
	COUNT(DISTINCT city) AS total_cities,
	COUNT(DISTINCT supplier_id) AS total_suppliers
FROM gold.dim_suppliers;

-- ============================================================
-- Group 3: Date Exploration
-- Which time periods do the orders, shipments, deliveries and reviews cover
-- ============================================================

-- What period do our orders cover, and how many months is that
SELECT 
	MIN(order_date) AS first_order_date,
	MAX(order_date) AS last_order_date,
	DATEDIFF(Month,MIN(order_date),MAX(order_date)) AS months_between
FROM gold.fact_sales;

-- How many orders do we get in each month

SELECT 
	YEAR(order_date) AS order_year,
	MONTH(order_date) AS order_month,
	COUNT(DISTINCT order_id) AS total_orders
FROM gold.fact_sales
GROUP BY YEAR(order_date),
	MONTH(order_date)
ORDER BY order_year, order_month;

-- What period do our shipments and deliveries cover

SELECT 
	MIN(shipment_date) AS first_shipment_date,
	MAX(shipment_date) AS last_shipment_date,
	MIN(delivery_date) AS first_delivery_date,
	MAX(delivery_date) AS last_delivery_date
FROM gold.fact_sales;

-- What period do our reviews cover?

SELECT 
	MIN(review_date) AS first_review_date,
	MAX(review_date) AS last_review_date
FROM gold.fact_reviews;


-- ============================================================
-- Group 4: Key Numbers
-- What are the headline numbers of the business?
-- ============================================================

-- What is our total revenue
SELECT SUM(sales_amount) AS total_revenue FROM gold.fact_sales;

-- How many units have we sold in total
SELECT SUM(quantity) AS total_qty_sold FROM gold.fact_sales;

-- What is the average selling price of an item, and the average value of an order
SELECT 
	CAST(AVG(unit_selling_price) AS DECIMAL(10,2)) AS avg_price,
	CAST(SUM(Sales_amount) / COUNT(DISTINCT order_id) AS DECIMAL(10,2)) AS avg_order_value
FROM gold.fact_sales;

-- How many orders have we received
SELECT COUNT(DISTINCT order_id) AS total_orders FROM gold.fact_sales;

-- How many different products have been sold
SELECT COUNT(DISTINCT product_key) AS total_products FROM gold.fact_sales;

-- How many different customers have placed an order
SELECT COUNT(DISTINCT customer_key) AS total_customers FROM gold.fact_sales;

-- Where do the first quarter, the median and the third quarter of the selling prices fall
SELECT DISTINCT
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY unit_selling_price) OVER() AS Q1_price,
	PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY unit_selling_price) OVER() AS median_price,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY unit_selling_price) OVER() AS Q3_price
FROM gold.fact_sales;

-- What are our review numbers: how many reviews, the average rating, and how many products and customers are covered
SELECT 
	COUNT(*) AS total_reviews,
	CAST(AVG(CAST(DR.rating AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_rating,
	MIN(DR.rating) AS lowest_rating,
	MAX(DR.rating) AS highest_rating,
	COUNT(DISTINCT FR.customer_key) AS customers_reviewed,
	COUNT(DISTINCT FR.product_key) AS products_reviewed
FROM gold.fact_reviews AS FR
LEFT JOIN gold.dim_rating AS DR
	ON FR.rating_key = DR.rating_key;

-- How big is a typical order, and how much do the order values vary
SELECT DISTINCT
	MIN(total_revenue) OVER() AS lowest_revenue,
	MAX(total_revenue) OVER() AS highest_revenue,
	CAST(AVG(total_revenue) OVER() AS DECIMAL(10,2)) AS avg_revenue,
	CAST(STDEV(total_revenue) OVER() AS DECIMAL(10,2)) AS std_revenue,
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_revenue) OVER() AS q1_revenue,
	PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_revenue) OVER() AS median_revenue,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_revenue) OVER() AS q3_revenue
FROM
(SELECT 
	order_id,
	SUM(sales_amount) AS total_revenue
FROM gold.fact_sales
GROUP BY order_id) t;

-- How many orders fall into each size band, from small orders to large ones
WITH order_total AS (
SELECT 
	order_id,
	SUM(sales_amount) AS total_revenue
FROM gold.fact_sales
GROUP BY order_id
)
, banded_orders AS (
SELECT 
	order_id,
	total_revenue,
	CASE
		WHEN total_revenue < 1000 THEN 'Under 1000'
		WHEN total_revenue < 2500 THEN '1000 to 2499'
		WHEN total_revenue < 5000 THEN '2500 to 4999'
		WHEN total_revenue < 7500 THEN '5000 to 7499'
		ELSE '7500 AND above'
	END AS order_band 
FROM order_total
)

SELECT 
	order_band,
	COUNT(*) AS total_orders
FROM banded_orders
GROUP BY order_band
ORDER BY MIN(total_revenue);

-- How many customers ordered only once, and how many came back to order again
SELECT
	orders_per_customer,
	COUNT(*) AS total_customers
FROM (
	SELECT
		customer_key,
		COUNT(DISTINCT order_id) AS orders_per_customer
	FROM gold.fact_sales
	GROUP BY customer_key
) t
GROUP BY orders_per_customer
ORDER BY orders_per_customer;


-- Key metrics report: a scorecard of the main business numbers.
-- Each row is one metric, with its group (Sales or Reviews), its name and its value.
-- Every metric is calculated on its own query and the results are stacked with UNION ALL.
SELECT 'Sales' AS metric_group, 'Total Revenue' AS measure_name,
	SUM(sales_amount) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'Sales' AS metric_group, 'Total Quantity Sold' AS measure_name,
	SUM(quantity) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'Sales' AS metric_group, 'Total Orders' AS measure_name,
	COUNT(DISTINCT order_id) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'Sales' AS metric_group, 'Average Selling Price' AS measure_name,
	AVG(unit_selling_price) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'Sales' AS metric_group, 'Average Order Value' AS measure_name,
	 SUM(Sales_amount) / COUNT(DISTINCT order_id) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'Sales' AS metric_group, 'Products Sold' AS measure_name,
	 COUNT(DISTINCT product_key) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECT 'Sales', 'Customers Who Ordered',
	COUNT(DISTINCT customer_key)
FROM gold.fact_sales
UNION ALL
SELECT 'Reviews' AS metric_group, 'Total Reviews' AS measure_name,
	 COUNT(*) AS measure_value
FROM gold.fact_reviews
UNION ALL
SELECT 'Reviews', 'Average Rating',
	CAST(AVG(CAST(DR.rating AS DECIMAL(10,2))) AS DECIMAL(10,2))
FROM gold.fact_reviews AS FR
LEFT JOIN gold.dim_rating AS DR
	ON FR.rating_key = DR.rating_key
UNION ALL
SELECT 'Reviews' AS metric_group, 'Customers Who Reviewed' AS measure_name,
	 COUNT(DISTINCT customer_key) AS measure_value
FROM gold.fact_reviews
UNION ALL
SELECT 'Reviews' AS metric_group, 'Products Reviewed' AS measure_name,
	 COUNT(DISTINCT product_key) AS measure_value
FROM gold.fact_reviews;


-- ============================================================
-- Group 5: Magnitude
-- How are sales and reviews spread across categories, states, shipment statuses and ratings?
-- ============================================================

-- How much revenue and how many units does each category bring in, and what share of the total revenue is that
WITH category_wise_revenue AS (
SELECT 
	P.category,
	SUM(S.sales_amount) AS total_revenue,
	SUM(S.quantity) AS total_qty
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_products AS P
	ON S.product_key = P.product_key
GROUP BY P.category
)

SELECT 
	category,
	total_revenue,
	total_qty,
	CAST(total_revenue * 100.0 / SUM(total_revenue) OVER () AS DECIMAL(10,2)) AS revenue_share_pct
FROM category_wise_revenue
ORDER BY total_revenue DESC;


-- How does each state perform: customers, orders, sales and sales per customer
SELECT 
	C.state_code,
	COUNT(DISTINCT S.customer_key) AS total_customers,
	COUNT(DISTINCT S.order_id) AS total_orders,
	SUM(S.sales_amount) AS total_sales,
	CAST(SUM(S.sales_amount) / COUNT(DISTINCT S.customer_key) AS DECIMAL(10,2)) AS sales_per_customer
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_customers AS C
	ON S.customer_key = C.customer_key
GROUP BY C.state_code
ORDER BY total_sales DESC;


-- How many orders and how much sales does each shipment status hold, and what share of the total sales is that
WITH status_summary AS (
SELECT 
	SP.shipment_status,
	COUNT(DISTINCT S.order_id) AS total_orders,
	SUM(S.sales_amount) AS total_sales
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_shipments AS SP
	ON S.shipment_key = SP.shipment_key
GROUP BY SP.shipment_status
)

SELECT 
	shipment_status,
	total_orders,
	total_sales,
	CAST(total_sales * 100 / SUM(total_sales) OVER () AS DECIMAL(10,2)) AS sales_share_pct
FROM status_summary
ORDER BY total_sales DESC;


-- How are our reviews spread across the ratings 1 to 5, and what share of all reviews is each rating
WITH rating_summary AS (
SELECT 
	DR.rating,
	COUNT(*) AS total_reviews
FROM gold.fact_reviews AS FR
LEFT JOIN gold.dim_rating AS DR
	ON FR.rating_key = DR.rating_key
GROUP BY DR.rating
)
SELECT 
	rating,
	total_reviews,
	CAST(total_reviews * 100.0 / SUM(total_reviews) OVER() AS DECIMAL(10,2)) AS review_share_pct
FROM rating_summary
ORDER BY total_reviews DESC;


-- How many reviews does each category get, and what is its average rating
SELECT 
	P.category,
	COUNT(*) AS total_reviews,
	CAST(AVG(CAST(DR.rating AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_rating
FROM gold.fact_reviews AS FR
LEFT JOIN gold.dim_rating AS DR
	ON FR.rating_key = DR.rating_key
LEFT JOIN gold.dim_products AS P
	ON FR.product_key = P.product_key
GROUP BY P.category
ORDER BY avg_rating DESC;


-- ============================================================
-- Group 6: Two Categories Together
-- How do two descriptive columns relate to each other?
-- ============================================================

-- Are the shipment statuses spread evenly across the carriers, or does one carrier have more cancelled or pending shipments
SELECT 
	carrier,
	shipment_status,
	COUNT(*) AS total_shipments
FROM gold.dim_shipments
GROUP BY carrier,
	shipment_status
ORDER BY carrier, shipment_status;

-- How are the order items of each category spread across the shipment statuses, and what share of them is cancelled?
SELECT 
	P.category,
	SUM(CASE WHEN SP.shipment_status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_items,
	SUM(CASE WHEN SP.shipment_status = 'Shipped' THEN 1 ELSE 0 END) AS shipped_items,
	SUM(CASE WHEN SP.shipment_status = 'Pending' THEN 1 ELSE 0 END) AS pending_items,
	SUM(CASE WHEN SP.shipment_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_items,
	COUNT(*) AS total_items,
	CAST(SUM(CASE WHEN SP.shipment_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) AS cancelled_share_pct
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_products AS P
	ON S.product_key = P.product_key
LEFT JOIN gold.dim_shipments AS SP
	ON S.shipment_key = SP.shipment_key
GROUP BY P.category
ORDER BY total_items DESC;


-- ============================================================
-- Group 7: Ranking
-- Which products, customers and suppliers lead in sales?
-- ============================================================

-- Which five products bring in the most sales
SELECT TOP 5 
	P.product_id,
	P.category,
	P.product_name,
	SUM(S.sales_amount) AS total_sales
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_products AS P
	ON S.product_key = P.product_key
GROUP BY P.product_id,
	P.category,
	P.product_name
ORDER BY total_sales DESC;

-- Which products have never been sold?

SELECT 
	P.product_id,
	P.category,
	P.product_name
FROM gold.dim_products AS P
LEFT JOIN gold.fact_sales AS S
	ON P.product_key = S.product_key
WHERE S.product_key IS NULL;


-- Who are our top 10 customers by sales, and how many orders did each place?
SELECT TOP 10
	S.customer_key,
	C.customer_name,
	COUNT(DISTINCT S.order_id) AS total_orders,
	SUM(S.sales_amount) AS total_revenue
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_customers AS C
	ON S.customer_key = C.customer_key
GROUP BY S.customer_key,
	C.customer_name
ORDER BY total_revenue DESC;

-- What are the 10 biggest single purchases, and who bought which product?
WITH top_purchases AS (
SELECT TOP 10
	C.customer_key,
	P.product_key,
	S.quantity,
	S.unit_selling_price,
	S.sales_amount
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_customers AS C
	ON S.customer_key = C.customer_key
LEFT JOIN gold.dim_products AS P
	ON S.product_key = P.product_key
ORDER BY S.sales_amount DESC
)

SELECT 
	C.customer_name,
	P.product_name,
	P.category,
	TP.quantity,
	TP.unit_selling_price,
	TP.sales_amount
FROM top_purchases AS TP
LEFT JOIN gold.dim_customers AS C
	ON TP.customer_key = C.customer_key
LEFT JOIN gold.dim_products AS P
	ON TP.product_key = P.product_key
ORDER BY sales_amount DESC;

-- Which 10 suppliers bring in the most sales, and how many units and products does each one sell?
WITH top_suppliers AS (
	SELECT TOP 10
		supplier_key,
		SUM(sales_amount) AS total_sales,
		SUM(quantity) AS units_sold,
		COUNT(DISTINCT product_key) AS products_sold
	FROM gold.fact_sales
	GROUP BY supplier_key
	ORDER BY total_sales DESC
)
SELECT
	TS.supplier_key,
	SP.supplier_name,
	TS.total_sales,
	TS.units_sold,
	TS.products_sold
FROM top_suppliers AS TS
LEFT JOIN gold.dim_suppliers AS SP
	ON TS.supplier_key = SP.supplier_key
ORDER BY TS.total_sales DESC;



