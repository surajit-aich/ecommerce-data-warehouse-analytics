-- ============================================================
-- Script    : 12_merchandising_analysis.sql
-- Project   : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose   : Answer merchandising questions about our products:
--             how much revenue comes from bulk buying, which products
--             lead each category, which ones carry most of the revenue,
--             and which ones sell well despite poor ratings.
-- Views     : fact_sales, dim_products, fact_reviews, dim_rating
-- Questions : 1. Revenue from small, medium and bulk orders
--             2. Top 3 product types in each category
--             3. ABC product classes
--             4. Poorly rated products that still sell
-- Note      : Every order in the data holds one product, so a bulk
--             order means many units of the same product.
--             All queries only read data.
-- Author    : Surajit
-- Date      : 2026-11-19
-- ============================================================

-- How much of our revenue comes from bulk orders
-- If a big part of revenue comes from customers who buy in large amounts, the business depends on them and should look after them
-- Groups orders as small, medium or bulk by their total units, with each group's share of orders and revenue and its average order value
-- Helps decide whether volume prices or minimum order offers are worth trying
WITH order_quantities AS (
SELECT 
	order_id,
	SUM(quantity) AS units,
	SUM(sales_amount) AS order_revenue
FROM gold.fact_sales
GROUP BY order_id
)
, order_size_bands AS (
SELECT 
	order_id,
	units,
	order_revenue,
	CASE 
		WHEN units BETWEEN 1 AND 3 THEN 'Small (1 to 3 units)'
		WHEN units BETWEEN 4 AND 7 THEN 'Medium (4 to 7 units)'
		ELSE 'Bulk (8 or more units)'
	END AS order_size
FROM order_quantities
)
, order_size_summary AS (
SELECT 
	order_size,
	COUNT(*) AS orders,
	SUM(order_revenue) AS revenue
FROM order_size_bands
GROUP BY order_size
)
SELECT 
	order_size,
	orders,
	revenue,
	CAST(orders * 100.0 / SUM(orders) OVER() AS DECIMAL(10,2)) AS order_share_pct,
	CAST(revenue * 100.0 / SUM(revenue) OVER() AS DECIMAL(10,2)) AS revenue_share_pct,
	CAST(revenue / orders AS DECIMAL(10,2)) AS avg_order_value
FROM order_size_summary;


-- Top 3 product types by revenue in each category
-- Category managers need to know which products bring in the most money in their own category
-- Shows the three product types with the most revenue in each category, with their units sold and rank
-- Helps decide which products to always keep in stock and lead promotions with
WITH product_type_sales AS (
SELECT 
	P.category,
	P.product_name,
	SUM(S.quantity) AS units_sold,
	SUM(S.sales_amount) AS revenue
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_products AS P
	ON S.product_key = P.product_key
-- A product type is a product name, such as 4K Monitor, which covers several product IDs in the same category
GROUP BY P.category,
	P.product_name
)
SELECT 
	category,
	product_name,
	units_sold,
	revenue,
	revenue_rank
FROM 
(SELECT 
	category,
	product_name,
	units_sold,
	revenue,
	DENSE_RANK () OVER(PARTITION BY category
		ORDER BY revenue DESC) AS revenue_rank
FROM product_type_sales) t 
WHERE revenue_rank <= 3;


-- Which products bring most of our revenue (ABC classes)
-- Products don't earn the same, so giving them all the same stock and attention wastes money
-- Shows how many products make up most of the revenue, and how many add only a small part
-- Helps decide what to always keep in stock and what to review, discount or drop
WITH product_revenue AS (
SELECT 
	product_key,
	SUM(sales_amount) AS revenue
FROM gold.fact_sales
GROUP BY product_key
)
, running_share AS (
SELECT 
	product_key,
	revenue,
	SUM(revenue) OVER(ORDER BY revenue DESC
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0 /
		SUM(revenue) OVER() AS running_share_pct
FROM product_revenue
)
, classified_products AS (
SELECT 
	product_key,
	revenue,
	running_share_pct,
-- A = the products that make the first 80% of revenue, B = the next 15%, C = the last 5%
	CASE 
		WHEN running_share_pct <= 80 THEN 'A'
		WHEN running_share_pct <= 95 THEN 'B'
		ELSE 'C'
	END AS abc_class
FROM running_share
)
SELECT 
	abc_class,
	products,
	revenue,
	CAST(products * 100.0 / SUM(products) OVER() AS DECIMAL(10,2)) AS product_share_pct,
	CAST(revenue * 100.0 / SUM(revenue) OVER() AS DECIMAL(10,2)) AS revenue_share_pct
FROM
(SELECT 
	abc_class,
	COUNT(*) AS products,
	SUM(revenue) AS revenue
FROM classified_products
GROUP BY abc_class) t;


-- Which products sell well even though customers rate them poorly
-- These products bring in good money, but low ratings can lead to complaints and lost repeat orders
-- Shows the low-rated products that still sell more than an average product
-- Helps pick the products that need a quality check or a talk with their supplier
WITH product_sales AS (
SELECT 
	P.product_key,
	P.product_id,
	P.category,
	P.product_name,
	SUM(S.quantity) AS units_sold,
	SUM(S.sales_amount) AS sales
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_products AS P
	ON S.product_key = P.product_key
GROUP BY P.product_key,
	P.product_id,
	P.category,
	P.product_name
)
,sales_with_avg AS (
SELECT 
	product_key,
	product_id,
	category,
	product_name,
	units_sold,
	sales,
-- The average is taken over all products that sold, before the join with reviews
	AVG(sales) OVER () AS avg_product_sales
FROM product_sales
)
, product_ratings AS (
SELECT 
	FR.product_key,
	COUNT(FR.review_id) AS reviews,
	CAST(AVG(CAST(DR.rating AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_rating
FROM gold.fact_reviews AS FR
LEFT JOIN gold.dim_rating AS DR
	ON FR.rating_key = DR.rating_key
GROUP BY FR.product_key
)
SELECT 
	SAVG.product_id,
	SAVG.category,
	SAVG.product_name,
	PR.reviews,
	PR.avg_rating,
	SAVG.units_sold,
	SAVG.sales
FROM sales_with_avg AS SAVG
INNER JOIN product_ratings AS PR
	ON SAVG.product_key = PR.product_key
-- Poorly rated means an average of 2 or below, and selling well means more than the average product
WHERE PR.avg_rating <= 2 AND 
	SAVG.sales > SAVG.avg_product_sales
ORDER BY sales DESC;