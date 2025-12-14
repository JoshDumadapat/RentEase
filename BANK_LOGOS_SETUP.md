# Bank Logos Setup Guide

This guide explains how to set up bank logos in Firestore with Cloudinary URLs.

## Firestore Collection Structure

Create a collection named `banks` in Firestore with the following structure:

### Document Structure:
```json
{
  "name": "Bank Name",
  "logoUrl": "https://res.cloudinary.com/dqymvfmbi/image/upload/v1234567890/banks/bank-logo.png",
  "code": "BANK_CODE" // Optional
}
```

## Steps to Add Bank Logos

### 1. Upload Bank Logos to Cloudinary

1. Go to [Cloudinary Console](https://console.cloudinary.com/)
2. Navigate to Media Library
3. Create a folder named `banks` (if it doesn't exist)
4. Upload bank logos to the `banks` folder
5. Copy the **Secure URL** for each logo

### 2. Add Banks to Firestore

For each bank, create a document in the `banks` collection:

#### Example Banks (Philippines):

**BDO (Banco de Oro)**
- Document ID: `bdo`
- Fields:
  - `name`: "BDO"
  - `logoUrl`: `[Cloudinary URL]`
  - `code`: "BDO" (optional)

**BPI (Bank of the Philippine Islands)**
- Document ID: `bpi`
- Fields:
  - `name`: "BPI"
  - `logoUrl`: `[Cloudinary URL]`
  - `code`: "BPI" (optional)

**Metrobank**
- Document ID: `metrobank`
- Fields:
  - `name`: "Metrobank"
  - `logoUrl`: `[Cloudinary URL]`
  - `code`: "MBTC" (optional)

**Landbank**
- Document ID: `landbank`
- Fields:
  - `name`: "Landbank"
  - `logoUrl`: `[Cloudinary URL]`
  - `code`: "LBP" (optional)

**Security Bank**
- Document ID: `security_bank`
- Fields:
  - `name`: "Security Bank"
  - `logoUrl`: `[Cloudinary URL]`
  - `code`: "SBC" (optional)

**RCBC (Rizal Commercial Banking Corporation)**
- Document ID: `rcbc`
- Fields:
  - `name`: "RCBC"
  - `logoUrl`: `[Cloudinary URL]`
  - `code`: "RCBC" (optional)

**UnionBank**
- Document ID: `unionbank`
- Fields:
  - `name`: "UnionBank"
  - `logoUrl`: `[Cloudinary URL]`
  - `code`: "UBP" (optional)

**EastWest Bank**
- Document ID: `eastwest`
- Fields:
  - `name`: "EastWest Bank"
  - `logoUrl`: `[Cloudinary URL]`
  - `code`: "EWB" (optional)

**Chinabank**
- Document ID: `chinabank`
- Fields:
  - `name`: "Chinabank"
  - `logoUrl`: `[Cloudinary URL]`
  - `code`: "CBC" (optional)

**PNB (Philippine National Bank)**
- Document ID: `pnb`
- Fields:
  - `name`: "PNB"
  - `logoUrl`: `[Cloudinary URL]`
  - `code`: "PNB" (optional)

## Using Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to Firestore Database
4. Click "Start collection" or select existing `banks` collection
5. Add documents with the structure above

## Using Python Script (Optional)

You can also use a Python script to populate banks:

```python
from firebase_admin import firestore
import firebase_admin
from firebase_admin import credentials

# Initialize Firebase Admin
cred = credentials.Certificate("path/to/firebase-credentials.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# Banks data with Cloudinary URLs
banks = [
    {
        "name": "BDO",
        "logoUrl": "https://res.cloudinary.com/dqymvfmbi/image/upload/v1234567890/banks/bdo.png",
        "code": "BDO"
    },
    {
        "name": "BPI",
        "logoUrl": "https://res.cloudinary.com/dqymvfmbi/image/upload/v1234567890/banks/bpi.png",
        "code": "BPI"
    },
    # Add more banks...
]

# Add to Firestore
for bank in banks:
    doc_id = bank["name"].lower().replace(" ", "_")
    db.collection("banks").document(doc_id).set(bank)
    print(f"Added {bank['name']} to Firestore")
```

## Logo Requirements

- **Format**: PNG or SVG (transparent background recommended)
- **Size**: 200x200px minimum (will be scaled down in UI)
- **Aspect Ratio**: Square (1:1) preferred
- **Background**: Transparent or white

## Notes

- The app will automatically load banks from Firestore
- Banks are displayed in alphabetical order
- If a logo fails to load, a default bank icon is shown
- The `code` field is optional and can be used for payment processing integration later
