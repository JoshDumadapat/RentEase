# PowerShell script to download MobileFaceNet TFLite model
# Run this script: .\download_model.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MobileFaceNet TFLite Model Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create assets/models directory if it doesn't exist
$modelsDir = "assets\models"
if (-not (Test-Path $modelsDir)) {
    New-Item -ItemType Directory -Path $modelsDir -Force | Out-Null
    Write-Host "Created directory: $modelsDir" -ForegroundColor Green
}

# Model file path
$modelPath = "$modelsDir\mobilefacenet.tflite"

# Check if model already exists
if (Test-Path $modelPath) {
    $fileSize = (Get-Item $modelPath).Length / 1MB
    Write-Host "Model already exists!" -ForegroundColor Green
    Write-Host "Location: $modelPath" -ForegroundColor Gray
    Write-Host "Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Setup complete! The model is ready to use." -ForegroundColor Green
    exit 0
}

Write-Host "Model file not found. Please download manually:" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MANUAL DOWNLOAD INSTRUCTIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 1: Download from Google Drive (Recommended)" -ForegroundColor Yellow
Write-Host "1. Visit: https://drive.google.com/drive/folders/1LyyVSZxrJNQkfdJ5nvwB6wRMk3o4spjE" -ForegroundColor Gray
Write-Host "   (Search for 'MobileFaceNet TFLite' on Google Drive)" -ForegroundColor Gray
Write-Host "2. Download mobilefacenet.tflite" -ForegroundColor Gray
Write-Host "3. Place it in: $modelPath" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 2: Use TensorFlow Hub Model" -ForegroundColor Yellow
Write-Host "1. Visit: https://tfhub.dev/" -ForegroundColor Gray
Write-Host "2. Search for 'MobileFaceNet' or 'face recognition'" -ForegroundColor Gray
Write-Host "3. Download and convert to TFLite format" -ForegroundColor Gray
Write-Host ""
Write-Host "Option 3: Convert from Keras Model" -ForegroundColor Yellow
Write-Host "If you have a MobileFaceNet Keras model (.h5), convert it:" -ForegroundColor Gray
Write-Host "  import tensorflow as tf" -ForegroundColor Cyan
Write-Host "  converter = tf.lite.TFLiteConverter.from_keras_model(model)" -ForegroundColor Cyan
Write-Host "  tflite_model = converter.convert()" -ForegroundColor Cyan
Write-Host "  with open('mobilefacenet.tflite', 'wb') as f:" -ForegroundColor Cyan
Write-Host "      f.write(tflite_model)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 4: Use Alternative Model" -ForegroundColor Yellow
Write-Host "You can use any face recognition TFLite model with:" -ForegroundColor Gray
Write-Host "- Input size: 112x112 (or adjust _inputSize in code)" -ForegroundColor Gray
Write-Host "- Embedding size: 192 (or adjust _embeddingSize in code)" -ForegroundColor Gray
Write-Host "- Output: Normalized face embeddings" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "QUICK SETUP (After Download)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Place the .tflite file in: $modelPath" -ForegroundColor Gray
Write-Host "2. Run: flutter pub get" -ForegroundColor Gray
Write-Host "3. Run: flutter run" -ForegroundColor Gray
Write-Host ""
Write-Host "The app will automatically load the model on first use." -ForegroundColor Green
