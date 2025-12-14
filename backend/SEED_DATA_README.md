# RentEase Data Seeding Script

This script populates your Firebase project with sample users, listings, reviews, comments, and "Looking For" posts.

## Prerequisites

1. **Firebase Service Account Key**
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file as `backend/firebase-credentials.json`

2. **Python Dependencies**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

## Usage

1. **Set up Firebase credentials**
   - Place your Firebase service account JSON file at `backend/firebase-credentials.json`
   - Or set the `FIREBASE_CREDENTIALS` environment variable to the path of your credentials file

2. **Run the seeding script**
   ```bash
   cd backend
   python seed_data.py
   ```

## What the Script Does

1. **Creates 16 Firebase Auth Users**
   - Each user has an email and password
   - Users are created with verified email addresses
   - Default password for all users: `Password123!`

2. **Creates User Documents in Firestore**
   - User profiles with names, usernames, and basic stats
   - All users are marked as verified

3. **Uploads Images to Cloudinary**
   - Downloads images from the provided URLs
   - Uploads them to Cloudinary in the `properties` folder
   - Stores Cloudinary URLs in Firestore

4. **Creates Listings**
   - 16 property listings across different categories:
     - 4 Condo Rentals
     - 3 House Rentals
     - 2 Rooms
     - 2 Boarding Houses
     - 3 Apartments
     - 2 Student Dorms
   - Each listing includes:
     - Property details (bedrooms, bathrooms, area, price)
     - Description
     - Location
     - Amenities
     - Images (uploaded to Cloudinary)

5. **Creates Additional Data**
   - Reviews for some listings
   - Comments on listings
   - "Looking For" posts

## User Accounts Created

All users follow this pattern:
- Email: `user{N}.{category}@rentease.com`
- Password: `Password123!`

Example users:
- `user1.condo@rentease.com` - Maria Santos (Condo)
- `user5.house@rentease.com` - Janell Amistoso (House)
- `user8.room@rentease.com` - Roberto Lopez (Room)
- `user14.dorm@rentease.com` - Ryan Dela Cruz (Student Dorm)

## Categories

- **Condo Rentals**: Users 1-4
- **House Rentals**: Users 5-7
- **Rooms**: Users 8-9
- **Boarding House**: Users 10, 15
- **Apartment**: Users 11-13
- **Student Dorms**: Users 14, 16

## Notes

- The script will skip users that already exist in Firebase Auth
- Images are downloaded from external URLs and uploaded to Cloudinary
- All listings are published (not drafts)
- Users are marked as verified
- The script creates realistic property data based on the provided information

## Troubleshooting

1. **"Firebase credentials file not found"**
   - Make sure `backend/firebase-credentials.json` exists
   - Or set the `FIREBASE_CREDENTIALS` environment variable

2. **"User already exists"**
   - The script will continue and use the existing user
   - To start fresh, delete users from Firebase Console

3. **Image upload failures**
   - Check your internet connection
   - Some external URLs may be temporarily unavailable
   - The script will continue even if some images fail to upload

4. **Cloudinary upload errors**
   - Verify your Cloudinary credentials in the script
   - Check your Cloudinary account limits

## Customization

To modify the seed data:
1. Edit the `USER_DATA` list in `seed_data.py`
2. Add or modify user entries with their property information
3. Run the script again

Note: The script will create new users/listings each time it runs. To avoid duplicates, delete existing data first or modify the script to check for existing entries.
