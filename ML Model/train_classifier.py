import tensorflow as tf
from tensorflow.keras import layers, models
import numpy as np
import pandas as pd
import urllib.request
import os
import json
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

print("TensorFlow version:", tf.__version__)

# ── 1. Download Dataset ──────────────────────────────────────────────────────
# Dataset from hand-gesture-recognition-mediapipe (GitHub) - confirmed working
DATA_URL  = "https://raw.githubusercontent.com/kinivi/hand-gesture-recognition-mediapipe/main/model/keypoint_classifier/keypoint.csv"
LABEL_URL = "https://raw.githubusercontent.com/kinivi/hand-gesture-recognition-mediapipe/main/model/keypoint_classifier/keypoint_classifier_label.csv"
CSV_FILE   = "hand_gestures.csv"
LABEL_FILE = "hand_gesture_labels.csv"
OUTPUT_DIR = r"c:\Flutter Projects\Hand Gesture Detector using Custom Model\gesture_detector\assets"

if not os.path.exists(CSV_FILE):
    print("Downloading dataset from GitHub...")
    urllib.request.urlretrieve(DATA_URL, CSV_FILE)
    print("Dataset download complete!")
else:
    print("Dataset already downloaded.")

if not os.path.exists(LABEL_FILE):
    urllib.request.urlretrieve(LABEL_URL, LABEL_FILE)

# Load labels (one per line, e.g. Open, Close, Pointer, OK)
with open(LABEL_FILE, encoding='utf-8-sig') as f:
    unique_labels = [line.strip() for line in f if line.strip()]
print(f"Labels: {unique_labels}")

# ── 2. Preprocess ─────────────────────────────────────────────────────────────
# Format: first column = class index, remaining 42 = landmark coords
df = pd.read_csv(CSV_FILE, header=None)
print(f"Dataset shape: {df.shape}")
print(f"Class distribution:\n{df[0].value_counts().sort_index()}")

X = df.iloc[:, 1:].values.astype(np.float32)   # 42 landmark coordinates
y = df.iloc[:, 0].values.astype(np.int32)       # class index

num_classes  = len(unique_labels)
num_features = X.shape[1]
print(f"Features: {num_features}, Classes: {num_classes}")

# Save labels JSON directly to Flutter assets
with open(os.path.join(OUTPUT_DIR, 'gesture_labels.json'), 'w') as f:
    json.dump(unique_labels, f)
print("Saved gesture_labels.json to assets/")

# ── 3. Split and Normalize ────────────────────────────────────────────────────
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)

scaler_params = {'mean': scaler.mean_.tolist(), 'scale': scaler.scale_.tolist()}
with open(os.path.join(OUTPUT_DIR, 'scaler_params.json'), 'w') as f:
    json.dump(scaler_params, f)
print("Saved scaler_params.json to assets/")
print(f"Train: {len(X_train)}, Test: {len(X_test)}")

# ── 4. Build Model ────────────────────────────────────────────────────────────
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

# ── 5. Train ──────────────────────────────────────────────────────────────────
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

# ── 6. Evaluate ───────────────────────────────────────────────────────────────
test_loss, test_accuracy = model.evaluate(X_test, y_test, verbose=0)
print(f"\nTest Accuracy: {test_accuracy * 100:.2f}%")
print(f"Test Loss:     {test_loss:.4f}")

y_pred = np.argmax(model.predict(X_test), axis=1)
print("\nPer-gesture accuracy:")
for idx, label in enumerate(unique_labels):
    mask = y_test == idx
    if mask.sum() > 0:
        acc = (y_pred[mask] == y_test[mask]).mean() * 100
        print(f"  {label:20s}: {acc:.1f}%")

# ── 7. Export to TFLite ───────────────────────────────────────────────────────
print("\nConverting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

output_path = os.path.join(OUTPUT_DIR, 'gesture_classifier.tflite')
with open(output_path, 'wb') as f:
    f.write(tflite_model)

size_kb = os.path.getsize(output_path) / 1024
print(f"Saved gesture_classifier.tflite ({size_kb:.1f} KB) to assets/")
print("\nAll done! Your Flutter app is ready to build.")
