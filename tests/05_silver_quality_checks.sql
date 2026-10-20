-- ============================================================
-- Script   : 05_silver_quality_checks.sql
-- Project  : ECommerce Data Warehouse (ECommerce_DWH)
-- Purpose  : Check the quality of the Bronze data before it is
--            loaded into the Silver layer. The results decide
--            which cleaning steps and filters the Silver load needs.
-- Schema   : bronze
-- Tables   : ecom_customers, ecom_order_items, ecom_orders,
--            ecom_payment, ecom_products, ecom_reviews,
--            ecom_shipments, ecom_suppliers
-- Note     : There is one section for each table, checked column
--            by column. A query marked "Expectation: No Results"
--            should return no rows. The other queries only list
--            values so they can be reviewed. The relationship
--            checks come last in each section. Every query only
--            reads data, so nothing in the tables is changed.
-- Usage    : Run each query on its own and look at the result.
-- Author   : Surajit
-- Date     : 2026-10-16
-- ============================================================


-- ============================================================
-- Quality Check: bronze.ecom_customers
-- ============================================================

-- Check 1: Duplicate customer_id
-- Result: No duplicates found 
SELECT 
    customer_id,
    COUNT(*)
FROM bronze.ecom_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check 2: NULL or invalid customer_id
-- Result: No NULLs or invalid values found 
SELECT *
FROM bronze.ecom_customers
WHERE customer_id IS NULL
OR customer_id <= 0;

-- Check 3: NULL or unwanted spaces in first_name and last_name
-- Result: No issues found

Select 
    first_name,
    last_name
from bronze.ecom_customers
WHERE first_name != TRIM(first_name) OR 
    last_name != TRIM(last_name) OR
    first_name IS NULL OR
    last_name IS NULL;

-- Check 4: Distinct values to spot formatting inconsistencies
-- Result: Only 2 distinct first names and 70 distinct last names.No formatting issues found
Select DISTINCT
    first_name,
    last_name
FROM bronze.ecom_customers;

Select DISTINCT
    last_name
FROM bronze.ecom_customers;


-- Check 5: NULL, empty or unwanted spaces in address column
-- Result: No issues found 

Select 
    address
FROM bronze.ecom_customers
WHERE address != TRIM(address) OR
    address IS NULL OR
    address = '';

-- Check 6: Address column structure
-- Found 59 distinct addresses for 10,000 customers
-- Observation:Address column has 3 parts mixed together: Street, City and State

Select 
    address,
    COUNT(*) AS customer_count
FROM bronze.ecom_customers
GROUP BY address
ORDER BY customer_count DESC;

-- Check 7: NULL, empty or unwanted spaces in email column
-- Result: No issues found 
select 
    email
FROM bronze.ecom_customers
WHERE email IS NULL OR
    email = '' OR
    email != TRIM(email);

-- Check 8: Invalid email format check (must contain @ and .)
-- Result: No issues found, all emails follow standard format 
Select 
    email
FROM bronze.ecom_customers
WHERE email NOT LIKE '%@%.%';

-- Check: NULL, empty or unwanted spaces in phone_number
-- Result: No issues found

Select 
    phone_number
from bronze.ecom_customers
WHERE phone_number IS NULL OR
    phone_number != TRIM(phone_number) OR
    phone_number = '';

-- Check: Phone number format consistency  
-- Result: All numbers follow consistent format

Select DISTINCT
    phone_number
FROM bronze.ecom_customers
ORDER BY phone_number;

SELECT 
    first_name,
    last_name,
    email,
    COUNT(*) AS duplicate_count
FROM bronze.ecom_customers
GROUP BY first_name, last_name, email
HAVING COUNT(*) > 1;


-- Referential Integrity Check: ecom_customers
-- Verify every customer_id in orders exists in customers table
-- Result: No orphan records found 

Select * 
FROM bronze.ecom_orders
WHERE customer_id NOT IN 
    (Select customer_id 
    from bronze.ecom_customers
);

-- Verify every customer_id in reviews exists in customers table
-- Result: No orphan records found

Select * 
FROM bronze.ecom_reviews
WHERE customer_id NOT IN 
    (Select customer_id 
    from bronze.ecom_customers
);



