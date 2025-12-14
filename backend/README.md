# ID Validation Backend Service

Python backend service for ID validation using InsightFace, Tesseract OCR, and fuzzywuzzy.

## Setup Instructions

### 1. Install Python Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Install Tesseract OCR

**Windows:**
- Download from: https://github.com/UB-Mannheim/tesseract/wiki
- Install to default location: `C:\Program Files\Tesseract-OCR\tesseract.exe`
- Update `app.py` line 20 if installed to different location

**Linux:**
```bash
sudo apt-get install tesseract-ocr
```

**macOS:**
```bash
brew install tesseract
```

### 3. Download InsightFace Models

The InsightFace model will be automatically downloaded on first run. This may take a few minutes.

### 4. Run the Server

```bash
python app.py
```

The server will run on `http://localhost:5000`

### 5. Test the Service

```bash
curl http://localhost:5000/health
```

## API Endpoints

### POST /extract-text
Extract text from ID image using Tesseract OCR

### POST /compare-faces
Compare faces from ID and selfie using InsightFace

### POST /validate-id
Complete ID validation (text + face + ID type)

## Configuration

Update the backend URL in Flutter app's `id_validation_service.dart`:
- Development: `http://localhost:5000` (use `10.0.2.2` for Android emulator)
- Production: Your deployed backend URL

