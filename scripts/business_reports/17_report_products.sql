-- ============================================================
-- Script    : 17_report_products.sql
-- Project   : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose   : Create the product report: one row per product with
--             units sold, revenue, ABC class, number of reviews and
--             average rating.
-- Creates   : gold.report_products
-- Views used: fact_sales, dim_products, fact_reviews, dim_rating
-- Usage     : SELECT * FROM gold.report_products;
-- Note      : Products that never sold show 0 sales and the class
--             Not sold. Products without reviews show 0 reviews and
--             an empty rating.
-- Author    : Surajit
-- Date      : 2026-11-19
-- ============================================================


-- Product report: one row per product, including products that never sold
-- Shows each product's sales, ABC class, number of reviews and average rating
-- A class products make the first 80% of revenue, B the next 15%, and C the last 5%
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO
CREATE VIEW gold.report_products AS
WITH product_sales AS (
SELECT 
	product_key,
	SUM(quantity) AS units_sold,
	SUM(sales_amount) AS revenue
FROM gold.fact_sales
GROUP BY product_key
)
, running_share AS (
SELECT 
	product_key,
	units_sold,
	revenue,
	SUM(revenue) OVER(ORDER BY revenue DESC
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0 /
		SUM(revenue) OVER() AS running_share_pct
FROM product_sales
)
, abc_classes AS (
SELECT 
	product_key,
	units_sold,
	revenue,
	CASE 
		WHEN running_share_pct <= 80 THEN 'A'
		WHEN running_share_pct <= 95 THEN 'B'
		ELSE 'C'
	END AS abc_class
FROM running_share
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
	P.product_key,
	P.product_id,
	P.product_name,
	P.category,
	P.listed_price,
	COALESCE(A.units_sold, 0) AS units_sold,
	COALESCE(A.revenue, 0) AS revenue,
	COALESCE(A.abc_class, 'Not sold') AS abc_class,
	COALESCE(R.reviews, 0) AS reviews,
	R.avg_rating
FROM gold.dim_products AS P
LEFT JOIN abc_classes AS A
	ON P.product_key = A.product_key
LEFT JOIN product_ratings AS R
	ON P.product_key = R.product_key;
GO