-- ============================================================
-- Quality Check: bronze.ecom_order_items
-- ============================================================

-- Check 1: Duplicate order_item_id (Primary Key)
-- Result: No duplicates found 

Select 
    order_item_id,
    COUNT(*) AS Total_count
FROM bronze.ecom_order_items
GROUP BY order_item_id
HAVING COUNT(*) > 1;

-- Check 2: NULL or invalid order_item_id
-- Result: No issues found

Select *
FROM bronze.ecom_order_items
WHERE order_item_id IS NULL OR
    order_item_id <= 0;

-- Check 3: NULL or invalid order_id and product_id
-- Result: No issues found

Select * 
from bronze.ecom_order_items
WHERE order_id IS NULL OR
    order_id <= 0 OR
    product_id IS NULL OR
    product_id <= 0;

-- Check 4: Duplicate order_id and product_id
-- Result: Both columns have expected duplicates
-- One order can have many items, one product can appear in many orders
-- This confirms our 1 to Many relationships

Select 
    order_id,
    COUNT(*) AS total_count
FROM bronze.ecom_order_items
GROUP BY order_id
HAVING  COUNT(*) > 1;

Select 
    product_id,
    COUNT(*) AS total_count
FROM bronze.ecom_order_items
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Check 5: NULL or invalid quantity values
-- Result: No issues found

Select 
    quantity
FROM bronze.ecom_order_items
WHERE Quantity is NULL OR
    Quantity <= 0;

-- Check 6: Outlier detection using 3-Sigma rule
-- Result: AVG: 4.69 | STDEV: 2.92 | Upper Limit: 12.76

Select 
    AVG(quantity) AS avg_quantity,
    ROUND(STDEV(quantity),2) AS stdev_quantity,
    ROUND(AVG(quantity) + 3 * STDEV(quantity),2) AS upper_limit
FROM bronze.ecom_order_items;

-- Check 7: Confirm no outliers exist above upper limit
-- Result: No outliers found — all quantities within normal range

SELECT *
FROM bronze.ecom_order_items
WHERE quantity > (SELECT AVG(quantity) + 3 * STDEV(quantity) 
                  FROM bronze.ecom_order_items);

-- Check 8: NULL or invalid price_at_purchase values
-- Result: Found 2 records with price_at_purchase = 0 — cannot be corrected as no reliable source exists
-- Decision: Load all records into Silver, filter in analytics where price is needed

Select 
    order_item_id,
    product_id,
    price_at_purchase
FROM bronze.ecom_order_items
WHERE price_at_purchase IS NULL OR
    price_at_purchase <= 0;

-- Check 9: Outlier detection for price_at_purchase using 3-Sigma rule
-- Result: AVG: 387.01 | STDEV: 324.77 | Upper Limit: 1361.32

Select  
    ROUND(AVG(price_at_purchase),2) AS avg_price,
    ROUND(STDEV(Price_at_purchase),2) AS stdev_price,
    ROUND(AVG(price_at_purchase) + 3 * STDEV(Price_at_purchase),2) AS upper_limit
FROM bronze.ecom_order_items;

-- Check 10: Confirm no outliers exist above upper limit
-- Result: No outliers found — all prices within normal range

SELECT *
FROM bronze.ecom_order_items
WHERE price_at_purchase > 1361.32;

-- Check 11: Referential integrity — every order_id in order_items must exist in orders
-- Result: No orphan records found
Select * 
FROM bronze.ecom_order_items
WHERE order_id NOT IN (
    Select order_id
    FROM bronze.ecom_orders
);

-- Check 12: Referential integrity — every product_id in order_items must exist in products
-- Result: No orphan records found

Select * 
FROM bronze.ecom_order_items
WHERE product_id NOT IN (
    Select product_id
    FROM bronze.ecom_products
);

-- ============================================================
-- Quality Check: bronze.ecom_orders
-- ============================================================

-- Check 1: Duplicate order_id (Primary Key)
-- Result: No duplicates found 


Select 
    order_id,
    COUNT(*) AS total_count
FROM bronze.ecom_orders
GROUP BY order_id
HAVING  Count(*) > 1;

