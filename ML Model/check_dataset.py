import pandas as pd
import numpy as np
import sys

df = pd.read_csv('hand_gestures.csv')
X = df.iloc[:, :-1].values
y = df.iloc[:, -1].values

print(f"X shape: {X.shape}")
print(f"y shape: {y.shape}")

# Let's look at the first few rows of X
for i in range(3):
    print(f"Row {i} (Label: {y[i]}):")
    row = X[i].reshape(21, 2)
    print(row)
    print("-----")
    
# Let's check max and min values for each row to see how it was scaled
max_vals = np.max(X, axis=1)
min_vals = np.min(X, axis=1)
ranges = max_vals - min_vals

print(f"Max ranges: {ranges.max()}, Min ranges: {ranges.min()}, Mean ranges: {ranges.mean()}")

# check if wrist is always 0,0
wrist_x = X[:, 0]
wrist_y = X[:, 1]
print(f"Wrist X max/min: {wrist_x.max()}/{wrist_x.min()}")
print(f"Wrist Y max/min: {wrist_y.max()}/{wrist_y.min()}")

# What about the maximum absolute value per row?
max_abs = np.max(np.abs(X), axis=1)
print(f"Max abs max: {max_abs.max()}, Min abs max: {max_abs.min()}, Mean abs max: {max_abs.mean()}")
