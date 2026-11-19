-- ============================================================
-- Script    : 11_logistics_analysis.sql
-- Project   : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose   : Answer logistics questions about delivery and supply:
--             how long orders take, where the delays come from, and
--             which suppliers carry the most risk.
-- Views     : fact_sales, dim_shipments, dim_customers,
--             fact_reviews, dim_rating
-- Questions : 1. Order time split into warehouse and carrier time
--             2. Late delivery share by carrier
--             3. Supplier groups by revenue and product rating
--             4. Late delivery share by customer state
-- Note      : Only delivered orders are used for delivery times.
--             "Late" means more than 9 days from order to delivery,
--             since the data has no promised delivery date.
--             All queries only read data.
-- Author    : Surajit
-- Date      : 2026-11-19
-- ============================================================


-- How long does an order take to reach the customer, and how much of that time is spent in our warehouse and how much with the carrier
-- Slow delivery hurts customers, and the business needs to know which part of the wait it can actually fix
-- Shows the average processing, transit and total days for delivered orders, the fastest and slowest delivery, and the carrier's share of the time
-- Helps decide whether to work on warehouse speed or carrier performance first
WITH delivered_order_durations AS (
SELECT DISTINCT
	order_id,
	order_date,
	shipment_date,
	delivery_date,
	DATEDIFF(day, order_date, shipment_date) AS processing_days,
	DATEDIFF(day, shipment_date, delivery_date) AS transit_days,
	DATEDIFF(day, order_date, shipment_date) + DATEDIFF(day, shipment_date, delivery_date) AS total_days
FROM gold.fact_sales
-- Only delivered orders are used, since the others have no delivery date yet
WHERE delivery_date IS NOT NULL
)
SELECT 
	COUNT(DISTINCT order_id) AS delivered_orders,
	CAST(AVG(processing_days * 1.0) AS DECIMAL(10,2)) AS avg_processing_days,
	CAST(AVG(transit_days * 1.0) AS DECIMAL(10,2)) AS avg_transit_days,
	CAST(AVG(total_days * 1.0) AS DECIMAL(10,2)) AS avg_total_days,
	MIN(total_days) AS fastest_days,
	MAX(total_days) AS slowest_days,
	CAST(SUM(transit_days) * 100.0 / SUM(total_days) AS DECIMAL(10,2)) AS transit_share_pct
FROM delivered_order_durations;


-- Which delivery company (carrier) is late most often
-- Late deliveries upset customers, and the business needs to know whether one carrier is the cause
-- Shows each carrier's delivered orders, late orders, late share and average delivery days
-- Helps decide whether moving orders to another carrier would cut late deliveries
WITH delivered_orders_by_carrier AS (
SELECT DISTINCT
	S.order_id,
	S.order_date,
	S.shipment_date,
	S.delivery_date,
	SP.carrier,
	DATEDIFF(day, S.order_date, S.shipment_date) + DATEDIFF(day, S.shipment_date, S.delivery_date) AS total_days
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_shipments AS SP
	ON S.shipment_key = SP.shipment_key
WHERE S.delivery_date IS NOT NULL
)
SELECT 
	carrier,
	delivered_orders,
	delayed_orders,
	CAST(delayed_orders * 100.0 / delivered_orders AS DECIMAL(10,2)) AS delayed_share_pct,
	avg_total_days
FROM 
(SELECT 
	carrier,
	COUNT(*) AS delivered_orders,
-- Late means more than 9 days from order to delivery, about the slowest quarter of orders, since the data has no promised delivery date
	SUM(CASE 
		WHEN total_days > 9 THEN 1 
		ELSE 0
	END) AS delayed_orders,
	CAST(AVG(total_days * 1.0) AS DECIMAL(10,2)) AS avg_total_days
FROM delivered_orders_by_carrier
GROUP BY carrier)t
ORDER BY delayed_share_pct DESC;


-- Which suppliers bring us a lot of money but have products that customers rate badly
-- The business works with many suppliers and needs to know which ones carry the most risk, so it can deal with them first
-- Groups suppliers by revenue (above or below the average supplier) and by average product rating, with each group's revenue share
-- Helps decide which suppliers to check first, which to keep or grow, and which to replace
WITH supplier_revenue AS (
SELECT 
	supplier_key,
	SUM(sales_amount) AS revenue
FROM gold.fact_sales
GROUP BY supplier_key
)
,supplier_ratings AS (
SELECT 
	FR.supplier_key,
	CAST(AVG(CAST(DR.rating AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_rating
FROM gold.fact_reviews AS FR
LEFT JOIN gold.dim_rating AS DR
	ON FR.rating_key = DR.rating_key
GROUP BY FR.supplier_key
)
, supplier_segments AS (
SELECT 
	R.supplier_key,
	R.revenue,
	SR.avg_rating,
	AVG(R.revenue) OVER() AS avg_supplier_revenue,
-- A low rating means an average of 2 or below; suppliers without any reviews go to No reviews
	CASE 
		WHEN SR.avg_rating <= 2 AND R.revenue >=
			AVG(R.revenue) OVER() THEN 'High revenue, low rating'
		WHEN SR.avg_rating > 2 AND R.revenue >=
			AVG(R.revenue) OVER() THEN 'High revenue, OK rating'
		WHEN SR.avg_rating <= 2 AND R.revenue <
			AVG(R.revenue) OVER() THEN 'Low revenue, low rating'
		WHEN SR.avg_rating > 2 AND R.revenue < 
			AVG(R.revenue) OVER() THEN 'Low revenue, OK rating'
		ELSE 'No reviews'
	END AS supplier_group
FROM supplier_revenue AS R
LEFT JOIN supplier_ratings AS SR
	ON R.supplier_key = SR.supplier_key
)
SELECT 
	supplier_group,
	suppliers,
	revenue,
	CAST(revenue * 100.0 / SUM(revenue) OVER() AS DECIMAL(10,2)) AS revenue_share_pct
FROM
(SELECT 
	supplier_group,
	COUNT(*) AS suppliers,
	SUM(revenue) AS revenue
FROM supplier_segments
GROUP BY supplier_group) t
ORDER BY revenue_share_pct DESC;


-- Which states get late deliveries most often
-- If parcels to some states are late more often, the business needs to know where to look first
-- Shows each customer state's delivered orders, late orders, late share and average delivery days
-- Helps pick the states where courier routes and local delivery partners need checking
WITH delivered_orders_by_state AS (
SELECT DISTINCT
	C.state_code,
	S.order_id,
	S.order_date,
	S.delivery_date,
	S.shipment_date,
	DATEDIFF(day, S.order_date, S.shipment_date) + 
		DATEDIFF(day, S.shipment_date, S.delivery_date) AS total_days
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_customers AS C
	ON S.customer_key = C.customer_key
WHERE S.delivery_date IS NOT NULL
)
SELECT 
	state_code,
	delivered_orders,
	delayed_orders,
	CAST(delayed_orders * 100.0 / delivered_orders AS DECIMAL(10,2)) AS delayed_share_pct,
	avg_total_days
FROM 
(SELECT 
	state_code,
	COUNT(*) AS delivered_orders,
-- Late means more than 9 days from order to delivery, the same rule as the carrier question
	SUM(CASE 
		WHEN total_days > 9 THEN 1
		ELSE 0
	END) AS delayed_orders,
	CAST(AVG(total_days * 1.0) AS DECIMAL(10,2)) AS avg_total_days
FROM delivered_orders_by_state
GROUP BY state_code) t
ORDER BY delayed_share_pct DESC;