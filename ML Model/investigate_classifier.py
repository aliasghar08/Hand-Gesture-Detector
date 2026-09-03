"""
Fixed investigation - look at the ACTUAL training CSV format
to understand what coordinate preprocessing was applied.
"""
import numpy as np
import tensorflow as tf
import json, os, glob

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

with open(r'c:\Flutter Projects\Hand Gesture Detector using Custom Model\gesture_detector\assets\scaler_params.json') as f:
    scaler = json.load(f)
mean  = np.array(scaler['mean'], dtype=np.float32)
scale = np.array(scaler['scale'], dtype=np.float32)

print("=== SCALER ANALYSIS ===")
print(f"Mean values (first 10 of 42): {mean[:10].round(4)}")
print(f"Scale values (first 10 of 42): {scale[:10].round(4)}")
print(f"Mean range: [{mean.min():.4f}, {mean.max():.4f}]")
print(f"Scale range: [{scale.min():.4f}, {scale.max():.4f}]")

neg_means = sum(1 for m in mean if m < 0)
print(f"Number of NEGATIVE means: {neg_means} / 42")
print()

# Check the CSV training data
csv_files = glob.glob(r'c:\Flutter Projects\Hand Gesture Detector using Custom Model\ML Model\*.csv')
print(f"CSV files found: {csv_files}")
for path in csv_files:
    print(f"\n=== {os.path.basename(path)} ===")
    with open(path, 'r') as f:
        lines = f.readlines()
    print(f"Total rows: {len(lines)}")
    print(f"First row (raw): {lines[0][:200]}")
    
    # Parse first 5 rows
    for i, line in enumerate(lines[:5]):
        parts = line.strip().split(',')
        label = parts[0]
        values = [float(x) for x in parts[1:] if x]
        neg_count = sum(1 for v in values if v < 0)
        print(f"  Row {i}: label={label}, values[0:6]={[round(v,4) for v in values[:6]]}, negatives={neg_count}/{len(values)}")

print()
print("=== CONCLUSION ===")
print("If training data has NEGATIVE values, coordinates are wrist-relative.")
print("If all values are in [0,1], they are raw image-normalized.")
print()
print("Raw MediaPipe output from hand_landmarker plugin = image-normalized [0,1]")
print("If scaler means are negative = training used WRIST-RELATIVE coords")
print("-> This is the classification bug!")
