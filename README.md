# BMW Used-Car Price Prediction
 
Predicting the resale price of used BMW cars from their specifications (model, age, mileage, fuel type, engine size, ...) with tree-based machine learning models in scikit-learn.
 
**Final model:** `HistGradientBoostingRegressor` (histogram-based gradient boosting), wrapped in a preprocessing pipeline, trained on a log-transformed target and tuned with randomized search + 5-fold cross-validation.
 
| Metric | Value |
|---|---|
| MAE  | ~1,429 |
| RMSE | ~2,485 |
| R²   | ~0.950 |
 
(Price units are those of the source dataset.)
 
---

## Tech stack
 
Python, pandas, NumPy, scikit-learn (`ColumnTransformer`, `Pipeline`, `TransformedTargetRegressor`, `RandomizedSearchCV`, `ExtraTreesRegressor`, `HistGradientBoostingRegressor`).

---
 
## Data Source
The data is sourced from [Kaggle: BMW Used Car Listing](https://www.kaggle.com/datasets/mysarahmadbhat/bmw-used-car-listing), containing the following columns:  

| Column         | Description                  |
|----------------|------------------------------|
| model          | BMW model                    |
| year           | Registration year            |
| price          | Price in Euros               |
| transmission   | Gearbox type                 |
| mileage        | Distance driven              |
| fuelType       | Fuel type                    |
| tax            | Road tax                     |
| mpg            | Miles per gallon             |
| engineSize     | Engine size in litres        |

## Database Design
- Primary key `car_id` added to uniquely identify each listing  
- Staging table created with all columns as `TEXT` to safely ingest raw CSV data  
- Final cleaned table with appropriate data types (`INT`, `FLOAT`, `VARCHAR`)  

---

## Data Cleaning & Preprocessing
1. Imported raw CSV data into `usedCars_staging`.  
2. Converted empty strings to `NULL` using `NULLIF`.  
3. Cast data into proper types (`INT`, `FLOAT`) for analysis.  
4. Checked for null values (none found).  
5. Removed duplicates.  
6. Standardized categorical columns (`model`, `transmission`, `fuelType`).  
7. Inspected for outliers in `price`, `mileage`, and `engineSize`.  

---



## 3. Pipeline overview
 
```

 bmw.csv
    |
    v
 [1] Load + inspect (shape, dtypes, NaNs)
    |
    v
 [2] Drop duplicates            10,781 -> 10,664 rows
    |
    v
 [3] Feature engineering        age, mileage_per_year
    |
    v
 [4] Train/test split (80/20)   8,531 train | 2,133 test
    |
    v
 +-------------------- Pipeline (per model) --------------------+
 |  ColumnTransformer                                           |
 |    categorical -> OneHotEncoder(handle_unknown="ignore")     |
 |    numeric     -> passthrough                                |
 |            |                                                 |
 |            v                                                 |
 |    Regressor (ExtraTrees  or  HistGradientBoosting)          |
 +--------------------------------------------------------------+
    |   wrapped in TransformedTargetRegressor (log1p / expm1)
    v
 [5] RandomizedSearchCV  (5-fold CV, scoring = -MAE)
    |
    v
 [6] Evaluate best model on the untouched test set
    |
    v
 [7] Predict prices for new cars
```
 
## Step-by-step explanation
 
### Data cleaning
`df.isna().sum()` shows no missing values. `drop_duplicates()` removes 117 exact duplicate rows. This is done **before** the split so the same car cannot appear in both train and test (which would inflate the score).
 
### Feature engineering
```python
age = REFERENCE_YEAR - year            # REFERENCE_YEAR = 2025, clipped at 0
mileage_per_year = mileage / max(age, 1)
```
- `age` is easier for a model to use than a calendar year and is directly related to depreciation.
- `mileage_per_year` separates "old but barely driven" from "young but heavily driven", which raw mileage alone cannot express.
- The raw `year` column is dropped from the model inputs because `age` carries the same information.
- Both features are computed row by row, so there is no leakage between train and test.
### 4.3 Train/test split
`train_test_split(test_size=0.2, random_state=42)`. The test set is only used for the final evaluation, never for tuning.
 
### Preprocessing
- **Categorical** (`model`, `transmission`, `fuelType`): **one-hot encoding**. Each category becomes a 0/1 column. `handle_unknown="ignore"` means an unseen category at prediction time produces an all-zero row instead of an error.
- **Numeric**: passed through unchanged. Tree models are insensitive to feature scale, so **no scaling is needed** (this is different from linear models, kNN or SVMs).
- For gradient boosting, the encoder is forced to return a **dense** array (`preprocessor_dense`), because the histogram boosting implementation expects dense input.
- 
### Log-transformed target
```python
TransformedTargetRegressor(regressor=pipeline, func=np.log1p, inverse_func=np.expm1)
```
Car prices are right-skewed (a few very expensive cars). The model is trained on `log(1 + price)` and predictions are converted back with `expm1`. Effects:
- The model optimizes **relative** rather than absolute error, so cheap cars are not ignored in favor of expensive ones.
- Predictions can never be negative.
- Cross-validation scores are still reported in the **original price units**, because predictions are inverse-transformed before scoring.
  
### Hyperparameter tuning
`RandomizedSearchCV` samples random combinations from a grid instead of trying all of them.
 
| | ExtraTrees | HistGradientBoosting |
|---|---|---|
| Combinations in grid | 3x4x3x3x3 = 324 | 3x3x3x3x3x3 = 729 |
| Sampled (`n_iter`) | 20 | 25 |
| CV folds | 5 | 5 |
| Total model fits | 100 | 125 |
| Scoring | negative MAE | negative MAE |
 
`KFold(n_splits=5, shuffle=True, random_state=42)` splits the training set into 5 parts; each part is used once for validation.
 
### The two models compared
 
**ExtraTreesRegressor (Extremely Randomized Trees)**
- An ensemble of many decision trees trained independently (a "bagging"-style method).
- Unlike Random Forest, split thresholds are chosen **randomly** rather than optimally, which adds diversity and reduces variance.
- The prediction is the **average** of all trees.
**HistGradientBoostingRegressor** (final model)
- **Boosting**: trees are built **sequentially**; each new tree fits the residual errors of the ensemble so far, scaled by the `learning_rate`.
- **Histogram-based**: continuous features are bucketed into at most 255 bins, which makes finding splits very fast on larger data.
- Supports built-in regularization (`l2_regularization`, `min_samples_leaf`, `max_leaf_nodes`).
```
Bagging / Extra Trees               Boosting (HGB)
 
 tree1  tree2  tree3 ...            tree1 -> residuals -> tree2 -> residuals -> tree3 ...
   \      |     /                      |                    |                       |
    \     |    /                       +---------- sum of (learning_rate x trees) --+
     average -> prediction                              -> prediction
 (parallel, reduces variance)        (sequential, reduces bias)
```
 
**Best hyperparameters found**
 
| ExtraTrees | HistGradientBoosting |
|---|---|
| n_estimators = 900 | max_iter = 800 |
| max_depth = 60 | max_depth = None |
| min_samples_split = 5 | learning_rate = 0.05 |
| min_samples_leaf = 1 | max_leaf_nodes = 31 |
| max_features = 0.7 | min_samples_leaf = 20 |
| | l2_regularization = 0.1 |
 
## Evaluation metrics
 
- **MAE** (mean absolute error): average size of the error in price units. Easy to interpret.
- **RMSE**: square root of the mean squared error. Penalizes large mistakes more, so it is always >= MAE.
- **R²**: share of price variance explained by the model (1.0 = perfect, 0 = no better than predicting the mean).
**Worked example (toy numbers)**
 
| Car | Actual | Predicted | Error |
|---|---|---|---|
| A | 10,000 | 11,000 | 1,000 |
| B | 20,000 | 18,000 | 2,000 |
| C | 30,000 | 33,000 | 3,000 |
 
```
MAE  = (1000 + 2000 + 3000) / 3               = 2,000
RMSE = sqrt((1000^2 + 2000^2 + 3000^2) / 3)   = sqrt(4,666,667) = 2,160
R2   = 1 - SSE/SST = 1 - 14,000,000 / 200,000,000 = 0.93
       (mean = 20,000; SST = 100M + 0 + 100M)
```
 
## Results
 
| Model | CV MAE (train, 5-fold) | Test MAE | Test RMSE | Test R² |
|---|---|---|---|---|
| ExtraTrees (tuned) | 1,563 | 1,515 | 2,643 | 0.944 |
| **HistGradientBoosting (tuned)** | **1,525** | **1,429** | **2,485** | **0.950** |
 
Boosting wins on every metric, and it also wins in cross-validation, so the choice is not based on the test set alone. The RMSE being well above the MAE indicates that a minority of predictions (likely the expensive or unusual cars) have much larger errors.
 
 
## Using the model
 
```python
sample = pd.DataFrame([{
    "model": "5 Series", "year": 2018, "transmission": "Automatic",
    "mileage": 23195, "fuelType": "Diesel", "tax": 145,
    "mpg": 65.7, "engineSize": 2.0,
}])
 
sample_fe = add_features(sample)                  # adds age + mileage_per_year
price = best_hgb.predict(sample_fe[feature_cols_fe])
```
 
## Example output from the notebook:
 
| model | year | transmission | mileage | fuel | predicted price |
|---|---|---|---|---|---|
| 5 Series | 2018 | Automatic | 23,195 | Diesel | 20,443 |
| 1 Series | 2017 | Manual | 17,117 | Petrol | 16,671 |
| X3 | 2016 | Automatic | 42,691 | Diesel | 17,993 |

  
