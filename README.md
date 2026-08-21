# Hand Gesture Recognition System

A real-time hand gesture recognition system built using a custom-trained MobileNetV2 machine learning model and a cross-platform Flutter application. 

This project trains a model on the [leapGestRecog Kaggle dataset](https://www.kaggle.com/gti-upm/leapgestrecog) and integrates the exported `.tflite` model directly into a Flutter app that runs 100% offline. The app features real-time camera inference and text-to-speech (TTS) pronunciation.

## Features
- **Custom Trained AI:** MobileNetV2 transfer learning via TensorFlow/Keras.
- **Offline Inference:** Fast, on-device inference using `tflite_flutter`.
- **Domain Shift Mitigation:** Real-time luminance/grayscale preprocessing of the camera feed to mimic the infrared training dataset, providing robustness against varied lighting conditions.
- **Accessibility:** Built-in local Text-to-Speech (TTS) pronunciation of detected gestures.

## Gestures Supported
- Palm
- L
- Fist
- Fist Moved
- Thumb
- Index
- OK
- Palm Moved
- C
- Down

## Project Structure
- `/ML Model` - Contains the Python scripts, Jupyter notebooks, and data processing pipelines for downloading the dataset and training the TensorFlow model.
- `/gesture_detector` - The Flutter application source code.

## Getting Started

### Building the ML Model
1. Ensure you have Python installed and run the notebook `ML Model/model_training_pipeline.ipynb`.
2. The pipeline will automatically download the dataset from Kaggle, process it, train the model, and export a `gesture_model.tflite` file.

### Running the App
1. Navigate to the `gesture_detector` directory:
   ```bash
   cd gesture_detector
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on a connected device:
   ```bash
   flutter run
   ```
4. Or build the release APK:
   ```bash
   flutter build apk
   ```
