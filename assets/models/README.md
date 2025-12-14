# Face Recognition Model Setup

This directory should contain a TensorFlow Lite face recognition model.

## Recommended Models
   
1. **MobileFaceNet** (Recommended - Small, Fast)
   - Input: 112x112 RGB
   - Output: 192-dimensional embedding
   - Download: Search for "MobileFaceNet TensorFlow Lite" or convert from TensorFlow

2. **FaceNet** (High Accuracy)
   - Input: 160x160 RGB
   - Output: 128-dimensional embedding
   - Download: https://github.com/tensorflow/models/tree/master/research/facenet

3. **ArcFace** (State-of-the-art)
   - Input: 112x112 RGB
   - Output: 512-dimensional embedding
   - Download: Search for "ArcFace TensorFlow Lite"

## Model File

Place your model file as: `mobilefacenet.tflite`

## Model Conversion

If you have a TensorFlow model, convert it to TFLite:

```python
import tensorflow as tf

# Load your model
model = tf.keras.models.load_model('your_model.h5')

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save
with open('mobilefacenet.tflite', 'wb') as f:
    f.write(tflite_model)
```

## Quick Start (Using Pre-trained Model)

1. Download a pre-trained MobileFaceNet TFLite model
2. Rename it to `mobilefacenet.tflite`
3. Place it in this directory (`assets/models/`)
4. Update `_embeddingSize` in `id_validation_service.dart` if needed (default: 192 for MobileFaceNet)

## Model Sources

- TensorFlow Hub: https://tfhub.dev/
- Model Zoo: https://github.com/tensorflow/models
- Search: "face recognition tensorflow lite mobile"

