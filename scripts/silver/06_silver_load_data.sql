
-- ============================================================
-- Script   : 06_silver_load_data.sql
-- Project  : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose  : Load the data from Bronze into the Silver tables.
--            Each table is emptied first and then loaded again,
--            so the procedure can be run any number of times
--            without creating duplicate rows.
-- Schema   : silver
-- Tables   : ecom_customers, ecom_order_items, ecom_orders,
--            ecom_payment, ecom_products, ecom_reviews,
--            ecom_shipments, ecom_suppliers
-- Note     : Only rows that pass the quality rules are loaded.
--            In customers and suppliers the address is split into
--            state, city and street, the email is written in
--            lowercase and the phone number is cleaned.
--            Blank ship and delivery dates are allowed for
--            shipments that have not reached that stage yet.
--            After each table, the Bronze and Silver row counts
--            are compared and a warning shows how many rows were
--            left out.
-- Usage    : EXEC silver.load_silver;
-- Author   : Surajit
-- Date     : 2026-10-16
-- ============================================================

CREATE OR ALTER PROCEDURE silver.load_silver 
AS
BEGIN
	
	DECLARE @start_time DATETIME;
	DECLARE @end_time DATETIME;
	DECLARE @batch_start DATETIME;
	DECLARE @batch_end DATETIME;
	DECLARE @row_count INT;
	DECLARE @bronze_count INT;

	BEGIN TRY
		
		SET @batch_start = GETDATE();

		PRINT '========================================================';
		PRINT 'Loading Silver Layer';
		PRINT '========================================================';

		PRINT '--------------------------------------------------------';
		PRINT 'Loading ECOM tables';
		PRINT '--------------------------------------------------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ecom_customers';
		TRUNCATE TABLE silver.ecom_customers;
		PRINT '>> Inserting Data Into: silver.ecom_customers';
		SELECT @bronze_count = COUNT(*) FROM bronze.ecom_customers;
		INSERT INTO silver.ecom_customers (
			customer_id,
			first_name,
			last_name,
			state,
			city,
			street_address,
			email,
			phone_number
		)
		Select 
			customer_id,
			TRIM(first_name) AS first_name,
			TRIM(last_name) AS last_name,
			TRIM(PARSENAME(REPLACE(address,',','.'),1)) AS state, -- Extract state from combined address
			TRIM(PARSENAME(REPLACE(address,',','.'),2)) AS city,  -- Extract city from combined address
			TRIM(PARSENAME(REPLACE(address,',','.'),3)) AS street_address, -- Extract street from combined address
			LOWER(email) AS email,  -- Standardize email to lowercase
			REPLACE(phone_number,'-','') AS phone_number  -- Remove dashes from phone number
		FROM bronze.ecom_customers
		WHERE customer_id IS NOT NULL;
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		IF @row_count != @bronze_count 
			PRINT '>> WARNING: ' + CAST(@bronze_count - @row_count AS NVARCHAR) + ' rows were rejected for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';


		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ecom_order_items';
		TRUNCATE TABLE silver.ecom_order_items;
		PRINT '>> Inserting Data Into: silver.ecom_order_items';
		SELECT @bronze_count = COUNT(*) FROM bronze.ecom_order_items;
		INSERT INTO silver.ecom_order_items (
			order_item_id,
			order_id,
			product_id,
			quantity,
			price_at_purchase
		)
		SELECT
			order_item_id,
			order_id,
			product_id,
			quantity,
			price_at_purchase
		FROM bronze.ecom_order_items
		WHERE order_item_id IS NOT NULL
		AND order_id IS NOT NULL
		AND product_id IS NOT NULL
		AND quantity > 0;
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		IF @row_count != @bronze_count 
			PRINT '>> WARNING: ' + CAST(@bronze_count - @row_count AS NVARCHAR) + ' rows were rejected for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';


		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ecom_orders';
		TRUNCATE TABLE silver.ecom_orders;
		PRINT '>> Inserting Data Into: silver.ecom_orders';
		SELECT @bronze_count = COUNT(*) FROM bronze.ecom_orders;
		Insert INTO silver.ecom_orders (
			order_id,
			order_date,
			customer_id,
			total_price
		)
		Select 
			order_id,
			order_date,
			customer_id,
			total_price
		FROM bronze.ecom_orders
		WHERE order_id IS NOT NULL
		AND order_date IS NOT NULL
		AND order_date <= GETDATE() -- no future dates
		AND customer_id IS NOT NULL
		AND total_price > 0;
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		IF @row_count != @bronze_count 
			PRINT '>> WARNING: ' + CAST(@bronze_count - @row_count AS NVARCHAR) + ' rows were rejected for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ecom_payment';
		TRUNCATE TABLE silver.ecom_payment;
		PRINT '>> Inserting Data Into: silver.ecom_payment';
		SELECT @bronze_count = COUNT(*) FROM bronze.ecom_payment;
		INSERT INTO silver.ecom_payment (
			payment_id,
			order_id,
			payment_method,
			amount,
			transaction_status
		)
		Select 
			payment_id,
			order_id,
			payment_method,
			amount,
			transaction_status
		FROM bronze.ecom_payment
		WHERE payment_id IS NOT NULL
		AND payment_id > 0
		AND order_id IS NOT NULL
		AND order_id > 0
		AND amount > 0
		AND transaction_status IS NOT NULL
		AND TRIM(transaction_status) != '';
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		IF @row_count != @bronze_count 
			PRINT '>> WARNING: ' + CAST(@bronze_count - @row_count AS NVARCHAR) + ' rows were rejected for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ecom_products';
		TRUNCATE TABLE silver.ecom_products;
		PRINT '>> Inserting Data Into: silver.ecom_products';
		SELECT @bronze_count = COUNT(*) FROM bronze.ecom_products;
		INSERT INTO silver.ecom_products (
			product_id,
			product_name,
			category,
			price,
			supplier_id
		)
		Select 
			product_id,
			product_name,
			category,
			price,
			supplier_id 
		FROM bronze.ecom_products
		WHERE product_id IS NOT NULL
		AND product_id > 0
		AND product_name IS NOT NULL
		AND TRIM(product_name) != ''
		AND category IS NOT NULL
		AND TRIM(category) != ''
		AND price IS NOT NULL
		AND supplier_id IS NOT NULL
		AND supplier_id > 0;
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		IF @row_count != @bronze_count 
			PRINT '>> WARNING: ' + CAST(@bronze_count - @row_count AS NVARCHAR) + ' rows were rejected for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';


		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ecom_reviews';
		TRUNCATE TABLE silver.ecom_reviews;
		PRINT '>> Inserting Data Into: silver.ecom_reviews';
		SELECT @bronze_count = COUNT(*) FROM bronze.ecom_reviews;
		INSERT INTO silver.ecom_reviews (
			review_id,
			product_id,
			customer_id,
			rating,
			review_text,
			review_date
		)
		SELECT 
			review_id,
			product_id,
			customer_id,
			rating,
			review_text,
			review_date
		FROM bronze.ecom_reviews
		WHERE review_id IS NOT NULL AND review_id > 0
			AND product_id IS NOT NULL AND product_id > 0
			AND customer_id IS NOT NULL AND customer_id > 0
			AND rating IS NOT NULL AND rating BETWEEN 1 AND 5
			AND review_date IS NOT NULL AND review_date BETWEEN '1900-01-01' AND GETDATE();
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		IF @row_count != @bronze_count 
			PRINT '>> WARNING: ' + CAST(@bronze_count - @row_count AS NVARCHAR) + ' rows were rejected for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ecom_shipments';
		TRUNCATE TABLE silver.ecom_shipments;
		PRINT '>> Inserting Data Into: silver.ecom_shipments';
		SELECT @bronze_count = COUNT(*) FROM bronze.ecom_shipments;
		INSERT INTO silver.ecom_shipments (
			shipment_id,
			order_id,
			shipment_date,
			carrier,
			tracking_number,
			delivery_date,
			shipment_status
		)
		SELECT 
			shipment_id,
			order_id,
			shipment_date,
			carrier,
			tracking_number,
			delivery_date,
			shipment_status
		FROM bronze.ecom_shipments
		WHERE shipment_id IS NOT NULL AND shipment_id > 0 AND 
			order_id IS NOT NULL AND order_id > 0 AND 
			carrier IS NOT NULL AND carrier != '' AND
			tracking_number IS NOT NULL AND tracking_number != '' AND 
			shipment_status IS NOT NULL AND shipment_status != '' AND 
			(
				(shipment_date IS NULL AND shipment_status NOT IN ('Delivered','Shipped')) OR
				shipment_date BETWEEN '1900-01-01' AND GETDATE()
			) AND 
			(
				(delivery_date IS NULL AND shipment_status != 'Delivered') OR
				delivery_date BETWEEN '1900-01-01' AND GETDATE()
			);
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		IF @row_count != @bronze_count 
			PRINT '>> WARNING: ' + CAST(@bronze_count - @row_count AS NVARCHAR) + ' rows were rejected for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.ecom_suppliers';
		TRUNCATE TABLE silver.ecom_suppliers;
		PRINT '>> Inserting Data Into: silver.ecom_suppliers';
		SELECT @bronze_count = COUNT(*) FROM bronze.ecom_suppliers;
		INSERT INTO silver.ecom_suppliers (
			supplier_id,
			supplier_name,
			contact_name,
			state,
			city,
			street_address,
			phone_number,
			email
		)
		SELECT 
			supplier_id,
			supplier_name,
			contact_name,
			TRIM(PARSENAME(REPLACE(address,',','.'),1)) AS state,
			TRIM(PARSENAME(REPLACE(address,',','.'),2)) AS city,
			TRIM(PARSENAME(REPLACE(address,',','.'),3)) AS street_address,
			REPLACE(REPLACE(REPLACE(REPLACE(phone_number,'(',''),')',''),' ',''),'-','') AS phone_number,
			LOWER(email) AS email
		FROM bronze.ecom_suppliers
		WHERE supplier_id IS NOT NULL AND supplier_id > 0 AND 
			supplier_name IS NOT NULL AND supplier_name != '' AND 
			contact_name IS NOT NULL AND contact_name != '' AND 
			phone_number IS NOT NULl AND 
			email IS NOT NULL AND 
			email NOT LIKE '% %';
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		IF @row_count != @bronze_count 
			PRINT '>> WARNING: ' + CAST(@bronze_count - @row_count AS NVARCHAR) + ' rows were rejected for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';
		

		SET @batch_end = GETDATE();
		PRINT '========================================================';
		PRINT 'Silver Layer Load Completed';
		PRINT '>> Total Duration: ' + CAST(DATEDIFF(MILLISECOND,@batch_start,@batch_end) AS NVARCHAR) + ' ms';
		PRINT '========================================================';
	
	END TRY 
	BEGIN CATCH 
		PRINT '========================================================';
		PRINT 'ERROR OCCURRED DURING LOADING SILVER LAYER';
		PRINT '>> Error Message: ' + ERROR_MESSAGE();
		PRINT '>> Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT '>> Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '>> Error Severity: ' + CAST(ERROR_SEVERITY() AS NVARCHAR);
		PRINT '>> Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT '========================================================';
	END CATCH
END






