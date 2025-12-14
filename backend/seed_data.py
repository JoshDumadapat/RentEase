"""
Seed Data Script for RentEase
Creates Firebase Auth users and populates Firestore with listings, reviews, comments, and looking for posts.
"""

import os
import sys
import json
import requests
import random
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import firebase_admin
from firebase_admin import credentials, auth, firestore
import cloudinary
import cloudinary.uploader
from cloudinary.utils import cloudinary_url

# Fix Windows console encoding issues
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# Initialize Firebase Admin SDK
# You need to download your Firebase service account key JSON file
# and set the path in FIREBASE_CREDENTIALS environment variable
# or place it in backend/firebase-credentials.json
# Try multiple possible paths
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
# Get these from your Cloudinary dashboard
CLOUDINARY_CLOUD_NAME = 'dqymvfmbi'
CLOUDINARY_API_KEY = '521481162223833'
CLOUDINARY_API_SECRET = 'Oo8-fwyxqi-k8GQijCS36TB1xfk'

cloudinary.config(
    cloud_name=CLOUDINARY_CLOUD_NAME,
    api_key=CLOUDINARY_API_KEY,
    api_secret=CLOUDINARY_API_SECRET
)

# User data with property information
USER_DATA = [
    {
        "user_num": 1,
        "email": "user1.condo@rentease.com",
        "password": "Password123!",
        "fname": "Maria",
        "lname": "Santos",
        "category": "Condo Rentals",
        "image_urls": [
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/513891690.jpg?k=91333ea170a358c3d5b9848e720dffd18275f170682bc5fa978e28da460b4c66&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/690596338.jpg?k=2b83a22fd6968891f85efa452d64f8c642dac7ea3df82b8320a41074ca14041a&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/513885977.jpg?k=14af71bdc19b0b8281de8f62f86dfd241a2427f2147b7665ef5f3c2da6668a96&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/506775265.jpg?k=1b5685f06fe5d506e30e27407525424005075039d3f81e1a1d783562847a4eab&o=",
        ],
        "property_info": {
            "title": "Modern 2BR Condo with City View",
            "location": "BGC, Taguig, Metro Manila",
            "price": 25000,
            "bedrooms": 2,
            "bathrooms": 2,
            "area": 75.0,
            "description": "Beautiful modern 2-bedroom condo unit with stunning city views. Fully furnished with modern amenities. Located in the heart of BGC with easy access to shopping centers, restaurants, and business districts. Includes gym access, swimming pool, and 24/7 security.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": True,
                "parking": True,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 2,
        "email": "user2.condo@rentease.com",
        "password": "Password123!",
        "fname": "John",
        "lname": "Reyes",
        "category": "Condo Rentals",
        "image_urls": [
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/482452106.jpg?k=f7ebb3ddff58e508c03cf700ed16774135f7e1595bd840ff71af36c526be5222&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/482452149.jpg?k=47426041da8065b536295118defc14049796c3f9e40fe94dc71600297684b226&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/482452095.jpg?k=acd8b3e5b2629f6c3afe7a2117b3761fbae1a91cb55551fa5e7e8a8561b64bba&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/482451930.jpg?k=f656a6f0530aa85ad32cd5d5b8d836e9595ca5de41a2bed85794a51e7e55e38e&o=",
        ],
        "property_info": {
            "title": "Luxury 1BR Condo Near Makati CBD",
            "location": "Makati City, Metro Manila",
            "price": 18000,
            "bedrooms": 1,
            "bathrooms": 1,
            "area": 45.0,
            "description": "Spacious 1-bedroom luxury condo unit in prime Makati location. Walking distance to Ayala Avenue and major business centers. Fully furnished with high-end appliances. Perfect for professionals working in Makati CBD.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": True,
                "internetIncluded": True,
                "wifi": True,
                "aircon": True,
                "parking": False,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 3,
        "email": "user3.condo@rentease.com",
        "password": "Password123!",
        "fname": "Anna",
        "lname": "Cruz",
        "category": "Condo Rentals",
        "image_urls": [
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/730270662.jpg?k=77fdc86aabc3b094a131e4abb3a31320bc5a53ba25d6edce0f9b6a567af1ecff&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/616620857.jpg?k=3286ad246e888bd29680577201ecd1aa4bf2876993d19078a6516ae6d86b5a74&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/555054725.jpg?k=16360c551e57ceab5ef4f446cbcc9a5a0268c8eb48552b8dbdd5f88a98fd04a4&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/616688557.jpg?k=696b5f89c6ad4cb9470b198db36bdf102cc07a0651d9ef8ea8586ff5c044bc5d&o=",
        ],
        "property_info": {
            "title": "Cozy Studio Condo in Ortigas",
            "location": "Ortigas Center, Pasig City",
            "price": 15000,
            "bedrooms": 1,
            "bathrooms": 1,
            "area": 30.0,
            "description": "Cozy and well-maintained studio condo unit in Ortigas Center. Perfect for students or young professionals. Close to malls, restaurants, and public transportation. Clean and move-in ready.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": True,
                "parking": False,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 4,
        "email": "user4.condo@rentease.com",
        "password": "Password123!",
        "fname": "Carlos",
        "lname": "Garcia",
        "category": "Condo Rentals",
        "image_urls": [
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/651346430.jpg?k=1dbcf2a929ae927a762c6b783b4aacad254a9c61c8b303d29badd2cbf1856d21&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/651345377.jpg?k=c636958ffa267c1d745d0c24ab8d59e354b41251793b9d8569f2e74ae9ddd598&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/616620877.jpg?k=fb864b625e7de5d6d9ec85d6f62bea9e4c81478928f467cf4f8b56eb41c89957&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/615381147.jpg?k=6603a7dd12c7dc4e40d9592d463a5fd969fbc7bddc4f9988b659ca5d6776685c&o=",
        ],
        "property_info": {
            "title": "Premium 3BR Condo with Balcony",
            "location": "Eastwood City, Quezon City",
            "price": 35000,
            "bedrooms": 3,
            "bathrooms": 2,
            "area": 120.0,
            "description": "Spacious 3-bedroom premium condo with large balcony and city views. Fully furnished with modern furniture and appliances. Perfect for families. Located in Eastwood City with access to shopping, dining, and entertainment.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": True,
                "internetIncluded": True,
                "wifi": True,
                "aircon": True,
                "parking": True,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 5,
        "email": "user5.house@rentease.com",
        "password": "Password123!",
        "fname": "Janell",
        "lname": "Amistoso",
        "category": "House Rentals",
        "image_urls": [
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1iYWNrZW5kLWIyYi1pbWFnZXMiLCJrZXkiOiJwcm9wZXJ0aWVzLzAxOWEyODg5LTQ1NmUtNzE1MS1hMDU5LTA2ZWU4MmFlN2Q1NC8wMTlhMjg4Yi0yNzEyLTcxZjgtODhiZC02Y2RhNGVhNDE0OGEuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1iYWNrZW5kLWIyYi1pbWFnZXMiLCJrZXkiOiJwcm9wZXJ0aWVzLzAxOWEyODg5LTQ1NmUtNzE1MS1hMDU5LTA2ZWU4MmFlN2Q1NC8wMTlhMjg4Yi0yODcyLTcxODktYjJiZS0yZTA0OTY2MmM1NTcuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1iYWNrZW5kLWIyYi1pbWFnZXMiLCJrZXkiOiJwcm9wZXJ0aWVzLzAxOWEyODg5LTQ1NmUtNzE1MS1hMDU5LTA2ZWU4MmFlN2Q1NC8wMTlhMjg4Yi0yODkxLTcyYTEtOTlhMy03NDg5N2FkNjJlYjguanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1iYWNrZW5kLWIyYi1pbWFnZXMiLCJrZXkiOiJwcm9wZXJ0aWVzLzAxOWEyODg5LTQ1NmUtNzE1MS1hMDU5LTA2ZWU4MmFlN2Q1NC8wMTlhMjg4Yi0yOTM4LTczMGMtODcxNC01ZTEwMmQ5YmY0ZWIuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1iYWNrZW5kLWIyYi1pbWFnZXMiLCJrZXkiOiJwcm9wZXJ0aWVzLzAxOWEyODg5LTQ1NmUtNzE1MS1hMDU5LTA2ZWU4MmFlN2Q1NC8wMTlhMjg4Yi0yOTFlLTcxMWEtOWVkMC03MjRjMzBiMDk4MjYuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
        ],
        "property_info": {
            "title": "Modern 2BR Home in Toscana Subdivision",
            "location": "Via Aretini, Camella Toscana, Bago Gallera, Talomo District, Davao City",
            "price": 20000,
            "bedrooms": 2,
            "bathrooms": 1,
            "area": 88.0,
            "description": "Modern 2-bedroom, 1-bathroom home in Toscana Subdivision. Unfurnished - decorate it your way! Safe and quiet neighborhood, ideal for small families, couples, or working professionals. Close to schools, malls, and main roads. Great value for size and location.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": False,
                "internetIncluded": False,
                "wifi": False,
                "aircon": False,
                "parking": True,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 6,
        "email": "user6.house@rentease.com",
        "password": "Password123!",
        "fname": "Janell",
        "lname": "Amistoso",
        "category": "House Rentals",
        "image_urls": [
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1iYWNrZW5kLWIyYi1pbWFnZXMiLCJrZXkiOiJwcm9wZXJ0aWVzLzAxOWEyODVjLTdkZWItNzZmYy05MzA2LWMyMzJlYjk4MzM0ZC8wMTlhMjg2Ny0yYzJhLTcyNGItODZlZi1lOGZkYjBjOGM3ZWMuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1iYWNrZW5kLWIyYi1pbWFnZXMiLCJrZXkiOiJwcm9wZXJ0aWVzLzAxOWEyODVjLTdkZWItNzZmYy05MzA2LWMyMzJlYjk4MzM0ZC8wMTlhMjg2Ny0yZDUwLTcxOTItODk3Zi00MTU2OGJjMzk1MDAuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1iYWNrZW5kLWIyYi1pbWFnZXMiLCJrZXkiOiJwcm9wZXJ0aWVzLzAxOWEyODVjLTdkZWItNzZmYy05MzA2LWMyMzJlYjk4MzM0ZC8wMTlhMjg2Ny0yZDk5LTcxODYtYTgyOS1kMGE2ZTdkZmMzODUuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1iYWNrZW5kLWIyYi1pbWFnZXMiLCJrZXkiOiJwcm9wZXJ0aWVzLzAxOWEyODVjLTdkZWItNzZmYy05MzA2LWMyMzJlYjk4MzM0ZC8wMTlhMjg2Ny0yZGY3LTcyOTMtOGViYi03ODM3ZjgwYjhiNmMuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1iYWNrZW5kLWIyYi1pbWFnZXMiLCJrZXkiOiJwcm9wZXJ0aWVzLzAxOWEyODVjLTdkZWItNzZmYy05MzA2LWMyMzJlYjk4MzM0ZC8wMTlhMjg2Ny0yZTQ0LTcyODctOGM3Ni1kZDgwY2RmMWE2YTkuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
        ],
        "property_info": {
            "title": "3-Bedroom Townhouse Near SM City Davao",
            "location": "Ecoland Drive, Purok 24-B, 76-A Bucana, Talomo District, Davao City",
            "price": 35000,
            "bedrooms": 3,
            "bathrooms": 2,
            "area": 150.0,
            "description": "3-bedroom townhouse with 1 maid's room. 3 bathrooms (2 upstairs, 1 downstairs). Bright, clean, and well-maintained unit. Safe and convenient location near malls, schools, and transport. Walking distance to SM City Davao (Ecoland). Long-term lease only. 2 months deposit + 1 month advance required.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": False,
                "internetIncluded": False,
                "wifi": False,
                "aircon": False,
                "parking": True,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 7,
        "email": "user7.house@rentease.com",
        "password": "Password123!",
        "fname": "K",
        "lname": "Land Property",
        "category": "House Rentals",
        "image_urls": [
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1wcm9qZWN0cy1hZG1pbi1pbWFnZXMiLCJrZXkiOiI5YTAyYWIyMC0yYjEwLTExZWMtYjVkMS0zN2JhOWExNDE0ZDEvOWEwMmFiMjAtMmIxMC0xMWVjLWI1ZDEtMzdiYTlhMTQxNGQxXzEuMC1QSC0wLVBKLTE4NTAzLTEwMTQ4MjU0MDU2MTY1MTFiMzNhMmM4LTEtMTIwMC04MDAuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1wcm9qZWN0cy1hZG1pbi1pbWFnZXMiLCJrZXkiOiI5YTAyYWIyMC0yYjEwLTExZWMtYjVkMS0zN2JhOWExNDE0ZDEvOWEwMmFiMjAtMmIxMC0xMWVjLWI1ZDEtMzdiYTlhMTQxNGQxXzEuMC1QSC0wLVBKLTE4NTAzLTE0NTIxNjIyNTE2MTY1MTFiMGFjZTU4LTEtMTIwMC04MDAuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1wcm9qZWN0cy1hZG1pbi1pbWFnZXMiLCJrZXkiOiI5YTAyYWIyMC0yYjEwLTExZWMtYjVkMS0zN2JhOWExNDE0ZDEvOWEwMmFiMjAtMmIxMC0xMWVjLWI1ZDEtMzdiYTlhMTQxNGQxXzEuMC1QSC0wLVBKLTE4NTAzLTE2NDcxOTQzNTU2MTY1MTFhZjNmYWZlLTEtMTIwMC04MDAuanBnIiwiYnJhbmQiOiJsYW11ZGkiLCJlZGl0cyI6eyJyb3RhdGUiOm51bGwsInJlc2l6ZSI6eyJ3aWR0aCI6OTAwLCJoZWlnaHQiOjY1MCwiZml0IjoiY292ZXIifX19",
            "https://img.lamudi.com/eyJidWNrZXQiOiJwcmQtbGlmdWxsY29ubmVjdC1wcm9qZWN0cy1hZG1pbi1pbWFnZXMiLCJrZXkiOiI5YTAyYWIyMC0yYjEwLTExZWMtYjVkMS0zN2JhOWExNDE0ZDEvOWEwMmFiMjAtMmIxMC0xMWVjLWI1ZDEtMzdiYTlhMTQxNGQxXzEuMC1QSC0wLVBKLTE4NTAzLTM0NTExMDczMzYxNjUxMWFkNjI0NjAtMS0xMjAwLTgwMC5qcGciLCJicmFuZCI6ImxhbXVkaSIsImVkaXRzIjp7InJvdGF0ZSI6bnVsbCwicmVzaXplIjp7IndpZHRoIjo5MDAsImhlaWdodCI6NjUwLCJmaXQiOiJjb3ZlciJ9fX0=",
        ],
        "property_info": {
            "title": "Fully Furnished House in Camella Davao",
            "location": "Camella Davao, Buhangin District, Davao City",
            "price": 25000,
            "bedrooms": 2,
            "bathrooms": 1,
            "area": 88.0,
            "description": "Fully furnished house for rent in guarded subdivision. Located at Camella Homes Davao, in front of Davao International Airport, 8-10 mins to SM Lanang Premier. 2 bedrooms with fully airconditioned including living room. With PLDT WiFi. Available for daily, weekly, or monthly rental.",
            "amenities": {
                "electricityIncluded": True,
                "waterIncluded": True,
                "internetIncluded": True,
                "wifi": True,
                "aircon": True,
                "parking": True,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 8,
        "email": "user8.room@rentease.com",
        "password": "Password123!",
        "fname": "Roberto",
        "lname": "Lopez",
        "category": "Rooms",
        "image_urls": [
            "https://pix8.agoda.net/hotelImages/22790295/0/a8704e697e3ccacc628d2f0a6487e14f.jpg?ca=17&ce=1&s=600x",
            "https://pix8.agoda.net/hotelImages/22790295/0/5ee571afd3c0f794a40656ab7e1140a8.jpg?ca=17&ce=1&s=600x",
            "https://pix8.agoda.net/hotelImages/22790295/0/0e242787419bed8db282655bc0f755d1.jpg?ca=17&ce=1&s=600x",
            "https://pix8.agoda.net/hotelImages/22790295/0/c6ffdb8f396cd3d267daae1e077694f2.jpg?ca=17&ce=1&s=600x",
        ],
        "property_info": {
            "title": "Cozy Private Room with Shared Facilities",
            "location": "Quezon City, Metro Manila",
            "price": 5000,
            "bedrooms": 1,
            "bathrooms": 0,
            "area": 20.0,
            "description": "Clean and cozy private room in a shared house. Shared kitchen and bathroom facilities. Perfect for students or working professionals. Safe neighborhood with easy access to public transportation.",
            "amenities": {
                "electricityIncluded": True,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": False,
                "parking": False,
                "security": False,
                "sharedCR": True,
                "kitchenAccess": True,
            }
        }
    },
    {
        "user_num": 9,
        "email": "user9.room@rentease.com",
        "password": "Password123!",
        "fname": "Lisa",
        "lname": "Torres",
        "category": "Rooms",
        "image_urls": [
            "https://q-xx.bstatic.com/xdata/images/hotel/max1024x768/778310458.jpg?k=dac056b9761c15d40f57ff4568b491b39c7029a273439f4e40d70ac6988d0e1b&o=&s=600x",
            "https://pix8.agoda.net/hotelImages/28348433/445187931/2dbee170a6828c66c38bf2e5b2fa0cec.png?ca=24&ce=0&s=600x",
            "https://q-xx.bstatic.com/xdata/images/hotel/max1024x768/678800859.jpg?k=5412fe80af5b4eed0c1cf0497d35b714e748a3aa1b7ac0bb484e35a2bb50c41d&o=&s=600x",
        ],
        "property_info": {
            "title": "Furnished Room with Aircon",
            "location": "Manila, Metro Manila",
            "price": 6000,
            "bedrooms": 1,
            "bathrooms": 0,
            "area": 18.0,
            "description": "Furnished room with airconditioning. Shared bathroom and kitchen. WiFi included. Perfect for students or young professionals. Close to universities and business districts.",
            "amenities": {
                "electricityIncluded": True,
                "waterIncluded": True,
                "internetIncluded": True,
                "wifi": True,
                "aircon": True,
                "parking": False,
                "security": False,
                "sharedCR": True,
                "kitchenAccess": True,
            }
        }
    },
    {
        "user_num": 10,
        "email": "user10.boarding@rentease.com",
        "password": "Password123!",
        "fname": "Michael",
        "lname": "Villanueva",
        "category": "Boarding House",
        "image_urls": [
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/763347376.jpg?k=641324460c76b8e4c562ae449ce2450703200b4bc2e61207df502ab163fd6fc5&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/604045163.jpg?k=77b1e58a71019a90bbe387d5c854ce4890746dc44212b6f4dcf932159d262ce6&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/604045160.jpg?k=c5169f6415e28d0fcb5bf2c7579b90fec119ea5992b1c2bfdda40433377d9fbc&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/604045157.jpg?k=c84037ad2fc667194c60a9235d43cae951ed5c00ed5ac057a71e5b3b8cf4227d&o=",
        ],
        "property_info": {
            "title": "Affordable Boarding House Room",
            "location": "Makati City, Metro Manila",
            "price": 4000,
            "bedrooms": 1,
            "bathrooms": 0,
            "area": 15.0,
            "description": "Affordable boarding house room. Clean and well-maintained. Shared facilities including kitchen and bathroom. Perfect for budget-conscious students or workers. Safe and secure location.",
            "amenities": {
                "electricityIncluded": True,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": False,
                "parking": False,
                "security": True,
                "sharedCR": True,
                "kitchenAccess": True,
            }
        }
    },
    {
        "user_num": 11,
        "email": "user11.apartment@rentease.com",
        "password": "Password123!",
        "fname": "Jennifer",
        "lname": "Mendoza",
        "category": "Apartment",
        "image_urls": [
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/604045164.jpg?k=1ad20a480028ff3b2d30951afa16ae2a628726f72232d7332c3472752f63c696&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/604045168.jpg?k=da52dbb76465a63737ef68830fcfc0e488f752a94c8315d4d9a4cf5fe61def98&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/604045175.jpg?k=fa8ce135073c99c289559ead3baa4543c1d18afd8a9c9855f996f4cb8189bea2&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/604045169.jpg?k=ebea59fef0749aec3d688c7eaf5dead7d31a4957961961cbe705ee2bdac09958&o=",
        ],
        "property_info": {
            "title": "2BR Apartment in Prime Location",
            "location": "Pasig City, Metro Manila",
            "price": 12000,
            "bedrooms": 2,
            "bathrooms": 1,
            "area": 55.0,
            "description": "Spacious 2-bedroom apartment in prime Pasig location. Close to malls, schools, and business centers. Clean and well-maintained. Perfect for small families or professionals.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": False,
                "parking": True,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 12,
        "email": "user12.apartment@rentease.com",
        "password": "Password123!",
        "fname": "David",
        "lname": "Fernandez",
        "category": "Apartment",
        "image_urls": [
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/418962903.jpg?k=2bcedb7d41f544a2c74b8c37b7f5da90243282a64d1cc4da25bf700b9223c626&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/418956448.jpg?k=c170825ccf5addfd633a4a6771362c82c9a1050f9a94360c96591dc03366770e&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/418959492.jpg?k=9f8146fe9d71cc9e71f3a923c9a08316d414f84853093aa283782bd03ee0a3ea&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/452967056.jpg?k=9edfa394fa2bbe47cc4db520efda3e86fcd637e5f6c5f638fc91278ff0b8e693&o=",
        ],
        "property_info": {
            "title": "Modern 1BR Apartment Unit",
            "location": "Mandaluyong City, Metro Manila",
            "price": 10000,
            "bedrooms": 1,
            "bathrooms": 1,
            "area": 40.0,
            "description": "Modern 1-bedroom apartment unit with contemporary design. Fully furnished with essential appliances. Located in Mandaluyong with easy access to EDSA and major business districts.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": True,
                "parking": False,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 13,
        "email": "user13.apartment@rentease.com",
        "password": "Password123!",
        "fname": "Patricia",
        "lname": "Ramos",
        "category": "Apartment",
        "image_urls": [
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/725086529.jpg?k=e6cbac972771b4300067abdda9ff52cb0abb8c66b136c3e04f7824e9e5cd9bdf&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/753887512.jpg?k=6a550f96f14d699085b155f2fc58bc3508fb2f82e505ae119dfcdeb17b2a3019&o=",
            "https://cf.bstatic.com/xdata/images/hotel/max1024x768/725086625.jpg?k=b6780476d7aad4596cd851ba58124a7c8c6fb7e4c5c24ef32cc9f4fa443e77fc&o=",
        ],
        "property_info": {
            "title": "Cozy Studio Apartment",
            "location": "San Juan City, Metro Manila",
            "price": 8000,
            "bedrooms": 1,
            "bathrooms": 1,
            "area": 25.0,
            "description": "Cozy studio apartment perfect for single professionals or students. Compact but functional space with all essential amenities. Quiet neighborhood with good security.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": False,
                "parking": False,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 14,
        "email": "user14.dorm@rentease.com",
        "password": "Password123!",
        "fname": "Ryan",
        "lname": "Dela Cruz",
        "category": "Student Dorms",
        "image_urls": [
            "https://odfcdn.dormy.ph/internal/img/rs_600xauto,to_webp,webp_q_50/5831c1b3-2a45-462c-04b3-b5cc7abba694.jpeg",
            "https://odfcdn.dormy.ph/internal/img/rs_600xauto,to_webp,webp_q_50/c4d3fb65-e421-80e0-2881-aa5bb1d4284d.jpeg",
            "https://odfcdn.dormy.ph/internal/img/rs_600xauto,to_webp,webp_q_50/61aa984e-b917-6ec0-978f-8ec9d31d8c62.jpeg",
        ],
        "property_info": {
            "title": "Student Dormitory - Single Bed",
            "location": "Diliman, Quezon City",
            "price": 3000,
            "bedrooms": 1,
            "bathrooms": 0,
            "area": 12.0,
            "description": "Student-friendly dormitory with study areas and WiFi. Close to universities. Shared facilities. Perfect for students looking for affordable accommodation near campus.",
            "amenities": {
                "electricityIncluded": True,
                "waterIncluded": True,
                "internetIncluded": True,
                "wifi": True,
                "aircon": False,
                "parking": False,
                "security": True,
                "sharedCR": True,
                "kitchenAccess": True,
            }
        }
    },
    {
        "user_num": 15,
        "email": "user15.boarding@rentease.com",
        "password": "Password123!",
        "fname": "Sarah",
        "lname": "Gonzales",
        "category": "Boarding House",
        "image_urls": [
            "https://odfcdn.dormy.ph/internal/img/rs_600xauto,to_webp,webp_q_50/3ab9da92-3b4e-a77a-1d77-54e19ef0bf49.png",
            "https://odfcdn.dormy.ph/internal/img/rs_600xauto,to_webp,webp_q_50/215ab39b-799c-4f7a-54cb-d994a856924a.jpeg",
            "https://odfcdn.dormy.ph/internal/img/rs_600xauto,to_webp,webp_q_50/b1465090-62b3-9b74-faa9-6c1de6e866d4.jpeg",
        ],
        "property_info": {
            "title": "Budget-Friendly Boarding House",
            "location": "Caloocan City, Metro Manila",
            "price": 3500,
            "bedrooms": 1,
            "bathrooms": 0,
            "area": 14.0,
            "description": "Budget-friendly boarding house room. Clean and safe environment. Shared kitchen and bathroom. Perfect for students or workers on a tight budget.",
            "amenities": {
                "electricityIncluded": True,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": False,
                "parking": False,
                "security": True,
                "sharedCR": True,
                "kitchenAccess": True,
            }
        }
    },
    {
        "user_num": 16,
        "email": "user16.dorm@rentease.com",
        "password": "Password123!",
        "fname": "Mark",
        "lname": "Rivera",
        "category": "Student Dorms",
        "image_urls": [
            "https://odfcdn.dormy.ph/internal/img/rs_600xauto,to_webp,webp_q_50/07b0592b-63c0-841f-b35d-94f50e3772fe.jpeg",
            "https://odfcdn.dormy.ph/internal/img/rs_600xauto,to_webp,webp_q_50/7bab8d49-4094-82a8-8875-2c9a2534f8fb.jpeg",
            "https://odfcdn.dormy.ph/internal/img/rs_600xauto,to_webp,webp_q_50/3968be4c-eeaf-0bdf-c73e-f75c079768d5.jpeg",
        ],
        "property_info": {
            "title": "Modern Student Dormitory",
            "location": "Manila, Metro Manila",
            "price": 3500,
            "bedrooms": 1,
            "bathrooms": 0,
            "area": 13.0,
            "description": "Modern student dormitory with WiFi and study areas. Clean and well-maintained. Close to universities and public transportation. Shared facilities available.",
            "amenities": {
                "electricityIncluded": True,
                "waterIncluded": True,
                "internetIncluded": True,
                "wifi": True,
                "aircon": False,
                "parking": False,
                "security": True,
                "sharedCR": True,
                "kitchenAccess": True,
            }
        }
    },
]

# Student users (not verified) - will post "Looking For" posts
STUDENT_USERS = [
    {
        "user_num": 17,
        "email": "student1@rentease.com",
        "password": "Password123!",
        "fname": "Alex",
        "lname": "Martinez",
    },
    {
        "user_num": 18,
        "email": "student2@rentease.com",
        "password": "Password123!",
        "fname": "Sophia",
        "lname": "Chen",
    },
    {
        "user_num": 19,
        "email": "student3@rentease.com",
        "password": "Password123!",
        "fname": "James",
        "lname": "Wilson",
    },
    {
        "user_num": 20,
        "email": "student4@rentease.com",
        "password": "Password123!",
        "fname": "Emma",
        "lname": "Brown",
    },
    {
        "user_num": 21,
        "email": "student5@rentease.com",
        "password": "Password123!",
        "fname": "Noah",
        "lname": "Davis",
    },
    {
        "user_num": 22,
        "email": "student6@rentease.com",
        "password": "Password123!",
        "fname": "Olivia",
        "lname": "Garcia",
    },
    {
        "user_num": 23,
        "email": "student7@rentease.com",
        "password": "Password123!",
        "fname": "Liam",
        "lname": "Rodriguez",
    },
    {
        "user_num": 24,
        "email": "student8@rentease.com",
        "password": "Password123!",
        "fname": "Ava",
        "lname": "Martinez",
    },
    {
        "user_num": 25,
        "email": "student9@rentease.com",
        "password": "Password123!",
        "fname": "Ethan",
        "lname": "Anderson",
    },
    {
        "user_num": 26,
        "email": "student10@rentease.com",
        "password": "Password123!",
        "fname": "Isabella",
        "lname": "Taylor",
    },
]

# Professional users (not verified) - will post listings
PROFESSIONAL_USERS = [
    {
        "user_num": 27,
        "email": "pro1@rentease.com",
        "password": "Password123!",
        "fname": "Robert",
        "lname": "Kim",
        "category": "Condo Rentals",
        "image_urls": [
            "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
            "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800",
            "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800",
        ],
        "property_info": {
            "title": "Cozy 1BR Condo in Quezon City",
            "location": "Quezon City, Metro Manila",
            "price": 15000,
            "bedrooms": 1,
            "bathrooms": 1,
            "area": 35.0,
            "description": "Affordable 1-bedroom condo unit. Perfect for professionals or students. Clean and well-maintained.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": True,
                "parking": False,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 28,
        "email": "pro2@rentease.com",
        "password": "Password123!",
        "fname": "Michelle",
        "lname": "Tan",
        "category": "Apartments",
        "image_urls": [
            "https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800",
            "https://images.unsplash.com/photo-1505843513577-22bb7d21e455?w=800",
            "https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800",
        ],
        "property_info": {
            "title": "2BR Apartment Near LRT Station",
            "location": "Manila, Metro Manila",
            "price": 12000,
            "bedrooms": 2,
            "bathrooms": 1,
            "area": 50.0,
            "description": "Spacious 2-bedroom apartment. Walking distance to LRT station. Great for families or roommates.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": False,
                "parking": True,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 29,
        "email": "pro3@rentease.com",
        "password": "Password123!",
        "fname": "Daniel",
        "lname": "Nguyen",
        "category": "Rooms",
        "image_urls": [
            "https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800",
            "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800",
        ],
        "property_info": {
            "title": "Private Room with Shared Facilities",
            "location": "Makati City, Metro Manila",
            "price": 5500,
            "bedrooms": 1,
            "bathrooms": 0,
            "area": 18.0,
            "description": "Clean private room in shared house. Shared kitchen and bathroom. WiFi included.",
            "amenities": {
                "electricityIncluded": True,
                "waterIncluded": True,
                "internetIncluded": True,
                "wifi": True,
                "aircon": False,
                "parking": False,
                "security": False,
                "sharedCR": True,
                "kitchenAccess": True,
            }
        }
    },
    {
        "user_num": 30,
        "email": "pro4@rentease.com",
        "password": "Password123!",
        "fname": "Jessica",
        "lname": "Lee",
        "category": "House Rentals",
        "image_urls": [
            "https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800",
            "https://images.unsplash.com/photo-1568605119132-009c8b6e3c8e?w=800",
            "https://images.unsplash.com/photo-1568605117035-36c46e4e4e4e?w=800",
        ],
        "property_info": {
            "title": "3BR House with Garden",
            "location": "Pasig City, Metro Manila",
            "price": 28000,
            "bedrooms": 3,
            "bathrooms": 2,
            "area": 130.0,
            "description": "Beautiful 3-bedroom house with garden. Perfect for families. Quiet neighborhood.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": False,
                "internetIncluded": False,
                "wifi": False,
                "aircon": False,
                "parking": True,
                "security": True,
                "privateCR": True,
            }
        }
    },
    {
        "user_num": 31,
        "email": "pro5@rentease.com",
        "password": "Password123!",
        "fname": "Christopher",
        "lname": "Wong",
        "category": "Cars",
        "image_urls": [
            "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=800",
            "https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=800",
            "https://images.unsplash.com/photo-1503376780353-7e6692757c70?w=800",
        ],
        "property_info": {
            "title": "Toyota Vios 2020 for Rent",
            "location": "Metro Manila",
            "price": 15000,
            "bedrooms": 0,
            "bathrooms": 0,
            "area": 0.0,
            "description": "Well-maintained Toyota Vios 2020. Perfect for daily commute or weekend trips. Includes insurance and registration.",
            "amenities": {}
        }
    },
    {
        "user_num": 32,
        "email": "pro6@rentease.com",
        "password": "Password123!",
        "fname": "Amanda",
        "lname": "Lim",
        "category": "Cars",
        "image_urls": [
            "https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800",
            "https://images.unsplash.com/photo-1502877338535-766e1452684a?w=800",
        ],
        "property_info": {
            "title": "Honda City 2019 - Monthly Rental",
            "location": "Quezon City, Metro Manila",
            "price": 18000,
            "bedrooms": 0,
            "bathrooms": 0,
            "area": 0.0,
            "description": "Honda City 2019 in excellent condition. Fuel efficient and reliable. Available for monthly rental.",
            "amenities": {}
        }
    },
    {
        "user_num": 33,
        "email": "pro7@rentease.com",
        "password": "Password123!",
        "fname": "Kevin",
        "lname": "Zhang",
        "category": "Boarding House",
        "image_urls": [
            "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
            "https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800",
        ],
        "property_info": {
            "title": "Affordable Boarding House Room",
            "location": "Caloocan City, Metro Manila",
            "price": 3800,
            "bedrooms": 1,
            "bathrooms": 0,
            "area": 15.0,
            "description": "Budget-friendly boarding house room. Clean and safe. Shared facilities available.",
            "amenities": {
                "electricityIncluded": True,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": False,
                "parking": False,
                "security": True,
                "sharedCR": True,
                "kitchenAccess": True,
            }
        }
    },
    {
        "user_num": 34,
        "email": "pro8@rentease.com",
        "password": "Password123!",
        "fname": "Nicole",
        "lname": "Park",
        "category": "Student Dorms",
        "image_urls": [
            "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800",
            "https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=800",
        ],
        "property_info": {
            "title": "Student Dormitory Near UP Diliman",
            "location": "Diliman, Quezon City",
            "price": 3200,
            "bedrooms": 1,
            "bathrooms": 0,
            "area": 12.0,
            "description": "Student-friendly dormitory. Close to UP Diliman. WiFi and study areas included.",
            "amenities": {
                "electricityIncluded": True,
                "waterIncluded": True,
                "internetIncluded": True,
                "wifi": True,
                "aircon": False,
                "parking": False,
                "security": True,
                "sharedCR": True,
                "kitchenAccess": True,
            }
        }
    },
    {
        "user_num": 35,
        "email": "pro9@rentease.com",
        "password": "Password123!",
        "fname": "Ryan",
        "lname": "Singh",
        "category": "Cars",
        "image_urls": [
            "https://images.unsplash.com/photo-1553440569-bcc63803a83d?w=800",
            "https://images.unsplash.com/photo-1494976388531-d1058494cdd8?w=800",
        ],
        "property_info": {
            "title": "Nissan Almera 2021 - Long Term Rental",
            "location": "Makati City, Metro Manila",
            "price": 20000,
            "bedrooms": 0,
            "bathrooms": 0,
            "area": 0.0,
            "description": "Nissan Almera 2021. Perfect for long-term rental. Well-maintained with complete documents.",
            "amenities": {}
        }
    },
    {
        "user_num": 36,
        "email": "pro10@rentease.com",
        "password": "Password123!",
        "fname": "Stephanie",
        "lname": "Yap",
        "category": "Apartments",
        "image_urls": [
            "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800",
            "https://images.unsplash.com/photo-1505843513577-22bb7d21e455?w=800",
            "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
        ],
        "property_info": {
            "title": "1BR Apartment in Ortigas",
            "location": "Ortigas Center, Pasig City",
            "price": 11000,
            "bedrooms": 1,
            "bathrooms": 1,
            "area": 38.0,
            "description": "Cozy 1-bedroom apartment in Ortigas. Close to business centers and malls.",
            "amenities": {
                "electricityIncluded": False,
                "waterIncluded": True,
                "internetIncluded": False,
                "wifi": True,
                "aircon": True,
                "parking": False,
                "security": True,
                "privateCR": True,
            }
        }
    },
]


def get_profile_image_url(name: str, gender: str = None) -> str:
    """Get a real human profile image URL from internet APIs"""
    try:
        import random
        import time
        
        # Primary: Use randomuser.me API for realistic human photos
        try:
            # Determine gender from name if not provided (simple heuristic)
            if not gender:
                # Common female names in the data
                female_names = ['anna', 'maria', 'sarah', 'jessica', 'nicole', 'stephanie', 'amanda', 'michelle', 'catherine', 'elena', 'isabella', 'olivia', 'ava', 'sophia', 'emma']
                first_name_lower = name.split()[0].lower() if name.split() else ""
                gender = 'female' if any(fn in first_name_lower for fn in female_names) else 'male'
            
            gender_param = f"&gender={gender}"
            api_url = f"https://randomuser.me/api/?results=1{gender_param}&nat=us,gb,ca,au,ph"
            response = requests.get(api_url, timeout=15)
            
            if response.status_code == 200:
                data = response.json()
                if data.get('results') and len(data['results']) > 0:
                    profile_url = data['results'][0]['picture']['large']
                    # Small delay to avoid rate limiting
                    time.sleep(0.2)
                    return profile_url
        except Exception as e:
            print(f"    [WARN] randomuser.me failed: {e}, trying alternative...")
        
        # Alternative 1: Use Picsum Photos with seed for consistent faces
        try:
            seed = abs(hash(name)) % 1000
            picsum_url = f"https://picsum.photos/seed/{seed}/400/400"
            # Verify it's accessible
            test_response = requests.head(picsum_url, timeout=5)
            if test_response.status_code == 200:
                time.sleep(0.1)
                return picsum_url
        except:
            pass
        
        # Alternative 2: Use Lorem Picsum with face filter (if available)
        try:
            face_id = abs(hash(name)) % 100
            face_url = f"https://i.pravatar.cc/400?img={face_id}"
            test_response = requests.head(face_url, timeout=5)
            if test_response.status_code == 200:
                time.sleep(0.1)
                return face_url
        except:
            pass
        
        # Fallback: Use UI Avatars (not human but better than nothing)
        name_encoded = name.replace(" ", "+")
        colors = ["00D1FF", "6C63FF", "FF6B6B", "4ECDC4", "45B7D1", "FFA07A", "98D8C8", "F7DC6F"]
        bg_color = random.choice(colors)
        ui_avatar_url = f"https://ui-avatars.com/api/?name={name_encoded}&size=400&background={bg_color}&color=fff&bold=true&format=png"
        return ui_avatar_url
        
    except Exception as e:
        print(f"  [WARN] Error getting profile image URL: {e}, using fallback")
        # Final fallback to UI Avatars
        name_encoded = name.replace(" ", "+")
        return f"https://ui-avatars.com/api/?name={name_encoded}&size=400&background=00D1FF&color=fff&bold=true&format=png"


def upload_image_to_cloudinary(image_url: str, folder: str = "properties") -> Optional[str]:
    """Download image from URL and upload to Cloudinary"""
    try:
        print(f"  [DOWNLOAD] Downloading image from: {image_url[:80]}...")
        response = requests.get(image_url, timeout=30)
        response.raise_for_status()
        
        print(f"  [UPLOAD] Uploading to Cloudinary...")
        upload_result = cloudinary.uploader.upload(
            response.content,
            folder=folder,
            resource_type="image"
        )
        
        cloudinary_url = upload_result.get('secure_url')
        print(f"  [OK] Uploaded: {cloudinary_url[:80]}...")
        return cloudinary_url
    except Exception as e:
        print(f"  [ERROR] Error uploading image: {e}")
        return None


def create_firebase_user(email: str, password: str, display_name: str) -> Optional[str]:
    """Create a Firebase Auth user"""
    try:
        user = auth.create_user(
            email=email,
            password=password,
            display_name=display_name,
            email_verified=True
        )
        print(f"  [OK] Created Firebase Auth user: {user.uid}")
        return user.uid
    except Exception as e:
        if "already exists" in str(e).lower():
            print(f"  [WARN] User already exists, fetching...")
            # Try to get existing user
            try:
                user = auth.get_user_by_email(email)
                return user.uid
            except:
                pass
        print(f"  [ERROR] Error creating Firebase user: {e}")
        return None


def create_user_document(uid: str, user_data: Dict, is_verified: bool = True, properties_count: int = 0, looking_for_count: int = 0, profile_image_url: str = None) -> None:
    """Create user document in Firestore"""
    try:
        username = f"{user_data['fname'].lower()}{user_data['lname'].lower()}".replace(" ", "")
        user_doc = {
            'email': user_data['email'],
            'fname': user_data['fname'],
            'lname': user_data['lname'],
            'displayName': f"{user_data['fname']} {user_data['lname']}",
            'username': username,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
            'isVerified': is_verified,
            'propertiesCount': properties_count,
            'favoritesCount': 0,
            'lookingForPostsCount': looking_for_count,
            'likesReceived': 0,
            'commentsReceived': 0,
        }
        
        # Add profile image URL if provided
        if profile_image_url:
            user_doc['profileImageUrl'] = profile_image_url
        
        db.collection('users').document(uid).set(user_doc)
        print(f"  [OK] Created user document in Firestore (verified: {is_verified})")
    except Exception as e:
        print(f"  [ERROR] Error creating user document: {e}")


def create_listing(uid: str, user_data: Dict, image_urls: List[str], is_owner_verified: bool = True) -> Optional[str]:
    """Create listing document in Firestore"""
    try:
        property_info = user_data['property_info']
        amenities = property_info.get('amenities', {})
        
        listing_data = {
            'userId': uid,
            'ownerName': f"{user_data['fname']} {user_data['lname']}",
            'isOwnerVerified': is_owner_verified,
            'title': property_info['title'],
            'category': user_data['category'],
            'location': property_info['location'],
            'price': property_info['price'],
            'description': property_info['description'],
            'imageUrls': image_urls,
            'bedrooms': property_info['bedrooms'],
            'bathrooms': property_info['bathrooms'],
            'area': property_info['area'],
            'createdAt': firestore.SERVER_TIMESTAMP,
            'postedDate': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
            'isDraft': False,
            'status': 'published',
            # Amenities
            'electricityIncluded': amenities.get('electricityIncluded', False),
            'waterIncluded': amenities.get('waterIncluded', False),
            'internetIncluded': amenities.get('internetIncluded', False),
            'privateCR': amenities.get('privateCR', False),
            'sharedCR': amenities.get('sharedCR', False),
            'kitchenAccess': amenities.get('kitchenAccess', False),
            'wifi': amenities.get('wifi', False),
            'laundry': amenities.get('laundry', False),
            'parking': amenities.get('parking', False),
            'security': amenities.get('security', False),
            'aircon': amenities.get('aircon', False),
            'petFriendly': amenities.get('petFriendly', False),
            # Counts
            'favoriteCount': 0,
            'viewCount': 0,
            'commentCount': 0,
            'reviewCount': 0,
            'averageRating': 0.0,
        }
        
        doc_ref = db.collection('listings').add(listing_data)
        listing_id = doc_ref[1].id
        print(f"  [OK] Created listing: {listing_id}")
        return listing_id
    except Exception as e:
        print(f"  [ERROR] Error creating listing: {e}")
        return None


def create_review(user_id: str, listing_id: str, reviewer_name: str, rating: int, comment: str) -> None:
    """Create a review for a listing"""
    try:
        review_data = {
            'userId': user_id,
            'listingId': listing_id,
            'reviewerName': reviewer_name,
            'rating': rating,
            'comment': comment,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
        }
        
        db.collection('reviews').add(review_data)
        print(f"  [OK] Created review")
    except Exception as e:
        print(f"  [ERROR] Error creating review: {e}")


def create_looking_for_post(user_id: str, username: str, description: str, location: str, 
                            budget: str, property_type: str) -> None:
    """Create a 'Looking For' post"""
    try:
        post_data = {
            'userId': user_id,
            'username': username,
            'description': description,
            'location': location,
            'budget': budget,
            'propertyType': property_type,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
            'likeCount': 0,
            'commentCount': 0,
            'isVerified': False,
        }
        
        db.collection('lookingForPosts').add(post_data)
        print(f"  [OK] Created looking for post")
    except Exception as e:
        print(f"  [ERROR] Error creating looking for post: {e}")


def create_comment(user_id: str, username: str, text: str, listing_id: str = None, 
                  looking_for_post_id: str = None, property_listing_id: str = None, is_verified: bool = False) -> None:
    """Create a comment"""
    try:
        comment_data = {
            'userId': user_id,
            'username': username,
            'text': text,
            'createdAt': firestore.SERVER_TIMESTAMP,
            'updatedAt': firestore.SERVER_TIMESTAMP,
            'isVerified': is_verified,
        }
        
        if listing_id:
            comment_data['listingId'] = listing_id
        if looking_for_post_id:
            comment_data['lookingForPostId'] = looking_for_post_id
        if property_listing_id:
            comment_data['propertyListingId'] = property_listing_id
        
        db.collection('comments').add(comment_data)
        print(f"  [OK] Created comment")
    except Exception as e:
        print(f"  [ERROR] Error creating comment: {e}")


def create_favorite(user_id: str, listing_id: str) -> None:
    """Add a listing to user's favorites"""
    try:
        # Check if already favorited
        existing = db.collection('favorites').where('userId', '==', user_id).where('listingId', '==', listing_id).limit(1).get()
        if existing and len(existing) > 0:
            return  # Already favorited
        
        # Create favorite document
        db.collection('favorites').add({
            'userId': user_id,
            'listingId': listing_id,
            'createdAt': firestore.SERVER_TIMESTAMP,
        })
        
        # Increment favorite count on listing
        listing_ref = db.collection('listings').document(listing_id)
        listing_ref.update({
            'favoriteCount': firestore.Increment(1),
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })
        
        # Update user's favoritesCount
        user_ref = db.collection('users').document(user_id)
        user_ref.update({
            'favoritesCount': firestore.Increment(1),
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })
        
        print(f"  [OK] Added favorite")
    except Exception as e:
        print(f"  [ERROR] Error creating favorite: {e}")


def like_looking_for_post(user_id: str, post_id: str) -> None:
    """Like a 'Looking For' post"""
    try:
        # Increment like count on post
        post_ref = db.collection('lookingForPosts').document(post_id)
        post_ref.update({
            'likeCount': firestore.Increment(1),
            'updatedAt': firestore.SERVER_TIMESTAMP,
        })
        
        # Update post owner's likesReceived
        post_doc = post_ref.get()
        if post_doc.exists:
            post_data = post_doc.to_dict()
            post_owner_id = post_data.get('userId')
            if post_owner_id:
                owner_ref = db.collection('users').document(post_owner_id)
                owner_ref.update({
                    'likesReceived': firestore.Increment(1),
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                })
        
        print(f"  [OK] Liked post")
    except Exception as e:
        print(f"  [ERROR] Error liking post: {e}")


def main():
    """Main seeding function"""
    print("=" * 80)
    print("RentEase Data Seeding Script")
    print("=" * 80)
    print()
    
    created_users = []
    created_listings = []
    
    # SKIP: Original verified users (already seeded)
    # Uncomment below to re-seed original users
    """
    # Process each user
    for user_data in USER_DATA:
        user_num = user_data['user_num']
        print(f"\n{'='*80}")
        print(f"[USER] Processing User {user_num}: {user_data['fname']} {user_data['lname']}")
        print(f"{'='*80}")
        
        # 1. Create Firebase Auth user
        print(f"\n[1/4] Creating Firebase Auth user...")
        uid = create_firebase_user(
            user_data['email'],
            user_data['password'],
            f"{user_data['fname']} {user_data['lname']}"
        )
        
        if not uid:
            print(f"  [ERROR] Skipping user {user_num} due to auth creation failure")
            continue
        
        created_users.append(uid)
        
        # 2. Get and upload profile image
        print(f"\n[2/5] Getting and uploading profile image...")
        display_name = f"{user_data['fname']} {user_data['lname']}"
        profile_image_url = get_profile_image_url(display_name)
        cloudinary_profile_url = upload_image_to_cloudinary(profile_image_url, folder="users")
        
        # 3. Create user document in Firestore
        print(f"\n[3/5] Creating user document in Firestore...")
        create_user_document(uid, user_data, is_verified=True, properties_count=1, profile_image_url=cloudinary_profile_url)
        
        # 4. Upload property images to Cloudinary
        print(f"\n[4/5] Uploading {len(user_data['image_urls'])} property images to Cloudinary...")
        cloudinary_urls = []
        for img_url in user_data['image_urls']:
            cloudinary_url = upload_image_to_cloudinary(img_url, folder="properties")
            if cloudinary_url:
                cloudinary_urls.append(cloudinary_url)
        
        if not cloudinary_urls:
            print(f"  [WARN] No images uploaded, skipping listing creation")
            continue
        
        # 5. Create listing
        print(f"\n[5/5] Creating listing...")
        listing_id = create_listing(uid, user_data, cloudinary_urls, is_owner_verified=True)
        if listing_id:
            created_listings.append((uid, listing_id, True))  # (uid, listing_id, is_verified)
        
        print(f"\n[OK] User {user_num} processing complete!")
    """
    
    # Process Student Users (not verified)
    print(f"\n\n{'='*80}")
    print("[STUDENTS] Processing 10 Student Users (Not Verified)...")
    print(f"{'='*80}")
    
    student_user_ids = []
    looking_for_post_ids = []
    
    looking_for_post_templates = [
        {
            'description': 'Looking for a studio or 1BR near university. Budget is tight but need a safe place. Prefer furnished.',
            'location': 'Quezon City',
            'budget': '₱4,000-₱6,000',
            'property_type': 'Rooms',
        },
        {
            'description': 'Need a room in a boarding house near my school. Must have WiFi and study area. Quiet environment preferred.',
            'location': 'Manila',
            'budget': '₱3,500-₱5,000',
            'property_type': 'Boarding House',
        },
        {
            'description': 'Looking for student dormitory near campus. Shared facilities OK. Budget conscious student here!',
            'location': 'Diliman, Quezon City',
            'budget': '₱3,000-₱4,000',
            'property_type': 'Student Dorms',
        },
        {
            'description': 'Searching for affordable 1BR apartment. Close to public transport. Must be pet-friendly (small dog).',
            'location': 'Pasig City',
            'budget': '₱8,000-₱10,000',
            'property_type': 'Apartment',
        },
        {
            'description': 'Looking for condo unit near BGC. Working student, need place close to work and school.',
            'location': 'Taguig City',
            'budget': '₱12,000-₱15,000',
            'property_type': 'Condo Rentals',
        },
        {
            'description': 'Need room for rent. Prefer female-only boarding house. Clean and safe environment.',
            'location': 'Makati City',
            'budget': '₱4,500-₱6,500',
            'property_type': 'Rooms',
        },
        {
            'description': 'Looking for student-friendly accommodation. Budget is limited. Shared room is OK.',
            'location': 'Caloocan City',
            'budget': '₱2,500-₱4,000',
            'property_type': 'Student Dorms',
        },
        {
            'description': 'Searching for 1BR near LRT station. Need good ventilation and natural light for studying.',
            'location': 'Manila',
            'budget': '₱7,000-₱9,000',
            'property_type': 'Apartment',
        },
        {
            'description': 'Looking for affordable boarding house. Must have WiFi. Kitchen access preferred.',
            'location': 'Quezon City',
            'budget': '₱3,000-₱5,000',
            'property_type': 'Boarding House',
        },
        {
            'description': 'Need studio condo or room. Close to university. Budget flexible for the right place.',
            'location': 'Ortigas, Pasig',
            'budget': '₱6,000-₱8,000',
            'property_type': 'Condo Rentals',
        },
    ]
    
    for i, student_data in enumerate(STUDENT_USERS):
        print(f"\n[STUDENT] Processing Student {student_data['user_num']}: {student_data['fname']} {student_data['lname']}")
        
        # Create Firebase Auth user
        uid = create_firebase_user(
            student_data['email'],
            student_data['password'],
            f"{student_data['fname']} {student_data['lname']}"
        )
        
        if not uid:
            continue
        
        student_user_ids.append(uid)
        created_users.append(uid)
        
        # Get and upload profile image
        display_name = f"{student_data['fname']} {student_data['lname']}"
        profile_image_url = get_profile_image_url(display_name)
        cloudinary_profile_url = upload_image_to_cloudinary(profile_image_url, folder="users")
        
        # Create user document (not verified)
        create_user_document(uid, student_data, is_verified=False, properties_count=0, looking_for_count=1, profile_image_url=cloudinary_profile_url)
        
        # Create "Looking For" post
        if i < len(looking_for_post_templates):
            post_template = looking_for_post_templates[i]
            username = f"{student_data['fname'].lower()}{student_data['lname'].lower()}".replace(" ", "")
            
            # Create the post and get its ID
            post_data = {
                'userId': uid,
                'username': username,
                'description': post_template['description'],
                'location': post_template['location'],
                'budget': post_template['budget'],
                'propertyType': post_template['property_type'],
                'createdAt': firestore.SERVER_TIMESTAMP,
                'updatedAt': firestore.SERVER_TIMESTAMP,
                'likeCount': 0,
                'commentCount': 0,
                'isVerified': False,
            }
            post_ref = db.collection('lookingForPosts').add(post_data)
            looking_for_post_ids.append((post_ref[1].id, uid))
            print(f"  [OK] Created 'Looking For' post")
    
    # Process Professional Users (not verified)
    print(f"\n\n{'='*80}")
    print("[PROFESSIONALS] Processing 10 Professional Users (Not Verified)...")
    print(f"{'='*80}")
    
    professional_user_ids = []
    professional_listing_ids = []
    
    for pro_data in PROFESSIONAL_USERS:
        print(f"\n[PRO] Processing Professional {pro_data['user_num']}: {pro_data['fname']} {pro_data['lname']}")
        
        # Create Firebase Auth user
        uid = create_firebase_user(
            pro_data['email'],
            pro_data['password'],
            f"{pro_data['fname']} {pro_data['lname']}"
        )
        
        if not uid:
            continue
        
        professional_user_ids.append(uid)
        created_users.append(uid)
        
        # Get and upload profile image
        display_name = f"{pro_data['fname']} {pro_data['lname']}"
        profile_image_url = get_profile_image_url(display_name)
        cloudinary_profile_url = upload_image_to_cloudinary(profile_image_url, folder="users")
        
        # Create user document (not verified)
        create_user_document(uid, pro_data, is_verified=False, properties_count=1, profile_image_url=cloudinary_profile_url)
        
        # Upload images
        cloudinary_urls = []
        for img_url in pro_data['image_urls']:
            cloudinary_url = upload_image_to_cloudinary(img_url, folder="properties")
            if cloudinary_url:
                cloudinary_urls.append(cloudinary_url)
        
        if cloudinary_urls:
            # Create listing (not verified owner)
            listing_id = create_listing(uid, pro_data, cloudinary_urls, is_owner_verified=False)
            if listing_id:
                professional_listing_ids.append((uid, listing_id))
                created_listings.append((uid, listing_id, False))  # Not verified
    
    # Professional users comment on "Looking For" posts with their listing links
    print(f"\n[COMMENTS] Professional users commenting on 'Looking For' posts...")
    comment_templates = [
        "I have a property that might match what you're looking for! Check it out:",
        "This listing might be perfect for you:",
        "I think my property fits your requirements. Here's the link:",
        "You might be interested in this property:",
    ]
    
    for i, (post_id, post_owner_id) in enumerate(looking_for_post_ids[:len(professional_listing_ids)]):
        if i < len(professional_listing_ids):
            pro_uid, pro_listing_id = professional_listing_ids[i]
            pro_user_doc = db.collection('users').document(pro_uid).get()
            if pro_user_doc.exists:
                pro_data = pro_user_doc.to_dict()
                pro_username = pro_data.get('username', 'user')
                comment_text = comment_templates[i % len(comment_templates)]
                create_comment(
                    pro_uid,
                    pro_username,
                    comment_text,
                    looking_for_post_id=post_id,
                    property_listing_id=pro_listing_id,
                    is_verified=False
                )
    
    # Students comment on each other's "Looking For" posts
    print(f"\n[COMMENTS] Students commenting on 'Looking For' posts...")
    student_comment_texts = [
        "Same here! Let me know if you find something good.",
        "I'm also looking in that area. Good luck!",
        "That budget is similar to mine. Hope you find something!",
        "I know a place that might work, but it's a bit far.",
    ]
    
    for i, (post_id, post_owner_id) in enumerate(looking_for_post_ids):
        # Get a different student to comment
        for student_uid in student_user_ids:
            if student_uid != post_owner_id:
                student_doc = db.collection('users').document(student_uid).get()
                if student_doc.exists:
                    student_data = student_doc.to_dict()
                    student_username = student_data.get('username', 'student')
                    comment_text = student_comment_texts[i % len(student_comment_texts)]
                    create_comment(
                        student_uid,
                        student_username,
                        comment_text,
                        looking_for_post_id=post_id,
                        is_verified=False
                    )
                    break
    
    # Create some reviews, comments, and looking for posts
    print(f"\n\n{'='*80}")
    print("[EXTRA] Creating additional data (reviews, comments, looking for posts)...")
    print(f"{'='*80}")
    
    # Create reviews for listings (only for newly created listings in this run)
    if created_listings:
        print(f"\n[REVIEWS] Creating reviews for new listings...")
        review_comments = [
            "Great place! Very clean and well-maintained.",
            "Excellent location, close to everything I need.",
            "The owner was very responsive and helpful.",
            "Good value for money. Highly recommended!",
            "Nice property, but could use some improvements.",
            "Perfect for my needs. Will definitely recommend!",
            "The place is exactly as described. Very satisfied!",
            "Good location and reasonable price.",
            "Had a great experience. Owner is very accommodating.",
            "Clean and comfortable. Would rent again!",
        ]
        
        # Reviews for 50% of non-verified listings (professional users' listings)
        non_verified_listings = [(uid, lid) for uid, lid, is_verified in created_listings if not is_verified]
        num_reviews = max(1, len(non_verified_listings) // 2)  # 50%, at least 1
        for i, (owner_id, listing_id) in enumerate(non_verified_listings[:num_reviews]):
            reviewer_id = None
            reviewer_name = None
            # Try to get a student user to review (not the owner)
            for uid in student_user_ids:
                if uid != owner_id:
                    user_doc = db.collection('users').document(uid).get()
                    if user_doc.exists:
                        data = user_doc.to_dict()
                        reviewer_id = uid
                        reviewer_name = data.get('displayName', 'Anonymous')
                        break
            
            # If no student available, try any other user
            if not reviewer_id:
                for uid in created_users:
                    if uid != owner_id:
                        user_doc = db.collection('users').document(uid).get()
                        if user_doc.exists:
                            data = user_doc.to_dict()
                            reviewer_id = uid
                            reviewer_name = data.get('displayName', 'Anonymous')
                            break
            
            if reviewer_id and reviewer_name:
                rating = 3 + (i % 3)  # Ratings between 3-5
                comment = review_comments[i % len(review_comments)]
                create_review(reviewer_id, listing_id, reviewer_name, rating, comment)
    
    # Create comments on some professional listings
    print(f"\n[COMMENTS] Creating comments on professional listings...")
    comment_texts = [
        "I have a similar property available! Check it out.",
        "This looks great! Is it still available?",
        "Interested! Can I schedule a viewing?",
        "Perfect location! How's the neighborhood?",
    ]
    
    professional_listings_for_comments = [(uid, lid) for uid, lid, is_verified in created_listings if not is_verified][:4]
    for i, (owner_id, listing_id) in enumerate(professional_listings_for_comments):
        commenter_id = None
        commenter_name = None
        # Try to get a student to comment
        for uid in student_user_ids:
            if uid != owner_id:
                user_doc = db.collection('users').document(uid).get()
                if user_doc.exists:
                    data = user_doc.to_dict()
                    commenter_id = uid
                    commenter_name = data.get('username', 'user')
                    break
        
        if commenter_id and commenter_name:
            comment_text = comment_texts[i % len(comment_texts)]
            is_commenter_verified = data.get('isVerified', False)
            create_comment(commenter_id, commenter_name, comment_text, listing_id=listing_id, is_verified=is_commenter_verified)
    
    print(f"\n\n{'='*80}")
    print("[SUCCESS] Seeding Complete!")
    print(f"{'='*80}")
    print(f"\n[SUMMARY]")
    print(f"  - Created {len(created_users)} new users (skipped existing verified users)")
    print(f"    * {len(STUDENT_USERS)} student users (not verified, with 'Looking For' posts)")
    print(f"    * {len(PROFESSIONAL_USERS)} professional users (not verified, with listings)")
    print(f"  - Created {len(created_listings)} new listings")
    verified_count = sum(1 for _, _, is_v in created_listings if is_v)
    print(f"    * {verified_count} verified listings")
    print(f"    * {len(created_listings) - verified_count} non-verified listings")
    print(f"  - Created {len(looking_for_post_ids)} 'Looking For' posts")
    print(f"  - Created reviews (50% of non-verified listings)")
    print(f"  - Created comments (on listings and 'Looking For' posts)")
    
    # Create additional users with different names (reusing mock data)
    print(f"\n\n{'='*80}")
    print("[ADDITIONAL] Creating more users with different names (using mock data)...")
    print(f"{'='*80}")
    
    # New names pool (different from existing)
    new_first_names = ["Andrea", "Benjamin", "Catherine", "Derek", "Elena", "Francis", "Grace", "Henry", "Iris", "Jake", "Katherine", "Lucas", "Maya", "Nathan", "Olivia", "Paul"]
    new_last_names = ["Bautista", "Castro", "Dizon", "Evangelista", "Flores", "Gutierrez", "Herrera", "Ignacio", "Jacinto", "Kalaw", "Luna", "Mendoza", "Navarro", "Ocampo", "Pascual", "Quizon"]
    
    additional_users = []
    additional_listings = []
    
    # Create 8 new verified users with different names, reusing property data
    for i in range(8):
        # Reuse property data from USER_DATA, cycling through them
        original_data = USER_DATA[i % len(USER_DATA)]
        new_user_num = 37 + i
        
        new_user_data = {
            "user_num": new_user_num,
            "email": f"newuser{new_user_num}@rentease.com",
            "password": "Password123!",
            "fname": new_first_names[i],
            "lname": new_last_names[i],
            "category": original_data["category"],
            "image_urls": original_data["image_urls"],
            "property_info": original_data["property_info"].copy()
        }
        
        # Modify title slightly to make it unique
        new_user_data["property_info"]["title"] = f"{original_data['property_info']['title']} - Unit {i+1}"
        # Modify price slightly
        new_user_data["property_info"]["price"] = original_data["property_info"]["price"] + (i * 500)
        
        print(f"\n[NEW USER] Creating User {new_user_num}: {new_user_data['fname']} {new_user_data['lname']}")
        
        # Create Firebase Auth user
        uid = create_firebase_user(
            new_user_data['email'],
            new_user_data['password'],
            f"{new_user_data['fname']} {new_user_data['lname']}"
        )
        
        if not uid:
            continue
        
        additional_users.append(uid)
        created_users.append(uid)
        
        # Get and upload profile image
        display_name = f"{new_user_data['fname']} {new_user_data['lname']}"
        profile_image_url = get_profile_image_url(display_name)
        cloudinary_profile_url = upload_image_to_cloudinary(profile_image_url, folder="users")
        
        # Create user document (verified)
        create_user_document(uid, new_user_data, is_verified=True, properties_count=1, profile_image_url=cloudinary_profile_url)
        
        # Upload images
        cloudinary_urls = []
        for img_url in new_user_data['image_urls']:
            cloudinary_url = upload_image_to_cloudinary(img_url, folder="properties")
            if cloudinary_url:
                cloudinary_urls.append(cloudinary_url)
        
        if cloudinary_urls:
            # Create listing
            listing_id = create_listing(uid, new_user_data, cloudinary_urls, is_owner_verified=True)
            if listing_id:
                additional_listings.append((uid, listing_id, True))
                created_listings.append((uid, listing_id, True))
    
    # Add more listings to existing verified users
    print(f"\n\n{'='*80}")
    print("[EXISTING USERS] Adding more listings to existing verified users...")
    print(f"{'='*80}")
    
    # Get existing verified users from Firestore
    existing_users_snapshot = db.collection('users').where('isVerified', '==', True).limit(20).get()
    existing_user_ids = [doc.id for doc in existing_users_snapshot]
    additional_listings_to_existing = 0
    
    if existing_user_ids:
        print(f"  Found {len(existing_user_ids)} existing verified users")
        
        # Add 1 additional listing to each existing user
        for i, existing_uid in enumerate(existing_user_ids[:16]):  # Limit to first 16
            # Reuse property data, cycling through USER_DATA
            original_data = USER_DATA[i % len(USER_DATA)]
            
            # Create variation of property data
            additional_property = original_data["property_info"].copy()
            additional_property["title"] = f"{original_data['property_info']['title']} - Additional Unit"
            additional_property["price"] = original_data["property_info"]["price"] + 2000
            
            # Get user data
            user_doc = db.collection('users').document(existing_uid).get()
            if not user_doc.exists:
                continue
            
            user_data_dict = user_doc.to_dict()
            fname = user_data_dict.get('fname', 'Owner')
            lname = user_data_dict.get('lname', '')
            
            print(f"\n[ADD LISTING] Adding listing to {fname} {lname}...")
            
            # Upload images
            cloudinary_urls = []
            for img_url in original_data['image_urls']:
                cloudinary_url = upload_image_to_cloudinary(img_url, folder="properties")
                if cloudinary_url:
                    cloudinary_urls.append(cloudinary_url)
            
            if cloudinary_urls:
                # Create listing data
                listing_data = {
                    'userId': existing_uid,
                    'ownerName': f"{fname} {lname}",
                    'isOwnerVerified': True,
                    'title': additional_property['title'],
                    'category': original_data['category'],
                    'location': additional_property['location'],
                    'price': additional_property['price'],
                    'description': additional_property['description'],
                    'imageUrls': cloudinary_urls,
                    'bedrooms': additional_property['bedrooms'],
                    'bathrooms': additional_property['bathrooms'],
                    'area': additional_property['area'],
                    'createdAt': firestore.SERVER_TIMESTAMP,
                    'postedDate': firestore.SERVER_TIMESTAMP,
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                    'isDraft': False,
                    'status': 'published',
                    'electricityIncluded': additional_property['amenities'].get('electricityIncluded', False),
                    'waterIncluded': additional_property['amenities'].get('waterIncluded', False),
                    'internetIncluded': additional_property['amenities'].get('internetIncluded', False),
                    'privateCR': additional_property['amenities'].get('privateCR', False),
                    'sharedCR': additional_property['amenities'].get('sharedCR', False),
                    'kitchenAccess': additional_property['amenities'].get('kitchenAccess', False),
                    'wifi': additional_property['amenities'].get('wifi', False),
                    'laundry': additional_property['amenities'].get('laundry', False),
                    'parking': additional_property['amenities'].get('parking', False),
                    'security': additional_property['amenities'].get('security', False),
                    'aircon': additional_property['amenities'].get('aircon', False),
                    'petFriendly': additional_property['amenities'].get('petFriendly', False),
                    'favoriteCount': 0,
                    'viewCount': 0,
                    'commentCount': 0,
                    'reviewCount': 0,
                    'averageRating': 0.0,
                }
                
                doc_ref = db.collection('listings').add(listing_data)
                listing_id = doc_ref[1].id
                created_listings.append((existing_uid, listing_id, True))
                additional_listings_to_existing += 1
                print(f"  [OK] Added listing: {listing_id}")
                
                # Update user's propertiesCount
                current_count = user_data_dict.get('propertiesCount', 0)
                db.collection('users').document(existing_uid).update({
                    'propertiesCount': current_count + 1
                })
    
    # Add more listings to existing professional users (non-verified)
    print(f"\n\n{'='*80}")
    print("[EXISTING PROS] Adding more listings to existing professional users...")
    print(f"{'='*80}")
    
    # Get existing non-verified users who have listings
    # Query without propertiesCount filter to avoid composite index requirement
    existing_pros_snapshot = db.collection('users').where('isVerified', '==', False).limit(20).get()
    existing_pro_ids = []
    additional_listings_to_pros = 0
    
    # Filter in memory for users with propertiesCount > 0
    for doc in existing_pros_snapshot:
        user_data = doc.to_dict()
        properties_count = user_data.get('propertiesCount', 0)
        if properties_count > 0:
            existing_pro_ids.append(doc.id)
            if len(existing_pro_ids) >= 10:
                break
    
    if existing_pro_ids:
        print(f"  Found {len(existing_pro_ids)} existing professional users")
        
        # Reuse property data from PROFESSIONAL_USERS
        for i, pro_uid in enumerate(existing_pro_ids[:10]):
            if i < len(PROFESSIONAL_USERS):
                original_data = PROFESSIONAL_USERS[i]
                
                # Create variation
                additional_property = original_data["property_info"].copy()
                additional_property["title"] = f"{original_data['property_info']['title']} - Additional"
                additional_property["price"] = original_data["property_info"]["price"] + 1000
                
                user_doc = db.collection('users').document(pro_uid).get()
                if not user_doc.exists:
                    continue
                
                user_data_dict = user_doc.to_dict()
                fname = user_data_dict.get('fname', 'Owner')
                lname = user_data_dict.get('lname', '')
                
                print(f"\n[ADD LISTING] Adding listing to {fname} {lname}...")
                
                # Upload images
                cloudinary_urls = []
                for img_url in original_data['image_urls']:
                    cloudinary_url = upload_image_to_cloudinary(img_url, folder="properties")
                    if cloudinary_url:
                        cloudinary_urls.append(cloudinary_url)
                
                if cloudinary_urls:
                    listing_data = {
                        'userId': pro_uid,
                        'ownerName': f"{fname} {lname}",
                        'isOwnerVerified': False,
                        'title': additional_property['title'],
                        'category': original_data['category'],
                        'location': additional_property['location'],
                        'price': additional_property['price'],
                        'description': additional_property['description'],
                        'imageUrls': cloudinary_urls,
                        'bedrooms': additional_property['bedrooms'],
                        'bathrooms': additional_property['bathrooms'],
                        'area': additional_property['area'],
                        'createdAt': firestore.SERVER_TIMESTAMP,
                        'postedDate': firestore.SERVER_TIMESTAMP,
                        'updatedAt': firestore.SERVER_TIMESTAMP,
                        'isDraft': False,
                        'status': 'published',
                        'electricityIncluded': additional_property['amenities'].get('electricityIncluded', False),
                        'waterIncluded': additional_property['amenities'].get('waterIncluded', False),
                        'internetIncluded': additional_property['amenities'].get('internetIncluded', False),
                        'privateCR': additional_property['amenities'].get('privateCR', False),
                        'sharedCR': additional_property['amenities'].get('sharedCR', False),
                        'kitchenAccess': additional_property['amenities'].get('kitchenAccess', False),
                        'wifi': additional_property['amenities'].get('wifi', False),
                        'laundry': additional_property['amenities'].get('laundry', False),
                        'parking': additional_property['amenities'].get('parking', False),
                        'security': additional_property['amenities'].get('security', False),
                        'aircon': additional_property['amenities'].get('aircon', False),
                        'petFriendly': additional_property['amenities'].get('petFriendly', False),
                        'favoriteCount': 0,
                        'viewCount': 0,
                        'commentCount': 0,
                        'reviewCount': 0,
                        'averageRating': 0.0,
                    }
                    
                    doc_ref = db.collection('listings').add(listing_data)
                    listing_id = doc_ref[1].id
                    created_listings.append((pro_uid, listing_id, False))
                    additional_listings_to_pros += 1
                    print(f"  [OK] Added listing: {listing_id}")
                    
                    # Update user's propertiesCount
                    current_count = user_data_dict.get('propertiesCount', 0)
                    db.collection('users').document(pro_uid).update({
                        'propertiesCount': current_count + 1
                    })
    
    print(f"\n\n{'='*80}")
    print("[SUCCESS] Additional Seeding Complete!")
    print(f"{'='*80}")
    print(f"\n[SUMMARY]")
    print(f"  - Created {len(additional_users)} new verified users (with different names)")
    print(f"  - Added {additional_listings_to_existing} additional listings to existing verified users")
    print(f"  - Added {additional_listings_to_pros} additional listings to existing professional users")
    print(f"  - Total new listings created: {len(additional_listings) + additional_listings_to_existing + additional_listings_to_pros}")
    # Update existing users with profile images (if they don't have one)
    print(f"\n\n{'='*80}")
    print("[PROFILE IMAGES] Updating existing users with profile images...")
    print(f"{'='*80}")
    
    all_existing_users = db.collection('users').limit(100).get()
    users_updated = 0
    
    for user_doc in all_existing_users:
        user_data = user_doc.to_dict()
        user_id = user_doc.id
        
        # Skip if user already has a profile image
        if user_data.get('profileImageUrl'):
            continue
        
        # Get user's name
        fname = user_data.get('fname', 'User')
        lname = user_data.get('lname', '')
        display_name = f"{fname} {lname}".strip() or "User"
        
        try:
            # Get and upload profile image
            profile_image_url = get_profile_image_url(display_name)
            cloudinary_profile_url = upload_image_to_cloudinary(profile_image_url, folder="users")
            
            if cloudinary_profile_url:
                # Update user document with profile image
                db.collection('users').document(user_id).update({
                    'profileImageUrl': cloudinary_profile_url,
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                })
                users_updated += 1
                print(f"  [OK] Updated profile image for {display_name}")
        except Exception as e:
            print(f"  [ERROR] Error updating profile image for {display_name}: {e}")
    
    print(f"\n  [SUMMARY] Updated {users_updated} users with profile images")
    
    # Seed reviews, ratings, favorites, and likes
    print(f"\n\n{'='*80}")
    print("[ENGAGEMENT] Seeding reviews, ratings, favorites, and likes...")
    print(f"{'='*80}")
    
    # Get all listings from Firestore
    all_listings_snapshot = db.collection('listings').where('status', '==', 'published').limit(50).get()
    all_listing_ids = []
    listing_owner_map = {}  # Map listing_id to owner_id
    
    for doc in all_listings_snapshot:
        listing_data = doc.to_dict()
        listing_id = doc.id
        owner_id = listing_data.get('userId')
        all_listing_ids.append(listing_id)
        listing_owner_map[listing_id] = owner_id
    
    # Get all users
    all_users_snapshot = db.collection('users').limit(50).get()
    all_user_ids = [doc.id for doc in all_users_snapshot]
    
    # Get all "Looking For" posts
    all_posts_snapshot = db.collection('lookingForPosts').limit(20).get()
    all_post_ids = []
    post_owner_map = {}
    
    for doc in all_posts_snapshot:
        post_data = doc.to_dict()
        post_id = doc.id
        owner_id = post_data.get('userId')
        all_post_ids.append(post_id)
        post_owner_map[post_id] = owner_id
    
    # Create more reviews with ratings
    print(f"\n[REVIEWS] Creating more reviews and ratings...")
    review_comments = [
        "Amazing place! Exceeded my expectations. Very clean and well-maintained.",
        "Great location, close to everything. The owner is very responsive.",
        "Perfect for my needs. Good value for money. Highly recommended!",
        "Nice property with all amenities. Would definitely rent again.",
        "Beautiful place, exactly as described. Very satisfied with my stay.",
        "Excellent property! Clean, spacious, and in a great neighborhood.",
        "The owner was very accommodating. Place is well-furnished and comfortable.",
        "Good location and reasonable price. Perfect for families.",
        "Very clean and modern. All facilities are working properly.",
        "Great experience overall. The property is well-maintained.",
        "Comfortable and cozy place. Owner is friendly and helpful.",
        "Nice property but could use some minor improvements.",
        "Good value for the price. Location is convenient.",
        "Well-maintained property. Owner responds quickly to inquiries.",
        "Perfect location! Close to shopping centers and public transport.",
    ]
    
    # Create reviews for listings (mix of verified and non-verified)
    # Each listing gets 2-4 reviews from different users
    for listing_id in all_listing_ids[:30]:  # Review first 30 listings
        owner_id = listing_owner_map.get(listing_id)
        if not owner_id:
            continue
        
        # Get listing to check if verified
        listing_doc = db.collection('listings').document(listing_id).get()
        if not listing_doc.exists:
            continue
        
        listing_data = listing_doc.to_dict()
        is_verified_listing = listing_data.get('isOwnerVerified', False)
        
        # Number of reviews per listing (2-4)
        num_reviews = 2 + (abs(hash(listing_id)) % 3)  # 2, 3, or 4 reviews
        
        reviewers_used = set()
        for i in range(num_reviews):
            # Find a reviewer who is not the owner
            reviewer_id = None
            reviewer_name = None
            for uid in all_user_ids:
                if uid != owner_id and uid not in reviewers_used:
                    user_doc = db.collection('users').document(uid).get()
                    if user_doc.exists:
                        data = user_doc.to_dict()
                        reviewer_id = uid
                        reviewer_name = data.get('displayName', 'Anonymous')
                        reviewers_used.add(uid)
                        break
            
            if reviewer_id and reviewer_name:
                # Ratings: verified listings get 4-5, non-verified get 3-5
                if is_verified_listing:
                    rating = 4 + (i % 2)  # 4 or 5
                else:
                    rating = 3 + (i % 3)  # 3, 4, or 5
                
                comment = review_comments[(abs(hash(f"{listing_id}{i}")) % len(review_comments))]
                create_review(reviewer_id, listing_id, reviewer_name, rating, comment)
    
    # Create favorites (users saving listings)
    print(f"\n[FAVORITES] Creating favorites (users saving listings)...")
    
    # Separate verified and non-verified listings
    verified_listing_ids = []
    non_verified_listing_ids = []
    verified_listing_map = {}  # Map listing_id to is_verified
    
    for listing_id in all_listing_ids:
        listing_doc = db.collection('listings').document(listing_id).get()
        if listing_doc.exists:
            listing_data = listing_doc.to_dict()
            is_verified = listing_data.get('isOwnerVerified', False)
            verified_listing_map[listing_id] = is_verified
            if is_verified:
                verified_listing_ids.append(listing_id)
            else:
                non_verified_listing_ids.append(listing_id)
    
    print(f"  Found {len(verified_listing_ids)} verified listings and {len(non_verified_listing_ids)} non-verified listings")
    
    # STEP 1: Ensure ALL verified listings get at least 5-15 favorites (none should have 0)
    print(f"\n  [STEP 1] Ensuring verified listings have favorites...")
    verified_favorites_count = 0
    for listing_id in verified_listing_ids:
        owner_id = listing_owner_map.get(listing_id)
        if not owner_id:
            continue
        
        # Each verified listing gets 5-15 favorites
        num_favorites_for_listing = 5 + (abs(hash(listing_id)) % 11)  # 5-15 favorites
        
        favorites_added = 0
        for user_id in all_user_ids:
            if favorites_added >= num_favorites_for_listing:
                break
            
            # Don't favorite own listings
            if owner_id == user_id:
                continue
            
            # Check if already favorited
            existing = db.collection('favorites').where('userId', '==', user_id).where('listingId', '==', listing_id).limit(1).get()
            if existing and len(existing) > 0:
                continue  # Already favorited
            
            create_favorite(user_id, listing_id)
            favorites_added += 1
            verified_favorites_count += 1
    
    print(f"  [OK] Added {verified_favorites_count} favorites to verified listings")
    
    # STEP 2: Add more favorites to non-verified listings (3-10 per listing)
    print(f"\n  [STEP 2] Adding favorites to non-verified listings...")
    non_verified_favorites_count = 0
    for listing_id in non_verified_listing_ids:
        owner_id = listing_owner_map.get(listing_id)
        if not owner_id:
            continue
        
        # Each non-verified listing gets 3-10 favorites
        num_favorites_for_listing = 3 + (abs(hash(listing_id)) % 8)  # 3-10 favorites
        
        favorites_added = 0
        for user_id in all_user_ids:
            if favorites_added >= num_favorites_for_listing:
                break
            
            # Don't favorite own listings
            if owner_id == user_id:
                continue
            
            # Check if already favorited
            existing = db.collection('favorites').where('userId', '==', user_id).where('listingId', '==', listing_id).limit(1).get()
            if existing and len(existing) > 0:
                continue  # Already favorited
            
            create_favorite(user_id, listing_id)
            favorites_added += 1
            non_verified_favorites_count += 1
    
    print(f"  [OK] Added {non_verified_favorites_count} favorites to non-verified listings")
    
    # STEP 3: Additional random favorites - users favoriting more listings
    print(f"\n  [STEP 3] Adding additional random favorites...")
    additional_favorites_count = 0
    for user_id in all_user_ids[:50]:  # More users (50 instead of 40)
        num_favorites = 5 + (abs(hash(user_id)) % 8)  # 5-12 favorites per user
        
        favorites_added = 0
        # Shuffle listings to get random selection
        shuffled_listings = all_listing_ids.copy()
        random.shuffle(shuffled_listings)
        
        for listing_id in shuffled_listings:
            if favorites_added >= num_favorites:
                break
            
            owner_id = listing_owner_map.get(listing_id)
            # Don't favorite own listings
            if owner_id == user_id:
                continue
            
            # Check if already favorited
            existing = db.collection('favorites').where('userId', '==', user_id).where('listingId', '==', listing_id).limit(1).get()
            if existing and len(existing) > 0:
                continue  # Already favorited
            
            # Prefer verified listings (80% chance for verified, 50% for non-verified)
            is_verified = verified_listing_map.get(listing_id, False)
            if is_verified:
                if (abs(hash(f"{user_id}{listing_id}")) % 10) < 8:  # 80% chance
                    create_favorite(user_id, listing_id)
                    favorites_added += 1
                    additional_favorites_count += 1
            else:
                if (abs(hash(f"{user_id}{listing_id}")) % 10) < 5:  # 50% chance
                    create_favorite(user_id, listing_id)
                    favorites_added += 1
                    additional_favorites_count += 1
    
    print(f"  [OK] Added {additional_favorites_count} additional random favorites")
    
    total_favorites = verified_favorites_count + non_verified_favorites_count + additional_favorites_count
    print(f"\n  [SUMMARY] Total favorites created: {total_favorites}")
    print(f"    - Verified listings: {verified_favorites_count}")
    print(f"    - Non-verified listings: {non_verified_favorites_count}")
    print(f"    - Additional random: {additional_favorites_count}")
    
    # Like "Looking For" posts
    print(f"\n[LIKES] Creating likes on 'Looking For' posts...")
    
    # Each post gets 5-15 likes from different users
    for post_id in all_post_ids:
        owner_id = post_owner_map.get(post_id)
        if not owner_id:
            continue
        
        num_likes = 5 + (abs(hash(post_id)) % 11)  # 5-15 likes
        
        likers_used = set()
        for i in range(num_likes):
            # Find a user who is not the owner
            liker_id = None
            for uid in all_user_ids:
                if uid != owner_id and uid not in likers_used:
                    liker_id = uid
                    likers_used.add(uid)
                    break
            
            if liker_id:
                like_looking_for_post(liker_id, post_id)
    
    # Update listing average ratings based on reviews
    print(f"\n[RATINGS] Updating listing average ratings...")
    
    for listing_id in all_listing_ids[:30]:
        # Get all reviews for this listing
        reviews_snapshot = db.collection('reviews').where('listingId', '==', listing_id).get()
        
        if reviews_snapshot:
            total_rating = 0
            review_count = len(reviews_snapshot)
            
            for review_doc in reviews_snapshot:
                review_data = review_doc.to_dict()
                rating = review_data.get('rating', 0)
                total_rating += rating
            
            if review_count > 0:
                average_rating = total_rating / review_count
                
                # Update listing
                listing_ref = db.collection('listings').document(listing_id)
                listing_ref.update({
                    'averageRating': round(average_rating, 1),
                    'reviewCount': review_count,
                    'updatedAt': firestore.SERVER_TIMESTAMP,
                })
    
    print(f"\n\n{'='*80}")
    print("[SUCCESS] Engagement Data Seeding Complete!")
    print(f"{'='*80}")
    print(f"\n[SUMMARY]")
    print(f"  - Created reviews for listings (2-4 reviews per listing)")
    print(f"  - Created favorites:")
    print(f"    * Verified listings: guaranteed 5-15 favorites each (none with 0)")
    print(f"    * Non-verified listings: 3-10 favorites each")
    print(f"    * Additional random favorites from users")
    print(f"  - Created likes on 'Looking For' posts (5-15 likes per post)")
    print(f"  - Updated listing average ratings and review counts")
    print(f"  - Updated user favoritesCount and likesReceived")
    print(f"\n[OK] All engagement data has been seeded successfully!")


if __name__ == "__main__":
    main()
