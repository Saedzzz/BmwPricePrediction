--- Verifying that all the data got imported
SELECT * FROM usedcars;

--- Verifying that copying the data from the staging table (usedCars_staging) to the main table (usedCars)
SELECT COUNT(*) FROM usedCars;
SELECT COUNT(*) FROM usedCars_staging;

--- Checking for Null values
SELECT COUNT(*) 
FROM usedCars
WHERE model IS NULL
	OR year IS NULL 
    OR price IS NULL
    OR transmission IS NULL
    OR mileage IS NULL
	OR fuelType IS NULL
	OR tax IS NULL
	OR mpg IS NULL
	OR engineSize IS NULL;



-- Find duplicates based on model, year, mileage, price
SELECT model, year, mileage, price, COUNT(*) AS count_duplicates
FROM usedCars
GROUP BY model, year, mileage, price
HAVING COUNT(*) > 1;


-- Delete exact duplicate rows
DELETE FROM usedCars a
USING usedCars b
WHERE a.ctid < b.ctid
  AND a.model = b.model
  AND a.year = b.year
  AND a.price = b.price
  AND a.transmission = b.transmission
  AND a.mileage = b.mileage
  AND a.fuelType = b.fuelType
  AND a.tax = b.tax
  AND a.mpg = b.mpg
  AND a.engineSize = b.engineSize;

-- Check for duplicates after deletion
SELECT COUNT(*) AS remaining_duplicates
FROM usedCars
GROUP BY model, year, mileage, price, transmission, fuelType, tax, mpg, engineSize
HAVING COUNT(*) > 1;

-- Remove unrealistic outliers
-- Example: very low or high prices, or very high mileage
DELETE FROM usedCars
WHERE price < 500 OR price > 200000
   OR mileage > 500000
   OR engineSize <= 0;

-- Standardize categorical values
-- Transmission
UPDATE usedCars
SET transmission = 'Automatic'
WHERE LOWER(transmission) LIKE 'auto%';

UPDATE usedCars
SET transmission = 'Manual'
WHERE LOWER(transmission) LIKE 'man%';

-- Fuel Type
UPDATE usedCars
SET fuelType = 'Petrol'
WHERE LOWER(fuelType) LIKE 'petrol%';

UPDATE usedCars
SET fuelType = 'Diesel'
WHERE LOWER(fuelType) LIKE 'diesel%';

SELECT * FROM usedCars;
