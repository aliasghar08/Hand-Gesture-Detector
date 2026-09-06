import tensorflow as tf
from tensorflow.keras import layers, models
import numpy as np
import pandas as pd
import os
import json
import math
import random
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

CSV_FILE = "hand_gestures.csv"
LABEL_FILE = "hand_gesture_labels.csv"
OUTPUT_DIR = "."

# Load labels
with open(LABEL_FILE, encoding='utf-8-sig') as f:
    unique_labels = [line.strip() for line in f if line.strip()]
print(f"Labels: {unique_labels}")

# Read dataset
df = pd.read_csv(CSV_FILE, header=None)
print(f"Original Dataset shape: {df.shape}")

X_orig = df.iloc[:, 1:].values.astype(np.float32)   # 42 landmark coordinates
y_orig = df.iloc[:, 0].values.astype(np.int32)       # class index

new_X = []
new_y = []

# Keep the user's brilliant 9 augmentations (so 10x multiplier)
NUM_AUGMENTATIONS = 9

def process_and_augment(row, label, flip_x=False):
    # 1. Flip X if needed (Mirroring for left hand)
    if flip_x:
        row = row.copy()
        for i in range(0, 42, 2):
            row[i] = -row[i]
            
    # 2. Rotation Invariance
    mx, my = row[18], row[19]
    angle = math.atan2(my, mx)
    delta = -math.pi/2 - angle
    
    cosD = math.cos(delta)
    sinD = math.sin(delta)
    
    rotated = []
    max_val = 0.0
    for i in range(0, 42, 2):
        x_val = row[i]
        y_val = row[i+1]
        rx = x_val * cosD - y_val * sinD
        ry = x_val * sinD + y_val * cosD
        rotated.extend([rx, ry])
        max_val = max(max_val, abs(rx), abs(ry))
        
    # 3. Max absolute scaling
    if max_val > 0:
        rotated = [v / max_val for v in rotated]
    else:
        rotated = row.tolist()
        
    # 4. Append cos(delta) and sin(delta) - exactly matching Flutter's 44 features!
    rotated.append(cosD)
    rotated.append(sinD)
    
    # Add original rotated data
    new_X.append(rotated)
    new_y.append(label)
    
    # 5. Generate Synthetic Augmented Data (10x multiplier)
    for _ in range(NUM_AUGMENTATIONS):
        aug_row = []
        # Random scale factor between 0.8 and 1.2
        scale = random.uniform(0.8, 1.2)
        aug_max_val = 0.0
        
        # Only scale and noise the first 42 features (coordinates)
        for i in range(42):
            noise = random.gauss(0, 0.02)
            val = (rotated[i] * scale) + noise
            aug_row.append(val)
            if abs(val) > aug_max_val:
                aug_max_val = abs(val)
                
        # Re-normalize augmented row
        if aug_max_val > 0:
            aug_row = [v / aug_max_val for v in aug_row]
            
        # Append the original cosD and sinD
        aug_row.append(rotated[42])
        aug_row.append(rotated[43])
            
        new_X.append(aug_row)
        new_y.append(label)

print("Applying rotation invariance, horizontal flipping, and 10x augmentation...")
for idx, row in enumerate(X_orig):
    label = y_orig[idx]
    
    # Normal right hand processing
    process_and_augment(row, label, flip_x=False)
    
    # Left hand (mirrored) processing
    process_and_augment(row, label, flip_x=True)

X = np.array(new_X, dtype=np.float32)
y = np.array(new_y, dtype=np.int32)

num_classes  = len(unique_labels)
num_features = X.shape[1]
print(f"Features: {num_features}, Classes: {num_classes}")
print(f"Final Dataset shape: {X.shape}")

# Save labels JSON
with open('gesture_labels.json', 'w') as f:
    json.dump(unique_labels, f)
print("Saved gesture_labels.json")

# Split and Normalize
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)

scaler_params = {'mean': scaler.mean_.tolist(), 'scale': scaler.scale_.tolist()}
with open('scaler_params.json', 'w') as f:
    json.dump(scaler_params, f)
print("Saved scaler_params.json")

print(f"Train: {len(X_train)}, Test: {len(X_test)}")

# Build Model
model = models.Sequential([
    layers.Input(shape=(num_features,)),
    layers.Dense(256, activation='relu'),
    layers.BatchNormalization(),
    layers.Dropout(0.3),
    layers.Dense(128, activation='relu'),
    layers.BatchNormalization(),
    layers.Dropout(0.2),
    layers.Dense(64, activation='relu'),
    layers.Dense(num_classes, activation='softmax')
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)
model.summary()

# Train
callbacks = [
    tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=10, restore_best_weights=True),
    tf.keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=5)
]

print("\nStarting training...")
history = model.fit(
    X_train, y_train,
    validation_split=0.15,
    epochs=100,
    batch_size=64,
    callbacks=callbacks,
    verbose=1
)
print("Training complete!")

# Evaluate
test_loss, test_accuracy = model.evaluate(X_test, y_test, verbose=0)
print(f"\nTest Accuracy: {test_accuracy * 100:.2f}%")

y_pred = np.argmax(model.predict(X_test), axis=1)
print("\nPer-gesture accuracy:")
for idx, label in enumerate(unique_labels):
    mask = y_test == idx
    if mask.sum() > 0:
        acc = (y_pred[mask] == y_test[mask]).mean() * 100
        print(f"  {label:20s}: {acc:.1f}%")

# Export to TFLite
print("\nConverting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

output_path = 'gesture_classifier.tflite'
with open(output_path, 'wb') as f:
    f.write(tflite_model)

size_kb = os.path.getsize(output_path) / 1024
print(f"Saved {output_path} ({size_kb:.1f} KB)")
