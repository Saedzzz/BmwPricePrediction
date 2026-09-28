import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import create_engine

# PostgreSQL connection string
engine = create_engine('postgresql://username:password.@localhost:5432/BmwDB')

# Test connection and load table
df = pd.read_sql("SELECT * FROM usedCars", engine)

# Quick check
print(df.head())