-- Check 2: NULL or invalid order_id
-- Result: No issues found

Select * 
FROM bronze.ecom_orders
WHERE order_id IS NULL OR 
    order_id <= 0;

-- Check 3: NULL or invalid order_date values
-- Result: No issues found

Select *
FROM bronze.ecom_orders
WHERE order_date IS NULL OR
    order_date NOT BETWEEN '1900-01-01' AND GETDATE();

-- Check 4: Date distribution check for unusual spikes
-- Result: Max 58 orders on a single day — within normal range 
-- Average ~41 orders per day across 365 days

Select 
    order_date,
    COUNT(*) AS order_count
FROM bronze.ecom_orders
GROUP BY order_date
ORDER BY order_count DESC;
 
-- Check 5: NULL or invalid customer_id
-- Result: No issues found

 Select * 
 FROM bronze.ecom_orders
 WHERE customer_id IS NULL OR 
    customer_id <= 0;


-- Check 6: Duplicate customer_id check
-- Expected behavior — one customer can place multiple orders

SELECT 
    customer_id,
    COUNT(*) AS order_count
FROM bronze.ecom_orders
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY order_count DESC;

-- Check 7: NULL or invalid total_price values
-- Result: No issues found 

Select *
FROM bronze.ecom_orders
WHERE total_price IS NULL OR
    total_price <= 0;

-- Check 8: Outlier detection for total_price using 3-Sigma rule
-- Result: AVG: 2833.05 | STDEV: 2275.53 | Upper Limit: 9659.63

Select 
    CAST(AVG(total_price)AS DECIMAL(10,2)) AS Avg_total_price,
    ROUND(STDEV(total_price),2) AS stdev_total_price,
    ROUND(AVG(total_price) + 3 * STDEV(total_price),2) AS upper_limit
FROM bronze.ecom_orders;

-- Check 9: Records above upper limit
-- Result: Found 52 high-value orders — all verified as genuine transactions 

Select *
FROM bronze.ecom_orders
WHERE total_price > 9659.63


-- Check 10: Consistency check — total_price must match sum of order items
-- Result: No mismatches found — total_price is perfectly consistent across all orders
Select 
    O.order_id,
    O.total_price,
    SUM(OI.quantity * OI.price_at_purchase) AS calculated_total
FROM bronze.ecom_orders AS O
INNER JOIN bronze.ecom_order_items AS OI
    ON O.order_id = OI.order_id
GROUP BY O.order_id,
    O.total_price
HAVING O.total_price != SUM(OI.quantity * OI.price_at_purchase);

-- Check 11: Referential integrity — every customer_id in orders must exist in customers
-- Result: No orphan records found

Select * 
FROM bronze.ecom_orders 
WHERE customer_id NOT IN
    (Select customer_id
    FROM bronze.ecom_customers
);

-- ============================================================
-- Quality Check: bronze.ecom_payment
-- ============================================================

-- Check 1: NULL or invalid payment_id (Primary Key)
-- Result: No issues found

Select * 
FROM bronze.ecom_payment
WHERE payment_id IS NULL OR 
    payment_id <= 0;

-- Check 2: Duplicate payment_id check
-- Result: No duplicates found

Select 
    payment_id,
    COUNT(*) AS Total_count
FROM bronze.ecom_payment
GROUP BY payment_id
HAVING COUNT(*) > 1;

-- Check 3: NULL or invalid order_id
-- Result: No issues found

Select 
    order_id
FROM bronze.ecom_payment
WHERE order_id IS NULL OR 
    order_id <= 0;

-- Check 4: Duplicate order_id check (1 to 1 relationship — each order has one payment)
-- Result: No duplicates found — 1 to 1 relationship confirmed

Select 
    order_id,
    COUNT(order_id) AS total_count
FROM bronze.ecom_payment 
GROUP BY order_id
HAVING COUNT(order_id) > 1;

-- Check 5: NULL, empty or unwanted spaces in payment_method
-- Result: No issues found

Select 
    payment_method
FROM bronze.ecom_payment
WHERE payment_method IS NULL OR
    payment_method != TRIM(payment_method) OR
    payment_method = '';

