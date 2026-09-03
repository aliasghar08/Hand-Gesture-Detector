"""
Deep diagnosis of the landmark model behavior.
Tests it on: blank image, real hand image, random noise.
This tells us if the model fundamentally can detect hand presence.
"""
import numpy as np
import tensorflow as tf
import urllib.request
import os

# Suppress TF logs
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

interp = tf.lite.Interpreter(
    model_path=r'c:\Flutter Projects\Hand Gesture Detector using Custom Model\gesture_detector\assets\landmark_model.tflite'
)
interp.allocate_tensors()
inp_idx = interp.get_input_details()[0]['index']
out_idx = interp.get_output_details()[0]['index']

def run(img_array):
    """img_array: (224,224,3) float32 in [0,1]"""
    interp.set_tensor(inp_idx, img_array[np.newaxis].astype(np.float32))
    interp.invoke()
    pts = interp.get_tensor(out_idx)[0]  # (42,)
    xs = pts[0::2]
    ys = pts[1::2]
    spread_x = xs.max() - xs.min()
    spread_y = ys.max() - ys.min()
    return pts, spread_x, spread_y

print("=" * 60)
print("TEST 1: All-black image (no hand)")
black = np.zeros((224, 224, 3), np.float32)
pts, sx, sy = run(black)
print(f"  Spread X: {sx:.4f}  Spread Y: {sy:.4f}")
print(f"  First 6 pts: {pts[:6].round(4)}")

print("\nTEST 2: All-white image (no hand)")
white = np.ones((224, 224, 3), np.float32)
pts, sx, sy = run(white)
print(f"  Spread X: {sx:.4f}  Spread Y: {sy:.4f}")
print(f"  First 6 pts: {pts[:6].round(4)}")

print("\nTEST 3: Random noise (no hand)")
rng = np.random.default_rng(42)
noise = rng.random((224, 224, 3)).astype(np.float32)
pts, sx, sy = run(noise)
print(f"  Spread X: {sx:.4f}  Spread Y: {sy:.4f}")
print(f"  First 6 pts: {pts[:6].round(4)}")

print("\nTEST 4: Skin-colored image (no hand shape, just skin color)")
skin = np.full((224, 224, 3), [0.87, 0.70, 0.59], np.float32)
pts, sx, sy = run(skin)
print(f"  Spread X: {sx:.4f}  Spread Y: {sy:.4f}")
print(f"  First 6 pts: {pts[:6].round(4)}")

print("\nTEST 5: Sample FreiHAND image (actual hand)")
# Try to load a real FreiHAND image
import cv2
frei_path = r'c:\Flutter Projects\Hand Gesture Detector using Custom Model\ML Model\freihand_data\training\rgb\00000000.jpg'
if os.path.exists(frei_path):
    img = cv2.imread(frei_path)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = cv2.resize(img, (224, 224)).astype(np.float32) / 255.0
    pts, sx, sy = run(img)
    print(f"  Spread X: {sx:.4f}  Spread Y: {sy:.4f}")
    print(f"  First 6 pts: {pts[:6].round(4)}")
else:
    print("  FreiHAND image not found — skipping")

print("\n" + "=" * 60)
print("ANALYSIS:")
print("If spread_x < 0.1 and spread_y < 0.1 on no-hand images,")
print("we can use spread as a hand-presence gate.")
print("If spread is always large, we CANNOT use this heuristic.")
print("In that case, we must use MediaPipe hand_landmarker.task")
print("for proper detection.")
