import os
import glob
import shutil
import tensorflow as tf
import numpy as np
import matplotlib.pyplot as plt

# 1. Organize Dataset
# The leapgestrecog dataset has structure: leapGestRecog/00/01_palm/img.png
# We want: organized_dataset/01_palm/img.png
DATASET_DIR = './leapgestrecog_retry/leapGestRecog'
ORGANIZED_DIR = './organized_dataset'

if not os.path.exists(ORGANIZED_DIR):
    os.makedirs(ORGANIZED_DIR)
    
    # Check if dataset exists yet
    if os.path.exists(DATASET_DIR):
        print("Organizing dataset...")
        for subject_id in os.listdir(DATASET_DIR):
            subject_path = os.path.join(DATASET_DIR, subject_id)
            if not os.path.isdir(subject_path):
                continue
            for gesture_name in os.listdir(subject_path):
                gesture_path = os.path.join(subject_path, gesture_name)
                if not os.path.isdir(gesture_path):
                    continue
                
                target_gesture_dir = os.path.join(ORGANIZED_DIR, gesture_name)
                if not os.path.exists(target_gesture_dir):
                    os.makedirs(target_gesture_dir)
                
                for img_name in os.listdir(gesture_path):
                    src = os.path.join(gesture_path, img_name)
                    # to avoid name collision, prefix with subject_id
                    dst = os.path.join(target_gesture_dir, f"{subject_id}_{img_name}")
                    shutil.copy2(src, dst)
        print("Dataset organized.")
    else:
        print("Waiting for dataset to download...")
        exit(0)

# Configuration
BATCH_SIZE = 32
IMG_HEIGHT = 224
IMG_WIDTH = 224
EPOCHS = 10

def build_efficient_model(num_classes):
    base_model = tf.keras.applications.MobileNetV2(
        input_shape=(IMG_HEIGHT, IMG_WIDTH, 3),
        include_top=False,
        weights='imagenet'
    )
    base_model.trainable = False

    data_augmentation = tf.keras.Sequential([
        tf.keras.layers.RandomFlip("horizontal"),
        tf.keras.layers.RandomRotation(0.1),
        tf.keras.layers.RandomZoom(0.1),
    ])

    inputs = tf.keras.Input(shape=(IMG_HEIGHT, IMG_WIDTH, 3))
    x = data_augmentation(inputs)
    x = tf.keras.applications.mobilenet_v2.preprocess_input(x)
    
    x = base_model(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(0.2)(x)
    outputs = tf.keras.layers.Dense(num_classes, activation='softmax')(x)
    
    model = tf.keras.Model(inputs, outputs)
    return model

# 2. Load Dataset
print("Loading dataset...")
train_dataset = tf.keras.utils.image_dataset_from_directory(
    ORGANIZED_DIR,
    validation_split=0.2,
    subset="training",
    seed=123,
    image_size=(IMG_HEIGHT, IMG_WIDTH),
    batch_size=BATCH_SIZE
)

val_dataset = tf.keras.utils.image_dataset_from_directory(
    ORGANIZED_DIR,
    validation_split=0.2,
    subset="validation",
    seed=123,
    image_size=(IMG_HEIGHT, IMG_WIDTH),
    batch_size=BATCH_SIZE
)

class_names = train_dataset.class_names
NUM_CLASSES = len(class_names)
print(f'Detected {NUM_CLASSES} classes: {class_names}')

AUTOTUNE = tf.data.AUTOTUNE
train_dataset = train_dataset.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
val_dataset = val_dataset.cache().prefetch(buffer_size=AUTOTUNE)

# 3. Model Training
model = build_efficient_model(NUM_CLASSES)
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

callbacks = [
    tf.keras.callbacks.EarlyStopping(patience=5, restore_best_weights=True),
    tf.keras.callbacks.ModelCheckpoint('best_gesture_model.keras', save_best_only=True),
    tf.keras.callbacks.ReduceLROnPlateau(factor=0.2, patience=3)
]

print("Starting training...")
history = model.fit(
    train_dataset,
    validation_data=val_dataset,
    epochs=EPOCHS,
    callbacks=callbacks
)

# 4. Save TFLite Model
print("Exporting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open('gesture_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("Training complete! Model saved as gesture_model.tflite")