-- Check 6: Distinct payment method values
-- Result: No formatting inconsistencies found

Select Distinct Payment_method FROM bronze.ecom_payment;

-- Check 7: NULL or invalid amount values
-- Result: No issues found

Select *
FROM bronze.ecom_payment
WHERE amount IS NULL OR 
    amount <= 0 ;

-- Check 8: Outlier detection for amount using 3-Sigma rule
-- Result: AVG: 358.98 | STDEV: 312.45 | Upper Limit: 1296.32

SELECT
    CAST(AVG(amount) AS DECIMAL(10,2)) AS avg_amount,
    ROUND(STDEV(amount), 2) AS stdev_amount,
    ROUND(AVG(amount) + 3 * STDEV(amount), 2) AS upper_limit
FROM bronze.ecom_payment;

-- Check 9: Confirm no outliers exist above upper limit
-- Result: No outliers found — all amounts within normal range

Select * 
FROM bronze.ecom_payment
WHERE amount > 1296.32

-- Check 10: NULL or empty transaction_status values
-- Result: No issues found

Select 
    transaction_status
FROM bronze.ecom_payment
WHERE transaction_status IS NULL OR
    transaction_status = '';

-- Check 11: Distinct transaction_status values
-- Result: 3 valid statuses found: Completed, Pending, Failed — no unexpected values 

Select DISTINCT transaction_status FROM bronze.ecom_payment;

-- Check 12: Referential integrity — every order_id in payment must exist in orders
-- Result: No orphan records found

Select *
FROM bronze.ecom_payment
WHERE order_id NOT IN 
    (Select order_id
     FROM bronze.ecom_orders);


-- ============================================================
-- Quality Check: bronze.ecom_products
-- ============================================================

-- Check 1: NULL or invalid product_id (Primary Key)
-- Result: No issues found

Select * 
FROM bronze.ecom_products
WHERE product_id IS NULL OR 
    product_id <= 0;


-- Check 2: Duplicate product_id check
-- Result: No duplicates found

Select 
    product_id,
    COUNT(*) AS Total_count
FROM bronze.ecom_products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Check 3: NULL, empty or unwanted spaces in product_name and category
-- Result: No issues found 

Select 
    product_name,
    category
FROM bronze.ecom_products
WHERE product_name IS NULL OR 
    category IS NULL OR 
    product_name != TRIM(product_name) OR
    category != TRIM(category) OR
    product_name = '' OR 
    category = '';

-- Check 4: Distinct product_name and category values
-- Result: 4 valid categories found: Electronics, Home & Kitchen, Accessories, Furniture
-- Result: No formatting inconsistencies found

Select DISTINCT
    product_name,
    category
FROM bronze.ecom_products
ORDER BY category, product_name


-- Check 5: NULL, invalid or out of range price values
-- Result: 2 unusually low prices found (product_id 844, 1522) — cannot be corrected from source
-- Excluding them would orphan related order items and reviews, so they are loaded as-is

Select *
FROM bronze.ecom_products
WHERE price IS NULL OR 
    price <= 0 OR
    price NOT BETWEEN 1 AND 99999;
    
-- Check 6: Outlier detection for price using 3-Sigma rule
-- Result: AVG: 504.91 | STDEV: 289 | Upper Limit: 1371.92

Select 
    CAST(AVG(price) AS DECIMAL(10,2)) AS avg_price,
    ROUND(STDEV(price),2) AS stdev_price,
    ROUND(AVG(price) +3 * STDEV(price),2) AS upper_limit
FROM bronze.ecom_products;

-- Check 7: Confirm no outliers exist above upper limit
-- Result: No outliers found — all prices within normal range

SELECT *
FROM bronze.ecom_products
WHERE price > 1371.92;

Select * 
FROM bronze.ecom_products
WHERE supplier_id IS NULL OR 
    supplier_id <= 0;

-- Check 9: Duplicate supplier_id check
-- Result: Each supplier supplies exactly 20 products — expected 1 to Many relationship

Select 
    supplier_id,
    COUNT(*) AS total_count
FROM bronze.ecom_products
GROUP BY supplier_id
HAVING COUNT(*) > 1;

