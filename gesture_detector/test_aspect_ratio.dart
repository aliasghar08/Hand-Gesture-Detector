
import "dart:math" as math;

void main() {
  final double trainWidth = 640.0;
  final double trainHeight = 240.0;
  
  // Simulated hand pointing UP in portrait (X=200, Y changes from 400 to 200)
  // Let preview be 720x1280
  double previewWidth = 720.0;
  double previewHeight = 1280.0;

  // In portrait, sensor width = 1280 (height of image), sensor height = 720 (width of image)
  // MediaPipe plugin output (assuming raw landscape sensor 1280x720):
  // X axis on sensor is long edge (1280), Y axis is short edge (720).
  // A hand pointing UP on the portrait screen points RIGHT on the sensor (increasing X, constant Y).
  
  // Wrist:
  double lmX_wrist = 1000 / 1280.0;
  double lmY_wrist = 360 / 720.0;
  
  // Middle MCP:
  double lmX_middle = 1200 / 1280.0;
  double lmY_middle = 360 / 720.0;

  // Apply mapping
  double mappedX_wrist = 1.0 - lmY_wrist;
  double mappedY_wrist = lmX_wrist;
  
  double fakeX_wrist = mappedX_wrist * (720.0 / trainWidth);
  double fakeY_wrist = mappedY_wrist * (1280.0 / trainHeight);
  
  double mappedX_middle = 1.0 - lmY_middle;
  double mappedY_middle = lmX_middle;
  
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

