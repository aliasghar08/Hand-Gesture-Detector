
import "dart:math" as math;

void main() {
  final double trainWidth = 640.0;
  final double trainHeight = 240.0;
  
  // Simulated hand pointing UP in portrait (X=360, Y changes from 1000 to 800)
  // Let preview be 720x1280
  double previewWidth = 720.0;
  double previewHeight = 1280.0;

  // Wrist:
  double lmX_wrist = 360 / 720.0;
  double lmY_wrist = 1000 / 1280.0;
  
  // Middle MCP:
  double lmX_middle = 360 / 720.0;
  double lmY_middle = 800 / 1280.0;

  // Apply mapping (direct, NO mapping)
  double mappedX_wrist = lmX_wrist;
  double mappedY_wrist = lmY_wrist;
  
  double fakeX_wrist = mappedX_wrist * (720.0 / trainWidth);
  double fakeY_wrist = mappedY_wrist * (1280.0 / trainHeight);
  
  double mappedX_middle = lmX_middle;
  double mappedY_middle = lmY_middle;
  
  double fakeX_middle = mappedX_middle * (720.0 / trainWidth);
  double fakeY_middle = mappedY_middle * (1280.0 / trainHeight);
  
  // Wrist relative
  double relX = fakeX_middle - fakeX_wrist;
  double relY = fakeY_middle - fakeY_wrist;
  
  print("RelX: $relX, RelY: $relY");
  
  // Angle
  double angle = math.atan2(relY, relX);
  print("Angle (should be approx -1.57 for UP): $angle");
}

