
-- ============================================================
-- Script   : 01_create_database_and_schemas.sql
-- Project  : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose  : Create the central data warehouse database and
--            define the three-layer Medallion Architecture
--            schemas: Bronze, Silver, and Gold
-- Author   : Surajit
-- Date     : 2026-09-27
-- ============================================================

-- ============================================================
-- Create the ECommerce Data Warehouse Database
-- ============================================================

-- Switch to master database before creating a new one
USE master;
GO

-- Create database only if it does not already exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'ECommerce_DWH')
BEGIN
	CREATE DATABASE ECommerce_DWH;
	PRINT 'Database ECommerce_DWH created Successfully.';
END 
ELSE PRINT 'Database ECommerce_DWH already exists. Skipping creation.';
GO

-- Switch to the newly created database
USE ECommerce_DWH;
GO


-- ============================================================
-- Create Schemas for Medallion Architecture Layers
-- ============================================================

-- Bronze Schema: stores raw, unprocessed data as-is from source
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bronze')
	EXEC('CREATE SCHEMA bronze');
GO

-- Silver Schema: stores cleaned and standardized data
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'silver')
	EXEC('CREATE SCHEMA silver');
GO

-- Gold Schema: stores business-ready data for reporting and analytics
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
	EXEC('CREATE SCHEMA gold');
GO

