import numpy as np

# Let's take the values from Row 0 of the dataset
row0 = np.array([
 [ 0.,          0.        ],
 [ 0.,          0.20634921],
 [-0.04365079,  0.37698413],
 [-0.16269841,  0.50793651],
 [-0.27380952,  0.61507937],
 [-0.3531746,   0.26587302],
 [-0.45238095,  0.3531746 ],
 [-0.6547619,   0.40873016],
 [-0.78174603,  0.4484127 ],
 [-0.90079365,  0.15079365],
 [-0.49206349,  0.20634921],
 [-0.72222222,  0.24206349],
 [-0.87301587,  0.26984127],
 [-1.,          0.03571429],
 [-0.48412698,  0.03174603],
 [-0.70634921,  0.03571429],
 [-0.8531746,   0.04761905],
 [-0.98015873, -0.07936508],
 [-0.42857143, -0.14285714],
 [-0.58333333, -0.18253968],
 [-0.69047619, -0.21031746]
])

print(f"Max abs in Row 0: {np.max(np.abs(row0))}")
print(f"Values are likely normalized by max absolute value? Since the max absolute value is exactly 1.0 (at index 13, x=-1.0).")

# Row 1 max abs is also exactly 1.0 (at index 13, x=-1.0)
# Row 2 max abs is also exactly 1.0 (at index 13, x=-1.0)

print("So the preprocessing algorithm is:")
print("1. Convert to relative coordinates (origin at wrist: index 0)")
print("2. Flatten to 1D array")
print("3. Find the maximum absolute value in the array")
print("4. Divide all elements by this maximum absolute value")
