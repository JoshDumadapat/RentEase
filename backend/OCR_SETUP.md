# Enhanced OCR Setup with Tesseract (Vertical Text Support)

## Overview

The Python backend now uses **Tesseract OCR** with enhanced preprocessing specifically designed for **vertical column text** (like ID numbers next to barcodes).

## Key Improvements

### 1. **Enhanced Image Preprocessing**
- Grayscale conversion
- Adaptive thresholding for better text contrast
- Morphological operations to clean up noise
- Optimized for vertical text extraction

### 2. **Multiple OCR Configurations**
The backend tries **6 different Tesseract PSM modes** to maximize text extraction:
- **PSM 6**: Uniform block of text (default)
- **PSM 4**: Single column (for vertical text)
- **PSM 7**: Single line (for ID numbers)
- **PSM 8**: Single word (for vertical digits)
- **PSM 11**: Sparse text (for vertical columns)
- **PSM 6 with whitelist**: Digits and special chars (`*S`)

### 3. **Rotation Handling**
Automatically tries rotated versions (90°, 180°, 270°) to capture vertical text in any orientation.

### 4. **Improved ID Number Extraction**
- Handles prefixes like "S" (e.g., "S548025")
- Extracts vertical column formats (e.g., "* S 5 4 8 0 2 5 *")
- Combines all digit sequences for maximum detection

## Setup Instructions

### Step 1: Install Tesseract OCR

**Windows:**
1. Download from: https://github.com/UB-Mannheim/tesseract/wiki
2. Install to: `C:\Program Files\Tesseract-OCR`
3. Add to PATH or configure in `app.py`:
   ```python
   pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
   ```

**Linux:**
```bash
sudo apt-get install tesseract-ocr
```

**macOS:**
```bash
brew install tesseract
```

### Step 2: Install Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### Step 3: Start the Backend Server

**Windows:**
```bash
start_server.bat
```

**Linux/macOS:**
```bash
./start_server.sh
```

The server will run on `http://localhost:5000` by default.

### Step 4: Configure Flutter App

In `lib/services/id_validation_service.dart`, set your backend URL:

```dart
static const String? _backendBaseUrl = 'http://YOUR_PC_IP:5000';
// Example: 'http://192.168.1.100:5000'
```

**To find your PC's IP address:**
- **Windows**: Run `ipconfig` in Command Prompt, look for "IPv4 Address"
- **Linux/macOS**: Run `ifconfig` or `ip addr`, look for your network interface IP

**Important:** Make sure your phone and PC are on the same Wi-Fi network!

## Usage

Once configured, the Flutter app will:
1. **Automatically use Python backend** for OCR if `backendUrl` is set
2. **Fall back to ML Kit** if backend is unavailable
3. **Extract vertical column text** much better than ML Kit alone

## Testing

1. Start the backend server
2. Set the backend URL in Flutter code
3. Run the app and test ID validation
4. Check console logs for "Using Python backend with Tesseract OCR"

## Troubleshooting

### Backend not connecting?
- Check firewall settings (allow port 5000)
- Verify IP address is correct
- Ensure phone and PC are on same network
- Check backend logs for errors

### OCR still not extracting ID number?
- Verify Tesseract is installed correctly
- Check backend logs for OCR errors
- Try different image quality/lighting
- The backend tries multiple configurations automatically

### Face comparison not working?
- Face comparison uses InsightFace (separate from OCR)
- Ensure InsightFace model is loaded (check backend startup logs)

## Performance

- **Backend OCR**: More accurate, especially for vertical text
- **ML Kit OCR**: Faster, works offline, but less accurate for vertical columns
- **Hybrid approach**: Best of both worlds - uses backend when available, falls back to ML Kit

