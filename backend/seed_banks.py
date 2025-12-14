"""
Seed Banks Script for RentEase
Downloads bank logos from the internet, uploads them to Cloudinary, and populates Firestore.
"""

import os
import sys
import json
import requests
from typing import List, Dict, Optional
from io import BytesIO
from PIL import Image, ImageDraw, ImageFont
import firebase_admin
from firebase_admin import credentials, firestore
import cloudinary
import cloudinary.uploader

# Fix Windows console encoding issues
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Initialize Firebase Admin SDK
_script_dir = os.path.dirname(os.path.abspath(__file__))
_possible_paths = [
    os.getenv('FIREBASE_CREDENTIALS'),
    os.path.join(_script_dir, 'firebase-credentials.json'),
    os.path.join(_script_dir, '..', 'backend', 'firebase-credentials.json'),
    'backend/firebase-credentials.json',
    'firebase-credentials.json',
]
FIREBASE_CREDENTIALS_PATH = None
for path in _possible_paths:
    if path and os.path.exists(path):
        FIREBASE_CREDENTIALS_PATH = path
        break
if not FIREBASE_CREDENTIALS_PATH:
    FIREBASE_CREDENTIALS_PATH = os.path.join(_script_dir, 'firebase-credentials.json')

if not os.path.exists(FIREBASE_CREDENTIALS_PATH):
    print(f"[ERROR] Firebase credentials file not found at {FIREBASE_CREDENTIALS_PATH}")
    print("Please download your Firebase service account key from Firebase Console")
    print("and save it as 'backend/firebase-credentials.json'")
    sys.exit(1)

cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

# Initialize Cloudinary
CLOUDINARY_CLOUD_NAME = 'dqymvfmbi'
CLOUDINARY_API_KEY = '521481162223833'
CLOUDINARY_API_SECRET = 'Oo8-fwyxqi-k8GQijCS36TB1xfk'

cloudinary.config(
    cloud_name=CLOUDINARY_CLOUD_NAME,
    api_key=CLOUDINARY_API_KEY,
    api_secret=CLOUDINARY_API_SECRET
)

# Bank data with logo URLs from the internet
# Using Wikimedia Commons and other reliable sources
BANKS_DATA = [
    {
        "id": "bdo",
        "name": "BDO",
        "code": "BDO",
        "logo_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/BDO_Unibank_logo.svg/512px-BDO_Unibank_logo.svg.png"
    },
    {
        "id": "bpi",
        "name": "BPI",
        "code": "BPI",
        "logo_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Bank_of_the_Philippine_Islands_logo.svg/512px-Bank_of_the_Philippine_Islands_logo.svg.png"
    },
    {
        "id": "metrobank",
        "name": "Metrobank",
        "code": "MBTC",
        "logo_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Metrobank_logo.svg/512px-Metrobank_logo.svg.png"
    },
    {
        "id": "landbank",
        "name": "Landbank",
        "code": "LBP",
        "logo_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/5/5a/Land_Bank_of_the_Philippines_logo.svg/512px-Land_Bank_of_the_Philippines_logo.svg.png"
    },
    {
        "id": "security_bank",
        "name": "Security Bank",
        "code": "SBC",
        "logo_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/7/7a/Security_Bank_logo.svg/512px-Security_Bank_logo.svg.png"
    },
    {
        "id": "rcbc",
        "name": "RCBC",
        "code": "RCBC",
        "logo_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6a/RCBC_logo.svg/512px-RCBC_logo.svg.png"
    },
    {
        "id": "unionbank",
        "name": "UnionBank",
        "code": "UBP",
        "logo_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9f/UnionBank_logo.svg/512px-UnionBank_logo.svg.png"
    },
    {
        "id": "eastwest",
        "name": "EastWest Bank",
        "code": "EWB",
        "logo_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/EastWest_Bank_logo.svg/512px-EastWest_Bank_logo.svg.png"
    },
    {
        "id": "chinabank",
        "name": "Chinabank",
        "code": "CBC",
        "logo_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/China_Banking_Corporation_logo.svg/512px-China_Banking_Corporation_logo.svg.png"
    },
    {
        "id": "pnb",
        "name": "PNB",
        "code": "PNB",
        "logo_url": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/8a/Philippine_National_Bank_logo.svg/512px-Philippine_National_Bank_logo.svg.png"
    }
]

