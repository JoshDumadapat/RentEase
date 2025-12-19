// ignore_for_file: file_names
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'BUserService.dart';

/// Listing service for Firestore
class BListingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BUserService _userService = BUserService();
  static const String _collectionName = 'listings';

  /// Create a new listing
  Future<String> createListing({
    required String userId,
    required String ownerName,
    required bool isOwnerVerified,
    required String title,
    required String category,
    required String location,
    required double price,
    required String description,
    required List<String> imageUrls,
    int? bedrooms,
    int? bathrooms,
    double? area,
    // Pricing details
    double? deposit,
    double? advance,
    // Location details
    String? landmark,
    double? latitude,
    double? longitude,
    // Contact information
    String? phone,
    String? messenger,
    // Availability
    DateTime? availableFrom,
    String? curfew,
    int? maxOccupants,
    // Amenities
    bool electricityIncluded = false,
    bool waterIncluded = false,
    bool internetIncluded = false,
    bool privateCR = false,
    bool sharedCR = false,
    bool kitchenAccess = false,
    bool wifi = false,
    bool laundry = false,
    bool parking = false,
    bool security = false,
    bool aircon = false,
    bool petFriendly = false,
    // Status
    bool isDraft = false,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // debugPrint('📝 [BListingService] Creating new listing...');
      // debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // debugPrint('👤 User ID: $userId');
      // debugPrint('📋 Title: $title');
      // debugPrint('🏠 Category: $category');
      // debugPrint('📍 Location: $location');
      // debugPrint('💰 Price: $price');
      // debugPrint('📸 Image URLs count: ${imageUrls.length}');
      // debugPrint('📝 Is Draft: $isDraft');
      // debugPrint('📊 Status: ${isDraft ? 'draft' : 'published'}');
      
      final listingData = <String, dynamic>{
        'userId': userId,
        'ownerName': ownerName,
        'isOwnerVerified': isOwnerVerified,
        'title': title,
        'category': category,
        'location': location,
        'price': price,
        'description': description,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'postedDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDraft': isDraft ? true : false, // Explicitly set boolean
        'status': isDraft ? 'draft' : 'published', // Ensure status is set correctly
        // Optional fields
        if (bedrooms != null) 'bedrooms': bedrooms,
        if (bathrooms != null) 'bathrooms': bathrooms,
        if (area != null) 'area': area,
        if (deposit != null) 'deposit': deposit,
        if (advance != null) 'advance': advance,
        if (landmark != null) 'landmark': landmark,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (phone != null) 'phone': phone,
        if (messenger != null) 'messenger': messenger,
        if (availableFrom != null) 'availableFrom': Timestamp.fromDate(availableFrom),
        if (curfew != null) 'curfew': curfew,
        if (maxOccupants != null) 'maxOccupants': maxOccupants,
        // Amenities
        'electricityIncluded': electricityIncluded,
        'waterIncluded': waterIncluded,
        'internetIncluded': internetIncluded,
        'privateCR': privateCR,
        'sharedCR': sharedCR,
        'kitchenAccess': kitchenAccess,
        'wifi': wifi,
        'laundry': laundry,
        'parking': parking,
        'security': security,
        'aircon': aircon,
        'petFriendly': petFriendly,
        // Counts
        'favoriteCount': 0,
        'viewCount': 0,
        'commentCount': 0,
        'reviewCount': 0,
        'averageRating': 0.0,
        if (additionalData != null) ...additionalData,
      };

      // debugPrint('📦 Listing data prepared with ${listingData.length} fields');
      // debugPrint('🔑 Key fields check:');
      // debugPrint('   - userId: ${listingData['userId']} (type: ${listingData['userId'].runtimeType})');
      // debugPrint('   - title: ${listingData['title']}');
      // debugPrint('   - category: ${listingData['category']}');
      // debugPrint('   - status: ${listingData['status']}');
      // debugPrint('   - isDraft: ${listingData['isDraft']}');
      
      // Verify userId is a string (required by Firestore rules)
      if (listingData['userId'] is! String) {
        throw Exception('userId must be a String, got: ${listingData['userId'].runtimeType}');
      }
      
      // CRITICAL: Verify Firebase Auth state right before writing
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated. Cannot create listing.');
      }
      
      final authUid = currentUser.uid;
      final dataUserId = listingData['userId'] as String;
      
      // debugPrint('🔐 AUTH VERIFICATION BEFORE WRITE:');
      // debugPrint('   - Firebase Auth UID: $authUid');
      // debugPrint('   - Data userId: $dataUserId');
      // debugPrint('   - UIDs match: ${authUid == dataUserId}');
      // debugPrint('   - Auth UID length: ${authUid.length}');
      // debugPrint('   - Data userId length: ${dataUserId.length}');
      // debugPrint('   - Auth UID bytes: ${authUid.codeUnits}');
      // debugPrint('   - Data userId bytes: ${dataUserId.codeUnits}');
      
      // Ensure userId matches auth.uid exactly (Firestore rules requirement)
      if (authUid != dataUserId) {
        throw Exception(
          'userId mismatch! Auth UID: "$authUid" but data userId: "$dataUserId". '
          'They must match exactly for Firestore rules to allow the write.'
        );
      }
      
      // debugPrint('✅ Auth verification passed - UIDs match exactly');
      // debugPrint('💾 Attempting to write to Firestore collection: $_collectionName');
      // debugPrint('   (Collection will be auto-created on first write)');
      // debugPrint('⚠️  IMPORTANT: Make sure Firestore rules are deployed to Firebase Console!');
      // debugPrint('   See DEPLOY_FIRESTORE_RULES.md for instructions');
      // debugPrint('   Current rule should be: allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;');
      
      // Firestore automatically creates collections on first write
      // No need to manually create the collection
      final docRef = await _firestore.collection(_collectionName).add(listingData);
      
      // Verify the listing was created correctly with correct status
      // This ensures the data is committed and searchable
      try {
        // Wait a brief moment to ensure write is committed
        await Future.delayed(const Duration(milliseconds: 100));
        final verifyDoc = await docRef.get(const GetOptions(source: Source.server));
        if (verifyDoc.exists) {
          final verifyData = verifyDoc.data();
          final verifyStatus = verifyData?['status'] as String?;
          final verifyIsDraft = verifyData?['isDraft'] as bool?;
          
          if (!isDraft && (verifyStatus != 'published' || verifyIsDraft == true)) {
            debugPrint('⚠️ [BListingService] WARNING: Listing created but status might be incorrect');
            debugPrint('   Expected: status=published, isDraft=false');
            debugPrint('   Actual: status=$verifyStatus, isDraft=$verifyIsDraft');
            debugPrint('   Listing ID: ${docRef.id}');
          }
        }
      } catch (e) {
        debugPrint('⚠️ [BListingService] Could not verify listing creation: $e');
      }
      
      // debugPrint('✅ [BListingService] Listing created successfully!');
      // debugPrint('📄 Document ID: ${docRef.id}');
      // debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      return docRef.id;
    } catch (e, stackTrace) {
      // debugPrint('❌ [BListingService] Error creating listing: $e');
      // debugPrint('📚 Stack trace: $stackTrace');
      // debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Get listing by ID
  Future<Map<String, dynamic>?> getListing(String listingId) async {
    try {
      if (listingId.isEmpty) {
        // debugPrint('⚠️ [BListingService] Empty listingId provided');
        return null;
      }
      final doc = await _firestore.collection(_collectionName).doc(listingId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          // Include the document ID in the returned data
          return {
            'id': doc.id,
            ...data,
          };
        }
      }
      return null;
    } catch (e) {
      // debugPrint('❌ [BListingService] Error getting listing: $e');
      return null;
    }
  }

  /// Get paginated listings (optimized for performance)
  /// Returns a list of listings and a DocumentSnapshot for the last item (for pagination)
  /// NOTE: Uses in-memory pagination to avoid Firestore composite index requirement
  Future<Map<String, dynamic>> getListingsPaginated({
    int limit = 12,
    DocumentSnapshot? lastDocument,
    bool randomize = true,
  }) async {
    try {
      // debugPrint('📖 [BListingService] Fetching paginated listings (limit: $limit)...');
      
      // Query without orderBy to avoid composite index requirement
      // We'll sort and paginate in memory
      Query query = _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'published');
      
      bool usedOrderBy = false;
      
      // If randomize is false, try to use proper Firestore pagination with orderBy
      if (!randomize) {
        try {
          // Use orderBy for proper pagination
          if (lastDocument != null) {
            query = query.orderBy('postedDate', descending: true).startAfterDocument(lastDocument).limit(limit);
          } else {
            query = query.orderBy('postedDate', descending: true).limit(limit);
          }
          usedOrderBy = true;
          // debugPrint('📖 [BListingService] Using orderBy pagination (randomize: false)');
        } catch (e) {
          // If orderBy fails (missing index), fall back to in-memory pagination
          // debugPrint('⚠️ [BListingService] OrderBy query failed, falling back to in-memory pagination: $e');
          usedOrderBy = false;
          final batchSize = limit * 3; // Get 3x the limit to account for filtering
          query = query.limit(batchSize);
        }
      } else {
        // Randomize mode - get larger batch and shuffle
        final batchSize = limit * 3; // Get 3x the limit to account for filtering
        query = query.limit(batchSize);
        // debugPrint('📖 [BListingService] Using randomize mode with batch size: $batchSize');
      }
      
      // debugPrint('📖 [BListingService] Executing query: status=published');
      // Use Source.server to force fresh data from server (not cache) to ensure new posts appear
      final snapshot = await query.get(const GetOptions(source: Source.server));
      
      // debugPrint('📖 [BListingService] Query returned ${snapshot.docs.length} documents');
      
      if (snapshot.docs.isEmpty) {
        // debugPrint('⚠️ [BListingService] No documents found in query');
        return {
          'listings': <Map<String, dynamic>>[],
          'lastDocument': null,
          'hasMore': false,
        };
      }
      
      // Convert to map and filter
      var allListings = snapshot.docs.map<Map<String, dynamic>>((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return <String, dynamic>{
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      // Filter out drafts
      final beforeDraftFilter = allListings.length;
      allListings = allListings.where((listing) {
        final isDraft = listing['isDraft'];
        return isDraft != true; // Filter out drafts (handle null as false)
      }).toList();
      
      // debugPrint('📊 [BListingService] After filtering drafts: ${allListings.length} listings (removed ${beforeDraftFilter - allListings.length})');
      
      // Filter out listings from deactivated users
      if (allListings.isNotEmpty) {
        final userIds = allListings.map((l) => l['userId'] as String?).whereType<String>().toList();
        // debugPrint('📊 [BListingService] Checking ${userIds.length} unique user IDs for deactivation');
        final deactivatedUserIds = await _userService.getDeactivatedUserIds(userIds);
        
        if (deactivatedUserIds.isNotEmpty) {
          final beforeDeactivatedFilter = allListings.length;
          allListings = allListings.where((listing) {
            final userId = listing['userId'] as String?;
            return userId == null || !deactivatedUserIds.contains(userId);
          }).toList();
          // debugPrint('📊 [BListingService] After filtering deactivated users: ${allListings.length} listings (removed ${beforeDeactivatedFilter - allListings.length})');
        } else {
          // debugPrint('📊 [BListingService] No deactivated users found, keeping all ${allListings.length} listings');
        }
      }
      
      List<Map<String, dynamic>> listings;
      DocumentSnapshot? lastDoc;
      bool hasMore;
      
      if (usedOrderBy) {
        // We used orderBy pagination - results are already sorted and limited
        // But we still need to filter drafts and deactivated users
        listings = allListings; // Already filtered above
        hasMore = snapshot.docs.length == limit; // If we got full limit, there might be more
        lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        // debugPrint('📊 [BListingService] Using orderBy pagination results: ${listings.length} listings');
      } else {
        // In-memory pagination (for randomize or fallback)
        // Sort by postedDate in memory (newest first)
        allListings.sort((a, b) {
          final aDate = a['postedDate'];
          final bDate = b['postedDate'];
          
          DateTime aDateTime;
          DateTime bDateTime;
          
          if (aDate is Timestamp) {
            aDateTime = aDate.toDate();
          } else if (aDate is DateTime) {
            aDateTime = aDate;
          } else {
            aDateTime = DateTime.fromMillisecondsSinceEpoch(0);
          }
          
          if (bDate is Timestamp) {
            bDateTime = bDate.toDate();
          } else if (bDate is DateTime) {
            bDateTime = bDate;
          } else {
            bDateTime = DateTime.fromMillisecondsSinceEpoch(0);
          }
          
          return bDateTime.compareTo(aDateTime); // Descending order
        });
        
        // Randomize if requested (shuffle the list)
        // NOTE: Only randomize on first page to avoid duplicates
        if (randomize && lastDocument == null && allListings.length > 1) {
          allListings.shuffle();
          // debugPrint('📊 [BListingService] Randomized ${allListings.length} listings (first page only)');
        }
        
        // Apply pagination limit
        listings = allListings.take(limit).toList();
        hasMore = allListings.length > limit;
        
        // Create a mock lastDocument for pagination tracking
        // Since we're doing in-memory pagination, we'll use the last listing's ID
        if (listings.isNotEmpty && snapshot.docs.isNotEmpty) {
          // Find the document that corresponds to the last listing
          final lastListingId = listings.last['id'] as String;
          try {
            lastDoc = snapshot.docs.firstWhere(
              (doc) => doc.id == lastListingId,
            );
          } catch (e) {
            // If not found, use the last document from snapshot
            lastDoc = snapshot.docs.last;
          }
        }
        // debugPrint('📊 [BListingService] Using in-memory pagination: ${listings.length} listings from ${allListings.length} total');
      }
      
      // debugPrint('✅ [BListingService] Fetched ${listings.length} listings from ${allListings.length} total (hasMore: $hasMore)');
      
      return {
        'listings': listings,
        'lastDocument': lastDoc,
        'hasMore': hasMore,
      };
    } catch (e, stackTrace) {
      // debugPrint('❌ [BListingService] Error fetching paginated listings: $e');
      // debugPrint('📚 Stack trace: $stackTrace');
      return {
        'listings': <Map<String, dynamic>>[],
        'lastDocument': null,
        'hasMore': false,
      };
    }
  }

  /// Get all published listings (excludes drafts and listings from deactivated users)
  Future<List<Map<String, dynamic>>> getAllListings() async {
    try {
      // debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // debugPrint('📖 [BListingService] Fetching all published listings...');
      
      // Query without orderBy to avoid composite index requirement
      // We'll sort in memory instead
      // Use Source.server to force fresh data from server (not cache) to ensure new posts appear
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'published')
          .get(const GetOptions(source: Source.server));
      
      // Filter out drafts and sort by postedDate in memory
      // Remove duplicates by ID
      final seenIds = <String>{};
      final listings = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        final isDraft = data['isDraft'] as bool? ?? false;
        final listingId = doc.id;
        
        // Only include if status is 'published' AND isDraft is false AND not duplicate
        if (status == 'published' && !isDraft && !seenIds.contains(listingId)) {
          seenIds.add(listingId);
          listings.add({
            'id': listingId,
            ...data,
          });
        }
      }
      
      // Filter out listings from deactivated users
      if (listings.isNotEmpty) {
        final userIds = listings.map((l) => l['userId'] as String?).whereType<String>().toList();
        final deactivatedUserIds = await _userService.getDeactivatedUserIds(userIds);
        
        if (deactivatedUserIds.isNotEmpty) {
          // debugPrint('🚫 [BListingService] Filtering out ${deactivatedUserIds.length} listings from deactivated users');
          listings.removeWhere((listing) {
            final userId = listing['userId'] as String?;
            return userId != null && deactivatedUserIds.contains(userId);
          });
        }
      }
      
      // Sort by postedDate in memory (newest first)
      listings.sort((a, b) {
        final aDate = a['postedDate'];
        final bDate = b['postedDate'];
        
        // Handle Timestamp objects
        DateTime aDateTime;
        DateTime bDateTime;
        
        if (aDate is Timestamp) {
          aDateTime = aDate.toDate();
        } else if (aDate is DateTime) {
          aDateTime = aDate;
        } else {
          aDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        if (bDate is Timestamp) {
          bDateTime = bDate.toDate();
        } else if (bDate is DateTime) {
          bDateTime = bDate;
        } else {
          bDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        return bDateTime.compareTo(aDateTime); // Descending order
      });
      
      // debugPrint('✅ [BListingService] Found ${listings.length} published listings (excluding deactivated users)');
      for (var listing in listings) {
        // debugPrint('   - ${listing['title']} (ID: ${listing['id']}, userId: ${listing['userId']}, status: ${listing['status']}, isDraft: ${listing['isDraft']})');
      }
      // debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      return listings;
    } catch (e, stackTrace) {
      // debugPrint('❌ [BListingService] Error fetching all listings: $e');
      // debugPrint('📚 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get listings by user ID (published only)
  Future<List<Map<String, dynamic>>> getListingsByUser(String userId) async {
    try {
      // debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      // debugPrint('📖 [BListingService] Fetching listings for user: $userId');
      
      // Query without orderBy to avoid composite index requirement
      // We'll sort in memory instead
      // IMPORTANT: Always filter out drafts - drafts should only be visible to the owner via getDraftsByUser
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'published')
          .get(const GetOptions(source: Source.server));
      
      // Filter out drafts and sort by postedDate in memory
      // Double-check to ensure no drafts slip through
      final listings = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final isDraft = data['isDraft'] as bool? ?? false;
            final status = data['status'] as String? ?? '';
            // Only include if explicitly not a draft AND status is published
            return isDraft == false && status == 'published';
          })
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          })
          .toList();
      
      // Sort by postedDate in memory (newest first)
      listings.sort((a, b) {
        final aDate = a['postedDate'];
        final bDate = b['postedDate'];
        
        // Handle Timestamp objects
        DateTime aDateTime;
        DateTime bDateTime;
        
        if (aDate is Timestamp) {
          aDateTime = aDate.toDate();
        } else if (aDate is DateTime) {
          aDateTime = aDate;
        } else {
          aDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        if (bDate is Timestamp) {
          bDateTime = bDate.toDate();
        } else if (bDate is DateTime) {
          bDateTime = bDate;
        } else {
          bDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        return bDateTime.compareTo(aDateTime); // Descending order
      });
      
      // debugPrint('✅ [BListingService] Found ${listings.length} listings for user $userId');
      for (var listing in listings) {
        // debugPrint('   - ${listing['title']} (ID: ${listing['id']}, status: ${listing['status']}, isDraft: ${listing['isDraft']})');
      }
      // debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      return listings;
    } catch (e, stackTrace) {
      // debugPrint('❌ [BListingService] Error fetching user listings: $e');
      // debugPrint('📚 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get listings by user ID as a stream
  Stream<List<Map<String, dynamic>>> getListingsByUserStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
      // Filter out drafts and sort by postedDate in memory
      // IMPORTANT: Always filter out drafts - drafts should only be visible to the owner via getDraftsByUser
      final listings = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final isDraft = data['isDraft'] as bool? ?? false;
            final status = data['status'] as String? ?? '';
            // Only include if explicitly not a draft AND status is published
            return isDraft == false && status == 'published';
          })
          .map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          })
          .toList();
      
      // Sort by postedDate in memory (newest first)
      listings.sort((a, b) {
        final aDate = a['postedDate'];
        final bDate = b['postedDate'];
        
        // Handle Timestamp objects
        DateTime aDateTime;
        DateTime bDateTime;
        
        if (aDate is Timestamp) {
          aDateTime = aDate.toDate();
        } else if (aDate is DateTime) {
          aDateTime = aDate;
        } else {
          aDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        if (bDate is Timestamp) {
          bDateTime = bDate.toDate();
        } else if (bDate is DateTime) {
          bDateTime = bDate;
        } else {
          bDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        return bDateTime.compareTo(aDateTime); // Descending order
      });
      
      return listings;
    });
  }

  /// Get listings by category (published only, excludes deactivated users)
  Future<List<Map<String, dynamic>>> getListingsByCategory(String category) async {
    try {
      // debugPrint('🔍 [BListingService] Querying category: "$category"');
      
      List<Map<String, dynamic>> listings = [];
      
      // Try query with orderBy first
      try {
        // Use Source.server to force fresh data from server (not cache) to ensure new posts appear
        final snapshot = await _firestore
            .collection(_collectionName)
            .where('category', isEqualTo: category)
            .where('isDraft', isEqualTo: false)
            .where('status', isEqualTo: 'published')
            .orderBy('postedDate', descending: true)
            .get(const GetOptions(source: Source.server));
        
        // debugPrint('📊 [BListingService] Firestore query returned ${snapshot.docs.length} documents for category "$category"');
        
        listings = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      } catch (e) {
        // If orderBy fails (missing index), try without orderBy and sort in memory
        // debugPrint('⚠️ [BListingService] OrderBy query failed, trying without orderBy: $e');
        // Use Source.server to force fresh data from server (not cache) to ensure new posts appear
        final snapshotNoOrder = await _firestore
            .collection(_collectionName)
            .where('category', isEqualTo: category)
            .where('isDraft', isEqualTo: false)
            .where('status', isEqualTo: 'published')
            .get(const GetOptions(source: Source.server));
        
        // debugPrint('📊 [BListingService] Firestore query (no orderBy) returned ${snapshotNoOrder.docs.length} documents for category "$category"');
        
        listings = snapshotNoOrder.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        
        // Sort in memory by postedDate
        listings.sort((a, b) {
          final aDate = a['postedDate'];
          final bDate = b['postedDate'];
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          
          // Handle Timestamp objects
          DateTime aDateTime;
          DateTime bDateTime;
          if (aDate is Timestamp) {
            aDateTime = aDate.toDate();
          } else if (aDate is DateTime) {
            aDateTime = aDate;
          } else {
            return 0;
          }
          
          if (bDate is Timestamp) {
            bDateTime = bDate.toDate();
          } else if (bDate is DateTime) {
            bDateTime = bDate;
          } else {
            return 0;
          }
          
          return bDateTime.compareTo(aDateTime); // descending
        });
      }
      
      // Remove duplicates by ID (safety check, though Firestore shouldn't return duplicates)
      final seenIds = <String>{};
      final uniqueListings = <Map<String, dynamic>>[];
      for (var listing in listings) {
        final listingId = listing['id'] as String? ?? '';
        if (listingId.isNotEmpty && !seenIds.contains(listingId)) {
          seenIds.add(listingId);
          uniqueListings.add(listing);
        }
      }
      listings = uniqueListings;
      
      // Filter out listings from deactivated users
      if (listings.isNotEmpty) {
        final userIds = listings.map((l) => l['userId'] as String?).whereType<String>().toList();
        final deactivatedUserIds = await _userService.getDeactivatedUserIds(userIds);
        
        if (deactivatedUserIds.isNotEmpty) {
          final beforeCount = listings.length;
          listings = listings.where((listing) {
            final userId = listing['userId'] as String?;
            return userId == null || !deactivatedUserIds.contains(userId);
          }).toList();
          // debugPrint('🚫 [BListingService] Filtered out ${beforeCount - listings.length} listings from deactivated users');
        }
      }
      
      // debugPrint('✅ [BListingService] Returning ${listings.length} unique listings for category "$category"');
      return listings;
    } catch (e, stackTrace) {
      // debugPrint('❌ [BListingService] Error querying category "$category": $e');
      // debugPrint('❌ [BListingService] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Update listing
  Future<void> updateListing(String listingId, Map<String, dynamic> data) async {
    try {
      // Verify user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated. Cannot update listing.');
      }

      // Verify ownership
      final listingDoc = await _firestore.collection(_collectionName).doc(listingId).get();
      if (!listingDoc.exists) {
        throw Exception('Listing not found');
      }

      final listingData = listingDoc.data()!;
      final listingUserId = listingData['userId'] as String?;
      
      // Debug logging
      // debugPrint('🔍 [BListingService] Update ownership check:');
      // debugPrint('   Current user UID: ${currentUser.uid}');
      // debugPrint('   Listing userId: $listingUserId');
      // debugPrint('   Match: ${listingUserId == currentUser.uid}');
      
      if (listingUserId == null) {
        throw Exception('Listing has no owner. Cannot update.');
      }
      
      if (listingUserId != currentUser.uid) {
        throw Exception('You do not have permission to update this listing. Owner: $listingUserId, Current user: ${currentUser.uid}');
      }

      // Prevent userId from being changed
      if (data.containsKey('userId') && data['userId'] != currentUser.uid) {
        throw Exception('Cannot change listing owner');
      }

      // Ensure userId is not in update data (it should remain unchanged)
      data.remove('userId');

      // Update the listing
      await _firestore.collection(_collectionName).doc(listingId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // debugPrint('✅ [BListingService] Listing updated: $listingId');
    } catch (e) {
      // debugPrint('❌ [BListingService] Error updating listing: $e');
      rethrow;
    }
  }

  /// Delete listing
  Future<void> deleteListing(String listingId) async {
    try {
      // Verify user is authenticated
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated. Cannot delete listing.');
      }

      // Verify ownership
      final listingDoc = await _firestore.collection(_collectionName).doc(listingId).get();
      if (!listingDoc.exists) {
        throw Exception('Listing not found');
      }

      final listingData = listingDoc.data()!;
      if (listingData['userId'] != currentUser.uid) {
        throw Exception('You do not have permission to delete this listing');
      }

      // Delete the listing
      // NOTE: Firestore rules should also enforce this
      // NOTE: Consider cascade deleting associated data (favorites, reviews, comments)
      // This can be handled via Firestore delete rules or Cloud Functions
      await _firestore.collection(_collectionName).doc(listingId).delete();

      // debugPrint('✅ [BListingService] Listing deleted: $listingId');
    } catch (e) {
      // debugPrint('❌ [BListingService] Error deleting listing: $e');
      rethrow;
    }
  }

  /// Search listings by query (excludes listings from deactivated users)
  /// Searches through title, description, location, category, and owner name
  Future<List<Map<String, dynamic>>> searchListings(String query) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }
      
      // Get all published listings (without isDraft) to search in memory
      // This allows us to search across multiple fields (title, description, ownerName)
      // Use Source.server to force fresh data from server (not cache) to ensure new posts appear
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'published')
          .get(const GetOptions(source: Source.server));
      
      // Filter listings with explicit checks for status and isDraft
      var listings = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final status = data['status'] as String?;
            final isDraft = data['isDraft'] as bool?;
            // Only include if status is 'published' AND isDraft is explicitly false or null
            return status == 'published' && (isDraft == false || isDraft == null);
          })
          .map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Remove duplicates by ID
      final seenIds = <String>{};
      final uniqueListings = <Map<String, dynamic>>[];
      for (var listing in listings) {
        final listingId = listing['id'] as String? ?? '';
        if (listingId.isNotEmpty && !seenIds.contains(listingId)) {
          seenIds.add(listingId);
          uniqueListings.add(listing);
        }
      }
      listings = uniqueListings;
      
      // Filter out listings from deactivated users
      if (listings.isNotEmpty) {
        final userIds = listings.map((l) => l['userId'] as String?).whereType<String>().toList();
        final deactivatedUserIds = await _userService.getDeactivatedUserIds(userIds);
        
        if (deactivatedUserIds.isNotEmpty) {
          listings = listings.where((listing) {
            final userId = listing['userId'] as String?;
            return userId == null || !deactivatedUserIds.contains(userId);
          }).toList();
        }
      }
      
      // Apply text search filter in memory
      // Search through title, description, location, category, and owner name
      final queryLower = query.toLowerCase().trim();
      listings = listings.where((listing) {
        final title = (listing['title'] as String? ?? '').toLowerCase();
        final description = (listing['description'] as String? ?? '').toLowerCase();
        final location = (listing['location'] as String? ?? '').toLowerCase();
        final listingCategory = (listing['category'] as String? ?? '').toLowerCase();
        final ownerName = (listing['ownerName'] as String? ?? '').toLowerCase();
        // Check if any field contains the search query
        return title.contains(queryLower) || 
               description.contains(queryLower) ||
               location.contains(queryLower) || 
               listingCategory.contains(queryLower) ||
               ownerName.contains(queryLower);
      }).toList();
      
      // debugPrint('🔍 [BListingService] Text search "$query" found ${listings.length} listings');
      
      return listings;
    } catch (e) {
      // debugPrint('❌ [BListingService] Error searching listings: $e');
      return [];
    }
  }

  /// Search listings with filters (excludes deactivated users and drafts)
  Future<List<Map<String, dynamic>>> searchListingsWithFilters({
    String? searchQuery,
    String? category,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    String? propertyType,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(_collectionName)
          .where('status', isEqualTo: 'published');
      
      // Apply filters that can be done in Firestore
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (minPrice != null) {
        query = query.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      
      if (maxPrice != null) {
        query = query.where('price', isLessThanOrEqualTo: maxPrice);
      }
      
      if (bedrooms != null) {
        query = query.where('bedrooms', isEqualTo: bedrooms);
      }
      
      if (bathrooms != null) {
        query = query.where('bathrooms', isEqualTo: bathrooms);
      }
      
      // Use Source.server to force fresh data from server (not cache) to ensure new posts appear
      final snapshot = await query.get(const GetOptions(source: Source.server));
      
      // Filter listings with explicit checks for status and isDraft
      var listings = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final status = data['status'] as String?;
            final isDraft = data['isDraft'] as bool?;
            // Only include if status is 'published' AND isDraft is explicitly false or null
            return status == 'published' && (isDraft == false || isDraft == null);
          })
          .map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      // Remove duplicates by ID first
      final seenIds = <String>{};
      final uniqueListings = <Map<String, dynamic>>[];
      for (var listing in listings) {
        final listingId = listing['id'] as String? ?? '';
        if (listingId.isNotEmpty && !seenIds.contains(listingId)) {
          seenIds.add(listingId);
          uniqueListings.add(listing);
        }
      }
      listings = uniqueListings;

      // Apply text search filter in memory (if provided)
      // Search through title, description, location, category, and owner name
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase().trim();
        listings = listings.where((listing) {
          final title = (listing['title'] as String? ?? '').toLowerCase();
          final description = (listing['description'] as String? ?? '').toLowerCase();
          final location = (listing['location'] as String? ?? '').toLowerCase();
          final listingCategory = (listing['category'] as String? ?? '').toLowerCase();
          final ownerName = (listing['ownerName'] as String? ?? '').toLowerCase();
          // Check if any field contains the search query
          return title.contains(queryLower) || 
                 description.contains(queryLower) ||
                 location.contains(queryLower) || 
                 listingCategory.contains(queryLower) ||
                 ownerName.contains(queryLower);
        }).toList();
        // debugPrint('🔍 [BListingService] Text search "$searchQuery" filtered to ${listings.length} listings');
      }
      
      // Apply property type filter in memory (complex matching)
      if (propertyType != null) {
        final typeLower = propertyType.toLowerCase();
        listings = listings.where((listing) {
          final listingCategory = (listing['category'] as String? ?? '').toLowerCase();
          if (typeLower == 'apartment') {
            return listingCategory.contains('apartment');
          } else if (typeLower == 'house') {
            return listingCategory.contains('house');
          } else if (typeLower == 'condo') {
            return listingCategory.contains('condo');
          } else if (typeLower == 'room') {
            return listingCategory.contains('room');
          } else if (typeLower == 'villa') {
            return listingCategory.contains('villa');
          }
          return true;
        }).toList();
      }
      
      // Filter out listings from deactivated users
      if (listings.isNotEmpty) {
        final userIds = listings.map((l) => l['userId'] as String?).whereType<String>().toList();
        final deactivatedUserIds = await _userService.getDeactivatedUserIds(userIds);
        
        if (deactivatedUserIds.isNotEmpty) {
          listings = listings.where((listing) {
            final userId = listing['userId'] as String?;
            return userId == null || !deactivatedUserIds.contains(userId);
          }).toList();
        }
      }
      
      // Sort by postedDate descending (newest first)
      listings.sort((a, b) {
        final aDate = a['postedDate'];
        final bDate = b['postedDate'];
        
        DateTime aDateTime;
        DateTime bDateTime;
        
        if (aDate is Timestamp) {
          aDateTime = aDate.toDate();
        } else if (aDate is DateTime) {
          aDateTime = aDate;
        } else {
          aDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        if (bDate is Timestamp) {
          bDateTime = bDate.toDate();
        } else if (bDate is DateTime) {
          bDateTime = bDate;
        } else {
          bDateTime = DateTime.fromMillisecondsSinceEpoch(0);
        }
        
        return bDateTime.compareTo(aDateTime);
      });
      
      return listings;
    } catch (e, stackTrace) {
      // debugPrint('❌ [BListingService] Error searching listings with filters: $e');
      // debugPrint('📚 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get listing document reference
  DocumentReference getListingDocument(String listingId) {
    return _firestore.collection(_collectionName).doc(listingId);
  }

  /// Get user's favorite listings (excludes listings from deactivated users)
  /// Favorites are stored in a 'favorites' collection with userId and listingId
  Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    try {
      // Get all favorite document IDs for this user
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      if (favoritesSnapshot.docs.isEmpty) {
        return [];
      }

      // Extract listing IDs from favorites
      final listingIds = favoritesSnapshot.docs
          .map((doc) => doc.data()['listingId'] as String?)
          .where((id) => id != null)
          .toList();

      if (listingIds.isEmpty) {
        return [];
      }

      // Fetch the actual listings
      final listings = <Map<String, dynamic>>[];
      for (final listingId in listingIds) {
        final listing = await getListing(listingId!);
        if (listing != null) {
          listings.add({
            'id': listingId,
            ...listing,
          });
        }
      }

      // Filter out listings from deactivated users
      if (listings.isNotEmpty) {
        final listingUserIds = listings.map((l) => l['userId'] as String?).whereType<String>().toList();
        final deactivatedUserIds = await _userService.getDeactivatedUserIds(listingUserIds);
        
        if (deactivatedUserIds.isNotEmpty) {
          listings.removeWhere((listing) {
            final listingUserId = listing['userId'] as String?;
            return listingUserId != null && deactivatedUserIds.contains(listingUserId);
          });
        }
      }

      return listings;
    } catch (e) {
      // Error:'Error getting user favorites: $e');
      return [];
    }
  }

  /// Get user favorites as a real-time stream (excludes listings from deactivated users)
  /// Returns a stream that emits updated lists of favorite listings whenever favorites change
  Stream<List<Map<String, dynamic>>> getUserFavoritesStream(String userId) {
    return _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .asyncMap((favoritesSnapshot) async {
      if (favoritesSnapshot.docs.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      // Extract listing IDs from favorites
      final listingIds = favoritesSnapshot.docs
          .map((doc) => doc.data()['listingId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toList();

      if (listingIds.isEmpty) {
        return <Map<String, dynamic>>[];
      }

      // Fetch the actual listings in parallel
      final listings = <Map<String, dynamic>>[];
      final futures = listingIds.map((listingId) async {
        final listing = await getListing(listingId);
        if (listing != null) {
          return {
            'id': listingId,
            ...listing,
          };
        }
        return null;
      });

      final results = await Future.wait(futures);
      listings.addAll(results.whereType<Map<String, dynamic>>());

      // Filter out listings from deactivated users
      if (listings.isNotEmpty) {
        final listingUserIds = listings.map((l) => l['userId'] as String?).whereType<String>().toList();
        final deactivatedUserIds = await _userService.getDeactivatedUserIds(listingUserIds);
        
        if (deactivatedUserIds.isNotEmpty) {
          listings.removeWhere((listing) {
            final listingUserId = listing['userId'] as String?;
            return listingUserId != null && deactivatedUserIds.contains(listingUserId);
          });
        }
      }

      // Sort by createdAt descending (newest first)
      listings.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      return listings;
    });
  }

  /// Create or update a draft listing
  Future<String> saveDraft({
    required String userId,
    String? draftId,
    String? title,
    String? category,
    String? location,
    double? price,
    String? description,
    int? bedrooms,
    int? bathrooms,
    double? area,
    List<String>? imageUrls,
    int? currentStep,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // debugPrint('💾 [BListingService] Saving draft - userId: $userId, draftId: $draftId');
      // debugPrint('💾 [BListingService] Draft data - title: $title, step: $currentStep, imageUrls: ${imageUrls?.length ?? 0}');
      
      final draftData = <String, dynamic>{
        'userId': userId,
        'isDraft': true,
        'updatedAt': FieldValue.serverTimestamp(),
        if (title != null) 'title': title,
        if (category != null) 'category': category,
        if (location != null) 'location': location,
        if (price != null) 'price': price,
        if (description != null) 'description': description,
        if (bedrooms != null) 'bedrooms': bedrooms,
        if (bathrooms != null) 'bathrooms': bathrooms,
        if (area != null) 'area': area,
        if (imageUrls != null) 'imageUrls': imageUrls,
        if (currentStep != null) 'currentStep': currentStep,
        if (additionalData != null) ...additionalData,
      };

      if (draftId != null) {
        // Update existing draft
        // debugPrint('💾 [BListingService] Updating existing draft: $draftId');
        await _firestore.collection(_collectionName).doc(draftId).update(draftData);
        // debugPrint('✅ [BListingService] Draft updated successfully: $draftId');
        return draftId;
      } else {
        // Create new draft
        draftData['createdAt'] = FieldValue.serverTimestamp();
        // debugPrint('💾 [BListingService] Creating new draft');
        final docRef = await _firestore.collection(_collectionName).add(draftData);
        // debugPrint('✅ [BListingService] Draft created successfully: ${docRef.id}');
        return docRef.id;
      }
    } catch (e) {
      // debugPrint('❌ [BListingService] Error saving draft: $e');
      rethrow;
    }
  }

  /// Get draft listings by user ID
  /// NOTE: Query without orderBy to avoid Firestore composite index requirement
  /// Sorting is done in memory instead
  Future<List<Map<String, dynamic>>> getDraftsByUser(String userId) async {
    try {
      // debugPrint('📖 [BListingService] Fetching drafts for user: $userId');
      
      // Query WITHOUT orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('isDraft', isEqualTo: true)
          .get();
      
      // debugPrint('📖 [BListingService] Found ${snapshot.docs.length} draft documents');
      
      // Sort by updatedAt descending in memory (newest first)
      final drafts = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      
      drafts.sort((a, b) {
        final aDate = a['updatedAt'] as Timestamp?;
        final bDate = b['updatedAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate); // Descending order
      });
      
      // debugPrint('✅ [BListingService] Returning ${drafts.length} sorted drafts');
      for (var draft in drafts) {
        // debugPrint('   - ${draft['title'] ?? 'Untitled'} (ID: ${draft['id']}, step: ${draft['currentStep']}, images: ${(draft['imageUrls'] as List?)?.length ?? 0})');
      }
      
      return drafts;
    } catch (e) {
      // debugPrint('❌ [BListingService] Error fetching drafts: $e');
      return [];
    }
  }

  /// Delete draft
  Future<void> deleteDraft(String draftId) async {
    try {
      await _firestore.collection(_collectionName).doc(draftId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String listingId) async {
    try {
      await _firestore.collection(_collectionName).doc(listingId).update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail for view count
    }
  }

  /// Increment favorite count
  Future<void> incrementFavoriteCount(String listingId) async {
    try {
      await _firestore.collection(_collectionName).doc(listingId).update({
        'favoriteCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Decrement favorite count
  Future<void> decrementFavoriteCount(String listingId) async {
    try {
      await _firestore.collection(_collectionName).doc(listingId).update({
        'favoriteCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Increment comment count
  Future<void> incrementCommentCount(String listingId) async {
    try {
      await _firestore.collection(_collectionName).doc(listingId).update({
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Decrement comment count
  Future<void> decrementCommentCount(String listingId) async {
    try {
      await _firestore.collection(_collectionName).doc(listingId).update({
        'commentCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update average rating and review count
  Future<void> updateRating(String listingId, double averageRating, int reviewCount) async {
    try {
      await _firestore.collection(_collectionName).doc(listingId).update({
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}

