# Python Backend Setup Guide

## Quick Start

### 1. Install Python (3.8+)
Make sure Python 3.8 or higher is installed.

### 2. Install Tesseract OCR

**Windows:**
1. Download installer from: https://github.com/UB-Mannheim/tesseract/wiki
2. Install to: `C:\Program Files\Tesseract-OCR\`
3. Add to PATH or update `app.py` line 20 with the path

**Linux:**
```bash
sudo apt-get update
sudo apt-get install tesseract-ocr
```

**macOS:**
```bash
brew install tesseract
```

### 3. Install Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

**Note:** InsightFace will download models automatically on first run (may take a few minutes).

### 4. Run the Server

**Windows:**
```bash
python app.py
```

**Linux/macOS:**
```bash
python3 app.py
```

Or use the provided scripts:
- Windows: `start_server.bat`
- Linux/macOS: `chmod +x start_server.sh && ./start_server.sh`

Server will run on `http://localhost:5000`

### 5. Test the Server

```bash
curl http://localhost:5000/health
```

Should return: `{"status":"ok","message":"ID Validation Service is running"}`

## Flutter App Configuration

Update the backend URL in `lib/services/id_validation_service.dart`:

- **Android Emulator**: `http://10.0.2.2:5000` (default)
- **iOS Simulator**: `http://localhost:5000`
- **Physical Device**: Use your computer's IP address (e.g., `http://192.168.1.100:5000`)

To find your computer's IP:
- Windows: `ipconfig` (look for IPv4 Address)
- Linux/macOS: `ifconfig` or `ip addr`

## Troubleshooting

### Tesseract not found
- Windows: Update line 20 in `app.py` with your Tesseract path
- Linux/macOS: Make sure Tesseract is in PATH

### InsightFace model download fails
- Check internet connection
- Models will be cached in `~/.insightface/` after first download

### Port 5000 already in use
- Change port in `app.py` last line: `app.run(host='0.0.0.0', port=5001)`
- Update Flutter app with new port

### Connection refused from Flutter
- Make sure backend is running
- Check firewall settings
- For physical device: ensure phone and computer are on same network

