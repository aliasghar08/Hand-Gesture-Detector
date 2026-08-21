<div align="center">

# 🖐️ Hand Gesture Recognition System

**Real-Time, On-Device Hand Gesture Detection & Vocal Feedback**

An end-to-end computer vision and machine learning pipeline featuring a fine-tuned **MobileNetV2** architecture deployed 100% offline via **Flutter** and **TensorFlow Lite**.

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![TensorFlow](https://img.shields.io/badge/TensorFlow-%23FF6F00.svg?style=for-the-badge&logo=TensorFlow&logoColor=white)](https://www.tensorflow.org/)
[![Keras](https://img.shields.io/badge/Keras-%23D00000.svg?style=for-the-badge&logo=Keras&logoColor=white)](https://keras.io/)
[![Kaggle](https://img.shields.io/badge/Kaggle-20BEFF?style=for-the-badge&logo=Kaggle&logoColor=white)](https://www.kaggle.com/gti-upm/leapgestrecog)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com/)
[![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)

---

</div>

## 📌 Overview

This project bridges edge machine learning with cross-platform mobile development. Trained on the **LeapGestRecog Infrared Gesture Dataset**, the model is optimized for low-latency inference on edge devices using a quantized `.tflite` model, running entirely on-device without requiring an internet connection.

---

## ✨ Key Features

- ⚡ **Real-Time Offline Inference:** Ultra-low latency edge predictions powered by `tflite_flutter`.
- 🧠 **Optimized MobileNetV2 Architecture:** Transfer learning pipeline with custom classification layers tailored for edge deployment.
- 🌓 **Domain Shift Preprocessing:** Custom camera frame transformation pipeline (luminance/grayscale mapping) matching infrared training distributions to ensure resilience across diverse ambient lighting.
- 🔊 **Voice Feedback (TTS):** Integrated Text-to-Speech engine for hands-free and accessible feedback.
- 📱 **Cross-Platform Compatibility:** Universal codebase designed to run smoothly on both Android and iOS devices.

---

## 🎯 Supported Gestures (10 Classes)

| Gesture | Label | Gesture | Label |
| :--- | :--- | :--- | :--- |
| ✋ **Palm** | `01_palm` | 👆 **Index** | `06_index` |
| 🇱 **L-Sign** | `02_l` | 👌 **OK-Sign** | `07_ok` |
| ✊ **Fist** | `03_fist` | 👋 **Palm (Moved)** | `08_palm_moved` |
| 🤛 **Fist (Moved)** | `04_fist_moved` | 🗜️ **C-Sign** | `09_c` |
| 👍 **Thumb** | `05_thumb` | 👇 **Down** | `10_down` |

---

## 🛠️ Tech Stack & Architecture

| Layer | Technologies / Tools | Description |
| :--- | :--- | :--- |
| **Model Development** | Python, TensorFlow 2.x, Keras, NumPy | Data preprocessing, augmentation, and model training |
| **Edge Optimization** | TFLite Converter, Float16/INT8 Quantization | Exporting lightweight graphs for edge devices |
| **Application Layer**| Flutter, Dart | UI layout, state management, and real-time camera stream |
| **Hardware Binding** | `camera`, `tflite_flutter`, `flutter_tts` | Camera frame stream interception, model invocation, audio synthesis |

---

## 📂 Project Structure

```text
Hand-Gesture-Detector/
├── ML Model/                          # Model training & conversion pipeline
│   ├── model_training_pipeline.ipynb  # Kaggle data pipeline & training notebook
│   └── gesture_model.tflite           # Exported TensorFlow Lite model
├── gesture_detector/                  # Flutter cross-platform mobile app
│   ├── assets/
│   │   ├── gesture_model.tflite       # Bundled model asset
│   │   └── labels.txt                 # Classification label mapping
│   ├── lib/                           # App source code (camera, inference, UI)
│   └── pubspec.yaml                   # Flutter dependency specifications
└── README.md
