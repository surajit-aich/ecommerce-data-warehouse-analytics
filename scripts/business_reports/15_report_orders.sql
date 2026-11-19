-- ============================================================
-- Script    : 15_report_orders.sql
-- Project   : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose   : Create the order report: one row per order with its day,
--             size, revenue, payment and shipment status, carrier,
--             delivery times and a late flag.
-- Creates   : gold.report_orders
-- Views used: fact_sales, dim_payment, dim_shipments
-- Usage     : SELECT * FROM gold.report_orders;
-- Note      : is_late is 1 when an order took more than 9 days, 0 when
--             it was on time, and empty when it is not delivered yet.
-- Author    : Surajit
-- Date      : 2026-11-19
-- ============================================================

-- Order report: one row per order
-- Shows each order's day, size, revenue, payment and shipment status, carrier and delivery time
-- An order counts as late when it took more than 9 days from order to delivery; orders not yet delivered are left empty
IF OBJECT_ID('gold.report_orders', 'V') IS NOT NULL
    DROP VIEW gold.report_orders;
GO
CREATE VIEW gold.report_orders AS 
WITH order_totals AS (
SELECT 
	S.order_id,
	S.customer_key,
	S.order_date,
	S.shipment_date,
	S.delivery_date,
	SUM(S.quantity) AS units,
	SUM(S.sales_amount) AS order_revenue,
	P.payment_status,
	SP.carrier,
	SP.shipment_status
FROM gold.fact_sales AS S
LEFT JOIN gold.dim_payment AS P
	ON S.payment_key = P.payment_key
LEFT JOIN gold.dim_shipments AS SP
	ON S.shipment_key = SP.shipment_key
GROUP BY S.order_id,
	S.customer_key,
	S.order_date,
	S.shipment_date,
	S.delivery_date,
	P.payment_status,
	SP.carrier,
	SP.shipment_status
)
SELECT 
	order_id,
	customer_key,
	order_date,
	DATENAME(Weekday, order_date) AS order_day,
	CASE	
		WHEN DATENAME(weekday, order_date) IN ('Saturday','Sunday') THEN 'Weekend'
		ELSE 'Weekday'
	END AS day_type,
	units,
	CASE	
		WHEN units BETWEEN 1 AND 3 THEN 'Small (1 to 3 units)'
		WHEN units BETWEEN 4 AND 7 THEN 'Medium (4 to 7 units)'
		ELSE 'Bulk (8 or more units)'
	END AS order_size,
	order_revenue,
	payment_status,
	carrier,
	shipment_status,
	DATEDIFF(day, order_date, shipment_date) AS processing_days,
	DATEDIFF(day, shipment_date, delivery_date) AS transit_days,
	DATEDIFF(day, order_date, shipment_date) + 
		DATEDIFF(day, shipment_date, delivery_date) AS total_days,
	CASE
		WHEN shipment_status = 'Delivered' AND DATEDIFF(day, order_date, shipment_date) +
			DATEDIFF(day, shipment_date, delivery_date) > 9 THEN 1
		WHEN shipment_status = 'Delivered' THEN 0
		ELSE NULL
	END AS is_late
FROM order_totals;
GO