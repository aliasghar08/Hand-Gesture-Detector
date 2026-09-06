import tensorflow as tf
import json

print("Loading Keras model...")
try:
    model = tf.keras.models.load_model('best_model.keras')
    print("Model loaded from best_model.keras")
except:
    print("Could not load best_model.keras, loading TFLite model is harder to extract weights. Trying to rebuild from retrain_model script...")
    # Actually, we can just load the H5 or Keras model. Let's see if best_model.keras has the weights.

layers_data = []
for layer in model.layers:
    if isinstance(layer, tf.keras.layers.Dense):
        w, b = layer.get_weights()
        layers_data.append({
            'type': 'Dense',
            'weights': w.tolist(),
            'biases': b.tolist(),
            'activation': layer.activation.__name__ if layer.activation else None
        })
    elif isinstance(layer, tf.keras.layers.BatchNormalization):
        gamma, beta, moving_mean, moving_variance = layer.get_weights()
        layers_data.append({
            'type': 'BatchNormalization',
            'gamma': gamma.tolist(),
            'beta': beta.tolist(),
            'moving_mean': moving_mean.tolist(),
            'moving_variance': moving_variance.tolist(),
            'epsilon': layer.epsilon
        })

with open('gesture_weights.json', 'w') as f:
    json.dump(layers_data, f)
print("Saved gesture_weights.json")