def download_image(url: str, timeout: int = 30) -> Optional[bytes]:
    """Download image from URL"""
    try:
        print(f"  [DOWNLOAD] Downloading from: {url[:80]}...")
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        response = requests.get(url, headers=headers, timeout=timeout)
        response.raise_for_status()
        return response.content
    except Exception as e:
        print(f"  [ERROR] Failed to download: {e}")
        return None

def create_placeholder_logo(bank_name: str, bank_id: str) -> Optional[bytes]:
    """Create a simple placeholder logo with bank name"""
    try:
        # Create a 200x200 image with a colored background
        img = Image.new('RGB', (200, 200), color=(0, 184, 230))  # Theme color
        draw = ImageDraw.Draw(img)
        
        # Try to use a default font, fallback to basic if not available
        try:
            # Try to use a system font
            font = ImageFont.truetype("arial.ttf", 40)
        except:
            try:
                font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 40)
            except:
                font = ImageFont.load_default()
        
        # Get text size and center it
        bbox = draw.textbbox((0, 0), bank_name, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        x = (200 - text_width) // 2
        y = (200 - text_height) // 2
        
        # Draw white text
        draw.text((x, y), bank_name, fill=(255, 255, 255), font=font)
        
        # Save to bytes
        img_bytes = BytesIO()
        img.save(img_bytes, format='PNG')
        img_bytes.seek(0)
        return img_bytes.getvalue()
    except Exception as e:
        print(f"  [ERROR] Failed to create placeholder: {e}")
        return None

def upload_to_cloudinary(image_bytes: bytes, bank_id: str) -> Optional[str]:
    """Upload image to Cloudinary"""
    try:
        print(f"  [UPLOAD] Uploading to Cloudinary...")
        upload_result = cloudinary.uploader.upload(
            image_bytes,
            folder="banks",
            public_id=bank_id,
            resource_type="image",
            overwrite=True
        )
        cloudinary_url = upload_result.get('secure_url')
        print(f"  [OK] Uploaded: {cloudinary_url[:80]}...")
        return cloudinary_url
    except Exception as e:
        print(f"  [ERROR] Failed to upload: {e}")
        return None

def seed_banks(use_manual_logos: bool = False, force_update: bool = False):
    """Create bank entries in Firestore. If use_manual_logos is True, skip logo download and create placeholder entries."""
    print("=" * 80)
    print("SEEDING BANKS TO FIRESTORE")
    print("=" * 80)
    
    if use_manual_logos:
        print("\n[MODE] Creating bank entries without logos.")
        print("       You can upload logos to Cloudinary manually and update the logoUrl field.")
    else:
        print("\n[MODE] Attempting to download and upload logos automatically.")
    
    if force_update:
        print("\n[FORCE] Force update mode - will re-download and upload logos even if they exist.")
    
    banks_collection = db.collection('banks')
    
    for bank_data in BANKS_DATA:
        bank_id = bank_data["id"]
        bank_name = bank_data["name"]
        bank_code = bank_data.get("code", "")
        logo_url = bank_data.get("logo_url", "")
        
        print(f"\n[{bank_name}] Processing...")
        
        # Check if bank already exists
        doc_ref = banks_collection.document(bank_id)
        doc = doc_ref.get()
        
        if doc.exists and not force_update:
            existing_data = doc.to_dict()
            existing_logo = existing_data.get('logoUrl', '')
            
            # If logo URL exists and is from Cloudinary, skip (unless force update)
            if existing_logo and 'cloudinary.com' in existing_logo:
                # Check if it's a valid URL (not placeholder)
                if not existing_logo.endswith('.png') or 'placeholder' in existing_logo.lower():
                    print(f"  [INFO] Bank exists but logo may be placeholder, attempting to update...")
                else:
                    print(f"  [SKIP] Bank already exists with Cloudinary logo")
                    continue
        
        cloudinary_url = None
        
        if not use_manual_logos:
            # Try to download from URL first
            if logo_url:
                image_bytes = download_image(logo_url)
                if image_bytes:
                    cloudinary_url = upload_to_cloudinary(image_bytes, bank_id)
            
            # If download failed, create placeholder logo
            if not cloudinary_url:
                print(f"  [INFO] Creating placeholder logo for {bank_name}...")
                placeholder_bytes = create_placeholder_logo(bank_name, bank_id)
                if placeholder_bytes:
                    cloudinary_url = upload_to_cloudinary(placeholder_bytes, bank_id)
        
        # If still no Cloudinary URL, create placeholder entry
        if not cloudinary_url:
            if use_manual_logos:
                print(f"  [INFO] Creating bank entry. Upload logo to Cloudinary folder 'banks' with public_id '{bank_id}'")
                print(f"         Then update the logoUrl field in Firestore.")
            else:
                print(f"  [WARN] Could not create logo, creating entry with placeholder URL.")
                print(f"         Upload logo to Cloudinary folder 'banks' with public_id '{bank_id}'")
                print(f"         Then update the logoUrl field in Firestore.")
            
            # Create placeholder entry
            cloudinary_url = f"https://res.cloudinary.com/{CLOUDINARY_CLOUD_NAME}/image/upload/banks/{bank_id}.png"
        
        # Add to Firestore
        bank_doc = {
            "name": bank_name,
            "logoUrl": cloudinary_url,
            "code": bank_code
        }
        
        try:
            doc_ref.set(bank_doc, merge=True)
            print(f"  [SUCCESS] Added {bank_name} to Firestore")
            if not cloudinary_url or 'placeholder' in cloudinary_url.lower() or not cloudinary_url.startswith('https://res.cloudinary.com'):
                print(f"           ⚠️  Logo URL needs to be updated with actual Cloudinary URL")
        except Exception as e:
            print(f"  [ERROR] Failed to add to Firestore: {e}")
    
    print("\n" + "=" * 80)
    print("BANK SEEDING COMPLETE")
    print("=" * 80)
    
    # Verify banks
    print("\nVerifying banks in Firestore...")
    try:
        banks = list(banks_collection.get())
        print(f"Total banks in Firestore: {len(banks)}")
        for doc in banks:
            data = doc.to_dict()
            print(f"  - {data.get('name', 'Unknown')} ({doc.id})")
    except Exception as e:
        print(f"  [WARN] Could not verify banks: {e}")

if __name__ == "__main__":
    import sys
    
    # Check if --manual flag is provided
    use_manual = '--manual' in sys.argv or '-m' in sys.argv
    # Check if --force flag is provided
    force_update = '--force' in sys.argv or '-f' in sys.argv
    
    try:
        seed_banks(use_manual_logos=use_manual, force_update=force_update)
        
        if use_manual:
            print("\n" + "=" * 80)
            print("NEXT STEPS:")
            print("=" * 80)
            print("1. Go to Cloudinary Console: https://console.cloudinary.com/")
            print("2. Navigate to Media Library")
            print("3. Create folder 'banks' if it doesn't exist")
            print("4. Upload bank logos with these public_ids:")
            for bank in BANKS_DATA:
                print(f"   - {bank['id']} ({bank['name']})")
            print("5. Copy the Secure URL for each logo")
            print("6. Update the logoUrl field in Firestore for each bank document")
            print("=" * 80)
    except KeyboardInterrupt:
        print("\n\n[INTERRUPTED] Seeding cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n[ERROR] Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
