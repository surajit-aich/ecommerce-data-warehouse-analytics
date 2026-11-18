-- ============================================================
-- Script    : 10_finance_analysis.sql
-- Project   : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose   : Answer finance questions about revenue: how it moves
--             month to month, how much is lost to failed or pending
--             payments, and which categories drive the changes.
-- Views     : fact_sales, dim_payment, dim_products
-- Questions : 1. Monthly revenue, daily average, change from last month and running total
--             2. Revenue lost to failed payments by month
--             3. Pending payments by age
--             4. Orders and revenue per day, weekdays vs weekends
--             5. Each category's monthly revenue against its own average
-- Note      : Questions 1 and 5 use only the full months, December 2023
--             to October 2024. All queries only read data.
-- Author    : Surajit
-- Date      : 2026-11-18
-- ============================================================

-- How does revenue change from month to month, and what is the running total over the full months
-- Finance needs to see which months grow or fall and how revenue builds up over the year
-- Shows each month's revenue, its average revenue per day, the change from the previous month and the running total
-- Helps spot weak months early and track the year against its revenue target
WITH monthly_revenue AS (
SELECT 
	DATETRUNC(month, order_date) AS order_month,
	SUM(sales_amount) AS revenue
FROM gold.fact_sales
-- Only full months are used: the data starts on 5 Nov 2023 and ends on 4 Nov 2024, so those two months are partial
WHERE order_date >= '2023-12-01' AND order_date < '2024-11-01'
GROUP BY DATETRUNC(month, order_date)
) 
SELECT 
	order_month,
	revenue,
	CAST(revenue / DAY(EOMONTH(order_month)) AS DECIMAL(10,2)) AS avg_daily_revenue,
	previous_month_revenue,
	CAST((revenue - previous_month_revenue) * 100.0 / previous_month_revenue AS DECIMAL(10,2)) AS mom_change_pct,
	running_total
FROM
(SELECT 
	order_month,
	revenue,
	LAG(revenue) OVER(ORDER BY order_month) AS previous_month_revenue,
	SUM(revenue) OVER(ORDER BY order_month) AS running_total
FROM monthly_revenue)t
ORDER BY order_month;


-- How much revenue is lost to failed payments each month, and what share of the month's revenue is that
-- A failed payment means an order with no money coming in, so finance needs to know the size of the loss and whether it is growing
-- Shows each month's orders, failed orders, revenue, failed revenue and the failed share
-- Helps judge how big the payment problem is and how urgently it needs fixing
WITH order_revenue AS (
SELECT 
	order_id,
	payment_status,
	DATETRUNC(month, order_date) AS order_month,
	SUM(sales_amount) AS order_revenue
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_payment AS P
	ON S.payment_key = P.payment_key
GROUP BY order_id,
	payment_status,
	DATETRUNC(month, order_date)
) 
, monthly_payment_summary AS (
SELECT 
	order_month,
	COUNT(*) AS orders,
	SUM(CASE 
		WHEN payment_status = 'Failed' THEN 1
		ELSE 0
	END) AS failed_orders,
	SUM(order_revenue) AS total_revenue,
	SUM(CASE
		WHEN payment_status = 'Failed' THEN order_revenue
		ELSE 0
	END) AS failed_revenue
FROM order_revenue
-- All 13 months are kept: the failed share compares figures from the same month, so the partial months are still fair
GROUP BY order_month
)
SELECT 
	order_month,
	orders,
	failed_orders,
	total_revenue,
	failed_revenue,
	CAST(failed_revenue * 100.0 / total_revenue AS DECIMAL(10,2)) AS failed_share_pct
FROM monthly_payment_summary
ORDER BY order_month;