-- Check 10: Referential integrity — every supplier_id in products must exist in suppliers
-- Result: No orphan records found

Select * 
FROM bronze.ecom_products
WHERE supplier_id NOT IN 
    (Select supplier_id
    FROM bronze.ecom_suppliers
);

-- ============================================================
-- Quality Check: bronze.ecom_reviews
-- ============================================================

-- Check for NULL or invalid values in review_id.
-- Every review must have a valid positive ID, because it is the primary key.
-- Expectation: No Results

Select *
From bronze.ecom_reviews
WHERE review_id IS NULL OR
    review_id <= 0;

-- Check for duplicate review_id values.
-- A primary key must be unique, so each review should appear only once.
-- Expectation: No Results

Select 
    review_id,
    COUNT(*) AS duplicate_count
FROM bronze.ecom_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

-- Check for missing or invalid values in product_id and customer_id.
-- Every review must belong to a real product and a real customer,
-- so neither column should be NULL, zero or negative.
-- Expectation: No Results

Select * 
FROM bronze.ecom_reviews
WHERE product_id IS NULL OR
    customer_id IS NULL OR
    product_id <= 0 OR 
    customer_id <= 0 ;

-- Check how many reviews each product has.
-- A product can have many reviews, so repeated product_id values are normal here.
-- This only helps us understand the pattern.

Select 
    product_id,
    COUNT(product_id) AS total_reviews
FROM bronze.ecom_reviews
GROUP BY product_id
HAVING COUNT(product_id) > 1;

-- Check how many reviews each customer has.
-- A customer can write many reviews, so repeated customer_id values are normal here.
-- This only helps us understand the pattern.

Select 
    customer_id,
    COUNT(customer_id) AS total_reviews
FROM bronze.ecom_reviews
GROUP BY customer_id
HAVING COUNT(customer_id) > 1;

-- Check how many reviews come from customers who bought the same product they reviewed.
-- Each review is linked to the customer's orders, then to the items in those orders,
-- and only rows where the product matches are kept. Every review is counted once.

SELECT COUNT(DISTINCT ER.review_id) AS verified_purchase_reviews
FROM bronze.ecom_reviews AS ER
INNER JOIN bronze.ecom_orders AS O
    ON ER.customer_id = O.customer_id
INNER JOIN bronze.ecom_order_items AS OI
    ON O.order_id = OI.order_id
   AND ER.product_id = OI.product_id;

-- Check for missing or invalid values in rating.
-- Every review should have a rating between 1 and 5,
-- so anything NULL, zero, negative or above 5 needs a closer look.
-- Expectation: No Results

SELECT * 
FROM bronze.ecom_reviews 
WHERE rating is NULL OR
    rating <= 0 OR
    rating > 5;

-- Check how many reviews fall under each rating.
-- This helps us understand how the ratings are spread across the 1 to 5 scale.

SELECT 
    rating,
    COUNT(*) AS total_reviews
FROM bronze.ecom_reviews
GROUP BY rating
ORDER BY rating;


Select *
FROM bronze.ecom_reviews 
WHERE review_date IS NULL OR
    review_date NOT BETWEEN '1900-01-01' AND GETDATE();

-- Check that every product_id in reviews exists in the products table.
-- A review that points to a product that doesn't exist would be an orphan record.
-- Expectation: No Results

SELECT * 
from bronze.ecom_reviews
WHERE product_id NOT IN 
    (SELECT product_id
    FROM bronze.ecom_products
);

-- Check that every customer_id in reviews exists in the customers table.
-- A review from a customer who doesn't exist would be an orphan record.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_reviews
WHERE customer_id NOT IN 
    (SELECT customer_id
    FROM bronze.ecom_customers
);

-- ============================================================
-- Quality Check: bronze.ecom_shipments
-- ============================================================

-- Check for missing or invalid values in shipment_id.
-- Every shipment must have a valid positive ID, because it is the primary key.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_shipments
WHERE shipment_id IS NULL OR
    shipment_id <= 0;


-- Check for duplicate shipment_id values.
-- A primary key must be unique, so each shipment should appear only once.
-- Expectation: No Results

