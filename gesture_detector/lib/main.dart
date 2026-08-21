import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_gesture_app/screens/home.dart';

// Declare cameras at top level
List<CameraDescription>? cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // CRITICAL: This must be here!
  
  // Initialize cameras
  try {
    cameras = await availableCameras();
    print('Number of cameras found: ${cameras?.length}');
  } catch (e) {
    print('Error initializing cameras: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hand Gesture App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        "/Home": (context) => HomePage(),
      },
      initialRoute: "/Home",
    );
  }
}