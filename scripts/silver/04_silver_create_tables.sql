-- ============================================================
-- Script   : 04_silver_create_tables.sql
-- Project  : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose  : Create all cleaned and standardized tables in the
--            Silver layer following the Medallion Architecture.
--            Tables store transformed data prepared for analysis.
--            Data is loaded from Bronze layer with cleaning and
--            standardization applied.
-- Schema   : silver
-- Tables   : ecom_customers, ecom_order_items, ecom_orders,
--            ecom_payment, ecom_products, ecom_reviews,
--            ecom_shipments, ecom_suppliers
-- Note     : Each table has a 'dwh_create_date' column that
--            fills itself with the load date and time.
-- Author   : Surajit
-- Date     : 2026-10-04
-- ============================================================



-- Drop and recreate the customers table to reflect any structural changes
IF OBJECT_ID ('silver.ecom_customers','U') IS NOT NULL
	DROP TABLE silver.ecom_customers;

CREATE TABLE silver.ecom_customers (
	customer_id INT,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	state  VARCHAR(50),
	city VARCHAR(100),
	street_address VARCHAR(150),
	email VARCHAR(50),
	phone_number VARCHAR(25),
	dwh_create_date DATETIME DEFAULT GETDATE()
);
GO

-- Drop and recreate the order items table to reflect any structural changes
IF OBJECT_ID ('silver.ecom_order_items','U') IS NOT NULL
	DROP TABLE silver.ecom_order_items;

CREATE TABLE silver.ecom_order_items (
	order_item_id INT,
	order_id INT,
	product_id INT,
	quantity INT,
	price_at_purchase DECIMAL(10,2),
	dwh_create_date DATETIME DEFAULT GETDATE()
);
GO

-- Drop and recreate the orders table to reflect any structural changes
IF OBJECT_ID ('silver.ecom_orders','U') IS NOT NULL
	DROP TABLE silver.ecom_orders;

CREATE TABLE silver.ecom_orders (
	order_id INT,
	order_date DATE,
	customer_id INT,
	total_price DECIMAL(10,2),
	dwh_create_date DATETIME DEFAULT GETDATE()
);
GO

-- Drop and recreate the payment table to reflect any structural changes
IF OBJECT_ID ('silver.ecom_payment','U') IS NOT NULL
	DROP TABLE silver.ecom_payment;

CREATE TABLE silver.ecom_payment (
	payment_id INT,
	order_id INT,
	payment_method VARCHAR(50),
	amount DECIMAL(10,2),
	transaction_status VARCHAR(50),
	dwh_create_date DATETIME DEFAULT GETDATE()
);
GO

-- Drop and recreate the products table to reflect any structural changes
IF OBJECT_ID ('silver.ecom_products','U') IS NOT NULL
	DROP TABLE silver.ecom_products;

CREATE TABLE silver.ecom_products (
	product_id INT,
	product_name VARCHAR(150),
	category VARCHAR(150),
	price DECIMAL(10,2),
	supplier_id INT,
	dwh_create_date DATETIME DEFAULT GETDATE()
);
GO

-- Drop and recreate the reviews table to reflect any structural changes
IF OBJECT_ID ('silver.ecom_reviews','U') IS NOT NULL
	DROP TABLE silver.ecom_reviews;

CREATE TABLE silver.ecom_reviews (
	review_id INT,
	product_id INT,
	customer_id INT,
	rating INT,
	review_text VARCHAR(150),
	review_date DATE,
	dwh_create_date DATETIME DEFAULT GETDATE()
);
GO


-- Drop and recreate the shipments table to reflect any structural changes
IF OBJECT_ID ('silver.ecom_shipments','U') IS NOT NULL
	DROP TABLE silver.ecom_shipments;

CREATE TABLE silver.ecom_shipments (
	shipment_id INT,
	order_id INT,
	shipment_date DATE,
	carrier VARCHAR(50),
	tracking_number VARCHAR(150),
	delivery_date DATE,
	shipment_status VARCHAR(50),
	dwh_create_date DATETIME DEFAULT GETDATE()
);
GO


-- Drop and recreate the suppliers table to reflect any structural changes
IF OBJECT_ID ('silver.ecom_suppliers','U') IS NOT NULL
	DROP TABLE silver.ecom_suppliers;

CREATE TABLE silver.ecom_suppliers (
	supplier_id INT,
	supplier_name VARCHAR(150),
	contact_name VARCHAR(50),
	state VARCHAR(50),
	city VARCHAR(100),
	street_address VARCHAR(150),
	phone_number VARCHAR(50),
	email VARCHAR(75),
	dwh_create_date DATETIME DEFAULT GETDATE()
);
GO