SELECT 
    shipment_id,
    COUNT(*) AS duplicate_count
FROM bronze.ecom_shipments
GROUP BY shipment_id
HAVING COUNT(*) > 1;

-- Check for missing or invalid values in order_id.
-- Every shipment must belong to an order, so order_id should never be NULL, zero or negative.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_shipments
WHERE order_id IS NULL OR 
    order_id <= 0;

-- Check for duplicate order_id values.
-- Orders and shipments have a 1 to 1 relationship, so each order has exactly one shipment
-- and an order_id should never appear more than once.
-- Expectation: No Results

SELECT 
    order_id,
    COUNT(*) AS duplicate_count
FROM bronze.ecom_shipments
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Check for missing or impossible values in shipment_date.
-- A blank ship date is normal for shipments that haven't gone out yet (Pending and Cancelled).
-- Dates that are filled in can't be in the future or absurdly old.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_shipments
WHERE (shipment_date IS NULL AND shipment_status IN ('Shipped', 'Delivered'))
   OR shipment_date NOT BETWEEN '1900-01-01' AND GETDATE();

-- Check for missing, blank or badly spaced values in carrier.
-- Every shipment needs a carrier name, and extra spaces at the start or end
-- would make the same carrier look like two different ones.
-- Expectation: No Results

Select *
FROM bronze.ecom_shipments
WHERE carrier IS NULl OR 
    carrier = '' OR
    DATALENGTH(carrier) != DATALENGTH(TRIM(carrier));


-- Check which carriers exist in the shipments table.
-- This helps us spot spelling or capitalization differences in the carrier names.

SELECT DISTINCT 
    carrier
FROM bronze.ecom_shipments;

-- Check for missing or impossible values in delivery_date.
-- A blank delivery date is normal until the package arrives (Pending, Cancelled and Shipped).
-- Dates that are filled in can't be in the future or absurdly old.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_shipments
WHERE (delivery_date IS NULL AND shipment_status = 'Delivered')
   OR delivery_date NOT BETWEEN '1900-01-01' AND GETDATE();


-- Check that the order, shipment and delivery dates follow the correct sequence.
-- An order is placed first, then shipped, then delivered,
-- so no date should come before the one that precedes it.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_orders AS O
INNER JOIN bronze.ecom_shipments AS S
    ON O.order_id = S.order_id
WHERE O.order_date > S.shipment_date OR
    O.order_date > S.delivery_date OR
    S.shipment_date > S.delivery_date;

-- Check for missing, blank or badly spaced values in tracking_number.
-- Every shipment needs a tracking number, and extra spaces at the start or end
-- would make the number hard to search for.
-- Expectation: No Results

Select * 
FROM bronze.ecom_shipments
WHERE tracking_number IS NULL OR
    tracking_number = '' OR
    DATALENGTH(tracking_number) != DATALENGTH(TRIM(tracking_number));

-- Show all columns for shipments that share a tracking number with another shipment.
-- This lets us compare the repeated tracking numbers side by side.

SELECT *
FROM bronze.ecom_shipments
WHERE tracking_number IN(
Select 
    tracking_number
FROM bronze.ecom_shipments
GROUP BY tracking_number
HAVING COUNT(*) > 1)
ORDER BY tracking_number, shipment_id;

-- Check for missing, blank or badly spaced values in shipment_status.
-- Every shipment needs a status, and extra spaces at the start or end
-- would make the same status look like two different ones.
-- Expectation: No Results

Select * 
FROM bronze.ecom_shipments
WHERE shipment_status IS NULL OR 
    shipment_status = '' OR 
    DATALENGTH(shipment_status) != DATALENGTH(TRIM(shipment_status));

-- Check which shipment statuses exist in the shipments table.
-- This helps us spot spelling or capitalization differences in the status names.

SELECT DISTINCT
    shipment_status
FROM bronze.ecom_shipments;

-- Check that each shipment status
-- Delivered has both dates, Shipped has only a ship date,
-- and Pending and Cancelled have no dates.

SELECT 
    shipment_status,
    COUNT(*) AS total_shipments,
    COUNT(shipment_date) AS shipments_with_ship_date,
    COUNT(delivery_date) AS shipments_with_delivery_date
