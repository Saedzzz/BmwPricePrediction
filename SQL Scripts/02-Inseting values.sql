--- Inserting the values from the staging table into the actual table
INSERT INTO usedCars (
    model, year, price, transmission, mileage,
    fuelType, tax, mpg, engineSize
)
SELECT
    model,
    NULLIF(year, '')::INT,
    NULLIF(price, '')::INT,
    transmission,
    NULLIF(mileage, '')::INT,
    fuelType,
    NULLIF(tax, '')::INT,
    NULLIF(mpg, '')::FLOAT,
    NULLIF(engineSize, '')::FLOAT
FROM usedCars_staging;
