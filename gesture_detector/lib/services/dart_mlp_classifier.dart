import 'dart:convert';
import 'dart:math' as math;

class DartMlpClassifier {
  List<dynamic>? _layers;
  bool get isReady => _layers != null;

  Future<void> loadWeights(String jsonString) async {
    _layers = jsonDecode(jsonString);
  }

  List<double> predict(List<double> input) {
    if (!isReady) throw Exception("Model not loaded");
    
    List<double> current = List.from(input);

    for (var layer in _layers!) {
      String type = layer['type'];
      
      if (type == 'Dense') {
        List<dynamic> w = layer['weights'];
        List<dynamic> b = layer['biases'];
        String? activation = layer['activation'];

        int inFeatures = current.length;
        int outFeatures = b.length;
        List<double> next = List.filled(outFeatures, 0.0);

        for (int i = 0; i < outFeatures; i++) {
          double sum = b[i].toDouble();
          for (int j = 0; j < inFeatures; j++) {
            sum += current[j] * w[j][i].toDouble();
          }
          next[i] = sum;
        }

        if (activation == 'relu') {
          for (int i = 0; i < outFeatures; i++) {
            next[i] = math.max(0.0, next[i]);
          }
        } else if (activation == 'softmax') {
          double maxVal = next.reduce(math.max);
          double sum = 0.0;
          for (int i = 0; i < outFeatures; i++) {
            next[i] = math.exp(next[i] - maxVal);
            sum += next[i];
          }
          for (int i = 0; i < outFeatures; i++) {
            next[i] /= sum;
          }
        }
        
        current = next;

      } else if (type == 'BatchNormalization') {
        List<dynamic> gamma = layer['gamma'];
        List<dynamic> beta = layer['beta'];
        List<dynamic> mean = layer['moving_mean'];
        List<dynamic> variance = layer['moving_variance'];
        double epsilon = layer['epsilon'].toDouble();

        for (int i = 0; i < current.length; i++) {
          double normalized = (current[i] - mean[i].toDouble()) / math.sqrt(variance[i].toDouble() + epsilon);
          current[i] = normalized * gamma[i].toDouble() + beta[i].toDouble();
        }
      }
    }

    return current;
  }
}
