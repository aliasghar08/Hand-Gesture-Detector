import tensorflow as tf
from tensorflow.keras import layers, models
import numpy as np
import pandas as pd
import json
import os

CSV_FILE = "extracted_landmarks.csv"
if not os.path.exists(CSV_FILE):
    print(f"Error: {CSV_FILE} not found. Run extract_landmarks.py first.")
    exit(1)

print("Loading dataset...")
df = pd.read_csv(CSV_FILE)
print(f"Dataset shape: {df.shape}")

# The label is the last column
label_col = df.columns[-1]
feature_cols = df.columns[:-1]

X = df[feature_cols].values.astype(np.float32)
y_raw = df[label_col].values

# Encode string labels to integers
unique_labels = sorted(list(set(y_raw)))
label_to_idx = {label: idx for idx, label in enumerate(unique_labels)}
idx_to_label = {idx: label for label, idx in label_to_idx.items()}
y = np.array([label_to_idx[label] for label in y_raw])

num_classes = len(unique_labels)
num_features = X.shape[1]

print(f"Number of features (landmark coords): {num_features}")
print(f"Number of gesture classes: {num_classes}")
print(f"Labels: {unique_labels}")

# Save labels to a JSON file for the Flutter app
with open('gesture_labels.json', 'w') as f:
    json.dump(unique_labels, f)
print("Saved gesture_labels.json")

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

# Normalize landmark coordinates using StandardScaler
scaler = StandardScaler()
X_train = scaler.fit_transform(X_train)
X_test = scaler.transform(X_test)

# Save scaler params for inference
scaler_params = {'mean': scaler.mean_.tolist(), 'scale': scaler.scale_.tolist()}
with open('scaler_params.json', 'w') as f:
    json.dump(scaler_params, f)
print("Saved scaler_params.json")

def build_gesture_classifier(num_features, num_classes):
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
    return model

model = build_gesture_classifier(num_features, num_classes)

callbacks = [
    tf.keras.callbacks.EarlyStopping(monitor='val_accuracy', patience=10, restore_best_weights=True),
    tf.keras.callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=5)
]

print("Starting training...")
model.fit(
    X_train, y_train,
    validation_split=0.15,
    epochs=100,
    batch_size=64,
    callbacks=callbacks,
    verbose=1
)
print("Training complete!")

test_loss, test_accuracy = model.evaluate(X_test, y_test, verbose=0)
print(f"\nTest Accuracy: {test_accuracy * 100:.2f}%")

print("Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

output_path = 'gesture_classifier.tflite'
with open(output_path, 'wb') as f:
    f.write(tflite_model)

print(f"\nDone! Copy {output_path} and gesture_labels.json to your Flutter assets folder.")
