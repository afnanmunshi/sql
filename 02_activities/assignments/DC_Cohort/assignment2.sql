/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product


But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with
nulls, and 'unit' for the second column with nulls. 

**HINT**: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
<<<<<<< HEAD
All the other rows will remain the same. */

/* a) Replace NULL product_size with a blank '' */

SELECT 
  product_name || ', ' || COALESCE(product_size, '') || ' (' || product_qty_type || ')' 
    AS product_detail
FROM product;

/* b) Replace NULL product_qty_type with 'unit' */
SELECT 
  product_name || ', ' || product_size || ' (' || COALESCE(product_qty_type, 'unit') || ')' 
    AS product_detail
FROM product; 
   
--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT
  customer_id,
  market_date,
  transaction_time,
  ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY market_date, transaction_time
  ) AS visit_number
FROM customer_purchases
ORDER BY customer_id, market_date, transaction_time;


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */
WITH visits AS (
  SELECT
    customer_id,
    market_date,
    DENSE_RANK() OVER (
        PARTITION BY customer_id
        ORDER BY market_date DESC
    ) AS reversed_visit_number
  FROM (
    SELECT DISTINCT customer_id, market_date
    FROM customer_purchases
  ) t
)
SELECT *
FROM visits
WHERE reversed_visit_number = 1
ORDER BY customer_id;


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT
  customer_id,
  product_id,
  market_date,
  quantity,
  cost_to_customer_per_qty,
  transaction_time,
  COUNT(*) OVER (
      PARTITION BY customer_id, product_id
  ) AS times_customer_bought_product
FROM customer_purchases
ORDER BY customer_id, product_id, market_date;



-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT
  product_name,
  CASE
    WHEN INSTR(product_name, '-') > 0 THEN
      TRIM(SUBSTR(product_name, INSTR(product_name, '-') + 1))
    ELSE NULL
  END AS description
FROM product;


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
SELECT *
FROM product
WHERE product_size REGEXP '[0-9]';



-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
WITH daily_sales AS (
  SELECT
    market_date,
    SUM(quantity * cost_to_customer_per_qty) AS total_sales
  FROM customer_purchases
  GROUP BY market_date
),
ranked_days AS (
  SELECT
    market_date,
    total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS best_rank,
    RANK() OVER (ORDER BY total_sales ASC)  AS worst_rank
  FROM daily_sales
)
SELECT
  'best day' AS day_type,
  market_date,
  total_sales
FROM ranked_days
WHERE best_rank = 1

UNION

SELECT
  'worst day' AS day_type,
  market_date,
  total_sales
FROM ranked_days
WHERE worst_rank = 1
ORDER BY total_sales DESC;




/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
SELECT
  vp.vendor_name,
  vp.product_name,
  5 * vp.original_price * COUNT(c.customer_id) AS total_revenue
FROM (
  SELECT DISTINCT
    vi.vendor_id,
    vi.product_id,
    v.vendor_name,
    p.product_name,
    vi.original_price
  FROM vendor_inventory AS vi
  JOIN vendor AS v
    ON vi.vendor_id = v.vendor_id
  JOIN product AS p
    ON vi.product_id = p.product_id
) AS vp
CROSS JOIN customer AS c
GROUP BY
  vp.vendor_name,
  vp.product_name,
  vp.original_price
ORDER BY vp.vendor_name, vp.product_name;



-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
DROP TABLE IF EXISTS product_units;

CREATE TABLE product_units AS
SELECT
  product_id,
  product_name,
  product_size,
  product_category_id,
  product_qty_type,
  CURRENT_TIMESTAMP AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

SELECT * FROM product_units;



/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
INSERT INTO product_units (
  product_id,
  product_name,
  product_size,
  product_category_id,
  product_qty_type,
  snapshot_timestamp
)
VALUES (
  999,                -- choose an ID not used in product_units
  'Apple Pie',
  '10"',
  3,                  -- category ID example (adjust if needed)
  'unit',
  CURRENT_TIMESTAMP
);

SELECT * FROM product_units WHERE product_name = 'Apple Pie';
-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
DELETE FROM product_units
WHERE rowid IN (
  SELECT rowid
  FROM product_units
  WHERE product_name = 'Apple Pie'
  ORDER BY snapshot_timestamp ASC
  LIMIT 1
);


SELECT * FROM product_units WHERE product_name = 'Apple Pie';

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax. */

ALTER TABLE product_units
ADD current_quantity INT;

/* Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


UPDATE product_units
SET current_quantity = COALESCE((
    SELECT vi.quantity
    FROM vendor_inventory AS vi
    WHERE vi.product_id = product_units.product_id
    ORDER BY vi.market_date DESC
    LIMIT 1
), 0);


SELECT * FROM product_units ORDER BY product_id;



/* Section 4:*/
/* This article challenges the myth that machine learning is powered purely by machines. The author reveals that beneath every intelligent there is human labour, judgment, and bias. 
Just as clothes are sewn by hand despite advances in automation, likewise neural networks are built through the invisible effort of people labeling, sorting, and classifying data.
The article draws comparison between the difficulty of automating sewing with the invisible work behind AI. Projects like ImageNet and WordNet were made possible by countless low-paid 
workers Mechanical Turk annotators, graduate students, and linguistic researchers who manually organized millions of images and words. 
This raises serious questions of labour ethics: Who contributes to AI systems? Who profits from them? 
The myth of automation hides the global workforce whose manual effort sustains AI. Every decision in building datasets reflects human assumptions about meaning, categories, and norms. 
Data labeling which is assumed to be objective, embeds bias from the start. ImageNet’s mislabeling of people with terms like “orphan” or “nerd” demonstrates how societal stereotypes become 
encoded into AI systems. These biases are not just accidents—they are consequences of social hierarchies and language choices reproduced at scale. Ethical AI must therefore begin with transparent and 
inclusive data collection, not just fairer algorithms.  Understanding history reveals that AI outcomes are inseparable from human decisions. When systems produce harmful or offensive results, 
accountability must extend to the data creators and institutions behind them. Transparency about how data is sourced and labeled is essential to ethical design.
Like ImageNet,the LLM's used today also rely on unpaid or uncredited human labour. Ethical AI development today must address this and ensure fair recognition and compensation for the 
human contributions beneath it. */
