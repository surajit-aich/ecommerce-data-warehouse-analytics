# E-Commerce Data Warehouse & Analytics

An end-to-end SQL Server project on e-commerce data. I built a three-layer data warehouse (Bronze, Silver, Gold) from 8 raw CSV files, explored it, answered 18 business questions for marketing, finance, logistics and merchandising, and saved the main results as five reporting views.

**Contents:** [The Business Problem](#the-business-problem) · [Key Numbers](#key-numbers) · [Key Insights and Recommendations](#key-insights-and-recommendations) · [How I Built the Warehouse](#how-i-built-the-warehouse) · [Exploratory Data Analysis](#exploratory-data-analysis) · [Business Analysis](#business-analysis) · [Business Reports](#business-reports) · [What the Data Can't Tell Us](#what-the-data-cant-tell-us) · [How to Run](#how-to-run)

---

## The Business Problem

An online store keeps its data in separate files: customers, orders, products, payments, shipments, reviews and suppliers. On their own, these files can't answer the questions a business asks every week. Which customers are worth keeping? How much money actually comes in? Why are deliveries slow? Which suppliers and products are customers unhappy with?

I brought the files together in a data warehouse and then used it to answer those questions. The data covers about one year of orders, from November 2023 to November 2024: 15,000 orders from 10,000 customers.

---

## Key Numbers

| | |
|---|---|
| Orders | 15,000 |
| Customers | 10,000 |
| Revenue from orders | 42.5 million |
| Average order value | 2,833 |
| Money not collected (failed and pending payments) | about 8.5 million (20%) |
| Customers who ordered only once | 50% |
| Average delivery time | 7.5 days |
| Average product rating | 2.76 out of 5 |

Revenue here is the value of all orders placed, including the ones that were never paid. Amounts are shown as they appear in the dataset, which doesn't name a currency.

---

## Key Insights and Recommendations

The store sells steadily all year, but a lot of the money never arrives, half the customers never come back, and customers rate many of the products poorly.

### The Five Biggest Findings

1. **About 8.5 million in orders was never paid, and those 3,000 orders never reached the customer.** Only about 34 million of the 42.5 million actually came in.
2. **Half the customers never came back for a second order.**
3. **About 9 million in revenue depends on suppliers whose products customers rate poorly.**
4. **Delivery takes a week, and 3 of those days are spent in our own warehouse.**
5. **Bulk orders bring 57% of revenue from 38% of orders.**

### Marketing

Customers are scored on how recently, how often and how much they buy (RFM), then grouped into VIP, Loyal, At-Risk and Lost.

| Insight | Impact | What I'd do |
|---|---|---|
| Half of all customers (5,000 of 10,000) bought once and never came back. Even the oldest customers, who had almost a year, returned only about 6 times in 10. | Each missing second order is worth about 2,800. | Send a second-order offer two to three months after the first order. |
| VIP and Loyal customers are 42% of customers but bring 62.65% of revenue, over 26.6 million. | Losing them would hurt the most. | Put most of the retention budget here. |
| At-Risk customers still bring 10.5 million, and 926 of them are repeat buyers who have gone quiet. | This is the money most at stake. | Win back those 926 first. |
| Customers who come back take about four months on average. | After that, a return gets less likely. | Remind at two to three months, and make a stronger offer after four. |
| The top 20% of customers bring 43% of revenue, not 80%. The top 40% bring about 70%. | The business doesn't depend on a handful of big buyers. | Focus retention money on the top two groups. |

### Finance

| Insight | Impact | What I'd do |
|---|---|---|
| Failed payments cost 4.19 million (9.86% of revenue), at a steady 8 to 13% every month. All 1,500 of these orders were cancelled. | About 320,000 in lost sales a month. Because it's so steady, it looks like a problem in the payment process. | Find where payments fail and retry them automatically. |
| 4.28 million is still pending, and 3.2 million of it has waited more than 90 days. None of these orders has shipped. | Only about 1.09 million is still realistically collectable, and these customers are still waiting for their orders. | Chase the orders under 90 days first, set a cut-off for cancelling old ones, and send automatic reminders. |
| Monthly revenue is steady at about 3.57 million, roughly 117,000 a day. February's 10% drop is mostly the shorter month: per day it's about 4%. | There's no real slump. | Compare months by revenue per day before reacting to a drop. |
| Weekdays and weekends sell the same, about 116,000 a day. | Weekend-only campaigns or extra weekend staff wouldn't pay off. | Plan stock and staff evenly across the week. |
| Electronics had a genuinely weak February, about 11% below normal even per day. Home & Kitchen swings about 15% either way from month to month. | About 195,000 lost in Electronics that February, and Home & Kitchen stock is hard to plan. | Check Electronics stock and prices before February, and keep a stock buffer for Home & Kitchen. |

### Logistics

| Insight | Impact | What I'd do |
|---|---|---|
| An order takes 7.49 days on average, anywhere from 2 to 13. About 3 days are in our warehouse and 4.5 with the carrier. | One day less in the warehouse would make delivery about 13% faster. | Aim to ship within one or two days. |
| DHL, FedEx and UPS are all late about 24% of the time and equally fast. | Switching carrier would change almost nothing. | Agree delivery targets with all three. |
| Missouri has the highest late share, 32.93%, but each state has only 160 to 260 orders. | It's a weak signal, not proof. | Check Missouri's routes, and track late deliveries by state every month. |
| 20 high-revenue suppliers have products rated 2 or below, carrying 9.04 million (21%). Another 21 suppliers have no reviews at all, carrying 8.82 million. | The biggest quality risk, plus a blind spot. | Start quality reviews with the 20, and collect reviews for the rest. |

### Merchandising

| Insight | Impact | What I'd do |
|---|---|---|
| Bulk orders (8 or more units) are 38% of orders but 57% of revenue. A bulk order averages 4,311, against 990 for a small one. | Over 24 million depends on bulk buyers. | Offer volume prices, and nudge medium orders up with offers that start at 8 units. |
| 80% of revenue needs 62% of products, and the top product types are only slightly ahead of the rest. | There are no hero products. | Keep a broad range in stock, and don't cut the types that are close behind. |
| 293 C-class products bring only 5% of revenue, and 3 products never sold. | Stock and space for very little return. | Review the C products, and remove the 3 that never sold. |
| 32 products sell above average despite ratings of 2 or below, and only 8% of products have any reviews. | A quality warning, and most products are never rated. | Check the 32, starting with the 17 rated 1, and ask every customer for a rating after delivery. |

---

## How I Built the Warehouse

### Data Pipeline

Raw CSV Files → Bronze → Silver → Gold

- **Bronze:** the raw data, loaded from the CSV files with no changes. A stored procedure empties each table and reloads it, and prints the rows loaded and the time taken.
- **Silver:** the cleaned data. Names are trimmed, emails are written in lowercase, phone numbers keep only digits, and the address is split into state, city and street. Only rows that pass the quality rules are loaded.
- **Gold:** the business-ready layer, built as views in a star schema.

### Data Model

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

### Data Quality and Cleaning

Before loading Silver, I ran quality checks on every Bronze table (`tests/05_silver_quality_checks.sql`):

- missing, blank and invalid values
- duplicate keys
- extra spaces in text columns
- formats of emails, phone numbers and addresses
- outliers in numeric columns, using the 3-sigma rule
- date order: order date, then ship date, then delivery date
- relationships between tables, so that every foreign key has a matching parent

The Silver load procedure also compares the Bronze and Silver row counts after each table and prints a warning with the number of rows it left out.

### Key Design Decisions

- **One row per order item in the sales fact.** An order can have several items, so this grain answers both product-level and order-level questions. The order total is the sum of its items, so it isn't stored on every row. That way it is never counted twice.
- **Surrogate keys in every dimension.** The dimension creates the key, and the fact views copy it by joining on the original ID.
- **Ratings in their own dimension.** A rating is something you average, not add up, so `fact_reviews` holds only keys and a date. This is called a factless fact table.
- **Blank dates stay blank.** A shipment that hasn't been sent or delivered has no ship or delivery date yet, so those columns are left empty instead of filled with a made-up value.
- **Gold is made of views.** There is nothing to load in Gold. The views always read the current Silver data.

### Validation

I checked the warehouse at every layer:

- Row counts in Silver match Bronze for all 8 tables.
- `fact_sales` has 20,000 rows, one for each order item, and none of its five keys is empty.
- Revenue in `fact_sales` adds up to the same total as the order totals in Silver, about 42.5 million.
- The average rating calculated through the star schema equals the average in the source reviews.

---

## Exploratory Data Analysis

After building the warehouse, I explored the Gold layer to understand the data before answering business questions. The script `scripts/eda/08_eda_analysis.sql` has 21 questions in seven groups:

| Group | What it looks at |
|---|---|
| Database exploration | The Gold views and their columns |
| Dimension exploration | Customers, products, shipping, payments and suppliers |
| Date exploration | The time periods of orders, shipments, deliveries and reviews |
| Key numbers | Revenue, orders, customers, order value spread and a key metrics report |
| Magnitude | Revenue and reviews by category, state, shipment status and rating |
| Two categories together | Shipment status by carrier and by product category, and payment status against shipment status |
| Ranking | Top products, products never sold, top customers and top suppliers |

All queries only read the Gold views, so nothing in the warehouse changes.

---

## Business Analysis

I answered 18 business questions, grouped by the team that would ask them. Each query has a short comment with the question, the business problem behind it, what it shows and how it helps. The findings are in [Key Insights and Recommendations](#key-insights-and-recommendations) above.

**Marketing** (`scripts/business_analysis/09_marketing_analysis.sql`)
1. Which customers are VIP, Loyal, At-Risk or Lost (RFM)
2. Which tier brings the most revenue, and how its order value compares with the lowest tier
3. How many days pass between a customer's first and second order
4. Of the customers who first bought in each month, how many came back (cohort analysis)
5. How much revenue each 20% group of customers brings

**Finance** (`scripts/business_analysis/10_finance_analysis.sql`)
1. How revenue changes month to month, with the daily average and the running total
2. How much revenue is lost to failed payments each month
3. How much money is stuck in pending payments, and for how long
4. Whether weekdays and weekends differ in orders and revenue per day
5. Which categories sold above or below their usual level each month

**Logistics** (`scripts/business_analysis/11_logistics_analysis.sql`)
1. How long an order takes, split into warehouse and carrier time
2. Which carrier is late most often
3. Which suppliers bring a lot of revenue but have poorly rated products
4. Which states get late deliveries most often

**Merchandising** (`scripts/business_analysis/12_merchandising_analysis.sql`)
1. How much revenue comes from small, medium and bulk orders
2. The top 3 product types by revenue in each category
3. Which products carry most of the revenue (ABC classes)
4. Which products sell well despite poor ratings

---

## Business Reports

The main results are saved as five views in the Gold schema, so anyone can get them with a simple `SELECT` instead of rewriting the logic. The scripts are in `scripts/business_reports`.

| View | One row is | Use it to |
|---|---|---|
| `gold.report_customers` | a customer | see each customer's orders, spend, RFM scores and tier, and pick who to reward or win back |
| `gold.report_monthly_sales` | a full month | follow revenue, the daily average, growth from the previous month and the running total |
| `gold.report_orders` | an order | check each order's size, payment and shipment status, delivery time and whether it was late |
| `gold.report_suppliers` | a supplier | see each supplier's sales, reviews, average rating and risk group |
| `gold.report_products` | a product | see each product's sales, ABC class and rating, including products that never sold |

---

## What the Data Can't Tell Us

- There are no product costs, so there's no profit or margin.
- There are no returns or refunds.
- There's no promised delivery date, so "late" is my own rule: more than 9 days from order to delivery, roughly the slowest quarter of orders.
- There's no payment due date, so pending payments are aged from the order date.
- Every payment uses the same method, so methods can't be compared.
- Each customer has at most 2 orders, so the frequency score in RFM has only two values.
- Every order holds one product, so there's no basket analysis.
- Only 8% of products have reviews, 7 each, and reviews aren't linked to actual purchases.
- There are no stock levels, marketing spend, website visits, or customer age and gender.
- Listed prices and selling prices don't line up, so discounts can't be analysed.
- There's only one year of data, so there's no year-over-year comparison and only one February.

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
├── datasets/                  the 8 source CSV files
├── scripts/
│   ├── 01_create_database_and_schemas.sql
│   ├── bronze/                02_bronze_create_tables.sql, 03_bronze_load_data.sql
│   ├── silver/                04_silver_create_tables.sql, 06_silver_load_data.sql
│   ├── gold/                  07_gold_create_views.sql
│   ├── eda/                   08_eda_analysis.sql
│   ├── business_analysis/     09_marketing_analysis.sql, 10_finance_analysis.sql,
│   │                          11_logistics_analysis.sql, 12_merchandising_analysis.sql
│   └── business_reports/      13_report_customers.sql, 14_report_monthly_sales.sql,
│                              15_report_orders.sql, 16_report_suppliers.sql,
│                              17_report_products.sql
├── tests/                     05_silver_quality_checks.sql
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
8. Run `scripts/eda/08_eda_analysis.sql` to explore the Gold views.
9. Run the four files in `scripts/business_analysis` (09 to 12) to see the answers to the business questions.
10. Run the five files in `scripts/business_reports` (13 to 17) to create the report views, then query them, for example `SELECT * FROM gold.report_customers;`.

---

## Skills Demonstrated

- Data warehouse design with Medallion Architecture (Bronze, Silver, Gold)
- ETL with stored procedures, including error handling, logging and row count checks
- Data cleaning and standardization in T-SQL
- Data quality testing before loading
- Dimensional modelling: star schema, surrogate keys, fact table grain and a factless fact table
- CTEs and window functions: NTILE, LAG, DENSE_RANK, running totals and averages by group
- Customer analysis: RFM segmentation and cohort repeat rates
- Finance and operations analysis: payment aging, month-over-month change and delivery time splits
- Product analysis: ABC classes and ranking within categories
- Reporting views for reuse
- Turning query results into business findings and recommendations

---

## Author

**Surajit Aich** [GitHub](https://github.com/surajit-aich) | [LinkedIn](https://www.linkedin.com/in/surajit-aich-a25651229/)

---

## Disclaimer

The dataset used in this project is from Kaggle and is used purely for learning and portfolio purposes.
