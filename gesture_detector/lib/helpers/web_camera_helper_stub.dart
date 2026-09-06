import 'dart:typed_data';

class WebCameraHelper {
  static void startWebCameraStream(Function(dynamic image) onFrame) {
    throw UnsupportedError('Only supported on Web');
  }
}
