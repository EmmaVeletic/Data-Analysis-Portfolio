/*

Car Price Exploration
Skills used: Windows Functions, Creating Views, Using CTE tables,
Aggregate Functions, Converting Data Types, Case Expression

*/



SELECT * 
FROM 
	car_price_dataset


--Check Duplicates
SELECT * 
FROM 
	car_price_dataset
GROUP BY 
	model,brand,
	year_of_car,
	engine_size,
	fuel_type,
	transmission,
	mileage,
	doors,
	owner_count,
	price,
	car_id
HAVING COUNT(*) > 1

--Adding ID
ALTER TABLE car_price_dataset 
ADD COLUMN car_id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY

-----------------------------------------------------
--The average price of cars for each brand
SELECT 
	brand, 
	CAST(AVG(price)AS money) AS average_price 
FROM 
	car_price_dataset
GROUP BY brand

------------------------------------------------------
--The distribution of cars across different fuel types
SELECT 
	fuel_type,
	COUNT(*) 
FROM 
	car_price_dataset
GROUP BY 
	fuel_Type
ORDER BY 
	COUNT(*) DESC

--------------------------------------------------------
--The average mileage for cars of each transmission type
SELECT 
	transmission, 
	ROUND(AVG(mileage),0) AS average_mileage
FROM 
	car_price_dataset
GROUP BY 
	transmission
ORDER BY 
	average_mileage


------------------------------------------------------------
-- The minimum, maximum, and average prices for cars produced
--in each year
SELECT
	year_of_car,
	MIN(price)::MONEY AS min_price,
	MAX(price)::MONEY AS max_price,
	AVG(price)::MONEY AS avg_price
FROM 
	car_price_dataset
GROUP BY 
	year_of_car


------------------------------------------------------------
--The average price of cars of the same brand and model
SELECT 
	brand, 
	model,
	AVG(price) OVER(PARTITION BY brand, model) avg_price_same_brand_model
FROM car_price_dataset



-----------------------------------------------------------
--Cars that are priced above the average for their brand
WITH avg_price_brand AS (
    SELECT 
		brand, 
		AVG(price) AS avg_price
    FROM 
		car_price_dataset
    GROUP BY 
		brand
)

SELECT 
	main.brand, 
	model, 
	CAST(price AS MONEY), 
	CAST(avg_price AS MONEY)
FROM 
	avg_price_brand AS sub
INNER JOIN 
	car_price_dataset AS main
ON 
	main.brand = sub.brand
WHERE 
	price > avg_price
GROUP BY 
	main.brand, 
	model, price, 
	avg_price
ORDER BY 
	brand ASC, 
	model ASC


-------------------------------------------------------------
--The number of cars of most common fuel type for each year
WITH common_fuel_type AS (
	SELECT 
		year_of_car,
		fuel_type,
		(ROW_NUMBER() OVER (PARTITION BY year_of_car ORDER BY COUNT(*) DESC)) AS row_num
	FROM 
		car_price_dataset
	GROUP BY 
		year_of_car, 
		fuel_type

),
most_common_fuel_type AS (
    SELECT
        year_of_car,
        fuel_type
    FROM
        common_fuel_type
    WHERE
        row_num = 1

)

SELECT 
	sub.year_of_car,
	sub.fuel_type,
	COUNT(*) AS number_of_cars 
FROM 
	car_price_dataset AS main
INNER JOIN 
	most_common_fuel_type AS sub
ON 
	main.year_of_car = sub.year_of_car AND main.fuel_type = sub.fuel_type
GROUP BY 
	sub.year_of_car, 
	sub.fuel_type
ORDER BY 
	sub.year_of_car, 
	sub.fuel_type


--------------------------------------------------
--Top 5 most expensive cars
CREATE OR REPLACE VIEW most_expensive_cars AS
SELECT 
	brand, 
	model, 
	year_of_car, 
	price 
FROM 
	car_price_dataset
ORDER BY 
	price DESC
LIMIT 5

SELECT *
FROM 
	most_expensive_cars


-----------------------------------------------------------
--Analyze of the average price within each mileage category
CREATE OR REPLACE VIEW car_mileage_categories AS
SELECT
	price,
	CASE
		WHEN mileage > 200000 THEN 'High'
		WHEN mileage > 100000 THEN 'Medium'
		WHEN mileage > 30000 THEN 'Low'
		ELSE 'Very low'
	END AS mileage_category
FROM 
	car_price_dataset


SELECT
	mileage_category,
	CAST(AVG(price) AS MONEY)
FROM
	car_mileage_categories
GROUP BY
	mileage_category


