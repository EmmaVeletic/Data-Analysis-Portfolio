/*

Coffee Shop Exploration
Skills used: Joins, Aggregate Functions, Converting Data Types
Windows Functions, Extract date, Case Expression, Creating Views

*/

-- Cleaning Data in SQL Queries
--Check Duplicates
SELECT * FROM items

--Standardize Data Formats
UPDATE items
SET item_price = (item_price/100);

SELECT * FROM ingredients;

UPDATE ingredients
SET ing_price = (ing_price/100);

SELECT * FROM inventory;

SELECT * FROM orders;
ALTER TABLE orders
DROP COLUMN row_id;

--Handle Missing (NULL) Values
SELECT * FROM orders 
WHERE in_or_out IS NULL;

UPDATE orders
SET in_or_out = 'Unknown' 
WHERE in_or_out IS NULL OR in_or_out = ' ';

--Delete Unnecessary Columns
SELECT * FROM recipe;
ALTER TABLE recipe
DROP COLUMN row_id;

SELECT * FROM rota;
ALTER TABLE rota
DROP COLUMN row_id;

SELECT * FROM shift;

SELECT * FROM staff;

--Summarized the variety and number of items sold
SELECT 
	item_cat AS item_category, 
	COUNT(o.order_id) AS count_of_orders
FROM orders AS o
INNER JOIN items AS it
ON o.item_id = it.item_id
GROUP BY item_category

--Determined the average revenue per order
SELECT 
	ROUND(AVG(CAST(it.item_price AS NUMERIC )*o.quantity),2) AS average_price
FROM orders AS o
INNER JOIN items AS it
ON o.item_id = it.item_id

--Analyzed revenue generation by item category
SELECT 
	item_cat AS item_category, 
	SUM(item_price) AS sum_of_price
FROM items
GROUP BY item_category

--Identified the most popular items
SELECT 
	it.item_name, 
	COUNT(order_id) AS count_of_orders
FROM items AS it
INNER JOIN orders AS o
ON o.item_id = it.item_id
GROUP BY it.item_name
ORDER BY count_of_orders DESC
LIMIT 3

--Examined the distribution of orders throughout the day
SELECT 
	COUNT(order_id) AS total_orders,
	CASE 
		WHEN (EXTRACT(HOUR FROM created_at)) BETWEEN 7 AND 10 THEN 'Early morning'
		WHEN (EXTRACT(HOUR FROM created_at)) BETWEEN 11 AND 14 THEN 'Lunch time'
		WHEN (EXTRACT(HOUR FROM created_at)) BETWEEN 15 AND 17 THEN 'Afternoon'
    	ELSE 'Closed'
	END AS time_of_the_day 
FROM orders
GROUP BY time_of_the_day
ORDER BY total_orders DESC

--Analyzed hourly revenue trends
SELECT 
	EXTRACT(HOUR FROM created_at) AS hour_in_a_day, 
	SUM(item_price) AS sum_of_price
FROM orders AS o
INNER JOIN items AS it
ON o.item_id = it.item_id
GROUP BY hour_in_a_day
ORDER BY hour_in_a_day

--Differentiated between dine-in and takeout orders
SELECT 
	in_or_out, 
	COUNT(order_id) AS count_of_orders
FROM orders AS o
LEFT JOIN items AS it
ON o.item_id = it.item_id
WHERE (EXTRACT(HOUR FROM created_at) BETWEEN 11 AND 14) 
		AND item_cat='Snacks' 
		AND in_or_out != 'Unknown'
GROUP BY in_or_out


 --Calculate the total usage of each ingredient
 SELECT 
 	ing.ing_name AS ingredient_name, 
	CAST(SUM(r.quantity) AS VARCHAR) || ' ' || ing.ing_meas AS total_weight
 FROM ingredients AS ing
 INNER JOIN recipe AS r
 ON ing.ing_id = r.ing_id
 GROUP BY ingredient_name, ing.ing_meas

 --Estimated the overall cost of ingredients used
