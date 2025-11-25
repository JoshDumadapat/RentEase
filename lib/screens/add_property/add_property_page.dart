import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rentease_app/screens/add_property/widgets/property_media_section.dart';
import 'package:rentease_app/screens/add_property/widgets/property_basic_info_section.dart';
import 'package:rentease_app/screens/add_property/widgets/pricing_section.dart';
import 'package:rentease_app/screens/add_property/widgets/location_section.dart';
import 'package:rentease_app/screens/add_property/widgets/amenities_section.dart';
import 'package:rentease_app/screens/add_property/widgets/availability_section.dart';
import 'package:rentease_app/screens/add_property/widgets/contact_section.dart';

/// Main Add Property page for listing rental properties
/// 
/// This page follows the app's design system with:
/// - Clean, minimal UI
/// - Form validation
/// - Image upload support
/// - Dark/light mode support
/// - Responsive design
class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

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
  int? _maxOccupants;
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

  // Image management
  final List<XFile> _images = [];
  final ImagePicker _imagePicker = ImagePicker();

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

      final remainingSlots = 10 - _images.length;
      if (remainingSlots <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 10 images allowed'),
              backgroundColor: Colors.orange,
            ),
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
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
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
    });
  }

  void _reorderImage(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _images.removeAt(oldIndex);
      _images.insert(newIndex, item);
      if (_coverImageIndex == oldIndex) {
        _coverImageIndex = newIndex;
      } else if (_coverImageIndex == newIndex) {
        _coverImageIndex = oldIndex;
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
        const SnackBar(
          content: Text('Please add at least one image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_propertyType == null && !isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a property type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _uploadProgress = i / 100;
          });
        }
      }

      // TODO: Implement actual API call here
      // await PropertyService.createProperty(...);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDraft
                  ? 'Property saved as draft'
                  : 'Property published successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back or reset form
        if (!isDraft) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Property',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator when submitting
            if (_isSubmitting)
              LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Media Section
                    PropertyMediaSection(
                      images: _images,
                      coverImageIndex: _coverImageIndex,
                      onPickImages: _pickImages,
                      onRemoveImage: _removeImage,
                      onSetCoverImage: _setCoverImage,
                      onReorderImage: _reorderImage,
                    ),
                    const SizedBox(height: 32),

                    // Basic Info Section
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

                    // Pricing Section
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
                    const SizedBox(height: 32),

                    // Location Section
                    LocationSection(
                      addressController: _addressController,
                      landmarkController: _landmarkController,
                      onMapPicker: () {
                        // TODO: Implement map picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Map picker coming soon'),
                          ),
                        );
                      },
                      onGPSFill: () {
                        // TODO: Implement GPS auto-fill
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('GPS auto-fill coming soon'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Amenities Section
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
                    const SizedBox(height: 32),

                    // Availability Section
                    AvailabilitySection(
                      availableFrom: _availableFrom,
                      maxOccupantsController: _maxOccupantsController,
                      onDateSelected: _selectDate,
                      onMaxOccupantsChanged: (value) {
                        setState(() {
                          _maxOccupants = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),

                    // Contact Section
                    ContactSection(
                      phoneController: _phoneController,
                      messengerController: _messengerController,
                    ),
                    const SizedBox(height: 32),

                    // Submit Buttons
                    _buildSubmitButtons(colorScheme, textTheme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButtons(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      children: [
        // Publish Button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isSubmitting
                ? null
                : () => _submitForm(isDraft: false),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Text(
                    'Publish',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // Save as Draft Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSubmitting
                ? null
                : () => _submitForm(isDraft: true),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(color: colorScheme.outline),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save as Draft',
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

