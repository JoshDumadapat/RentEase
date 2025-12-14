# MobileFaceNet TFLite Model Setup Guide

## Quick Setup

### Step 1: Download the Model

You need to download a MobileFaceNet TFLite model. Here are several options:

#### Option 1: Pre-trained Model (Recommended)

**Download from one of these sources:**

1. **GitHub Repositories:**
   - Search GitHub for "mobilefacenet tflite"
   - Look for repositories with pre-converted models
   - Example: https://github.com/search?q=mobilefacenet+tflite

2. **TensorFlow Hub:**
   - Visit: https://tfhub.dev/
   - Search for "face recognition" or "MobileFaceNet"
   - Download and convert to TFLite if needed

3. **Model Zoo:**
   - Check TensorFlow Model Zoo
   - Look for MobileFaceNet or similar face recognition models

#### Option 2: Convert from Keras/TensorFlow

If you have a MobileFaceNet Keras model (.h5 file):

```python
import tensorflow as tf

# Load your Keras model
model = tf.keras.models.load_model('mobilefacenet.h5')

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save
with open('mobilefacenet.tflite', 'wb') as f:
    f.write(tflite_model)
```

#### Option 3: Train Your Own

Follow MobileFaceNet training procedures and convert to TFLite.

### Step 2: Place the Model File

1. Download the `mobilefacenet.tflite` file
2. Place it in: `assets/models/mobilefacenet.tflite`
3. The directory structure should be:
   ```
   assets/
     models/
       mobilefacenet.tflite
   ```

### Step 3: Verify pubspec.yaml

Make sure `pubspec.yaml` includes the models directory:

```yaml
flutter:
  assets:
    - assets/models/
```

### Step 4: Run the App

```bash
flutter pub get
flutter run
```

## Model Requirements

The model should have these specifications:

- **Input Size:** 112x112 RGB images
- **Output:** 192-dimensional normalized embeddings (for MobileFaceNet)
- **Format:** TensorFlow Lite (.tflite)
- **Normalization:** Embeddings should be L2-normalized

## Alternative Models

If you can't find MobileFaceNet, you can use:

1. **FaceNet** (128-dim embeddings, 160x160 input)
   - Update `_inputSize = 160` in code
   - Update `_embeddingSize = 128` in code

2. **ArcFace** (512-dim embeddings, 112x112 input)
   - Update `_embeddingSize = 512` in code

3. **Any face recognition model** with normalized embeddings

## Troubleshooting

### Error: "Unable to load asset"
- Check that the file exists at `assets/models/mobilefacenet.tflite`
- Run `flutter clean` and `flutter pub get`
- Verify `pubspec.yaml` includes `assets/models/`

### Error: "Model input/output mismatch"
- Check the model's input size and update `_inputSize` if needed
- Check the model's output size and update `_embeddingSize` if needed

### Model Not Working
- Verify the model outputs normalized embeddings
- Check that the model accepts RGB images (not BGR)
- Ensure pixel values are normalized to [0.0, 1.0]

## Testing

After setup, the app will:
1. Load the model on first face comparison
2. Generate embeddings for ID and selfie faces
3. Compare using cosine similarity
4. Return PASS if similarity ≥ 0.55

Check the console logs for detailed information about the face comparison process.

