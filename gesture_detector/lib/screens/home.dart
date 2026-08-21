import 'package:flutter/material.dart';
import 'package:hand_gesture_app/main.dart';
import 'package:hand_gesture_app/screens/CameraScreen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
 Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hand Gesture App",
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CameraScreen()),
                );
              },
              child: Text("Get Started"),
            ),
          ],
        ),
      ),
    );
  }
}