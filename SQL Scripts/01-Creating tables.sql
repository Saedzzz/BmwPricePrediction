--- Creating the staging table 
CREATE TABLE usedCars_staging (
    model TEXT,
    year TEXT,
    price TEXT,
    transmission TEXT,
    mileage TEXT,
    fuelType TEXT,
    tax TEXT,
    mpg TEXT,
    engineSize TEXT
);

--- Creating the actual table
DROP TABLE IF EXISTS usedCars;
CREATE TABLE usedCars (
    car_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    model VARCHAR(50),
    year INT,
    price INT,
    transmission VARCHAR(20),
    mileage INT,
    fuelType VARCHAR(20),
    tax INT,
    mpg FLOAT,
    engineSize FLOAT
);
