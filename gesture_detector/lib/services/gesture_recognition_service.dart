import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class GestureRecognitionService {
  Interpreter? _interpreter;
  List<String>? _labels;

  // Assume the model from the Jupyter notebook (MobileNetV2 based) expects 224x224 RGB
  static const int inputSize = 224;

  // Placeholder labels based on our plan
  static const List<String> defaultLabels = [
    "Palm",
    "L Shape",
    "Fist",
    "Fist Moved",
    "Thumb",
    "Index",
    "OK",
    "Palm Moved",
    "C Shape",
    "Down"
  ];

  Future<void> initialize() async {
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset('assets/gesture_model.tflite');
      _labels = defaultLabels; // Or load from a file if needed
      print("Model loaded successfully.");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  void dispose() {
    _interpreter?.close();
  }

  String recognizeGesture(CameraImage cameraImage) {
    if (_interpreter == null) {
      return "Model not loaded";
    }

    try {
      // 1. Convert CameraImage to image.Image
      img.Image? image = _convertCameraImage(cameraImage);
      if (image == null) return "Failed to process image";

      // 2. Resize to required input size (224x224)
      img.Image resizedImage = img.copyResize(image, width: inputSize, height: inputSize);

      // 3. Preprocess and convert to Tensor input (1, 224, 224, 3)
      var inputTensor = _imageToByteListFloat32(resizedImage, inputSize, 127.5, 127.5);

      // 4. Run inference
      var outputBuffer = List.filled(1 * defaultLabels.length, 0.0).reshape([1, defaultLabels.length]);
      _interpreter!.run(inputTensor, outputBuffer);

      // 5. Parse output
      List<double> probabilities = (outputBuffer[0] as List).cast<double>();
      
      int highestProbIndex = 0;
      double maxProb = probabilities[0];
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          highestProbIndex = i;
        }
      }

      // 6. Return label if confidence is high enough
      if (maxProb > 0.5) {
        return _labels![highestProbIndex];
      } else {
        return "Unrecognized";
      }

    } catch (e) {
      print("Error during inference: $e");
      return "Error";
    }
  }

  /// Converts a [CameraImage] to an [img.Image]
  img.Image? _convertCameraImage(CameraImage image) {
    if (Platform.isAndroid && image.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420ToImage(image);
    } else if (Platform.isIOS && image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888ToImage(image);
    }
    return null; // Unsupported format
  }

  img.Image _convertYUV420ToImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    
    final imgImage = img.Image(width: width, height: height);

    final yBuffer = image.planes[0].bytes;
    final uBuffer = image.planes[1].bytes;
    final vBuffer = image.planes[2].bytes;

    final int yRowStride = image.planes[0].bytesPerRow;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      int uvRow = y >> 1;
      for (int x = 0; x < width; x++) {
        int uvCol = x >> 1;
        
        int yIndex = (y * yRowStride) + x;
        int uvIndex = (uvRow * uvRowStride) + (uvCol * uvPixelStride);

        int yValue = yBuffer[yIndex];
        int uValue = uBuffer[uvIndex];
        int vValue = vBuffer[uvIndex];

        // Convert YUV to RGB
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round().clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        imgImage.setPixelRgb(x, y, r, g, b);
      }
    }
    return imgImage;
  }

  img.Image _convertBGRA8888ToImage(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  /// Converts [img.Image] to a 3D float32 array for MobileNetV2
  /// simulating grayscale to match the training dataset conditions.
  List<List<List<List<double>>>> _imageToByteListFloat32(img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = List.generate(
      1,
      (i) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            // Convert to grayscale using standard luminance formula
            final num luminance = (0.299 * pixel.r) + (0.587 * pixel.g) + (0.114 * pixel.b);
            final normalized = (luminance - mean) / std;
            
            return [
              normalized,
              normalized,
              normalized,
            ];
          },
        ),
      ),
    );
    return convertedBytes;
  }
}
