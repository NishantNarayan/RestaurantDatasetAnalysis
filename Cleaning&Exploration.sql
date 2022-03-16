CREATE DATABASE restaurantBusiness

-- Importing flat files from local computer using the import flat file feature
SELECT * FROM [dbo].[data_dictionary]

SELECT * FROM [dbo].[consumers]
SELECT * FROM [dbo].[preferences]
SELECT * FROM [dbo].[ratings]
SELECT * FROM [dbo].[restaurant_cuisines]
SELECT * FROM [dbo].[restaurants] 

-- Modelled using explicit key relationships as referential integrity is a need

-- Exploring Data

SELECT * FROM consumers

-- 1. Starting with consumer study

SELECT	City, 
		COUNT(*) as consumer_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM consumers 
GROUP BY City
ORDER BY consumer_count DESC 


SELECT	State, 
		COUNT(*) as consumer_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM consumers 
GROUP BY State
ORDER BY consumer_count DESC

SELECT Smoker, COUNT(*) as smoker_count,
	(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM consumers
GROUP BY Smoker
ORDER BY smoker_count DESC --(spotted NULLS)

SELECT * FROM consumers WHERE Smoker IS NULL -- (for now, decided to let it be)

SELECT	Drink_Level, 
		COUNT(*) as consumer_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM consumers 
GROUP BY Drink_Level
ORDER BY consumer_count DESC

SELECT	Transportation_Method, 
		COUNT(*) as consumer_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM consumers 
GROUP BY Transportation_Method
ORDER BY consumer_count DESC

SELECT	Marital_Status, 
		COUNT(*) as consumer_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM consumers 
GROUP BY Marital_Status
ORDER BY consumer_count DESC

SELECT	Children, 
		COUNT(*) as consumer_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM consumers 
GROUP BY Children
ORDER BY consumer_count DESC

-- Age with bins for easier interpretation
SELECT 
	count(CASE WHEN Age>= 0 AND Age < 20 THEN 1 END) AS '0 - 20',
	count(CASE WHEN Age>= 21 AND Age < 40 THEN 1 END) AS '21 - 40',
	count(CASE WHEN Age>= 41 AND Age < 60 THEN 1 END) AS '41 - 60',
	count(CASE WHEN Age>= 61 AND Age < 80 THEN 1 END) AS '61 - 80',
	count(CASE WHEN Age>= 80 THEN 1 END) AS 'Above 80'
FROM (SELECT Age FROM consumers) AS AgeGroups

SELECT	Occupation, 
		COUNT(*) as consumer_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM consumers 
GROUP BY Occupation
ORDER BY consumer_count DESC 

SELECT	Budget, 
		COUNT(*) as consumer_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM consumers 
GROUP BY Budget
ORDER BY consumer_count DESC 

-- 2. Consumer preference analysis - cuisine
SELECT	Preferred_Cuisine, 
		COUNT(*) as cusine_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM preferences 
GROUP BY Preferred_Cuisine
ORDER BY cusine_count DESC

-- 3. Restaurant cuisine distribution
SELECT	Cuisine, 
		COUNT(*) as cusine_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM restaurant_cuisines 
GROUP BY Cuisine
ORDER BY cusine_count DESC

-- 4. Ratings 

SELECT * FROM Ratings

SELECT	r.Restaurant_ID, Cuisine, 
		AVG(Overall_Rating) as overall,		
		AVG(Food_Rating) as food, 
		AVG(Service_Rating) as service,
		ROW_NUMBER() OVER(ORDER BY AVG(Overall_Rating) DESC) AS RatingRank#
FROM Ratings r
JOIN restaurant_cuisines rc
ON r.Restaurant_ID=rc.Restaurant_ID
GROUP BY r.Restaurant_ID, Cuisine
ORDER BY overall DESC, food DESC, service DESC

-- 5. Restaurants

SELECT * FROM restaurants

GO
WITH tempTable as (
SELECT	City, 
		COUNT(*) as restaurant_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM restaurants)) as abs_percent
FROM restaurants 
GROUP BY City
)

SELECT *, CAST(REPLICATE('*',abs_percent) AS varchar(100)) AS histogram
FROM tempTable
ORDER BY restaurant_count DESC


SELECT	State, 
		COUNT(*) as restaurant_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM restaurants)) as abs_percent
FROM restaurants 
GROUP BY State
ORDER BY restaurant_count DESC

SELECT	Zip_Code, 
		COUNT(*) as restaurant_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM restaurants)) as abs_percent
FROM restaurants 
GROUP BY Zip_Code
ORDER BY restaurant_count DESC

SELECT	Alcohol_Service, 
		COUNT(*) as restaurant_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM restaurants)) as abs_percent
FROM restaurants 
GROUP BY Alcohol_Service
ORDER BY restaurant_count DESC

SELECT	Price, 
		COUNT(*) as restaurant_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM restaurants)) as abs_percent
FROM restaurants 
GROUP BY Price
ORDER BY restaurant_count DESC

-- Same field analysis can be done for others as well

-- Combining Data to infer Insights