-----------------------------------------------------------
--Top 10 cars with the largest price differences between
-- each car and the average price for its brand and model
WITH average_price_car AS (
SELECT
	brand,
	model,
	AVG(price) AS avg_price
FROM 
	car_price_dataset
GROUP BY
	brand,
	model
),
price_difference AS(
SELECT
	main.brand,
	main.model,
	CAST(main.price AS MONEY),
	CAST(sub.avg_price AS MONEY),
	CAST(ABS(main.price - sub.avg_price) AS MONEY) AS difference
FROM
	average_price_car AS sub
INNER JOIN
	car_price_dataset AS main
ON 
	main.brand = sub.brand AND main.model = sub.model
GROUP BY
	main.brand,
	main.model,
	main.price,
	sub.avg_price
)

SELECT *
FROM
	price_difference
ORDER BY
	difference DESC
LIMIT 10


----------------------------------------------------------
--Top 3 most expensive cars for each fuel type
WITH ranked_cars AS(
	SELECT
		brand,
		model,
		year_of_car,
		fuel_type,
		price,
		ROW_NUMBER() OVER(PARTITION BY fuel_type ORDER BY price DESC) AS price_rank 
	
	FROM
		car_price_dataset
	GROUP BY
		brand,
		model,
		year_of_car,
		fuel_type,
		price
		
)

SELECT * 
FROM 
	ranked_cars
WHERE 
	price_rank <= 3
ORDER BY 
	fuel_type, 
	price DESC


-------------------------------------------------------------
--The first value of each car within its Brand and Fuel_Type 
--based on price relative to the average
WITH avg_price_fuel AS (
    SELECT 
		fuel_type, 
		AVG(price) AS avg_price
    FROM 
		car_price_dataset
    GROUP BY 
		fuel_type
),
ranked_cars2 AS (
	SELECT
		main.brand,
		main.fuel_type,
		CAST(main.price AS MONEY),
		CAST(sub.avg_price AS MONEY),
		RANK() OVER(PARTITION BY main.brand,main.fuel_type ORDER BY ABS(main.price - sub.avg_price)) AS ranking
	FROM
		car_price_dataset AS main
	INNER JOIN 
		 avg_price_fuel AS sub
	ON main.fuel_type = sub.fuel_type
	GROUP BY
		main.brand,
		main.fuel_type,
		main.price,
		sub.avg_price
)

SELECT *
FROM 
	ranked_cars2
WHERE
	ranking = 1
ORDER BY
	brand,
	fuel_type,
	ranking


------------------------------------------------------------
--Rank the cars with Kia brand based on their price
SELECT
	brand,
	price,
	RANK() OVER(PARTITION BY brand ORDER BY price DESC)
FROM
	car_price_dataset
WHERE
	brand = 'Kia'
GROUP BY
	brand,
	price


------------------------------------------------------------
--The cumulative sum of prices for each brand over the years
SELECT
	 DISTINCT brand,
	 CAST(SUM(price) OVER(PARTITION BY brand )AS MONEY) AS cumulative_sum
FROM
	car_price_dataset


------------------------------------------------------------
--Price difference between temporary and previous 
--most expensive car of the same brand
SELECT
    brand,
    model,
    year_of_car,
    price,
    LAG(price, 1, NULL) OVER (PARTITION BY brand ORDER BY price DESC) AS previous_higher_price,  
    LAG(price, 1, NULL) OVER (PARTITION BY brand ORDER BY price DESC) - price AS price_difference
FROM
    car_price_dataset
ORDER BY
    brand, price DESC



------------------------------------------------------------
--Segment the car market into different price ranges
--and analyze the characteristics of cars within each segment

WITH car_price_segment AS(
SELECT 
	brand,
    model,
    year_of_car,
    fuel_type,
    transmission,
    mileage,
    price,
	CASE
		WHEN price < 6000 THEN 'Budget'
        WHEN price >= 6000 AND price < 12000 THEN 'Mid-Range'
        ELSE 'Luxury'
     END AS price_segment
FROM
	car_price_dataset
)

-- Analysis 1: Average price and mileage within each segment
SELECT
    price_segment,
    CAST(AVG(price) AS MONEY) AS average_price,
	ROUND(AVG(mileage),0) AS average_mileage,
    COUNT(*) AS number_of_cars
FROM
    car_price_segment
GROUP BY
    price_segment
ORDER BY
    average_price

---- Analysis 2: Distribution of fuel types within each segment
SELECT
    price_segment,
    fuel_type,
    COUNT(*) AS number_of_cars,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY price_segment)),2) AS percentage_of_segment
FROM
    car_price_segment
GROUP BY
    price_segment,
    fuel_type
ORDER BY
    price_segment,
    percentage_of_segment DESC