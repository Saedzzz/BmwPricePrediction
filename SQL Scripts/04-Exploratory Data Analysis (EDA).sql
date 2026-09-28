-- 1. Basic summary
SELECT COUNT(*) AS total_listings,
       MIN(price) AS min_price,
       MAX(price) AS max_price,
       AVG(price) AS avg_price
FROM usedCars;

-- 2. Average price by model
SELECT model, AVG(price) AS avg_price
FROM usedCars
GROUP BY model
ORDER BY avg_price DESC;

-- 3. Price vs mileage
SELECT mileage, AVG(price) AS avg_price
FROM usedCars
GROUP BY mileage
ORDER BY mileage;

-- 4. Transmission impact on price
SELECT transmission, AVG(price) AS avg_price
FROM usedCars
GROUP BY transmission;

-- 5. Fuel type impact on price
SELECT fuelType, AVG(price) AS avg_price
FROM usedCars
GROUP BY fuelType;