/*
1. What can you learn from the highest rated restaurants? Do consumer preferences have an effect on ratings?

2. What are the consumer demographics? Does this indicate a bias in the data sample?

3. Are there any demand & supply gaps that you can exploit in the market?

4. If you were to invest in a restaurant, which characteristics would you be looking for?

*/

-- 1 Top rated restaurants with matching cuisine between consumer and restaurant
WITH tempTab AS (
SELECT	Name as restaurant_name, 
		Cuisine as restaurant_cuisine, 
		c.Consumer_ID, 
		Preferred_Cuisine, 
		Overall_Rating, Food_Rating, Service_Rating,
		ROW_NUMBER() OVER(PARTITION BY c.Consumer_ID ORDER BY Overall_Rating DESC) AS RatingRank#,
		CASE WHEN Cuisine = Preferred_Cuisine THEN 1
			ELSE 0 END as Match FROM 
restaurants r JOIN ratings ra
ON r.Restaurant_ID=ra.Restaurant_ID
JOIN consumers c 
ON ra.Consumer_ID = c.Consumer_ID
JOIN preferences p
ON c.Consumer_ID=p.Consumer_ID
JOIN restaurant_cuisines rc
ON r.Restaurant_ID=rc.Restaurant_ID)
SELECT *
FROM tempTab WHERE RatingRank#=1 

-- 2
	-- From consumer table study, we could see that three of the demographic characteristics are skewed.
	-- 1) Smoker Field - non-smokers comprised 78%
	-- 2) Marital_Status - Singles 89%
	-- 3) Children - 81% consumers had independent children 

-- 3
	-- In terms of cuisine, it is observed that American cuisine was the second most preferred among the consumers data
	-- there are only 5 restaurants offering the cuisine which accounts for only 3%

	-- For drinking, it is evident that, with almost 65% of consumers falling in either casual or social drinker categery,
	-- whereas only 35% of the restaurants offer drinks

SELECT	Drink_Level, 
		COUNT(*) as consumer_count,
		(COUNT(*)*100/(SELECT COUNT(*) FROM consumers)) as abs_percent
FROM consumers 
GROUP BY Drink_Level
ORDER BY consumer_count DESC

SELECT	Alcohol_Service, 
		COUNT(*) as restaurant_count,
		CAST(COUNT(*)*100 as FLOAT)/CAST((SELECT COUNT(*) FROM restaurants) AS float) as abs_percent
FROM restaurants 
GROUP BY Alcohol_Service
ORDER BY restaurant_count DESC

-- 4
	-- Following are the characteristics I would consider before I invest
	-- 1) American cuisine offering alcohol - addresses two demand supply gaps. However, none of the american restaurants are offering alcohol
	--	Considering, cuisine has a higher demand supply gap, I would go with American cuisine over choosing the one offering alcohol
	-- 2) Ratings - well rated restaurant 


SELECT * FROM restaurants r JOIN restaurant_cuisines rc
ON r.Restaurant_ID=rc.Restaurant_ID
WHERE rc.Cuisine='American' AND r.Alcohol_Service <> 'None' -- None of the American Restaurants are offering alcohol

SELECT * FROM restaurants r JOIN restaurant_cuisines rc
ON r.Restaurant_ID=rc.Restaurant_ID
WHERE rc.Cuisine='American' 

-- Shortlisted American restaurants based on ratings given by customers who prefer a different cuisine, and also with individual rating of 2

WITH tempTab AS (
SELECT	Name as restaurant_name, 
		Cuisine as restaurant_cuisine, 
		c.Consumer_ID, r.Restaurant_ID,
		Preferred_Cuisine, 
		Overall_Rating, Food_Rating, Service_Rating,
		ROW_NUMBER() OVER(PARTITION BY c.Consumer_ID ORDER BY Overall_Rating DESC) AS RatingRank#,
		CASE	WHEN Cuisine = Preferred_Cuisine THEN 1
				ELSE 0 END as Match 
FROM 
restaurants r JOIN ratings ra
ON r.Restaurant_ID=ra.Restaurant_ID
JOIN consumers c 
ON ra.Consumer_ID = c.Consumer_ID
JOIN preferences p
ON c.Consumer_ID=p.Consumer_ID
JOIN restaurant_cuisines rc
ON r.Restaurant_ID=rc.Restaurant_ID)
SELECT *
FROM tempTab WHERE RatingRank#=1 AND Match=0 AND restaurant_cuisine= 'American'


SELECT	r.Restaurant_ID, Cuisine, 
		AVG(Overall_Rating) as overall,		
		AVG(Food_Rating) as food, 
		AVG(Service_Rating) as service,
		ROW_NUMBER() OVER(ORDER BY AVG(Overall_Rating) DESC) AS RatingRank#
FROM Ratings r
JOIN restaurant_cuisines rc
ON r.Restaurant_ID=rc.Restaurant_ID
WHERE Cuisine = 'American'
GROUP BY r.Restaurant_ID, Cuisine
ORDER BY overall DESC, food DESC, service DESC

-- In conclusion, with an overall impressive rating in the american cuisine, 
-- and addressing the demand gap, it is compelling to invest in 132583 (McDonalds Centro)