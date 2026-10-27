# E-Commerce Data Warehouse & Analytics

An end-to-end SQL Server project on e-commerce data: a three-layer data warehouse (Bronze, Silver, Gold) with a star schema, built from 8 raw CSV files.

---

## Overview

An online store keeps its data in separate files: customers, orders, products, payments, shipments, reviews and suppliers. On their own, these files can't answer simple business questions, like how much revenue each product brings in, how long deliveries take, or which suppliers' products customers rate lowest.

I built a data warehouse to fix that. The raw files are loaded as they are, cleaned and checked, and then reshaped into a star schema that is easy to query. The warehouse covers about one year of orders (November 2023 to November 2024): 15,000 orders and 20,000 order items.

This repository covers the warehouse. The analysis comes next, in the same repository.

---

## Data Pipeline

Raw CSV Files → Bronze → Silver → Gold

- **Bronze:** the raw data, loaded from the CSV files with no changes. A stored procedure empties each table and reloads it, and prints the rows loaded and the time taken.
- **Silver:** the cleaned data. Names are trimmed, emails are written in lowercase, phone numbers keep only digits, and the address is split into state, city and street. Only rows that pass the quality rules are loaded.
- **Gold:** the business-ready layer, built as views in a star schema.

---

## Data Model

The Gold layer is a star schema with two fact views and six dimension views. Each dimension creates its own surrogate key, and the fact views store those keys.

| View | Type | Rows | One row is |
|---|---|---|---|
| dim_customers | Dimension | 10,000 | a customer |
| dim_products | Dimension | 2,000 | a product |
| dim_suppliers | Dimension | 100 | a supplier |
| dim_payment | Dimension | 15,000 | a payment |
| dim_shipments | Dimension | 15,000 | a shipment |
| dim_rating | Dimension | 5 | a rating from 1 to 5 |
| fact_sales | Fact | 20,000 | an order item |
| fact_reviews | Fact | 1,106 | a review |

`fact_sales` holds the keys of the customer, product, supplier, payment and shipment dimensions, the order, ship and delivery dates, the quantity, the price paid per item and the sales amount. `fact_reviews` holds the keys of the customer, product, supplier and rating, plus the review date.

---

## Data Quality and Cleaning

Before loading Silver, I ran quality checks on every Bronze table (`tests/05_silver_quality_checks.sql`):

- missing, blank and invalid values
- duplicate keys
- extra spaces in text columns
- formats of emails, phone numbers and addresses
- outliers in numeric columns, using the 3-sigma rule
- date order: order date, then ship date, then delivery date
- relationships between tables, so that every foreign key has a matching parent

The Silver load procedure also compares the Bronze and Silver row counts after each table and prints a warning with the number of rows it left out.

---

## Key Design Decisions

- **One row per order item in the sales fact.** An order can have several items, so this grain answers both product-level and order-level questions. The order total is the sum of its items, so it isn't stored on every row. That way it is never counted twice.
- **Surrogate keys in every dimension.** The dimension creates the key, and the fact views copy it by joining on the original ID.
- **Ratings in their own dimension.** A rating is something you average, not add up, so `fact_reviews` holds only keys and a date. This is called a factless fact table.
- **Blank dates stay blank.** A shipment that hasn't been sent or delivered has no ship or delivery date yet, so those columns are left empty instead of filled with a made-up value.
- **Gold is made of views.** There is nothing to load in Gold. The views always read the current Silver data.

---

## Validation

I checked the warehouse at every layer:

- Row counts in Silver match Bronze for all 8 tables.
- `fact_sales` has 20,000 rows, one for each order item, and none of its five keys is empty.
- Revenue in `fact_sales` adds up to the same total as the order totals in Silver, about 42.5 million.
- The average rating calculated through the star schema equals the average in the source reviews.

---

## Dataset

8 CSV files in the `datasets` folder:

| File | Rows | What it holds |
|---|---|---|
| customers.csv | 10,000 | customer names, address, email and phone |
| orders.csv | 15,000 | order date, customer and order total |
| order_items.csv | 20,000 | product, quantity and price of each order line |
| payment.csv | 15,000 | payment method and status |
| products.csv | 2,000 | product name, category, price and supplier |
| reviews.csv | 1,106 | rating, review text and date |
| shipments.csv | 15,000 | carrier, tracking number, dates and status |
| suppliers.csv | 100 | supplier name, contact, address and email |

---

## Tech Stack

- Tool: SQL Server Management Studio (SSMS)
- Language: T-SQL
- Architecture: Medallion Architecture (Bronze → Silver → Gold)
- Data Modelling: Star Schema (fact and dimension views)
- Version Control: GitHub

---

## Repository Structure

```
ecommerce-data-warehouse-analytics/
├── datasets/        the 8 source CSV files
├── scripts/
│   ├── 01_create_database_and_schemas.sql
│   ├── bronze/      02_bronze_create_tables.sql, 03_bronze_load_data.sql
│   ├── silver/      04_silver_create_tables.sql, 06_silver_load_data.sql
│   └── gold/        07_gold_create_views.sql
├── tests/           05_silver_quality_checks.sql
└── README.md
```

---

## How to Run

1. Run `scripts/01_create_database_and_schemas.sql` to create the database and the three schemas.
2. Run `scripts/bronze/02_bronze_create_tables.sql` to create the Bronze tables.
3. Run `scripts/bronze/03_bronze_load_data.sql` to create the load procedure. Change the file paths inside it to match your computer, then run `EXEC bronze.load_bronze;`.
4. Run `scripts/silver/04_silver_create_tables.sql` to create the Silver tables.
5. Optional: run `tests/05_silver_quality_checks.sql` to check the Bronze data.
6. Run `scripts/silver/06_silver_load_data.sql` to create the load procedure, then run `EXEC silver.load_silver;`.
7. Run `scripts/gold/07_gold_create_views.sql` to create the Gold views.

---

## Skills Demonstrated

- Data warehouse design with Medallion Architecture (Bronze, Silver, Gold)
- ETL with stored procedures, including error handling, logging and row count checks
- Data cleaning and standardization in T-SQL
- Data quality testing before loading
- Dimensional modelling: star schema, surrogate keys, fact table grain and a factless fact table
- Window functions (ROW_NUMBER), multi-table joins and views

---

## Coming Next

- Exploratory data analysis
- Advanced analytics, with the business problems solved and the recommendations

---

## Author

**Surajit Aich** [GitHub](https://github.com/surajit-aich) | [LinkedIn](https://www.linkedin.com/in/surajit-aich-a25651229/)

---

## Disclaimer

The dataset used in this project is from Kaggle and is used purely for learning and portfolio purposes.
