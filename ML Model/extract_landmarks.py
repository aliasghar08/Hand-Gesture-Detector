import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import pandas as pd
import numpy as np
import os
import glob
import sys

# Suppress TF logging
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

print("Initializing MediaPipe Hands (Tasks API)...")

# Setup MediaPipe Hands Task
base_options = python.BaseOptions(model_asset_path=os.path.abspath('hand_landmarker.task'))
options = vision.HandLandmarkerOptions(
    base_options=base_options,
    num_hands=1,
    min_hand_detection_confidence=0.5,
    min_hand_presence_confidence=0.5,
    min_tracking_confidence=0.5
)
detector = vision.HandLandmarker.create_from_options(options)

DATASET_ROOT = sys.argv[1] if len(sys.argv) > 1 else 'leapgestrecog/extracted'
OUTPUT_CSV = 'extracted_landmarks.csv'

print(f"Scanning directory: {DATASET_ROOT}")

image_paths = []
class_counts = {}
for root, dirs, files in os.walk(DATASET_ROOT):
    for file in files:
        if file.lower().endswith(('.png', '.jpg', '.jpeg')):
            label = os.path.basename(root)
            if label not in ['01_palm', '02_l', '03_fist', '05_thumb', '06_index', '07_ok', '09_c', '10_down']:
                continue
            if label not in class_counts:
                class_counts[label] = 0
            if class_counts[label] < 1500:
                image_paths.append(os.path.join(root, file))
                class_counts[label] += 1

print(f"Found {len(image_paths)} images across {len(class_counts)} classes.")

if len(image_paths) == 0:
    print("No images found. Exiting.")
    sys.exit(1)

import math

def preprocess_landmarks(landmarks):
    # landmarks is a list of 42 floats [x0, y0, x1, y1, ...]
    wrist_x, wrist_y = landmarks[0], landmarks[1]
    
    # 1. Wrist-relative translation
    translated = []
    for i in range(0, len(landmarks), 2):
        translated.append(landmarks[i] - wrist_x)
        translated.append(landmarks[i+1] - wrist_y)
        
    # 2. Rotation invariance
    # Middle Finger MCP is at index 9 (x=18, y=19)
    mx, my = translated[18], translated[19]
    
    # Calculate angle of wrist-to-middle_mcp
    angle = math.atan2(my, mx)
    # Target angle is -pi/2 (pointing straight up)
    delta = -math.pi/2 - angle
    
    cos_d = math.cos(delta)
    sin_d = math.sin(delta)
    
    rotated = []
    for i in range(0, len(translated), 2):
        x = translated[i]
        y = translated[i+1]
        x_rot = x * cos_d - y * sin_d
        y_rot = x * sin_d + y * cos_d
        rotated.extend([x_rot, y_rot])
    
    # 3. Max absolute scaling
    max_abs_value = 0.0
    for val in rotated:
        if abs(val) > max_abs_value:
            max_abs_value = abs(val)
            
    if max_abs_value > 0:
        rotated = [c / max_abs_value for c in rotated]
        
    rotated.extend([math.cos(angle), math.sin(angle)])
        
    return rotated

data = []
success_count = 0

for i, img_path in enumerate(image_paths):
    if i % 1000 == 0 and i > 0:
        print(f"Processed {i}/{len(image_paths)} images...")
        
    label = os.path.basename(os.path.dirname(img_path))
    
    # Read the input image using OpenCV
    try:
        img = cv2.imread(img_path)
        if img is None:
            continue
        
        # Convert to RGB (leapGestRecog images are mostly grayscale but cv2.imread loads them as 3-channel BGR)
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Create MediaPipe Image from numpy array
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_rgb)
    except Exception as e:
        print(f"Error loading {img_path}: {e}")
        continue
    
    # Detect hand landmarks
    try:
        detection_result = detector.detect(mp_image)
    except Exception as e:
        print(f"MediaPipe failed on {img_path}: {e}")
        continue
    
    if detection_result.hand_landmarks:
        # We only take the first hand
        hand_landmarks = detection_result.hand_landmarks[0]
        
        raw_coords = []
        img_h, img_w, _ = img.shape
        for lm in hand_landmarks:
            raw_coords.extend([lm.x * img_w, lm.y * img_h])
            
        processed_coords = preprocess_landmarks(raw_coords)
        row = [label] + processed_coords
        data.append(row)
        
        # Horizontal flip augmentation to support left hands & mirrored webcams!
        flipped_coords = []
        for i in range(0, len(raw_coords), 2):
            flipped_coords.extend([img_w - raw_coords[i], raw_coords[i+1]])
        processed_flipped = preprocess_landmarks(flipped_coords)
        row_flipped = [label] + processed_flipped
        data.append(row_flipped)
        
        success_count += 1

print(f"\nSuccessfully extracted landmarks from {success_count}/{len(image_paths)} images.")

cols = ['label'] + [f'feat_{i}' for i in range(44)]
df = pd.DataFrame(data, columns=cols)

# Make label the last column
cols = [f'feat_{i}' for i in range(44)] + ['label']
df = df[cols]

df.to_csv(OUTPUT_CSV, index=False)
print(f"Saved {len(df)} rows to {OUTPUT_CSV}")