SELECT 
	ing.ing_name AS ingredient_name, 
	CAST((ROUND(SUM((ing.ing_price::NUMERIC/ing.ing_weight)* r.quantity), 2)) AS money) AS total_usage_price 
FROM ingredients AS ing
INNER JOIN recipe AS r
ON ing.ing_id = r.ing_id
GROUP BY ingredient_name, ing.ing_price, ing.ing_weight


--Determined the cost to produce each coffee item
SELECT 
	ing.ing_name AS ingredient_name, 
	CAST((ROUND(SUM((ing.ing_price::NUMERIC/ing.ing_weight)* r.quantity), 2)) AS money) AS total_usage_price 
FROM ingredients AS ing
INNER JOIN recipe AS r
ON ing.ing_id = r.ing_id
WHERE r.ing_id = 'ING001'
GROUP BY ingredient_name, ing.ing_price, ing.ing_weight

--Assessed stock levels as a percentage of total capacity
SELECT ing.ing_name AS ingredient_name, 
	   CAST(ROUND((inv.quantity * 100.0) / SUM(inv.quantity) OVER (), 2) AS NUMERIC(5, 2)) AS percentage
FROM inventory AS inv
INNER JOIN ingredients AS ing
ON inv.ing_id = ing.ing_id
GROUP BY ingredient_name, inv.quantity

--Identified ingredients needing replenishment based on inventory levels
SELECT 
	ing.ing_name AS ingredient_name,
	r.quantity - inv.quantity AS quantity_in_inventory
FROM recipe AS r
INNER JOIN inventory AS inv
ON r.ing_id = inv.ing_id
INNER JOIN ingredients AS ing
ON ing.ing_id = inv.ing_id
WHERE (r.quantity - inv.quantity) < 0
GROUP BY ingredient_name, r.quantity, inv.quantity

--Calculated the total expenditure on staff salaries
SELECT 
	staff.sal_per_hour * SUM(EXTRACT(HOUR FROM (shift.end_time - shift.start_time))) AS total_salary
FROM staff
INNER JOIN rota
ON staff.staff_id = rota.staff_id 
INNER JOIN shift
ON shift.shift_id = rota.shift_id
GROUP BY staff.sal_per_hour

--Summed up the hours staff worked
SELECT 
	SUM(EXTRACT(HOUR FROM (end_time - start_time))) AS total_hours
FROM shift;


--Broke down hours worked by individual employees
SELECT staff.first_name || ' ' || staff.last_name AS employee,
       SUM(EXTRACT(HOUR FROM (shift.end_time - shift.start_time))) AS employee_hours
FROM staff
INNER JOIN rota
ON staff.staff_id = rota.staff_id 
INNER JOIN shift
ON shift.shift_id = rota.shift_id
GROUP BY employee


--Analyzed salary expenses per employee
SELECT 
	staff.first_name || ' ' || staff.last_name AS employee, 
	CAST(staff.sal_per_hour * SUM(EXTRACT(HOUR FROM (shift.end_time - shift.start_time))) AS money) AS salary
FROM staff 
INNER JOIN rota
ON staff.staff_id = rota.staff_id 
INNER JOIN shift
ON shift.shift_id = rota.shift_id
GROUP BY employee, staff.sal_per_hour

-- Creating View to store data for later visualisations
CREATE VIEW ingredient_percentage AS
SELECT 
    ing.ing_name AS ingredient_name, 
    CAST(ROUND((inv.quantity * 100.0) / SUM(inv.quantity) OVER (), 2) AS NUMERIC(5, 2)) AS percentage
FROM inventory AS inv
INNER JOIN ingredients AS ing
ON inv.ing_id = ing.ing_id
GROUP BY ingredient_name, inv.quantity

SELECT * FROM ingredient_percentage