FROM bronze.ecom_shipments
GROUP BY shipment_status;


SELECT
    S.shipment_status,
    P.transaction_status AS payment_status,
    COUNT(*) AS total_shipments
FROM bronze.ecom_shipments AS S
INNER JOIN bronze.ecom_payment AS P
    ON S.order_id = P.order_id
GROUP BY S.shipment_status, P.transaction_status
ORDER BY S.shipment_status, P.transaction_status;

-- Check that every order_id in shipments exists in the orders table.
-- A shipment that points to an order that doesn't exist would be an orphan record.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_shipments
WHERE order_id NOT IN 
    (SELECT order_id
    FROM bronze.ecom_orders
);


-- ============================================================
-- Quality Check: bronze.ecom_suppliers
-- ============================================================

-- Check for missing or invalid values in supplier_id.
-- Every supplier must have a valid positive ID, because it is the primary key.
-- Expectation: No Results

Select * from bronze.ecom_suppliers
WHERE supplier_id IS NULL OR 
    supplier_id <= 0;

-- Check for duplicate supplier_id values.
-- A primary key must be unique, so each supplier should appear only once.
-- Expectation: No Results

Select 
    supplier_id,
    COUNT(*) AS duplicate_count
FROM bronze.ecom_suppliers
GROUP BY supplier_id
HAVING COUNT(*) > 1;

-- Look for suppliers with a missing, empty or badly spaced name, contact or address.
-- Expectation: No Results

Select * 
from bronze.ecom_suppliers
WHERE supplier_name IS NULL OR 
    supplier_name = '' OR 
    DATALENGTH(supplier_name) != DATALENGTH(TRIM(supplier_name)) OR
    contact_name IS NULL OR 
    contact_name = '' OR 
    DATALENGTH(contact_name) != DATALENGTH(TRIM(contact_name)) OR
    address IS NULL OR 
    address = '' OR 
    DATALENGTH(address) != DATALENGTH(TRIM(address));

-- List the supplier names to make sure no company is written two different ways.

Select DISTINCT
    supplier_name
FROM bronze.ecom_suppliers;

-- List the contact names to check they are all written in the same style.

Select DISTINCT
    contact_name
FROM bronze.ecom_suppliers;

-- List the addresses to check they all follow the same format.

Select DISTINCT
    address
FROM bronze.ecom_suppliers;

-- Every address should have exactly two commas (street, city, state), so find any that don't.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_suppliers
WHERE LEN(address) - LEN(REPLACE(address, ',', '')) != 2;

-- Find addresses that contain a full stop, because the address split treats full stops as separators.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_suppliers
WHERE address LIKE '%.%';


-- Look for suppliers with a missing, empty or badly spaced phone number.
-- Expectation: No Results

SELECT * 
from bronze.ecom_suppliers
WHERE phone_number IS NULL OR 
    phone_number = '' OR 
    DATALENGTH(phone_number) != DATALENGTH(TRIM(phone_number));


-- Every phone number should look like (555) 484-6922, so find any that don't.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_suppliers
WHERE phone_number NOT LIKE '([0-9][0-9][0-9]) [0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]';


-- Look for suppliers with a missing, empty or badly spaced email.
-- Expectation: No Results

SELECT * 
from bronze.ecom_suppliers
WHERE email IS NULL OR 
    email = '' OR 
    DATALENGTH(email) != DATALENGTH(TRIM(email));

-- Every email should have one @, some text before it, a dot after it and no spaces.
-- Expectation: No Results

SELECT *
FROM bronze.ecom_suppliers
WHERE email NOT LIKE '%@%.%' OR
    email LIKE '% %' OR
    LEN(email) - LEN(REPLACE(email, '@', '')) != 1 OR
    email LIKE '@%';

-- Show the suppliers that share an email with another supplier, side by side.

SELECT *
FROM bronze.ecom_suppliers
WHERE email IN (
    SELECT email
    FROM bronze.ecom_suppliers
    GROUP BY email
    HAVING COUNT(*) > 1
)
ORDER BY email, supplier_id;