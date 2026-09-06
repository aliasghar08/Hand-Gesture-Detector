import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hand_gesture_app/screens/home.dart';
import 'package:hand_gesture_app/utils/debug_logger.dart';

// Declare cameras at top level
List<CameraDescription>? cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // CRITICAL: This must be here!
  
  // Initialize cameras
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
    DebugLogger.log('Number of cameras found: ${cameras?.length}');
  } catch (e) {
    DebugLogger.logError('Initializing cameras', e);
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaveSense',
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