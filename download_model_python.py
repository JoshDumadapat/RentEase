"""
Python script to download or convert MobileFaceNet TFLite model
Run: python download_model_python.py
"""

import os
import sys
import urllib.request
from pathlib import Path

def download_model():
    """Download MobileFaceNet TFLite model"""
    models_dir = Path("assets/models")
    models_dir.mkdir(parents=True, exist_ok=True)
    
    model_path = models_dir / "mobilefacenet.tflite"
    
    if model_path.exists():
        print(f"✅ Model already exists at: {model_path}")
        return True
    
    print("📥 Attempting to download MobileFaceNet TFLite model...")
    print("")
    
    # Try multiple sources
    urls = [
        "https://github.com/iwantooxxoox/Keras-to-TensorFlow-Lite-Converter/raw/master/mobilefacenet.tflite",
        "https://raw.githubusercontent.com/iwantooxxoox/Keras-to-TensorFlow-Lite-Converter/master/mobilefacenet.tflite",
    ]
    
    for url in urls:
        try:
            print(f"Trying: {url}")
            urllib.request.urlretrieve(url, model_path)
            
            if model_path.exists() and model_path.stat().st_size > 0:
                size_mb = model_path.stat().st_size / (1024 * 1024)
                print("")
                print(f"✅ Model downloaded successfully!")
                print(f"   Location: {model_path}")
                print(f"   Size: {size_mb:.2f} MB")
                return True
        except Exception as e:
            print(f"   Failed: {e}")
            continue
    
    return False

def convert_from_keras():
    """Convert Keras model to TFLite"""
    try:
        import tensorflow as tf
        
        keras_model_path = input("Enter path to MobileFaceNet Keras model (.h5): ").strip()
        if not os.path.exists(keras_model_path):
            print(f"❌ File not found: {keras_model_path}")
            return False
        
        print("Loading Keras model...")
        model = tf.keras.models.load_model(keras_model_path)
        
        print("Converting to TFLite...")
        converter = tf.lite.TFLiteConverter.from_keras_model(model)
        tflite_model = converter.convert()
        
        models_dir = Path("assets/models")
        models_dir.mkdir(parents=True, exist_ok=True)
        model_path = models_dir / "mobilefacenet.tflite"
        
        with open(model_path, 'wb') as f:
            f.write(tflite_model)
        
        print(f"✅ Model converted and saved to: {model_path}")
        return True
    except ImportError:
        print("❌ TensorFlow not installed. Install with: pip install tensorflow")
        return False
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        return False

if __name__ == "__main__":
    print("=" * 50)
    print("MobileFaceNet TFLite Model Setup")
    print("=" * 50)
    print("")
    
    # Try downloading
    if download_model():
        print("")
        print("✅ Setup complete! The model is ready to use.")
        sys.exit(0)
    
    print("")
    print("Automatic download failed.")
    print("")
    print("Options:")
    print("1. Manual download - See SETUP_TFLITE_MODEL.md")
    print("2. Convert from Keras model")
    print("")
    
    choice = input("Convert from Keras model? (y/n): ").strip().lower()
    if choice == 'y':
        if convert_from_keras():
            print("")
            print("✅ Setup complete!")
            sys.exit(0)
    
    print("")
    print("Please download the model manually:")
    print("1. See SETUP_TFLITE_MODEL.md for instructions")
    print("2. Place the model at: assets/models/mobilefacenet.tflite")
    sys.exit(1)

