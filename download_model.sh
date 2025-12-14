#!/bin/bash
# Shell script to download MobileFaceNet TFLite model
# Run this script: bash download_model.sh

echo "========================================"
echo "Downloading MobileFaceNet TFLite Model"
echo "========================================"
echo ""

# Create assets/models directory if it doesn't exist
MODELS_DIR="assets/models"
mkdir -p "$MODELS_DIR"
echo "✅ Created/verified directory: $MODELS_DIR"

# Model file path
MODEL_PATH="$MODELS_DIR/mobilefacenet.tflite"

# Check if model already exists
if [ -f "$MODEL_PATH" ]; then
    echo "⚠️  Model already exists at: $MODEL_PATH"
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Download cancelled."
        exit 1
    fi
fi

echo "📥 Downloading MobileFaceNet TFLite model..."
echo ""

# Download the model
MODEL_URL="https://github.com/iwantooxxoox/Keras-to-TensorFlow-Lite-Converter/raw/master/mobilefacenet.tflite"

if curl -L -o "$MODEL_PATH" "$MODEL_URL"; then
    FILE_SIZE=$(du -h "$MODEL_PATH" | cut -f1)
    echo ""
    echo "✅ Model downloaded successfully!"
    echo "   Location: $MODEL_PATH"
    echo "   Size: $FILE_SIZE"
    echo ""
    echo "✅ Setup complete! The model is ready to use."
else
    echo ""
    echo "❌ Download failed"
    echo ""
    echo "Alternative: Manual download instructions:"
    echo "1. Visit: https://github.com/iwantooxxoox/Keras-to-TensorFlow-Lite-Converter"
    echo "2. Download mobilefacenet.tflite"
    echo "3. Place it in: assets/models/mobilefacenet.tflite"
    echo ""
    echo "Or use this direct link:"
    echo "$MODEL_URL"
    exit 1
fi

echo ""
echo "========================================"
echo "Next Steps:"
echo "1. Run: flutter pub get"
echo "2. Run: flutter run"
echo "========================================"

