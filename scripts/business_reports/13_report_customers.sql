-- ============================================================
-- Script    : 13_report_customers.sql
-- Project   : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose   : Create the customer report: one row per customer with
--             orders, spend, recency, RFM scores and tier, so anyone
--             can see who to reward or win back with a simple SELECT.
-- Creates   : gold.report_customers
-- Views used: fact_sales, dim_customers
-- Usage     : SELECT * FROM gold.report_customers;
-- Author    : Surajit
-- Date      : 2026-11-19
-- ============================================================

-- Customer report: one row per customer
-- Shows each customer's orders, spend, recency, RFM scores and tier in one place
IF OBJECT_ID ('gold.report_customers','V') IS NOT NULL
	DROP VIEW gold.report_customers;
GO
CREATE VIEW gold.report_customers AS 
WITH customer_orders AS (
SELECT 
	S.customer_key,
	C.customer_id,
	C.customer_name,
	C.state_code,
	S.order_id,
	S.order_date,
	SUM(S.sales_amount) AS revenue
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_customers AS C
	ON S.customer_key = C.customer_key
GROUP BY S.customer_key,
	C.customer_id,
	C.customer_name,
	C.state_code,
	S.order_id,
	S.order_date
)
, customer_totals AS (
SELECT 
	customer_key,
	customer_id,
	customer_name,
	state_code,
	MIN(order_date) AS first_order_date,
	MAX(order_date) AS last_order_date,
	COUNT(DISTINCT order_id) AS orders,
	SUM(revenue) AS total_spend,
	DATEDIFF(day, MAX(order_date) , (SELECT 
		MAX(order_date) FROM gold.fact_sales)) AS recency_days
FROM customer_orders
GROUP BY customer_key,
	customer_id,
	customer_name,
	state_code
)
, rfm_scores AS (
SELECT 
	customer_key,
	customer_id,
	customer_name,
	state_code,
	first_order_date,
	last_order_date,
	orders,
	total_spend,
	CAST(total_spend / orders AS DECIMAL(10,2)) AS avg_order_value,
	recency_days,
	DATETRUNC(month, first_order_date) AS first_order_month,
	NTILE(4) OVER(ORDER BY recency_days DESC, customer_key) AS r_score,
	CASE 
		WHEN orders = 2 THEN 4
		ELSE 1
	END AS f_score,
	NTILE(4) OVER(ORDER BY total_spend, customer_key) AS m_score
FROM customer_totals
)

SELECT 
	customer_key,
	customer_id,
	customer_name,
	state_code,
	first_order_date,
	last_order_date,
	first_order_month,
	orders,
	total_spend,
	avg_order_value,
	recency_days,
	r_score,
	f_score,
	m_score,
	r_score + f_score + m_score AS rfm_score,
	CASE 
		WHEN r_score + f_score + m_score >= 11 THEN 'VIP'
		WHEN r_score + f_score + m_score >= 9 THEN 'Loyal'
		WHEN r_score + f_score + m_score >= 6 THEN 'At-Risk'
		ELSE 'Lost'
	END AS customer_tier
FROM rfm_scores;
GO