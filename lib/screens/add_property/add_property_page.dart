import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/backend/BListingService.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/services/cloudinary_service.dart';
import 'package:rentease_app/screens/add_property/widgets/property_media_section.dart';
import 'package:rentease_app/screens/add_property/widgets/property_basic_info_section.dart';
import 'package:rentease_app/screens/add_property/widgets/pricing_section.dart';
import 'package:rentease_app/screens/add_property/widgets/location_section.dart';
import 'package:rentease_app/screens/add_property/widgets/amenities_section.dart';
import 'package:rentease_app/screens/add_property/widgets/availability_section.dart';
import 'package:rentease_app/screens/add_property/widgets/contact_section.dart';
import 'package:rentease_app/screens/add_property/osm_location_picker_page.dart';
import 'package:rentease_app/services/location_picker_service.dart';
import 'package:rentease_app/utils/snackbar_utils.dart';
import 'package:latlong2/latlong.dart';

// Light blue theme constants aligned with HomePage
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorLight = Color(0xFFE5F9FF);
const Color _themeColorLight2 = Color(0xFFB3F0FF);
const Color _themeColorDark = Color(0xFF00B8E6);

/// Main Add Property page for listing rental properties
/// 
/// This page follows the app's design system with:
/// - Clean, minimal UI
/// - Form validation
/// - Image upload support
/// - Dark/light mode support
/// - Responsive design
class AddPropertyPage extends StatefulWidget {
  final String? draftId; // Optional draft ID to resume editing
  final Map<String, dynamic>? draftData; // Optional draft data to load
  final String? listingId; // Optional listing ID for edit mode
  final ListingModel? listing; // Optional listing model for edit mode

  const AddPropertyPage({
    super.key,
    this.draftId,
    this.draftData,
    this.listingId,
    this.listing,
  });

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  static const int _totalSteps = 3;
  int _currentStep = 0;

  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _depositController = TextEditingController();
  final _advanceController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messengerController = TextEditingController();
  final _curfewController = TextEditingController();
  final _maxOccupantsController = TextEditingController();

  // State variables
  String? _propertyType;
  DateTime? _availableFrom;
  int _coverImageIndex = 0;
  bool _electricityIncluded = false;
  bool _waterIncluded = false;
  bool _internetIncluded = false;
  bool _privateCR = false;
  bool _sharedCR = false;
  bool _kitchenAccess = false;
  bool _wifi = false;
  bool _laundry = false;
  bool _parking = false;
  bool _security = false;
  bool _aircon = false;
  bool _petFriendly = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  bool _hasUnsavedChanges = false;

  // Image management
  final List<XFile> _images = [];
  final ImagePicker _imagePicker = ImagePicker();
  
  // Services
  final BListingService _listingService = BListingService();
  final BUserService _userService = BUserService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Location coordinates (from map picker)
  double? _latitude;
  double? _longitude;
  
  // Track if we're editing a draft
  String? _currentDraftId;
  
  // Edit mode state
  bool _isEditMode = false;
  String? _editingListingId;
  List<String> _existingImageUrls = []; // Existing images from Firestore
  List<int> _removedImageIndexes = []; // Track which existing images to remove
  
  // User contact info from Firestore
  String? _ownerName;
  bool _isLoadingUserData = true;

  @override
  void initState() {
    super.initState();
    _currentDraftId = widget.draftId;
    
    // Check if in edit mode (from My Properties only)
    if (widget.listingId != null || widget.listing != null) {
      _isEditMode = true;
      _editingListingId = widget.listingId ?? widget.listing?.id;
      
      if (widget.listing != null) {
        _loadListingData(widget.listing!);
      } else if (widget.listingId != null) {
        _loadListingFromFirestore(widget.listingId!);
      }
    } else if (widget.draftData != null) {
      // Load draft data if provided directly
      _loadDraftData(widget.draftData!);
    } else if (widget.draftId != null) {
      // Load draft from Firestore if only draftId is provided
      _loadDraftFromFirestore(widget.draftId!);
    }
    
    // Load user contact information from Firestore
    _loadUserContactInfo();
    
    // Add listeners to track changes
    _titleController.addListener(() => _hasUnsavedChanges = true);
    _descriptionController.addListener(() => _hasUnsavedChanges = true);
    _monthlyRentController.addListener(() => _hasUnsavedChanges = true);
    _addressController.addListener(() => _hasUnsavedChanges = true);
  }
  
