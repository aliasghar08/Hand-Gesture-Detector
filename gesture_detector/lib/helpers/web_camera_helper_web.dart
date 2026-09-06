import 'package:web/web.dart' as web;
import 'dart:async';

class WebCameraHelper {
  static Timer? _timer;

  static void startWebCameraStream(Function(dynamic image) onFrame) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      try {
        final videos = web.document.getElementsByTagName('video');
        if (videos.length == 0) return;
        final video = videos.item(0) as web.HTMLVideoElement;
        
        final width = video.videoWidth;
        final height = video.videoHeight;
        if (width == 0 || height == 0) return;
        
        // Pass the HTMLVideoElement directly
        onFrame(video);
      } catch (e) {
        // ignore
      }
    });
  }
}
