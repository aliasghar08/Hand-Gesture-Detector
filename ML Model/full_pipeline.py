%pip install kaggle tensorflow matplotlib
!pip install numpy
!pip install tensorflow
!pip install matplotlib
import os

# Download a resized, class-balanced HaGRID dataset from Kaggle
# (Make sure your Kaggle API key is configured!)
!kaggle datasets download -d cjmill/hagrid-classification-512p --unzip -p ./hagrid_dataset

DATASET_PATH = './hagrid_dataset' # Update the path variable for the rest of the notebook

import tensorflow as tf
import numpy as np
import matplotlib.pyplot as plt
import os

print(f"TensorFlow Version: {tf.__version__}")

# Configuration variables
BATCH_SIZE = 32
IMG_HEIGHT = 224
IMG_WIDTH = 224
DATASET_PATH = './hagrid_dataset' # Update this path

# Efficient Data Loading using tf.keras.utils.image_dataset_from_directory
def create_dataset(data_dir, is_training=True):
    dataset = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=0.2 if is_training else None,
        subset="training" if is_training else None,
        seed=123,
        image_size=(IMG_HEIGHT, IMG_WIDTH),
        batch_size=BATCH_SIZE
    )
    
    # Performance optimization: caching and prefetching
    AUTOTUNE = tf.data.AUTOTUNE
    dataset = dataset.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
    return dataset

# Uncomment and update paths when data is available
train_dataset = create_dataset(DATASET_PATH, is_training=True)
val_dataset = tf.keras.utils.image_dataset_from_directory(DATASET_PATH, validation_split=0.2, subset='validation', seed=123, image_size=(IMG_HEIGHT, IMG_WIDTH), batch_size=BATCH_SIZE).cache().prefetch(buffer_size=tf.data.AUTOTUNE)

data_augmentation = tf.keras.Sequential([
  tf.keras.layers.RandomFlip("horizontal"),
  tf.keras.layers.RandomRotation(0.1),
  tf.keras.layers.RandomZoom(0.1),
])


def build_efficient_model(num_classes):
    # Use MobileNetV2 as the base model
    base_model = tf.keras.applications.MobileNetV2(
        input_shape=(IMG_HEIGHT, IMG_WIDTH, 3),
        include_top=False,
        weights='imagenet'
    )
    
    # Freeze the base model for transfer learning initially
    base_model.trainable = False

    inputs = tf.keras.Input(shape=(IMG_HEIGHT, IMG_WIDTH, 3))
    x = data_augmentation(inputs)
    
    # Preprocess inputs for MobileNetV2 (scales pixels to [-1, 1])
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    
    x = base_model(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation='softmax')(x)
    
    model = tf.keras.Model(inputs, outputs)
    return model

NUM_CLASSES = 5 # Example: update to your number of gestures
model = build_efficient_model(NUM_CLASSES)
model.summary()

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

callbacks = [
    tf.keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True),
    tf.keras.callbacks.ModelCheckpoint('best_model.keras', save_best_only=True),
    tf.keras.callbacks.ReduceLROnPlateau(factor=0.2, patience=3)
]

EPOCHS = 20

# Uncomment to train when dataset is ready
history = model.fit(
    train_dataset,
    validation_data=val_dataset,
    epochs=EPOCHS,
    callbacks=callbacks
)

# Extract the base model from our wrapped model
base_model = None
for layer in model.layers:
    if hasattr(layer, 'layers'):
        base_model = layer
        break

base_model.trainable = True
fine_tune_at = 100
for layer in base_model.layers[:fine_tune_at]:
    layer.trainable = False

model.compile(optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001), loss='sparse_categorical_crossentropy', metrics=['accuracy'])
history_fine = model.fit(train_dataset, validation_data=val_dataset, epochs=10, callbacks=callbacks)


def export_to_tflite(model, tflite_model_path='gesture_model.tflite'):
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Optional: Apply quantization for a smaller, faster model (useful for mobile)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    tflite_model = converter.convert()
    
    with open(tflite_model_path, 'wb') as f:
        f.write(tflite_model)
    print(f"TFLite model saved to {tflite_model_path}")

# Uncomment to export
# export_to_tflite(model)

