-- ============================================================
-- Script   : 02_bronze_create_tables.sql
-- Project  : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose  : Create all raw ingestion tables in the Bronze layer
--            following the Medallion Architecture pattern.
--            Tables store data as-is from the source CSV files
--            with no transformations applied.
-- Schema   : bronze
-- Tables   : ecom_customers, ecom_order_items, ecom_orders,
--            ecom_payment, ecom_products, ecom_reviews,
--            ecom_shipments, ecom_suppliers
-- Note     : Column names and data types follow the source CSV
--            files. No keys or constraints are added, so the
--            raw data loads exactly as it comes.
-- Author   : Surajit
-- Date     : 2026-09-27
-- ============================================================


-- Drop and recreate the customers table to reflect any structural changes
IF OBJECT_ID ('bronze.ecom_customers','U') IS NOT NULL
	DROP TABLE bronze.ecom_customers;

CREATE TABLE bronze.ecom_customers (
	customer_id INT,
	first_name VARCHAR(50),
	last_name VARCHAR(50),
	address VARCHAR(150),
	email VARCHAR(50),
	phone_number VARCHAR(25)	
);
GO


-- Drop and recreate the order items table to reflect any structural changes
IF OBJECT_ID ('bronze.ecom_order_items','U') IS NOT NULL
	DROP TABLE bronze.ecom_order_items;

CREATE TABLE bronze.ecom_order_items (
	order_item_id INT,
	order_id INT,
	product_id INT,
	quantity INT,
	price_at_purchase DECIMAL(10,2)
);
GO


-- Drop and recreate the orders table to reflect any structural changes
IF OBJECT_ID ('bronze.ecom_orders','U') IS NOT NULL
	DROP TABLE bronze.ecom_orders;

CREATE TABLE bronze.ecom_orders (
	order_id INT,
	order_date DATE,
	customer_id INT,
	total_price DECIMAL(10,2)	
);
GO


-- Drop and recreate the payment table to reflect any structural changes
IF OBJECT_ID ('bronze.ecom_payment','U') IS NOT NULL
	DROP TABLE bronze.ecom_payment;

CREATE TABLE bronze.ecom_payment (
	payment_id INT,
	order_id INT,
	payment_method VARCHAR(50),
	amount DECIMAL(10,2),
	transaction_status VARCHAR(50)	
);
GO


-- Drop and recreate the products table to reflect any structural changes
IF OBJECT_ID ('bronze.ecom_products','U') IS NOT NULL
	DROP TABLE bronze.ecom_products;

CREATE TABLE bronze.ecom_products (
	product_id INT,
	product_name VARCHAR(150),
	category VARCHAR(150),
	price DECIMAL(10,2),
	supplier_id INT
);
GO


-- Drop and recreate the reviews table to reflect any structural changes
IF OBJECT_ID ('bronze.ecom_reviews','U') IS NOT NULL
	DROP TABLE bronze.ecom_reviews;

CREATE TABLE bronze.ecom_reviews (
	review_id INT,
	product_id INT,
	customer_id INT,
	rating INT,
	review_text VARCHAR(150),
	review_date DATE	
);
GO


-- Drop and recreate the shipments table to reflect any structural changes
IF OBJECT_ID ('bronze.ecom_shipments','U') IS NOT NULL
	DROP TABLE bronze.ecom_shipments;

CREATE TABLE bronze.ecom_shipments (
	shipment_id INT,
	order_id INT,
	shipment_date DATE,
	carrier VARCHAR(50),
	tracking_number VARCHAR(150),
	delivery_date DATE,
	shipment_status VARCHAR(50)	
);
GO


-- Drop and recreate the suppliers table to reflect any structural changes
IF OBJECT_ID ('bronze.ecom_suppliers','U') IS NOT NULL
	DROP TABLE bronze.ecom_suppliers;

CREATE TABLE bronze.ecom_suppliers (
	supplier_id INT,
	supplier_name VARCHAR(150),
	contact_name VARCHAR(50),
	address VARCHAR(150),
	phone_number VARCHAR(50),
	email VARCHAR(75)	
);
GO