  /// Load user contact information from Firestore
  Future<void> _loadUserContactInfo() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingUserData = false;
        _ownerName = 'User';
      });
      return;
    }

    try {
      final userData = await _userService.getUserData(user.uid);
      
      if (userData != null && mounted) {
        // Get owner name
        final displayName = userData['displayName'] as String?;
        final fname = userData['fname'] as String?;
        final lname = userData['lname'] as String?;
        
        String ownerName;
        if (displayName != null && displayName.isNotEmpty) {
          ownerName = displayName;
        } else if (fname != null || lname != null) {
          ownerName = '${fname ?? ''} ${lname ?? ''}'.trim();
        } else {
          ownerName = user.displayName ?? user.email?.split('@')[0] ?? 'Property Owner';
        }
        
        // Get phone number
        final phone = userData['phone'] as String?;
        
        setState(() {
          _ownerName = ownerName;
          if (phone != null && phone.isNotEmpty && _phoneController.text.isEmpty) {
            // Format the phone number to 09XX XXX XXXX format
            final formattedPhone = _formatPhoneFromFirestore(phone);
            _phoneController.text = formattedPhone;
          }
          _isLoadingUserData = false;
        });
      } else {
        // Fallback if no user data
        setState(() {
          _ownerName = user.displayName ?? user.email?.split('@')[0] ?? 'Property Owner';
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [AddProperty] Error loading user contact info: $e');
      // Fallback on error
      if (mounted) {
        setState(() {
          _ownerName = user.displayName ?? user.email?.split('@')[0] ?? 'Property Owner';
          _isLoadingUserData = false;
        });
      }
    }
  }

  /// Format phone number from Firestore to 09XX XXX XXXX format
  /// Handles various formats that might be stored in Firestore
  String _formatPhoneFromFirestore(String phone) {
    // Remove all non-digit characters
    String digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // If it's 10 digits starting with 9, add leading 0
    if (digitsOnly.length == 10 && digitsOnly.startsWith('9')) {
      digitsOnly = '0$digitsOnly';
    }
    
    // If it's 11 digits but doesn't start with 09, try to fix it
    if (digitsOnly.length == 11 && !digitsOnly.startsWith('09')) {
      // If it starts with 9, add 0 at the beginning
      if (digitsOnly.startsWith('9')) {
        digitsOnly = '0$digitsOnly';
        // If that makes it 12 digits, take first 11
        if (digitsOnly.length > 11) {
          digitsOnly = digitsOnly.substring(0, 11);
        }
      }
    }
    
    // Format using the PhilippinePhoneFormatter
    return PhilippinePhoneFormatter.formatPhone(digitsOnly);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _monthlyRentController.dispose();
    _depositController.dispose();
    _advanceController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    _messengerController.dispose();
    _curfewController.dispose();
    _maxOccupantsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  /// Load draft from Firestore by ID
  Future<void> _loadDraftFromFirestore(String draftId) async {
    try {
      final draftData = await _listingService.getListing(draftId);
      if (draftData != null && mounted) {
        // Load location coordinates if available
        _loadLocationCoordinates(draftData);
        // Load draft data into form
        _loadDraftData(draftData);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Draft not found',
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [AddPropertyPage] Error loading draft: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error loading draft: ${e.toString()}',
          ),
        );
      }
    }
  }

  void _loadDraftData(Map<String, dynamic> data) {
    debugPrint('📝 [AddPropertyPage] Loading draft data: ${data.keys.toList()}');
    
    setState(() {
      _titleController.text = data['title']?.toString() ?? '';
      _descriptionController.text = data['description']?.toString() ?? '';
      _propertyType = data['category']?.toString();
      _bedroomsController.text = data['bedrooms']?.toString() ?? '';
      _bathroomsController.text = data['bathrooms']?.toString() ?? '';
      _areaController.text = data['area']?.toString() ?? '';
      _monthlyRentController.text = data['price']?.toString() ?? '';
      _depositController.text = data['deposit']?.toString() ?? '';
      _advanceController.text = data['advance']?.toString() ?? '';
      _addressController.text = data['location']?.toString() ?? '';
      _landmarkController.text = data['landmark']?.toString() ?? '';
      _phoneController.text = data['phone']?.toString() ?? '';
      _messengerController.text = data['messenger']?.toString() ?? '';
      _curfewController.text = data['curfew']?.toString() ?? '';
      _maxOccupantsController.text = data['maxOccupants']?.toString() ?? '';
      _currentStep = (data['currentStep'] as num?)?.toInt() ?? 0;
      
      // Parse availableFrom date
      if (data['availableFrom'] != null) {
        if (data['availableFrom'] is Timestamp) {
          _availableFrom = (data['availableFrom'] as Timestamp).toDate();
        } else if (data['availableFrom'] is DateTime) {
          _availableFrom = data['availableFrom'] as DateTime;
        }
      } else {
        _availableFrom = null;
      }
      
      // Load amenities
      _electricityIncluded = data['electricityIncluded'] as bool? ?? false;
      _waterIncluded = data['waterIncluded'] as bool? ?? false;
      _internetIncluded = data['internetIncluded'] as bool? ?? false;
      _privateCR = data['privateCR'] as bool? ?? false;
      _sharedCR = data['sharedCR'] as bool? ?? false;
      _kitchenAccess = data['kitchenAccess'] as bool? ?? false;
      _wifi = data['wifi'] as bool? ?? false;
      _laundry = data['laundry'] as bool? ?? false;
      _parking = data['parking'] as bool? ?? false;
      _security = data['security'] as bool? ?? false;
      _aircon = data['aircon'] as bool? ?? false;
      _petFriendly = data['petFriendly'] as bool? ?? false;
      
      // Load existing images if available
      if (data['imageUrls'] != null && data['imageUrls'] is List) {
        _existingImageUrls = List<String>.from(data['imageUrls'] as List);
      }
      
      _hasUnsavedChanges = false;
    });
    
    // Scroll to top and navigate to the saved step after a brief delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    debugPrint('✅ [AddPropertyPage] Draft loaded - Step: $_currentStep, Title: ${_titleController.text}');
  }

  /// Load listing from Firestore by ID
  Future<void> _loadListingFromFirestore(String listingId) async {
    try {
      final listingData = await _listingService.getListing(listingId);
      if (listingData != null) {
        // Load location coordinates if available
        _loadLocationCoordinates(listingData);
        
        final listing = ListingModel.fromMap({'id': listingId, ...listingData});
        _loadListingData(listing);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error loading property: $e'),
        );
      }
    }
  }

  /// Load listing data into form fields
  void _loadListingData(ListingModel listing) {
    setState(() {
      // Basic info
      _titleController.text = listing.title;
      _descriptionController.text = listing.description;
      _propertyType = listing.category;
      _bedroomsController.text = listing.bedrooms.toString();
      _bathroomsController.text = listing.bathrooms.toString();
      _areaController.text = listing.area.toString();
      _monthlyRentController.text = listing.price.toString();
      
      // Pricing
      _depositController.text = listing.deposit?.toString() ?? '';
      _advanceController.text = listing.advance?.toString() ?? '';
      
      // Location
      _addressController.text = listing.location;
      _landmarkController.text = listing.landmark ?? '';
      // Note: latitude/longitude are stored separately, loaded from Firestore data if needed
      
      // Contact
      _phoneController.text = listing.phone ?? '';
      _messengerController.text = listing.messenger ?? '';
      
      // Availability
      _availableFrom = listing.availableFrom;
      _curfewController.text = listing.curfew ?? '';
      _maxOccupantsController.text = listing.maxOccupants?.toString() ?? '';
      
      // Amenities
      _electricityIncluded = listing.electricityIncluded;
      _waterIncluded = listing.waterIncluded;
      _internetIncluded = listing.internetIncluded;
      _privateCR = listing.privateCR;
      _sharedCR = listing.sharedCR;
      _kitchenAccess = listing.kitchenAccess;
      _wifi = listing.wifi;
      _laundry = listing.laundry;
      _parking = listing.parking;
      _security = listing.security;
      _aircon = listing.aircon;
      _petFriendly = listing.petFriendly;
      
      // Images - store existing URLs separately, clear new images
      _existingImageUrls = List<String>.from(listing.imagePaths);
      _images.clear(); // Start with empty for new images
      _removedImageIndexes = [];
      _coverImageIndex = 0;
      
      // Debug: Log image URLs
      debugPrint('📸 [AddProperty] Loaded ${_existingImageUrls.length} existing images for edit:');
      for (int i = 0; i < _existingImageUrls.length; i++) {
        debugPrint('   [$i] ${_existingImageUrls[i]}');
      }
      
      _hasUnsavedChanges = false;
    });
  }

  /// Load latitude/longitude from Firestore data (called separately if needed)
  void _loadLocationCoordinates(Map<String, dynamic> data) {
    if (data['latitude'] != null) {
      _latitude = (data['latitude'] as num).toDouble();
    }
    if (data['longitude'] != null) {
      _longitude = (data['longitude'] as num).toDouble();
    }
  }
  
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) {
      return true;
    }
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with title and X button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Discard Changes?',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        icon: Icon(
                          Icons.close,
                          color: textColor.withOpacity(0.7),
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'You have unsaved changes. What would you like to do?',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons in one row
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // Save as Draft button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, 'save_draft'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _themeColorDark,
                            side: BorderSide(color: _themeColorDark, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save as Draft',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Discard button
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context, 'discard'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Discard',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    
    if (result == 'save_draft') {
      await _submitForm(isDraft: true);
      return true; // Allow navigation after saving draft
    } else if (result == 'discard') {
      return true; // Allow navigation to discard
    }
    
    return false; // Cancel - don't navigate
  }

  Future<void> _pickImages() async {
    try {
      // Show source selection dialog
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add Photos'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose an option:'),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Calculate remaining slots accounting for existing images
      final existingCount = _existingImageUrls.length - _removedImageIndexes.length;
      final totalCurrentImages = existingCount + _images.length;
      final remainingSlots = 18 - totalCurrentImages;
      if (remainingSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(context, 'Maximum 18 images allowed'),
          );
        }
        return;
      }

      // Try pickMultiImage first (available in newer versions)
      List<XFile> pickedImages = [];
      try {
        pickedImages = await _imagePicker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } catch (_) {
        // If pickMultiImage is not available, pick single image
        if (source == ImageSource.gallery) {
          final image = await _imagePicker.pickImage(
            source: source,
            imageQuality: 85,
            maxWidth: 1920,
            maxHeight: 1920,
          );
          if (image != null) {
            pickedImages = [image];
          }
        } else {
          // Camera only supports single image
          final image = await _imagePicker.pickImage(
            source: source,
            imageQuality: 85,
            maxWidth: 1920,
            maxHeight: 1920,
          );
          if (image != null) {
            pickedImages = [image];
          }
        }
      }

      if (pickedImages.isNotEmpty) {
        setState(() {
          _images.addAll(
            pickedImages.take(remainingSlots),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error picking images: $e'),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      final totalExisting = _existingImageUrls.length;
      
      if (index < totalExisting) {
        // Removing existing image - track it for removal
        if (!_removedImageIndexes.contains(index)) {
          _removedImageIndexes.add(index);
        }
        
        // Adjust cover image index if needed
        if (_coverImageIndex == index && (_existingImageUrls.length + _images.length) > 1) {
          // Find next available image
          int nextIndex = 0;
          for (int i = 0; i < totalExisting + _images.length; i++) {
            if (i != index) {
              nextIndex = i;
              break;
            }
          }
          _coverImageIndex = nextIndex;
        } else if (_coverImageIndex > index) {
          _coverImageIndex--;
        }
      } else {
        // Removing newly added image
        final newImageIndex = index - totalExisting;
        _images.removeAt(newImageIndex);
        
        // Adjust cover image index
        final totalImages = _existingImageUrls.length + _images.length;
        if (_coverImageIndex >= totalImages && totalImages > 0) {
          _coverImageIndex = totalImages - 1;
        } else if (_coverImageIndex == index && totalImages > 0) {
          _coverImageIndex = (totalImages - 1).clamp(0, totalImages - 1);
        }
      }
      
      // If no images left, reset cover index
      final remainingExisting = _existingImageUrls.length - _removedImageIndexes.length;
      if (remainingExisting == 0 && _images.isEmpty) {
        _coverImageIndex = 0;
      }
    });
  }

  void _setCoverImage(int index) {
    setState(() {
      _coverImageIndex = index;
      // Move cover image to first position
      if (index > 0 && index < _images.length) {
        final coverImage = _images.removeAt(index);
        _images.insert(0, coverImage);
        _coverImageIndex = 0;
      }
    });
  }

  /// Validate current step before proceeding to next step
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Step 1: Details - Validate images, title, description, property type
        // In edit mode, check both existing and new images
        // Calculate remaining existing images (not removed)
        int remainingExistingImages = 0;
        if (_isEditMode) {
          for (int i = 0; i < _existingImageUrls.length; i++) {
            if (!_removedImageIndexes.contains(i)) {
              remainingExistingImages++;
            }
          }
        }
        final totalImages = _isEditMode 
            ? (remainingExistingImages + _images.length)
            : _images.length;
        
        if (totalImages == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(context, 'Please add at least one photo'),
          );
          return false;
        }
        if (!_formKey.currentState!.validate()) {
          // Scroll to first error
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          return false;
        }
        if (_propertyType == null || _propertyType!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(context, 'Please select a property type'),
          );
          return false;
        }
        return true;
      case 1:
        // Step 2: Pricing & Location - Validate monthly rent and address
        if (!_formKey.currentState!.validate()) {
          // Scroll to first error
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          return false;
        }
        return true;
      case 2:
        // Step 3: Amenities & Contact - Validate available from date (required)
        if (_availableFrom == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBarUtils.buildThemedSnackBar(context, 'Please select available from date'),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _reorderImage(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex == newIndex) return;
      
      // Adjust newIndex if moving within list
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
      
      // Update cover index
      if (_coverImageIndex == oldIndex) {
        _coverImageIndex = newIndex;
      } else if (_coverImageIndex == newIndex && oldIndex < newIndex) {
        _coverImageIndex = newIndex - 1;
      } else if (_coverImageIndex == newIndex && oldIndex > newIndex) {
        _coverImageIndex = newIndex + 1;
      } else if (_coverImageIndex > oldIndex && _coverImageIndex <= newIndex) {
        _coverImageIndex -= 1;
      } else if (_coverImageIndex < oldIndex && _coverImageIndex >= newIndex) {
        _coverImageIndex += 1;
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _availableFrom ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _availableFrom = picked;
      });
    }
  }

  Future<void> _submitForm({required bool isDraft}) async {
    if (!isDraft && !_formKey.currentState!.validate()) {
      // Scroll to first error
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    // Validate required fields even for draft
    // For edit mode, we allow existing images, so check total images (existing + new)
    final totalImages = _isEditMode ? (_existingImageUrls.length + _images.length) : _images.length;
    if (totalImages == 0 && !isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Please add at least one image'),
      );
      return;
    }

    if (_propertyType == null && !isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Please select a property type'),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Please sign in to continue'),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      if (_isEditMode && !isDraft) {
        // UPDATE EXISTING LISTING
        await _updateListing();
      } else if (isDraft) {
        // Save as draft
        // Collect existing image URLs (excluding removed ones)
        final List<String> draftImageUrls = [];
        for (int i = 0; i < _existingImageUrls.length; i++) {
          if (!_removedImageIndexes.contains(i)) {
            draftImageUrls.add(_existingImageUrls[i]);
          }
        }
        
        debugPrint('💾 [AddPropertyPage] Saving draft with ${draftImageUrls.length} existing images');
        debugPrint('💾 [AddPropertyPage] Draft data - Step: $_currentStep, Title: ${_titleController.text}');
        
        final draftId = await _listingService.saveDraft(
          userId: user.uid,
          draftId: _currentDraftId,
          title: _titleController.text.isNotEmpty ? _titleController.text : null,
          category: _propertyType,
          location: _addressController.text.isNotEmpty ? _addressController.text : null,
          price: double.tryParse(_monthlyRentController.text),
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          imageUrls: draftImageUrls.isNotEmpty ? draftImageUrls : null,
          currentStep: _currentStep,
          additionalData: {
            'bedrooms': _bedroomsController.text.isNotEmpty ? int.tryParse(_bedroomsController.text) : null,
            'bathrooms': _bathroomsController.text.isNotEmpty ? int.tryParse(_bathroomsController.text) : null,
            'area': _areaController.text.isNotEmpty ? double.tryParse(_areaController.text) : null,
            'deposit': _depositController.text.isNotEmpty ? double.tryParse(_depositController.text) : null,
            'advance': _advanceController.text.isNotEmpty ? double.tryParse(_advanceController.text) : null,
            'landmark': _landmarkController.text.isNotEmpty ? _landmarkController.text : null,
            'phone': _phoneController.text.isNotEmpty 
                ? PhilippinePhoneFormatter.getDigitsOnly(_phoneController.text) 
                : null,
            'messenger': _messengerController.text.isNotEmpty ? _messengerController.text : null,
            'curfew': _curfewController.text.isNotEmpty ? _curfewController.text : null,
            'maxOccupants': _maxOccupantsController.text.isNotEmpty ? int.tryParse(_maxOccupantsController.text) : null,
            'availableFrom': _availableFrom != null ? Timestamp.fromDate(_availableFrom!) : null,
            'electricityIncluded': _electricityIncluded,
            'waterIncluded': _waterIncluded,
            'internetIncluded': _internetIncluded,
            'privateCR': _privateCR,
            'sharedCR': _sharedCR,
            'kitchenAccess': _kitchenAccess,
            'wifi': _wifi,
            'laundry': _laundry,
            'parking': _parking,
            'security': _security,
            'aircon': _aircon,
            'petFriendly': _petFriendly,
          },
        );
        
        debugPrint('✅ [AddPropertyPage] Draft saved with ID: $draftId');
        
        _currentDraftId = draftId;
        _hasUnsavedChanges = false;
        
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Property saved as draft',
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Publish listing - Upload images first
        setState(() => _uploadProgress = 0.1);
        
        List<String> imageUrls = [];
        if (_images.isNotEmpty) {
          final totalImages = _images.length;
          for (int i = 0; i < _images.length; i++) {
            try {
              final imageUrl = await _cloudinaryService.uploadImage(
                file: XFile(_images[i].path),
                uploadType: 'listing',
              );
              if (imageUrl != null) {
                imageUrls.add(imageUrl);
              }
              setState(() => _uploadProgress = 0.1 + (0.7 * (i + 1) / totalImages));
            } catch (e) {
              debugPrint('Error uploading image ${i + 1}: $e');
            }
          }
        }

        if (imageUrls.isEmpty) {
          throw Exception('Failed to upload images. Please try again.');
        }

        // Get user data for owner info
        final userData = await _userService.getUserData(user.uid);
        final ownerName = (userData?['displayName'] as String?) ?? 
                        ((userData?['fname'] != null && userData?['lname'] != null)
                            ? '${userData!['fname']} ${userData['lname']}'.trim()
                            : (user.displayName ?? 
                            user.email?.split('@')[0] ?? 
                            'Property Owner'));
        final isOwnerVerified = userData?['isVerified'] as bool? ?? false;

        setState(() => _uploadProgress = 0.9);

        // Create listing in Firestore
        final listingId = await _listingService.createListing(
          userId: user.uid,
          ownerName: ownerName,
          isOwnerVerified: isOwnerVerified,
          title: _titleController.text.trim(),
          category: _propertyType ?? 'Apartment',
          location: _addressController.text.trim(),
          price: double.tryParse(_monthlyRentController.text) ?? 0.0,
          description: _descriptionController.text.trim(),
          imageUrls: imageUrls,
          bedrooms: _bedroomsController.text.isNotEmpty 
              ? int.tryParse(_bedroomsController.text) 
              : null,
          bathrooms: _bathroomsController.text.isNotEmpty 
              ? int.tryParse(_bathroomsController.text) 
              : null,
          area: _areaController.text.isNotEmpty 
              ? double.tryParse(_areaController.text) 
              : null,
          deposit: _depositController.text.isNotEmpty 
              ? double.tryParse(_depositController.text) 
              : null,
          advance: _advanceController.text.isNotEmpty 
              ? double.tryParse(_advanceController.text) 
              : null,
          landmark: _landmarkController.text.trim().isNotEmpty 
              ? _landmarkController.text.trim() 
              : null,
          latitude: _latitude,
          longitude: _longitude,
          phone: _phoneController.text.trim().isNotEmpty
              ? PhilippinePhoneFormatter.getDigitsOnly(_phoneController.text.trim())
              : null,
          messenger: _messengerController.text.trim().isNotEmpty 
              ? _messengerController.text.trim() 
              : null,
          availableFrom: _availableFrom,
          curfew: _curfewController.text.trim().isNotEmpty 
              ? _curfewController.text.trim() 
              : null,
          maxOccupants: _maxOccupantsController.text.isNotEmpty 
              ? int.tryParse(_maxOccupantsController.text) 
              : null,
          electricityIncluded: _electricityIncluded,
          waterIncluded: _waterIncluded,
          internetIncluded: _internetIncluded,
          privateCR: _privateCR,
          sharedCR: _sharedCR,
          kitchenAccess: _kitchenAccess,
          wifi: _wifi,
          laundry: _laundry,
          parking: _parking,
          security: _security,
          aircon: _aircon,
          petFriendly: _petFriendly,
          isDraft: false,
        );

        // Delete draft if it exists
        if (_currentDraftId != null) {
          await _listingService.deleteDraft(_currentDraftId!);
        }

        setState(() => _uploadProgress = 1.0);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Property published successfully!',
            duration: const Duration(seconds: 3),
          ),
        );

        // Return the listing ID (UI will handle navigation)
        Navigator.of(context).pop(listingId);
      }
    } catch (e, stackTrace) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ [AddProperty] Error publishing listing:');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Check if it's a Firestore permission error
      if (e.toString().contains('permission-denied')) {
        debugPrint('🔒 PERMISSION DENIED ERROR DETECTED');
        debugPrint('   This usually means:');
        debugPrint('   1. User is not authenticated');
        debugPrint('   2. Firestore rules are blocking the operation');
        debugPrint('   3. userId does not match auth.uid');
        final user = _auth.currentUser;
        debugPrint('   Current user: ${user?.uid ?? 'NULL'}');
        debugPrint('   User email: ${user?.email ?? 'NULL'}');
        debugPrint('   User authenticated: ${user != null}');
      }
      
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (mounted) {
        String errorMessage = 'Error publishing property';
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Permission denied. Please check your authentication and try again.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            errorMessage,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  /// Update existing listing
  Future<void> _updateListing() async {
    final user = _auth.currentUser;
    if (user == null || _editingListingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Please sign in to continue'),
      );
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }

    // Ensure at least one image (existing or new)
    // Calculate final image count after accounting for removed images
    int remainingExistingImages = 0;
    for (int i = 0; i < _existingImageUrls.length; i++) {
      if (!_removedImageIndexes.contains(i)) {
        remainingExistingImages++;
      }
    }
    final finalImageCount = remainingExistingImages + _images.length;
    if (finalImageCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Please add at least one image'),
      );
      return;
    }

    if (_propertyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBarUtils.buildThemedSnackBar(context, 'Please select a property type'),
      );
      return;
    }

    try {
      // Step 1: Upload new images (if any)
      setState(() => _uploadProgress = 0.1);
      List<String> newImageUrls = [];
      if (_images.isNotEmpty) {
        final totalImages = _images.length;
        for (int i = 0; i < _images.length; i++) {
          try {
            final imageUrl = await _cloudinaryService.uploadImage(
              file: XFile(_images[i].path),
              uploadType: 'listing',
            );
            if (imageUrl != null) {
              newImageUrls.add(imageUrl);
            }
            setState(() => _uploadProgress = 0.1 + (0.6 * (i + 1) / totalImages));
          } catch (e) {
            debugPrint('Error uploading image ${i + 1}: $e');
          }
        }
      }

      // Step 2: Combine existing (non-removed) images with new images
      final finalImageUrls = <String>[];
      
      // Add existing images that weren't removed (by index)
      for (int i = 0; i < _existingImageUrls.length; i++) {
        if (!_removedImageIndexes.contains(i)) {
          finalImageUrls.add(_existingImageUrls[i]);
        }
      }
      
      // Add new uploaded images
      finalImageUrls.addAll(newImageUrls);

      if (finalImageUrls.isEmpty) {
        throw Exception('At least one image is required');
      }

      setState(() => _uploadProgress = 0.8);

      // Step 3: Prepare update data
      final updateData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'category': _propertyType ?? 'Apartment',
        'location': _addressController.text.trim(),
        'price': double.tryParse(_monthlyRentController.text) ?? 0.0,
        'description': _descriptionController.text.trim(),
        'imageUrls': finalImageUrls,
        
        // Optional fields - only include if they have values
        if (_bedroomsController.text.isNotEmpty)
          'bedrooms': int.tryParse(_bedroomsController.text),
        if (_bathroomsController.text.isNotEmpty)
          'bathrooms': int.tryParse(_bathroomsController.text),
        if (_areaController.text.isNotEmpty)
          'area': double.tryParse(_areaController.text),
        if (_depositController.text.isNotEmpty)
          'deposit': double.tryParse(_depositController.text),
        if (_advanceController.text.isNotEmpty)
          'advance': double.tryParse(_advanceController.text),
        if (_landmarkController.text.trim().isNotEmpty)
          'landmark': _landmarkController.text.trim(),
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
        if (_phoneController.text.trim().isNotEmpty)
          'phone': PhilippinePhoneFormatter.getDigitsOnly(_phoneController.text.trim()),
        if (_messengerController.text.trim().isNotEmpty)
          'messenger': _messengerController.text.trim(),
        if (_availableFrom != null)
          'availableFrom': Timestamp.fromDate(_availableFrom!),
        if (_curfewController.text.trim().isNotEmpty)
          'curfew': _curfewController.text.trim(),
        if (_maxOccupantsController.text.isNotEmpty)
          'maxOccupants': int.tryParse(_maxOccupantsController.text),
        
        // Amenities (always include, they're booleans)
        'electricityIncluded': _electricityIncluded,
        'waterIncluded': _waterIncluded,
        'internetIncluded': _internetIncluded,
        'privateCR': _privateCR,
        'sharedCR': _sharedCR,
        'kitchenAccess': _kitchenAccess,
        'wifi': _wifi,
        'laundry': _laundry,
        'parking': _parking,
        'security': _security,
        'aircon': _aircon,
        'petFriendly': _petFriendly,
      };

      // Step 4: Update in Firestore
      setState(() => _uploadProgress = 0.9);
      await _listingService.updateListing(_editingListingId!, updateData);

      setState(() => _uploadProgress = 1.0);
      _hasUnsavedChanges = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Property updated successfully',
            duration: const Duration(seconds: 3),
          ),
        );

        // Return the listing ID so parent can refresh
        Navigator.of(context).pop(_editingListingId);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AddProperty] Error updating listing: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Error updating property: ${e.toString()}',
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (await _onWillPop()) {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
          onPressed: () async {
            if (await _onWillPop()) {
              if (mounted) Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          _isEditMode ? 'Edit Property' : 'Add Property',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            primary: _themeColorDark,
            secondary: _themeColor,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: _themeColorLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _themeColorLight2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _themeColorLight2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _themeColorDark, width: 1.5),
            ),
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Progress indicator when submitting
              if (_isSubmitting)
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_themeColorDark),
                ),
              // Step progress indicator (custom horizontal stepper)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: _buildStepHeader(colorScheme),
              ),
              // Scrollable form content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildStepContent(colorScheme, textTheme),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSubmitButtons(ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isSubmitting ? null : () => _isEditMode ? _submitForm(isDraft: false) : _showPublishConfirmation(),
        style: FilledButton.styleFrom(
          backgroundColor: _themeColorDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isEditMode ? 'Update Property' : 'Publish Listing',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _showPublishConfirmation() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          _isEditMode ? 'Update Property' : 'Publish Listing',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          _isEditMode 
            ? 'Are you ready to update your property listing?'
            : 'Are you ready to publish your property listing?',
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(
              'Cancel',
              style: TextStyle(color: textColor),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _isEditMode ? 'update' : 'publish'),
            style: FilledButton.styleFrom(
              backgroundColor: _themeColorDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(_isEditMode ? 'Update' : 'Publish'),
          ),
        ],
      ),
    );

    if (result == 'publish' || result == 'update') {
      await _submitForm(isDraft: false);
    }
    // If result is 'cancel' or null, do nothing
  }

  /// Builds the full step header matching the reference design:
  /// horizontal line with circular step indicators and labels underneath.
  Widget _buildStepHeader(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Circles + connecting line
        SizedBox(
          height: 40,
          child: Row(
            children: List.generate(_totalSteps * 2 - 1, (index) {
              final isCircle = index.isEven;
              if (isCircle) {
                final stepIndex = index ~/ 2;
                return _buildStepCircle(stepIndex, colorScheme);
              } else {
                final lineIndex = (index - 1) ~/ 2;
                final isCompletedLine = lineIndex < _currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isCompletedLine
                        ? _themeColor
                        : colorScheme.surfaceContainerHighest,
                  ),
                );
              }
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Only show text for current step
            Expanded(child: _StepLabelText('Details', 0)),
            Expanded(child: _StepLabelText('Pricing & Location', 1)),
            Expanded(child: _StepLabelText('Amenities & Contact', 2)),
          ],
        ),
      ],
    );
  }

  Widget _buildStepCircle(int stepIndex, ColorScheme colorScheme) {
    final bool isActive = stepIndex == _currentStep;
    final bool isCompleted = stepIndex < _currentStep;

    Color backgroundColor;
    Color borderColor;
    Widget? child;

    if (isCompleted) {
      // Completed: solid light blue with checkmark
      backgroundColor = _themeColor;
      borderColor = _themeColor;
      child = const Icon(
        Icons.check,
        size: 16,
        color: Colors.white,
      );
    } else if (isActive) {
      // Current: solid lighter blue with step number
      backgroundColor = _themeColorLight2;
      borderColor = _themeColor;
      child = Text(
        '${stepIndex + 1}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _themeColorDark,
              fontWeight: FontWeight.w700,
            ),
      );
    } else {
      // Upcoming: neutral grey circle
      backgroundColor = colorScheme.surfaceContainerHighest;
      borderColor = colorScheme.outlineVariant;
      child = Text(
        '${stepIndex + 1}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildStepContent(
      ColorScheme colorScheme, TextTheme textTheme) {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            PropertyMediaSection(
              images: _images,
              existingImageUrls: _isEditMode ? _existingImageUrls : null,
              removedImageIndexes: _isEditMode ? _removedImageIndexes : null,
              coverImageIndex: _coverImageIndex,
              onPickImages: _pickImages,
              onRemoveImage: _removeImage,
              onSetCoverImage: _setCoverImage,
              onReorderImage: _reorderImage,
            ),
            const SizedBox(height: 24),
            PropertyBasicInfoSection(
              titleController: _titleController,
              descriptionController: _descriptionController,
              bedroomsController: _bedroomsController,
              bathroomsController: _bathroomsController,
              areaController: _areaController,
              propertyType: _propertyType,
              onPropertyTypeChanged: (type) {
                setState(() {
                  _propertyType = type;
                });
              },
            ),
            const SizedBox(height: 32),
            _buildStepNavigation(colorScheme, textTheme),
            const SizedBox(height: 24),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            PricingSection(
              monthlyRentController: _monthlyRentController,
              depositController: _depositController,
              advanceController: _advanceController,
              electricityIncluded: _electricityIncluded,
              waterIncluded: _waterIncluded,
              internetIncluded: _internetIncluded,
              onElectricityChanged: (value) {
                setState(() {
                  _electricityIncluded = value;
                });
              },
              onWaterChanged: (value) {
                setState(() {
                  _waterIncluded = value;
                });
              },
              onInternetChanged: (value) {
                setState(() {
                  _internetIncluded = value;
                });
              },
            ),
            const SizedBox(height: 24),
            LocationSection(
              addressController: _addressController,
              landmarkController: _landmarkController,
              onMapPicker: () async {
                final result = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OSMLocationPickerPage(
                      initialAddress: _addressController.text,
                    ),
                  ),
                );
                
                if (result != null && mounted) {
                  setState(() {
                    _addressController.text = result['address'] ?? '';
                    _latitude = result['latitude'] as double?;
                    _longitude = result['longitude'] as double?;
                  });
                }
              },
              onGPSFill: () async {
                final result = await LocationPickerService.getCurrentLocation();
                
                if (result != null && !result.containsKey('error') && mounted) {
                  setState(() {
                    _addressController.text = result['address'] ?? '';
                    _latitude = result['latitude'] as double?;
                    _longitude = result['longitude'] as double?;
                  });
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBarUtils.buildThemedSnackBar(
                      context,
                      result?['error'] ?? 'Failed to get location',
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            _buildStepNavigation(colorScheme, textTheme),
            const SizedBox(height: 24),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            AmenitiesSection(
              privateCR: _privateCR,
              sharedCR: _sharedCR,
              kitchenAccess: _kitchenAccess,
              wifi: _wifi,
              laundry: _laundry,
              parking: _parking,
              security: _security,
              aircon: _aircon,
              petFriendly: _petFriendly,
              curfewController: _curfewController,
              onPrivateCRChanged: (value) {
                setState(() {
                  _privateCR = value;
                });
              },
              onSharedCRChanged: (value) {
                setState(() {
                  _sharedCR = value;
                });
              },
              onKitchenAccessChanged: (value) {
                setState(() {
                  _kitchenAccess = value;
                });
              },
              onWifiChanged: (value) {
                setState(() {
                  _wifi = value;
                });
              },
              onLaundryChanged: (value) {
                setState(() {
                  _laundry = value;
                });
              },
              onParkingChanged: (value) {
                setState(() {
                  _parking = value;
                });
              },
              onSecurityChanged: (value) {
                setState(() {
                  _security = value;
                });
              },
              onAirconChanged: (value) {
                setState(() {
                  _aircon = value;
                });
              },
              onPetFriendlyChanged: (value) {
                setState(() {
                  _petFriendly = value;
                });
              },
            ),
            const SizedBox(height: 24),
            AvailabilitySection(
              availableFrom: _availableFrom,
              maxOccupantsController: _maxOccupantsController,
              onDateSelected: _selectDate,
              onMaxOccupantsChanged: (value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 24),
            ContactSection(
              phoneController: _phoneController,
              messengerController: _messengerController,
              ownerName: _ownerName,
            ),
            const SizedBox(height: 32),
            _buildStepNavigation(colorScheme, textTheme, isFinalStep: true),
            const SizedBox(height: 24),
          ],
        );
    }
  }

  Widget _buildStepNavigation(
    ColorScheme colorScheme,
    TextTheme textTheme, {
    bool isFinalStep = false,
  }) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      setState(() {
                        _currentStep =
                            (_currentStep - 1).clamp(0, _totalSteps);
                      });
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: _themeColorDark,
                side: const BorderSide(color: _themeColorLight2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Back'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          child: isFinalStep
              ? _buildSubmitButtons(colorScheme, textTheme)
              : FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          // Validate current step before proceeding
                          if (!_validateCurrentStep()) {
                            return;
                          }
                          setState(() {
                            _currentStep =
                                (_currentStep + 1).clamp(0, _totalSteps - 1);
                          });
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _themeColorDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StepLabelText extends StatelessWidget {
  final String label;
  final int stepIndex;

  const _StepLabelText(this.label, this.stepIndex);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state =
        context.findAncestorStateOfType<_AddPropertyPageState>();
    final currentStep = state?._currentStep ?? 0;
    const totalSteps = _AddPropertyPageState._totalSteps;

    final isActive = stepIndex == currentStep;
    final isCompleted = stepIndex < currentStep;
    final ColorScheme colorScheme = theme.colorScheme;

    Color textColor;
    FontWeight fontWeight;

    if (isActive) {
      textColor = _themeColorDark;
      fontWeight = FontWeight.w700;
    } else if (isCompleted) {
      textColor = colorScheme.onSurfaceVariant;
      fontWeight = FontWeight.w600;
    } else {
      textColor = colorScheme.onSurfaceVariant;
      fontWeight = FontWeight.w400;
    }

    TextAlign textAlign;
    if (stepIndex == 0) {
      textAlign = TextAlign.left;
    } else if (stepIndex == totalSteps - 1) {
      textAlign = TextAlign.right;
    } else {
      textAlign = TextAlign.center;
    }

    // Only show text if it's the current step
    if (!isActive) {
      return const SizedBox.shrink();
    }

    return Text(
      label,
      textAlign: textAlign,
      style: theme.textTheme.labelMedium?.copyWith(
        color: textColor,
        fontWeight: fontWeight,
      ),
    );
  }
}