-- How much money is stuck in pending payments, and for how long
-- Unpaid orders get harder to collect the older they are, so finance needs to know how old its pending money is
-- Groups pending orders into 30-day age bands, the usual way finance reviews unpaid money, with the orders and amount in each
-- Helps decide which pending payments to chase first and which to write off
WITH pending_orders AS (
SELECT 
	order_id,
	order_date,
	SUM(sales_amount) AS order_revenue,
-- Age is counted from the order date up to the last order date in the data, since there is no payment due date
	DATEDIFF(day, order_date, (SELECT MAX(order_date)
		FROM gold.fact_sales)) AS days_pending
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_payment AS P
	ON S.payment_key = P.payment_key
WHERE payment_status = 'Pending'
GROUP BY order_id,
	order_date
)
, pending_age_bands AS (
SELECT 
	order_id,
	order_date,
	order_revenue,
	days_pending,
	CASE
		WHEN days_pending BETWEEN 0 AND  30 THEN '0 to 30 days'
		WHEN days_pending BETWEEN 31 AND 60 THEN '31 to 60 days'
		WHEN days_pending BETWEEN 61 AND 90 THEN '61 to 90 days'
		ELSE 'Over 90 days'
	END AS age_band
FROM pending_orders
)
SELECT
	age_band,
	orders,
	pending_revenue,
	CAST(pending_revenue * 100.0 / SUM(pending_revenue) OVER() AS DECIMAL(10,2)) AS pending_share_pct
FROM 
(SELECT 
	age_band,
	COUNT(*) AS orders,
	SUM(order_revenue) AS pending_revenue
FROM pending_age_bands
GROUP BY age_band) t
ORDER BY age_band;


-- Do weekdays and weekends differ in the orders and revenue they bring each day
-- The business needs to know whether weekends need different campaigns, stock or staff
-- Shows the average orders and revenue per day for weekdays and for weekends
-- Helps decide whether weekends should be planned differently from weekdays
WITH sales_by_day_type AS (
SELECT 
	order_date,
	CASE
		WHEN DATENAME(weekday, order_date) IN ('Saturday','Sunday') THEN 'Weekend'
		ELSE 'Weekday'
	END AS day_type,
	order_id,
	sales_amount
FROM gold.fact_sales
)
SELECT 
	day_type,
	days,
	total_orders,
	total_revenue,
-- Divided by the number of days, since there are far more weekdays than weekend days
	CAST(total_orders * 1.0 / days AS DECIMAL(10,2)) AS avg_daily_orders,
	CAST(total_revenue * 1.0 / days AS DECIMAL(10,2)) AS avg_daily_revenue
FROM 
(SELECT 
	day_type,
	COUNT(DISTINCT order_date) AS days,
	COUNT(DISTINCT order_id) AS total_orders,
	SUM(sales_amount) AS total_revenue
FROM sales_by_day_type
GROUP BY day_type)t
ORDER BY day_type;


-- Which product categories sold above or below their usual level in each month
-- Categories differ a lot in size, so each one has to be judged against its own normal month to see its real ups and downs
-- Shows each category's monthly revenue next to its own monthly average, with the gap in value and in percent
-- Helps explain which categories caused a rise or fall in total revenue, and where stock plans need a buffer
WITH category_monthly_revenue AS (
SELECT 
	P.category,
	DATETRUNC(month, S.order_date) AS order_month,
	SUM(S.sales_amount) AS revenue
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_products AS P
	ON S.product_key = P.product_key
-- Only full months are used: the first and last months are partial and would pull the averages down
WHERE S.order_date >= '2023-12-01' AND S.order_date < '2024-11-01'
GROUP BY P.category,
	DATETRUNC(month, S.order_date)
)
SELECT 
	category,
	order_month,
	revenue,
	CAST(AVG(revenue) OVER(PARTITION BY category) AS DECIMAL(10,2)) AS avg_monthly_revenue,
	CAST(revenue - AVG(revenue) OVER(PARTITION BY category) AS DECIMAL(10,2)) AS diff_from_avg,
	CAST((revenue - AVG(revenue) OVER(PARTITION BY category)) * 100.0
		/ AVG(revenue) OVER(PARTITION BY category) AS DECIMAL(10,2)) AS pct_vs_avg
FROM category_monthly_revenue
ORDER BY category, order_month;