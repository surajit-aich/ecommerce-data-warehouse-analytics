-- ============================================================
-- Script   : 03_bronze_load_data.sql
-- Project  : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose  : Load raw data from the source CSV files into the
--            Bronze tables using BULK INSERT.
--            Each table is emptied before loading, so every
--            run is a clean full refresh.
-- Schema   : bronze
-- Tables   : ecom_customers, ecom_order_items, ecom_orders,
--            ecom_payment, ecom_products, ecom_reviews,
--            ecom_shipments, ecom_suppliers
-- Note     : BULK INSERT options differ by table to match the
--            source files (line endings and quoted fields).
--            Change the file paths to match your computer
--            before running.
-- Usage    : EXEC bronze.load_bronze;
-- Author   : Surajit
-- Date     : 2026-10-02
-- ============================================================

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN
	DECLARE @start_time DATETIME;
	DECLARE @end_time DATETIME;
	DECLARE @batch_start DATETIME;
	DECLARE @batch_end DATETIME;
	DECLARE @row_count INT;

	BEGIN TRY
		
		SET @batch_start = GETDATE();

		PRINT '========================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '========================================================';

		PRINT '--------------------------------------------------------';
		PRINT ' Loading ECOM Tables';
		PRINT '--------------------------------------------------------';




		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ecom_customers';
		TRUNCATE TABLE bronze.ecom_customers;
		PRINT '>> Inserting Data Into: bronze.ecom_customers';
		BULK INSERT bronze.ecom_customers
		FROM 'D:\E-Commerce SQL Analytics Personal Portfolio Project\Project Materials\CSV Files\customers.csv'
		WITH (
			FIRSTROW = 2,
			FORMAT = 'CSV',
			TABLOCK
		);
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ecom_order_items';
		TRUNCATE TABLE bronze.ecom_order_items;
		PRINT '>> Inserting Data Into: bronze.ecom_order_items';
		BULK INSERT bronze.ecom_order_items
		FROM 'D:\E-Commerce SQL Analytics Personal Portfolio Project\Project Materials\CSV Files\order_items.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';




		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ecom_orders';
		TRUNCATE TABLE bronze.ecom_orders;
		PRINT '>> Inserting Data Into: bronze.ecom_orders';
		BULK INSERT bronze.ecom_orders
		FROM 'D:\E-Commerce SQL Analytics Personal Portfolio Project\Project Materials\CSV Files\orders.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ecom_payment';
		TRUNCATE TABLE bronze.ecom_payment;
		PRINT '>> Inserting Data Into: bronze.ecom_payment';
		BULK INSERT bronze.ecom_payment
		FROM 'D:\E-Commerce SQL Analytics Personal Portfolio Project\Project Materials\CSV Files\payment.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ecom_products';
		TRUNCATE TABLE bronze.ecom_products;
		PRINT '>> Inserting Data Into: bronze.ecom_products';
		BULK INSERT bronze.ecom_products
		FROM 'D:\E-Commerce SQL Analytics Personal Portfolio Project\Project Materials\CSV Files\products.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ecom_reviews';
		TRUNCATE TABLE bronze.ecom_reviews;
		PRINT '>> Inserting Data Into: bronze.ecom_reviews';
		BULK INSERT bronze.ecom_reviews
		FROM  'D:\E-Commerce SQL Analytics Personal Portfolio Project\Project Materials\CSV Files\reviews.csv'
		WITH (
			FIRSTROW = 2,
			FORMAT = 'CSV',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ecom_shipments';
		TRUNCATE TABLE bronze.ecom_shipments;
		PRINT '>> Inserting Data Into: bronze.ecom_shipments';
		BULK INSERT bronze.ecom_shipments
		FROM  'D:\E-Commerce SQL Analytics Personal Portfolio Project\Project Materials\CSV Files\shipments.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';



		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.ecom_suppliers';
		TRUNCATE TABLE bronze.ecom_suppliers;
		PRINT '>> Inserting Data Into: bronze.ecom_suppliers';
		BULK INSERT bronze.ecom_suppliers
		FROM 'D:\E-Commerce SQL Analytics Personal Portfolio Project\Project Materials\CSV Files\suppliers.csv'
		WITH  (
			FIRSTROW = 2,
			FORMAT = 'CSV',
			ROWTERMINATOR = '0x0a',
			TABLOCK
		);
		SET @row_count = @@ROWCOUNT;
		SET @end_time = GETDATE();
		IF @row_count = 0
			PRINT '>> WARNING: No rows were loaded for this table!';
		PRINT '>> Rows Loaded: ' + CAST(@row_count AS NVARCHAR);
		PRINT '>> Load Duration: '+ CAST(DATEDIFF(MILLISECOND, @start_time, @end_time) AS NVARCHAR) + ' ms';
		PRINT '>> -------------';


		SET @batch_end = GETDATE();
		PRINT '========================================================';
		PRINT 'Bronze Layer Load Completed';
		PRINT '>> Total Duration: ' + CAST(DATEDIFF(MILLISECOND,@batch_start,@batch_end) AS NVARCHAR) + ' ms';
		PRINT '========================================================';

	END TRY
	BEGIN CATCH 
		PRINT '========================================================';
		PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
		PRINT '>> Error Message: ' + ERROR_MESSAGE();
		PRINT '>> Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
		PRINT '>> Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
		PRINT '>> Error Severity: ' + CAST(ERROR_SEVERITY() AS NVARCHAR);
		PRINT '>> Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
		PRINT '========================================================';
	END CATCH 
END











		






