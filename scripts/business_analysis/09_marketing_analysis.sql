-- ============================================================
-- Script    : 09_marketing_analysis.sql
-- Project   : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose   : Answer marketing questions about our customers: how
--             valuable they are, when and whether they come back,
--             and how much revenue depends on the biggest spenders.
-- Views     : fact_sales
-- Questions : 1. Customer tiers (VIP, Loyal, At-Risk, Lost)
--             2. Revenue and average order value by tier
--             3. Days between the first and second order
--             4. Repeat rate by first-order month (cohort)
--             5. Revenue share of each 20% group of customers
-- Note      : "Today" is the last order date in the data, so the
--             results never change. All queries only read data.
-- Author    : Surajit
-- Date      : 2026-11-18
-- ============================================================



-- Which customers are VIP, Loyal, At-Risk or Lost, based on how recently they bought, how often and how much they spent
-- Customers are not all worth the same, so marketing needs to know where to spend its effort
-- Groups every customer into a tier using recency, frequency and spending scores
-- Helps decide who to reward, who to win back and who needs less attention
WITH customers_spending AS (
SELECT 
	customer_key,
	COUNT(DISTINCT order_id) AS total_orders,
	MAX(order_date) AS last_order_date,
	SUM(sales_amount) AS total_spend
FROM gold.fact_sales
GROUP BY customer_key
)
, customer_recency AS (
SELECT 
	customer_key,
	total_orders,
	last_order_date,
	total_spend,
	DATEDIFF(day,last_order_date,(SELECT MAX(order_date) FROM gold.fact_sales)) AS recency_days
FROM customers_spending
)
, rfm_score AS (
SELECT 
	customer_key,
	total_orders,
	total_spend,
	recency_days,
	NTILE(4) OVER(ORDER BY recency_days DESC, customer_key) AS r_score,
	CASE 
		WHEN total_orders = 2 THEN 4
		ELSE 1
	END AS f_score,
	NTILE(4) OVER(ORDER BY total_spend, customer_key) AS m_score
FROM customer_recency
)
, customer_tiers AS (
SELECT 
	customer_key,
	r_score + f_score + m_score AS total_score,
	CASE 
		WHEN r_score + f_score + m_score >= 11 THEN 'VIP'
		WHEN r_score + f_score + m_score >= 9 THEN 'Loyal'
		WHEN r_score + f_score + m_score >= 6 THEN 'At-Risk'
		ELSE 'Lost'
	END AS customer_tier
FROM rfm_score
)
, tier_summary AS (
SELECT 
	customer_tier,
	COUNT(*) AS total_customers,
	MAX(total_score) AS top_score
FROM customer_tiers
GROUP BY customer_tier
)

SELECT 
	customer_tier,
	total_customers,
	CAST(total_customers * 100.0 / SUM(total_customers) OVER() AS DECIMAL(10,2)) AS customer_share_pct 
FROM tier_summary
ORDER BY top_score DESC;


-- Which customer tier brings the most revenue, and how does its average order value compare with the lowest tier
-- A big tier is not always the one that brings the money, and the retention budget should follow the revenue
-- Shows each tier's customers, orders, revenue share and average order value
-- Helps decide which tiers to protect first and where order value can be raised
WITH customer_totals AS (
SELECT 
	customer_key,
	COUNT(DISTINCT order_id) AS total_orders,
	MAX(order_date) AS last_order_date,
	SUM(sales_amount) AS total_spending
FROM gold.fact_sales
GROUP BY customer_key
)
, customer_recency AS (
SELECT 
	customer_key,
	total_orders,
	last_order_date,
	total_spending,
	DATEDIFF(day,last_order_date,(SELECT MAX(Order_date) FROM gold.fact_sales)) AS recency_days
FROM customer_totals
)
, rfm_scores AS (
SELECT 
	customer_key,
	total_orders,
	total_spending,
	recency_days,
	NTILE(4) OVER(ORDER BY recency_days DESC, customer_key) AS r_score,
	CASE 
		WHEN total_orders = 2 THEN 4
		ELSE 1
	END AS f_score,
	NTILE(4) OVER(ORDER BY total_spending, customer_key) AS m_score
FROM customer_recency
)
, customer_tiers AS (
SELECT 
	customer_key,
	total_orders,
	total_spending,
	r_score + f_score + m_score AS total_scores,
	CASE	
		WHEN r_score + f_score + m_score >= 11 THEN 'VIP'
		WHEN r_score + f_score + m_score >= 9 THEN 'Loyal'
		WHEN r_score + f_score + m_score >= 6 THEN 'At-Risk'
		ELSE 'Lost'
	END AS customer_tier
FROM rfm_scores
)
, tier_summary AS (
SELECT 
	customer_tier,
	COUNT(*) AS customers,
	SUM(total_orders) AS orders,
	SUM(total_spending) AS revenue
FROM customer_tiers
GROUP BY customer_tier
)
SELECT 
	customer_tier,
	customers,
	orders,
	revenue,
	CAST(revenue * 100.0 / SUM(revenue) OVER() AS DECIMAL(10,2)) AS revenue_share_pct,
	CAST(revenue / orders AS DECIMAL(10,2)) AS avg_order_value
