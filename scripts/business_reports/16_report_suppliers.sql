-- ============================================================
-- Script    : 16_report_suppliers.sql
-- Project   : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose   : Create the supplier report: one row per supplier with
--             sales, number of reviews, average product rating and
--             risk group.
-- Creates   : gold.report_suppliers
-- Views used: fact_sales, dim_suppliers, fact_reviews, dim_rating
-- Usage     : SELECT * FROM gold.report_suppliers;
-- Note      : Suppliers without reviews show 0 reviews and an empty
--             rating, and fall into the No reviews group.
-- Author    : Surajit
-- Date      : 2026-11-19
-- ============================================================


-- Supplier report: one row per supplier
-- Shows each supplier's sales, reviews, average product rating and risk group
-- A low rating means an average of 2 or below, and revenue is compared with the average supplier
IF OBJECT_ID('gold.report_suppliers', 'V') IS NOT NULL
    DROP VIEW gold.report_suppliers;
GO
CREATE VIEW gold.report_suppliers AS
WITH supplier_sales AS (
SELECT 
	S.supplier_key,
	SP.supplier_id,
	SP.supplier_name,
	SP.state_code,
	COUNT(DISTINCT S.product_key) AS products_sold,
	SUM(S.quantity) AS units_sold,
	SUM(S.sales_amount) AS revenue
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_suppliers AS SP
	ON S.supplier_key = SP.supplier_key
GROUP BY S.supplier_key,
	SP.supplier_id,
	SP.supplier_name,
	SP.state_code
)
, supplier_ratings AS (
SELECT 
	FR.supplier_key,
	COUNT(FR.review_id) AS reviews,
	CAST(AVG(CAST(DR.rating AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_rating
FROM gold.fact_reviews AS FR
LEFT JOIN gold.dim_rating AS DR
	ON FR.rating_key = DR.rating_key
GROUP BY FR.supplier_key
)
SELECT 
	S.supplier_key,
	S.supplier_id,
	S.supplier_name,
	S.state_code,
	S.products_sold,
	S.units_sold,
	S.revenue,
	ISNULL(R.reviews, 0) AS reviews,
	R.avg_rating,
	CASE 
		WHEN R.avg_rating <= 2 AND S.revenue >=
			AVG(S.revenue) OVER() THEN 'High revenue, low rating'
		WHEN R.avg_rating > 2 AND S.revenue >=
			AVG(S.revenue) OVER() THEN 'High revenue, OK rating'
		WHEN R.avg_rating <= 2 AND S.revenue <
			AVG(S.revenue) OVER() THEN 'Low revenue, low rating'
		WHEN R.avg_rating > 2 AND S.revenue < 
			AVG(S.revenue) OVER() THEN 'Low revenue, OK rating'
		ELSE 'No reviews'
	END AS supplier_group
FROM supplier_sales AS S
LEFT JOIN supplier_ratings AS R
	ON S.supplier_key = R.supplier_key;
GO
