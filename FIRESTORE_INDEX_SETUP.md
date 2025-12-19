# Firestore Index Setup for Chat Threads

## ⚠️ Required Index

The chat threads query requires a composite index. You have two options:

### Option 1: Create the Index (Recommended for Performance)

1. **Click the link from the error message** (it will auto-create the index):
   ```
   https://console.firebase.google.com/v1/r/project/renteasedb/firestore/indexes?create_composite=...
   ```

2. **Or manually create it:**
   - Go to Firebase Console → Firestore Database → Indexes
   - Click "Create Index"
   - Collection ID: `chat_threads`
   - Fields to index:
     - Field: `participants` | Type: Array | Order: Ascending
     - Field: `lastMessageTime` | Type: Timestamp | Order: Descending
   - Query scope: Collection
   - Click "Create"

### Option 2: Use Current Implementation (No Index Needed)

The current code sorts in memory, so it works without an index but may be slower with many chat threads.

## Current Status

The code is set to work **without requiring an index** by:
- Fetching all threads where user is a participant
- Sorting by `lastMessageTime` in memory
- This works but may be slower with 100+ threads

For better performance with many chats, create the index using Option 1.

