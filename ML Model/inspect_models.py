import tensorflow as tf

# Inspect landmark model
interp1 = tf.lite.Interpreter(model_path=r'c:\Flutter Projects\Hand Gesture Detector using Custom Model\gesture_detector\assets\landmark_model.tflite')
interp1.allocate_tensors()
inp1 = interp1.get_input_details()[0]
out1 = interp1.get_output_details()[0]
print("=== LANDMARK MODEL ===")
print("Input  shape:", inp1['shape'], " dtype:", inp1['dtype'])
print("Output shape:", out1['shape'], " dtype:", out1['dtype'])

# Inspect gesture classifier
interp2 = tf.lite.Interpreter(model_path=r'c:\Flutter Projects\Hand Gesture Detector using Custom Model\gesture_detector\assets\gesture_classifier.tflite')
interp2.allocate_tensors()
inp2 = interp2.get_input_details()[0]
out2 = interp2.get_output_details()[0]
print("\n=== GESTURE CLASSIFIER ===")
print("Input  shape:", inp2['shape'], " dtype:", inp2['dtype'])
print("Output shape:", out2['shape'], " dtype:", out2['dtype'])

# Run a quick sanity test on both models with dummy data
import numpy as np
print("\n=== SANITY TEST ===")
dummy_img = np.random.rand(1, 224, 224, 3).astype(np.float32)
interp1.set_tensor(inp1['index'], dummy_img)
interp1.invoke()
lm_out = interp1.get_tensor(out1['index'])
print("Landmark output sample (first 6 of 42):", lm_out[0][:6])

dummy_lm = np.random.rand(1, inp2['shape'][1]).astype(np.float32)
interp2.set_tensor(inp2['index'], dummy_lm)
interp2.invoke()
cls_out = interp2.get_tensor(out2['index'])
print("Classifier output (probabilities):", cls_out[0])
