import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/models/listing_model.dart';
import 'package:rentease_app/backend/BListingService.dart';
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

  const AddPropertyPage({
    super.key,
    this.draftId,
    this.draftData,
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Track if we're editing a draft
  String? _currentDraftId;

  @override
  void initState() {
    super.initState();
    _currentDraftId = widget.draftId;
    
    // Load draft data if provided
    if (widget.draftData != null) {
      _loadDraftData(widget.draftData!);
    }
    
    // Add listeners to track changes
    _titleController.addListener(() => _hasUnsavedChanges = true);
    _descriptionController.addListener(() => _hasUnsavedChanges = true);
    _monthlyRentController.addListener(() => _hasUnsavedChanges = true);
    _addressController.addListener(() => _hasUnsavedChanges = true);
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
  
  void _loadDraftData(Map<String, dynamic> data) {
    setState(() {
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _propertyType = data['category'];
      _monthlyRentController.text = data['price']?.toString() ?? '';
      _depositController.text = data['deposit']?.toString() ?? '';
      _advanceController.text = data['advance']?.toString() ?? '';
      _addressController.text = data['location'] ?? '';
      _landmarkController.text = data['landmark'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _messengerController.text = data['messenger'] ?? '';
      _curfewController.text = data['curfew'] ?? '';
      _maxOccupantsController.text = data['maxOccupants']?.toString() ?? '';
      _currentStep = data['currentStep'] ?? 0;
      _availableFrom = data['availableFrom'] != null 
          ? (data['availableFrom'] as Timestamp).toDate()
          : null;
      _electricityIncluded = data['electricityIncluded'] ?? false;
      _waterIncluded = data['waterIncluded'] ?? false;
      _internetIncluded = data['internetIncluded'] ?? false;
      _privateCR = data['privateCR'] ?? false;
      _sharedCR = data['sharedCR'] ?? false;
      _kitchenAccess = data['kitchenAccess'] ?? false;
      _wifi = data['wifi'] ?? false;
      _laundry = data['laundry'] ?? false;
      _parking = data['parking'] ?? false;
      _security = data['security'] ?? false;
      _aircon = data['aircon'] ?? false;
      _petFriendly = data['petFriendly'] ?? false;
      _hasUnsavedChanges = false;
    });
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

      final remainingSlots = 18 - _images.length;
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
      _images.removeAt(index);
      if (_coverImageIndex >= _images.length && _images.isNotEmpty) {
        _coverImageIndex = 0;
      } else if (_images.isEmpty) {
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
        if (_images.isEmpty) {
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
    if (_images.isEmpty && !isDraft) {
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
      if (isDraft) {
        // Save as draft
        final draftId = await _listingService.saveDraft(
          userId: user.uid,
          draftId: _currentDraftId,
          title: _titleController.text.isNotEmpty ? _titleController.text : null,
          category: _propertyType,
          location: _addressController.text.isNotEmpty ? _addressController.text : null,
          price: double.tryParse(_monthlyRentController.text),
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
          currentStep: _currentStep,
          additionalData: {
            'deposit': _depositController.text.isNotEmpty ? double.tryParse(_depositController.text) : null,
            'advance': _advanceController.text.isNotEmpty ? double.tryParse(_advanceController.text) : null,
            'landmark': _landmarkController.text.isNotEmpty ? _landmarkController.text : null,
            'phone': _phoneController.text.isNotEmpty ? _phoneController.text : null,
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
        // Publish listing (existing logic)
        // Note: Full implementation will be added when backend is ready
        final newListing = ListingModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.isEmpty
              ? 'New Property Listing'
              : _titleController.text,
          category: _propertyType ?? 'Apartment',
          location: _addressController.text.isEmpty
              ? 'Location to be updated'
              : _addressController.text,
          price: double.tryParse(_monthlyRentController.text) ?? 0,
          ownerName: 'You',
          isOwnerVerified: true,
          imagePaths: _images.isNotEmpty
              ? _images.map((xfile) => xfile.path).toList()
              : ListingModel.getMockListings().first.imagePaths,
          description: _descriptionController.text.isEmpty
              ? 'Description will be updated soon.'
              : _descriptionController.text,
          bedrooms: 1,
          bathrooms: 1,
          area: 20,
          postedDate: DateTime.now(),
        );

        // Delete draft if it exists
        if (_currentDraftId != null) {
          await _listingService.deleteDraft(_currentDraftId!);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(
            context,
            'Property published! Showing on your home feed.',
          ),
        );

        Navigator.of(context).pop<ListingModel>(newListing);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBarUtils.buildThemedSnackBar(context, 'Error: $e'),
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
          'Add Property',
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
        onPressed: _isSubmitting ? null : () => _showPublishConfirmation(),
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
                'Publish Listing',
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
          'Publish Listing',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Are you ready to publish your property listing? You can also save it as a draft to continue later.',
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
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'save_draft'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _themeColorDark,
              side: BorderSide(color: _themeColorDark),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Save as Draft'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'publish'),
            style: FilledButton.styleFrom(
              backgroundColor: _themeColorDark,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (result == 'publish') {
      await _submitForm(isDraft: false);
    } else if (result == 'save_draft') {
      await _submitForm(isDraft: true);
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
                  });
                }
              },
              onGPSFill: () async {
                final result = await LocationPickerService.getCurrentLocation();
                
                if (result != null && !result.containsKey('error') && mounted) {
                  setState(() {
                    _addressController.text = result['address'] ?? '';
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

