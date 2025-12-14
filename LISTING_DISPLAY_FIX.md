# Fix for Listings Not Displaying

## ✅ Changes Made

### 1. **Simplified Firestore Queries** (to avoid composite index issues)
   - `getAllListings()`: Now uses single `where('status', isEqualTo: 'published')` + `orderBy('postedDate')`
   - `getListingsByUser()`: Now uses `where('userId')` + `where('status')` + `orderBy('postedDate')`
   - Both filter `isDraft: false` in memory to avoid composite index requirement

### 2. **Added Debug Logging**
   - Both queries now log:
     - How many listings were found
     - Details of each listing (title, ID, userId, status, isDraft)
     - Any errors including composite index errors

### 3. **Added Auto-Refresh**
   - Profile page now refreshes when returning from AddPropertyPage
   - Post type selection modal handles the result

## 🔍 Debugging Steps

When you publish a listing, check the console logs:

1. **After Publishing:**
   ```
   ✅ [BListingService] Listing created successfully!
   📄 Document ID: [listing-id]
   ```

2. **When Home Page Loads:**
   ```
   📖 [BListingService] Fetching all published listings...
   ✅ [BListingService] Found X published listings
   ```

3. **When Profile Page Loads:**
   ```
   📖 [BListingService] Fetching listings for user: [user-id]
   ✅ [BListingService] Found X listings for user
   ```

## ⚠️ If Listings Still Don't Appear

### Check Console Logs:
- Are the queries finding listings? (Check the count)
- Are there any index errors?
- Are the listings showing the correct `status: 'published'` and `isDraft: false`?

### Possible Issues:

1. **Composite Index Required:**
   - If you see an index error, click the link in the error message
   - Or go to Firebase Console → Firestore → Indexes
   - Create the index as suggested

2. **Data Not Refreshing:**
   - Try pull-to-refresh on home page
   - Try pull-to-refresh on profile page
   - Navigate away and back to the pages

3. **Query Filters:**
   - Verify the listing has:
     - `status: 'published'`
     - `isDraft: false`
     - `userId: [your-user-id]`

## 🧪 Test Steps

1. Publish a new listing
2. Check console for success message
3. Go to Home page → Pull to refresh
4. Go to Profile page → Pull to refresh
5. Check console logs to see if listings are being fetched

## 📝 Next Steps

If listings still don't appear after pull-to-refresh:
1. Share the console logs
2. Check Firebase Console → Firestore → Data to verify the listing exists
3. Verify the listing has the correct fields
