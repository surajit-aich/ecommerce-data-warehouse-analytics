-- ============================================================
-- Script    : 14_report_monthly_sales.sql
-- Project   : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose   : Create the monthly sales report: one row per month with
--             orders, customers, revenue, daily average, growth from
--             the previous month and the running total.
-- Creates   : gold.report_monthly_sales
-- Views used: fact_sales
-- Usage     : SELECT * FROM gold.report_monthly_sales ORDER BY order_month;
-- Note      : Only the full months, December 2023 to October 2024,
--             are included.
-- Author    : Surajit
-- Date      : 2026-11-19
-- ============================================================

-- Monthly sales report: one row per month, from December 2023 to October 2024
-- The first and last months are left out because they are not full months
-- Shows orders, customers, units, revenue, average order value, average daily revenue, growth from the previous month and the running total
IF OBJECT_ID('gold.report_monthly_sales', 'V') IS NOT NULL
    DROP VIEW gold.report_monthly_sales;
GO
CREATE VIEW gold.report_monthly_sales AS 
WITH monthly_totals AS (
SELECT 
	DATETRUNC(month, order_date) AS order_month,
	COUNT(DISTINCT order_id) AS orders,
	COUNT(DISTINCT customer_key) AS customers,
	SUM(quantity) AS units_sold,
	SUM(sales_amount) AS revenue
FROM gold.fact_sales
WHERE order_date >= '2023-12-01' AND order_date < '2024-11-01'
GROUP BY DATETRUNC(month, order_date)
)
SELECT 
	order_month,
	orders,
	customers,
	units_sold,
	revenue,
	CAST(revenue / DAY(EOMONTH(order_month)) AS DECIMAL(10,2)) AS avg_daily_revenue,
	CAST(revenue / orders AS DECIMAL(10,2)) AS avg_order_value,
	LAG(revenue) OVER(ORDER BY order_month) AS prev_month_revenue,
	CAST((revenue - LAG(revenue) OVER(ORDER BY order_month)) * 100.0 /
		LAG(revenue) OVER(ORDER BY order_month) AS DECIMAL(10,2)) AS mom_change_pct,
	SUM(revenue) OVER(ORDER BY order_month 
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_revenue
FROM monthly_totals;
GO