FROM tier_summary
ORDER BY revenue DESC;



-- How many days pass between the first and second order of a repeat customer, in each customer tier
-- Marketing needs to know when customers usually come back, to time reminders and offers
-- Shows the average number of days between the two orders for repeat customers in each tier
-- Helps decide when to contact customers who haven't ordered again yet
WITH customer_recency AS (
SELECT 
	customer_key,
	COUNT(DISTINCT order_id) AS total_orders,
	MAX(order_date) AS last_order_date,
	SUM(sales_amount) AS total_spending,
	DATEDIFF(day,MAX(order_date),(SELECT MAX(Order_date) FROM gold.fact_sales)) AS recency_days
FROM gold.fact_sales
GROUP BY customer_key
)
, rfm_score AS (
SELECT 
	customer_key,
	recency_days,
	NTILE(4) OVER(ORDER BY recency_days DESC, customer_key) AS r_score,
	CASE 
		WHEN total_orders = 2 THEN 4
		ELSE 1
	END AS f_score,
	NTILE(4) OVER(ORDER BY total_spending, customer_key) AS m_score
FROM customer_recency
)
,customer_tiers AS (
SELECT 
	customer_key,
	r_score + f_score + m_score AS total_scores,
	CASE	
		WHEN r_score + f_score + m_score >= 11 THEN 'VIP'
		WHEN r_score + f_score + m_score >= 9 THEN 'Loyal'
		WHEN r_score + f_score + m_score >= 6 THEN 'At-Risk'
		ELSE 'Lost'
	END AS customer_tier
FROM rfm_score	
)
, customer_orders AS (
SELECT DISTINCT
	customer_key,
	order_id,
	order_date
FROM gold.fact_sales
)
, order_gaps AS (
SELECT 
	customer_key,
	order_id,
	order_date,
	previous_order_date,
	DATEDIFF(day, previous_order_date, order_date) AS days_between
FROM 
(SELECT 
	customer_key,
	order_id,
	order_date,
	LAG(order_date) OVER(PARTITION BY customer_key 
		ORDER BY order_date, order_id) AS previous_order_date
FROM customer_orders) t
WHERE previous_order_date IS NOT NULL
)
Select 
	customer_tier,
	COUNT(*) AS repeat_customer,
	CAST(AVG(days_between * 1.0) AS DECIMAL(10,2)) AS average_days
FROM order_gaps AS G
LEFT JOIN customer_tiers AS CT
	ON G.customer_key = CT.customer_key
GROUP BY customer_tier
ORDER BY average_days;




-- Of the customers who first bought in each month, how many came back and ordered again (cohort analysis)
-- The business needs to know whether new customers come back for a second order
-- Shows each first-order month's new customers, how many of them ordered again and the repeat rate
-- Helps track whether new customers are being kept, month after month
WITH customer_order_dates AS (
SELECT 
	customer_key,
	COUNT(DISTINCT order_id) AS total_orders,
	MIN(order_date) AS first_order_date,
	MAX(order_date) AS last_order_date
FROM gold.fact_sales
GROUP BY customer_key
)
, customer_cohorts AS (
SELECT 
	customer_key,
	total_orders,
	first_order_date,
	last_order_date,
	DATETRUNC(month, first_order_date) AS cohort_month
FROM customer_order_dates
)
SELECT 
	cohort_month,
	customers,
	repeat_customers,
	CAST(repeat_customers * 100.0 / customers AS DECIMAL(10,2)) AS repeat_rate_pct
FROM 
(SELECT 
	cohort_month,
	COUNT(customer_key) AS customers,
	SUM(CASE
		WHEN total_orders = 2 THEN 1
		ELSE 0
	END) AS repeat_customers
FROM customer_cohorts
GROUP BY cohort_month
)t
ORDER BY cohort_month;



-- How much revenue does each 20% group of customers bring, from the biggest spenders to the smallest
-- The business needs to know whether it depends on a small group of big customers
-- Shows the customers, revenue and revenue share of each group, from the top spenders down
-- Helps judge the risk of losing top customers and where retention money matters most
WITH customer_spending AS (
SELECT 
	customer_key,
	SUM(sales_amount) AS total_spend
FROM gold.fact_sales
GROUP BY customer_key
)
, spend_groups AS (
SELECT 
	customer_key,
	total_spend,
	NTILE(5) OVER(ORDER BY total_spend DESC, customer_key) AS spend_group
FROM customer_spending
)
SELECT 
	spend_group,
	customers,
	revenue,
	CAST(revenue * 100.0 / SUM(revenue) OVER() AS DECIMAL(10,2)) AS share_pct 
FROM 
(SELECT 
	spend_group,
	COUNT(customer_key) AS customers,
	SUM(total_spend) AS revenue
FROM spend_groups
GROUP BY spend_group) t
ORDER By spend_group;