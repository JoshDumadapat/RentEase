"""
Upload Subspace AI logo to Cloudinary
Downloads the logo from Shutterstock URL and uploads to Cloudinary
"""
import os
import sys
import requests
import firebase_admin
from firebase_admin import credentials, firestore
import cloudinary
import cloudinary.uploader

# Fix Windows console encoding issues
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Cloudinary configuration
cloudinary.config(
    cloud_name='dqymvfmbi',
    api_key='521481162223833',
    api_secret='Oo8-fwyxqi-k8GQijCS36TB1xfk'
)

# Firebase configuration
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

try:
    if not firebase_admin._apps:
        cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
        firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("✅ Firebase initialized")
except Exception as e:
    print(f"⚠️ Firebase initialization error (may already be initialized): {e}")
    db = firestore.client()

LOGO_URL = "https://www.shutterstock.com/image-vector/atom-icon-logo-atomic-neutron-600nw-2255754233.jpg"

def upload_subspace_logo():
    """Download and upload Subspace AI logo to Cloudinary"""
    try:
        print("📥 Downloading logo from Shutterstock...")
        response = requests.get(LOGO_URL, timeout=30)
        response.raise_for_status()
        
        print("☁️ Uploading to Cloudinary...")
        upload_result = cloudinary.uploader.upload(
            response.content,
            folder="ai",
            public_id="subspace_logo",
            resource_type="image",
            overwrite=True
        )
        
        cloudinary_url = upload_result.get('secure_url')
        print(f"✅ Logo uploaded successfully!")
        print(f"   Cloudinary URL: {cloudinary_url}")
        
        # Store in Firestore
        try:
            db.collection('app_config').document('subspace_ai').set({
                'logoUrl': cloudinary_url,
                'name': 'Subspace AI',
                'updatedAt': firestore.SERVER_TIMESTAMP
            }, merge=True)
            print(f"✅ Logo URL stored in Firestore: app_config/subspace_ai")
        except Exception as e:
            print(f"⚠️ Error storing in Firestore: {e}")
            print(f"   You can manually store the URL: {cloudinary_url}")
        
        return cloudinary_url
    except Exception as e:
        print(f"❌ Error uploading logo: {e}")
        return None

if __name__ == "__main__":
    print("=" * 60)
    print("Uploading Subspace AI Logo to Cloudinary")
    print("=" * 60)
    url = upload_subspace_logo()
    if url:
        print("\n✅ Success! Use this URL in your app:")
        print(f"   {url}")
    else:
        print("\n❌ Failed to upload logo")
    print("=" * 60)
