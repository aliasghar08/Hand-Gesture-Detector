import cv2
import json
import numpy as np
import tensorflow as tf
import mediapipe as mp
import math
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
import os
base_dir = os.path.dirname(os.path.abspath(__file__))

# Load model and metadata
interpreter = tf.lite.Interpreter(model_path=os.path.join(base_dir, "gesture_classifier.tflite"))
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

with open(os.path.join(base_dir, "gesture_labels.json"), "r") as f:
    labels = json.load(f)
    
with open(os.path.join(base_dir, "scaler_params.json"), "r") as f:
    scaler_params = json.load(f)

# Initialize MediaPipe
base_options = python.BaseOptions(model_asset_path=os.path.join(base_dir, 'hand_landmarker.task'))
options = vision.HandLandmarkerOptions(base_options=base_options, num_hands=1)
detector = vision.HandLandmarker.create_from_options(options)

def preprocess_landmarks(raw_coords):
    wrist_x, wrist_y = raw_coords[0], raw_coords[1]
    translated = []
    for i in range(0, len(raw_coords), 2):
        translated.append(raw_coords[i] - wrist_x)
        translated.append(raw_coords[i+1] - wrist_y)

    mid_mcp_x, mid_mcp_y = translated[18], translated[19]
    angle = math.atan2(mid_mcp_y, mid_mcp_x)
    delta = -math.pi/2 - angle
    
    cosD = math.cos(delta)
    sinD = math.sin(delta)
    
    rotated = []
    max_abs = 0.0
    for i in range(0, len(translated), 2):
        x, y = translated[i], translated[i+1]
        nx = x * cosD - y * sinD
        ny = x * sinD + y * cosD
        rotated.extend([nx, ny])
        max_abs = max(max_abs, abs(nx), abs(ny))
        
    if max_abs > 0:
        rotated = [c / max_abs for c in rotated]
        
    rotated.extend([cosD, sinD])
    return rotated

def predict(landmarks_list):
    processed = preprocess_landmarks(landmarks_list)
    # Scale
    scaled = []
    for i in range(44):
        val = (processed[i] - scaler_params['mean'][i]) / scaler_params['scale'][i]
        scaled.append(val)
        
    input_data = np.array([scaled], dtype=np.float32)
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    output_data = interpreter.get_tensor(output_details[0]['index'])[0]
    
    best_idx = np.argmax(output_data)
    best_prob = output_data[best_idx]
    
    return labels[best_idx] if best_prob > 0.4 else "Unknown", best_prob

# Open Webcam
cap = cv2.VideoCapture(0)
print("Opening webcam... Please point your hand at the camera!")
print("Press SPACE to capture and test, or 'q' to quit.")

while True:
    ret, frame = cap.read()
    if not ret:
        break
        
    # Process
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    mp_img = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    res = detector.detect(mp_img)
    
    pred_label = "Detecting..."
    if res.hand_landmarks:
        lm = res.hand_landmarks[0]
        h, w, _ = frame.shape
        raw = []
        for l in lm:
            raw.extend([l.x * w, l.y * h])
            
        label, prob = predict(raw)
        pred_label = f"{label} ({prob*100:.1f}%)"
        
        # Draw landmarks
        for i in range(21):
            x = int(lm[i].x * w)
            y = int(lm[i].y * h)
            cv2.circle(frame, (x, y), 3, (0, 255, 0), -1)
            
    cv2.putText(frame, pred_label, (10, 40), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
    cv2.imshow("Hand Gesture Test (Press SPACE to capture)", frame)
    
    key = cv2.waitKey(1)
    if key & 0xFF == ord('q'):
        break
    elif key & 0xFF == 32: # SPACE
        cv2.imwrite("C:/Users/alias/.gemini/antigravity-ide/brain/a1b62fb3-3dc9-4e95-990a-04cdc1818c72/scratch/webcam_test.png", frame)
        print("Captured! Check the chat.")
        break

cap.release()
cv2.destroyAllWindows()
