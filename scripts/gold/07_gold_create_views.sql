-- ============================================================
-- Script   : 07_gold_create_views.sql
-- Project  : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose  : Create the Gold layer views that are ready for
--            reporting and analysis. The views follow a star
--            schema: dimension views describe the business
--            (customers, products, suppliers, payments, shipments
--            and ratings) and fact views hold the keys, dates
--            and amounts.
-- Schema   : gold (source: silver)
-- Views    : dim_customers, dim_products, dim_suppliers,
--            dim_payment, dim_shipments, dim_rating,
--            fact_sales, fact_reviews
-- Note     : The dimensions come first because the fact views
--            read their keys. Each view is dropped and created
--            again, so the script can be run any number of times.
--            The customer_key, product_key and the other keys
--            are numbers created in the dimension views.
-- Usage    : Run the whole script from top to bottom.
-- Author   : Surajit
-- Date     : 2026-10-17
-- ============================================================


-- Drop the customer view if it already exists, then create it again.
-- One row per customer
IF OBJECT_ID ('gold.dim_customers' , 'V') IS NOT NULL 
	DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS 
SELECT 
	ROW_NUMBER() OVER(ORDER BY customer_id) AS customer_key,
	customer_id,
	first_name + ' ' +  last_name AS customer_name,
	state AS state_code,
	city,
	street_address,
	email AS email_address,
	phone_number
FROM silver.ecom_customers;
GO

-- Drop the product view if it already exists, then create it again.
-- One row per product.
IF OBJECT_ID ('gold.dim_products','V' ) IS NOT NULL 
	DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS 
SELECT 
	ROW_NUMBER() OVER (ORDER BY product_id) AS product_key,
	product_id,
	category,
	product_name,
	price AS listed_price
FROM silver.ecom_products;
GO

-- Drop the supplier view if it already exists, then create it again.
-- One row per supplier.
IF OBJECT_ID ('gold.dim_suppliers','V' ) IS NOT NULL 
	DROP VIEW gold.dim_suppliers;
GO

CREATE VIEW gold.dim_suppliers AS 
SELECT 
	ROW_NUMBER() OVER(ORDER BY supplier_id) AS supplier_key,
	supplier_id,
	supplier_name,
	contact_name,
	state AS state_code,
	city,
	street_address,
	email AS email_address,
	phone_number
FROM silver.ecom_suppliers;
GO

-- Drop the payment view if it already exists, then create it again.
-- One row per payment.
IF OBJECT_ID ('gold.dim_payment','V' ) IS NOT NULL 
	DROP VIEW gold.dim_payment;
GO

CREATE VIEW gold.dim_payment AS 
SELECT 
	ROW_NUMBER() OVER(ORDER BY payment_id) AS payment_key,
	payment_id,
	payment_method,
	transaction_status AS payment_status
FROM silver.ecom_payment;
GO

-- Drop the shipment view if it already exists, then create it again.
-- One row per shipment.
IF OBJECT_ID ('gold.dim_shipments','V' ) IS NOT NULL 
	DROP VIEW gold.dim_shipments;
GO

CREATE VIEW gold.dim_shipments AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY shipment_id) AS shipment_key,
	shipment_id,
	carrier,
	shipment_status
FROM silver.ecom_shipments;
GO


-- Drop the rating view if it already exists, then create it again.
-- One row for each rating.
IF OBJECT_ID ('gold.dim_rating','V' ) IS NOT NULL 
	DROP VIEW gold.dim_rating;
GO

CREATE VIEW gold.dim_rating AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY rating) AS rating_key,
	rating
FROM silver.ecom_reviews
GROUP BY rating;
GO

-- Drop the sales view if it already exists, then create it again.
-- One row per order item, linked to all the dimensions.
IF OBJECT_ID ('gold.fact_sales','V' ) IS NOT NULL 
	DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT 
	OI.order_item_id,
	OI.order_id,
	C.customer_key,
	GP.product_key,
	SP.supplier_key,
	GPY.payment_key,
	GSM.shipment_key,
	O.order_date,
	SM.shipment_date,
	SM.delivery_date,
	OI.quantity,
	OI.price_at_purchase AS unit_selling_price,
	OI.quantity * OI.price_at_purchase AS sales_amount	
FROM silver.ecom_order_items AS OI
LEFT JOIN silver.ecom_orders AS O
	ON OI.order_id = O.order_id
LEFT JOIN silver.ecom_payment AS PY
	ON OI.order_id = PY.order_id
LEFT JOIN silver.ecom_shipments AS SM
	ON OI.order_id = SM.order_id
LEFT JOIN silver.ecom_products AS P
	ON OI.product_id = P.product_id
LEFT JOIN gold.dim_customers AS C
	ON O.customer_id = C.customer_id
LEFT JOIN gold.dim_products AS GP
	ON OI.product_id = GP.product_id
LEFT JOIN gold.dim_suppliers AS SP
	ON P.supplier_id = SP.supplier_id
LEFT JOIN gold.dim_payment AS GPY
	ON PY.payment_id = GPY.payment_id
LEFT JOIN gold.dim_shipments AS GSM
	ON SM.shipment_id = GSM.shipment_id;

GO


-- Drop the reviews view if it already exists, then create it again.
-- One row per review, linked to the customer, product, supplier and rating.
IF OBJECT_ID ('gold.fact_reviews','V' ) IS NOT NULL 
	DROP VIEW gold.fact_reviews;
GO

CREATE VIEW gold.fact_reviews AS
SELECT 
	R.review_id,
	C.customer_key,
	GP.product_key,
	GS.supplier_key,
	GR.rating_key,
	R.review_date
FROM silver.ecom_reviews AS R
LEFT JOIN silver.ecom_products AS P
	ON R.product_id = P.product_id
LEFT JOIN gold.dim_customers AS C
	ON R.customer_id = C.customer_id
LEFT JOIN gold.dim_products AS GP
	ON R.product_id = GP.product_id
LEFT JOIN gold.dim_suppliers AS GS
	ON P.supplier_id = GS.supplier_id
LEFT JOIN gold.dim_rating AS GR
	ON R.rating = GR.rating;
GO




