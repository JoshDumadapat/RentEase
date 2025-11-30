import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentease_app/sign_in/sign_in_page.dart';
import 'package:rentease_app/sign_up/student_id_verification_page.dart';
import 'package:rentease_app/services/auth_service.dart';
import 'package:rentease_app/services/user_service.dart';
import 'package:rentease_app/main_app.dart';

/// Student Sign Up Page with form validation
class StudentSignUpPage extends StatefulWidget {
  final User? googleUser; // Firebase User from Google sign-in
  
  const StudentSignUpPage({super.key, this.googleUser});

  @override
  State<StudentSignUpPage> createState() => _StudentSignUpPageState();
}

class _StudentSignUpPageState extends State<StudentSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  
  String _selectedCountryCode = '+63';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Auto-fill from Google account if available
    if (widget.googleUser != null) {
      final displayName = widget.googleUser!.displayName ?? '';
      if (displayName.isNotEmpty) {
        final nameParts = displayName.split(' ');
        if (nameParts.isNotEmpty) {
          _firstNameController.text = nameParts[0];
        }
        if (nameParts.length > 1) {
          _lastNameController.text = nameParts.sublist(1).join(' ');
        }
      }
      _emailController.text = widget.googleUser!.email ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.grey[850]!,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
              surface: Colors.white,
              onSurfaceVariant: Colors.grey[600]!,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
            ),
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              headerBackgroundColor: Colors.grey[850],
              headerForegroundColor: Colors.white,
              headerHeadlineStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              headerHelpStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey[300]!,
              ),
              weekdayStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700]!,
              ),
              dayStyle: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              yearStyle: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
              rangeSelectionBackgroundColor: Colors.grey[200]!,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey[400];
                }
                return Colors.black87;
              }),
              yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey[400];
                }
                return Colors.black87;
              }),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[850],
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      if (mounted) {
        setState(() {
          _selectedDate = picked;
          _birthDateController.text =
              '${picked.day}/${picked.month}/${picked.year}';
        });
      }
    }
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, navigate to ID verification page with form data
      Navigator.of(context).push(
        _SlideUpPageRoute(
          page: StudentIDVerificationPage(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            birthday: _birthDateController.text.trim(),
            phone: _phoneNumberController.text.trim(),
            countryCode: _selectedCountryCode,
            googleUser: widget.googleUser,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image Widget at the top
          _BackgroundImageWidget(),
          // White Card Background Widget
          _WhiteCardBackgroundWidget(
            child: _StudentSignUpContentWidget(
              formKey: _formKey,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              emailController: _emailController,
              birthDateController: _birthDateController,
              phoneNumberController: _phoneNumberController,
              selectedCountryCode: _selectedCountryCode,
              selectedDate: _selectedDate,
              onCountryCodeChanged: (value) {
                if (mounted) {
                  setState(() {
                    _selectedCountryCode = value!;
                  });
                }
              },
              onDateTap: () => _selectDate(context),
              onNext: _handleNext,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for displaying the background image at the top
class _BackgroundImageWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.30;
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: imageHeight,
      child: Image.asset(
        'assets/sign_in_up/signGen.png',
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.blue[100],
            child: const Center(
              child: Icon(Icons.image, size: 100, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}

/// Widget for the white card background with rounded top corners
class _WhiteCardBackgroundWidget extends StatelessWidget {
  final Widget child;

  const _WhiteCardBackgroundWidget({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = screenHeight * 0.30;
    
    return Positioned(
      left: 0,
      right: 0,
      top: imageHeight - 55,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Widget for the student sign up content
class _StudentSignUpContentWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController birthDateController;
  final TextEditingController phoneNumberController;
  final String selectedCountryCode;
  final DateTime? selectedDate;
  final ValueChanged<String?> onCountryCodeChanged;
  final VoidCallback onDateTap;
  final VoidCallback onNext;

  const _StudentSignUpContentWidget({
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.birthDateController,
    required this.phoneNumberController,
    required this.selectedCountryCode,
    required this.selectedDate,
    required this.onCountryCodeChanged,
    required this.onDateTap,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isNarrowScreen = screenWidth < 360;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrowScreen ? 20.0 : 24.0,
          vertical: isSmallScreen ? 0.0 : 2.0,
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: isSmallScreen ? 8 : 12),
              // Back button and Logo aligned in same row
              Stack(
                alignment: Alignment.center,
                children: [
                  // Back button aligned to start (left) with negative margin
                  Positioned(
                    left: -12,
                    child: _BackButtonWidget(),
                  ),
                  // Logo centered horizontally
                  _LogoWidget(),
                ],
              ),
              SizedBox(height: isSmallScreen ? 14 : 16),
              // Title Widget
              _TitleWidget(),
              SizedBox(height: isSmallScreen ? 4 : 6),
              // Description Widget
              _DescriptionWidget(),
              SizedBox(height: isSmallScreen ? 16 : 18),
              // First Name and Last Name Row
              Row(
                children: [
                  Expanded(
                    child: _FirstNameInputWidget(
                      controller: firstNameController,
                    ),
                  ),
                  SizedBox(width: isNarrowScreen ? 8 : 12),
                  Expanded(
                    child: _LastNameInputWidget(
                      controller: lastNameController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 12 : 14),
              // Email Input Widget
              _EmailInputWidget(controller: emailController),
              SizedBox(height: isSmallScreen ? 12 : 14),
              // Birth Date Input Widget
              _BirthDateInputWidget(
                controller: birthDateController,
                onTap: onDateTap,
              ),
              SizedBox(height: isSmallScreen ? 12 : 14),
              // Phone Number Input Widget
              _PhoneNumberInputWidget(
                controller: phoneNumberController,
                selectedCountryCode: selectedCountryCode,
                onCountryCodeChanged: onCountryCodeChanged,
              ),
              SizedBox(height: isSmallScreen ? 16 : 18),
              // Next Button Widget
              _NextButtonWidget(onNext: onNext),
              SizedBox(height: isSmallScreen ? 12 : 16),
              // Sign In Link Widget
              _SignInLinkWidget(),
              SizedBox(height: isSmallScreen ? 20 : 24),
              // Divider Widget
              _DividerWidget(),
              SizedBox(height: isSmallScreen ? 20 : 24),
              // Google Sign Up Button Widget
              _GoogleSignUpButtonWidget(),
              SizedBox(height: isSmallScreen ? 8 : 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for back button
class _BackButtonWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
      onPressed: () {
        Navigator.of(context).pop();
      },
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

/// Widget for the RentEase logo
class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isNarrowScreen = screenWidth < 360;
    
    // Dynamic logo size based on screen dimensions
    double logoHeight;
    if (isVerySmallScreen) {
      logoHeight = screenHeight * 0.06; // 6% of screen height
    } else if (isSmallScreen) {
      logoHeight = screenHeight * 0.065; // 6.5% of screen height
    } else {
      logoHeight = screenHeight * 0.07; // 7% of screen height
    }
    
    // Cap the maximum size and ensure minimum size
    logoHeight = logoHeight.clamp(35.0, 45.0);
    
    // Adjust for narrow screens
    if (isNarrowScreen) {
      logoHeight *= 0.9;
    }
    
    return Center(
      child: Image.asset(
        'assets/sign_in_up/signlogo.png',
        height: logoHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.home, size: logoHeight, color: Colors.blue);
        },
      ),
    );
  }
}

/// Widget for the Sign Up as Student title
class _TitleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Text(
      'Sign Up as Student',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 20 : isSmallScreen ? 22 : 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}

/// Widget for the description text
class _DescriptionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Text(
      'Fill in your personal information to continue.',
      style: TextStyle(
        fontSize: isVerySmallScreen ? 12 : isSmallScreen ? 13 : 14,
        fontWeight: FontWeight.normal,
        color: Colors.grey[700],
        height: 1.4,
      ),
    );
  }
}

/// Widget for first name input field
class _FirstNameInputWidget extends StatelessWidget {
  final TextEditingController controller;

  const _FirstNameInputWidget({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'First Name',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 11 : isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(
            color: Colors.black87,
            fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 14 : 15,
          ),
          decoration: InputDecoration(
            hintText: 'First Name',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'First name is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// Widget for last name input field
class _LastNameInputWidget extends StatelessWidget {
  final TextEditingController controller;

  const _LastNameInputWidget({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Last Name',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 11 : isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(
            color: Colors.black87,
            fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 14 : 15,
          ),
          decoration: InputDecoration(
            hintText: 'Last Name',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Last name is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// Widget for email input field
class _EmailInputWidget extends StatelessWidget {
  final TextEditingController controller;

  const _EmailInputWidget({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 11 : isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
            color: Colors.black87,
            fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 14 : 15,
          ),
          decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// Widget for birth date input field
class _BirthDateInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const _BirthDateInputWidget({
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birth of date',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 11 : isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          style: TextStyle(
            color: Colors.black87,
            fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 14 : 15,
          ),
          decoration: InputDecoration(
            hintText: 'Birth of date',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            suffixIcon: Icon(
              Icons.calendar_today,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Birth date is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// Widget for phone number input field
class _PhoneNumberInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String selectedCountryCode;
  final ValueChanged<String?> onCountryCodeChanged;

  const _PhoneNumberInputWidget({
    required this.controller,
    required this.selectedCountryCode,
    required this.onCountryCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final isNarrowScreen = screenWidth < 360;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 11 : isSmallScreen ? 12 : 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country Code Dropdown
            Container(
              width: isNarrowScreen ? 90 : 110,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCountryCode,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  items: const [
                    DropdownMenuItem(
                      value: '+63',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🇵🇭', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('+63', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '+1',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🇺🇸', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('+1', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '+44',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🇬🇧', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('+44', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '+91',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🇮🇳', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('+91', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '+86',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🇨🇳', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('+86', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: '+81',
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🇯🇵', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text('+81', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: onCountryCodeChanged,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Phone Number Input
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 14 : 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Phone Number',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  errorStyle: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget for Next button
class _NextButtonWidget extends StatelessWidget {
  final VoidCallback onNext;

  const _NextButtonWidget({
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 40 : 42,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[850],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Next',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}

/// Widget for Sign In link
class _SignInLinkWidget extends StatefulWidget {
  @override
  State<_SignInLinkWidget> createState() => _SignInLinkWidgetState();
}

class _SignInLinkWidgetState extends State<_SignInLinkWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
          children: [
            const TextSpan(text: 'Already have an account? '),
            WidgetSpan(
              child: MouseRegion(
                onEnter: (_) {
                  if (mounted) setState(() => _isHovered = true);
                },
                onExit: (_) {
                  if (mounted) setState(() => _isHovered = false);
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      _SlideUpPageRoute(page: const SignInPage()),
                    );
                  },
                  child: Text(
                    'Sign In here.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _isHovered ? Colors.blue[800] : Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for divider
class _DividerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Or sign up with',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

/// Widget for Google Sign Up button
class _GoogleSignUpButtonWidget extends StatefulWidget {
  @override
  State<_GoogleSignUpButtonWidget> createState() => _GoogleSignUpButtonWidgetState();
}

class _GoogleSignUpButtonWidgetState extends State<_GoogleSignUpButtonWidget> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Starting Google Sign-In...');
      final userCredential = await _authService.signInWithGoogle();
      debugPrint('Google Sign-In completed, userCredential: ${userCredential != null}');
      
      if (userCredential != null && userCredential.user != null && mounted) {
        final user = userCredential.user!;
        final uid = user.uid;
        debugPrint('User authenticated: $uid');
        
        // Check if user exists in Firestore (with timeout and error handling)
        bool userExists = false;
        try {
          debugPrint('Checking if user exists in Firestore...');
          userExists = await _userService.userExists(uid).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('User exists check timed out, assuming new user');
              return false;
            },
          );
          debugPrint('User exists in Firestore: $userExists');
        } catch (e) {
          debugPrint('Error checking user exists: $e');
          // Assume new user on error - will redirect to sign up
          userExists = false;
        }
        
        if (userExists && mounted) {
          debugPrint('User exists, navigating to MainApp');
          // User already exists, navigate to main app
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainApp(),
            ),
          );
        } else if (mounted) {
          debugPrint('User does not exist, creating user record...');
          // User doesn't exist, create basic user record and redirect to sign up
          try {
            // Create a basic user record with Google account info
            final displayName = user.displayName;
            final nameParts = displayName != null ? displayName.split(' ') : <String>[];
            debugPrint('Creating user with name: $displayName, email: ${user.email}');
            await _userService.createOrUpdateUser(
              uid: uid,
              email: user.email ?? '',
              fname: nameParts.isNotEmpty ? nameParts.first : null,
              lname: nameParts.length > 1 
                  ? nameParts.sublist(1).join(' ')
                  : null,
              userType: 'student',
            );
            debugPrint('User record created successfully');
          } catch (e) {
            debugPrint('Error creating user record: $e');
            // Continue anyway - user can complete sign up manually
          }
          
          // Navigate to sign up page with Google user info to auto-fill
          if (mounted) {
            debugPrint('Navigating to StudentSignUpPage with Google user info');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => StudentSignUpPage(
                  googleUser: user,
                ),
              ),
            );
          }
        }
      } else if (mounted) {
        debugPrint('User canceled sign up or userCredential is null');
        // User canceled sign up
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error in Google Sign-Up flow: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show error message with better formatting
        final errorMessage = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 40 : 42,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignUp,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google icon from assets
                  Image.asset(
                    'assets/sign_in_up/google.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Sign up with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Custom page route with slide upward animation
class _SlideUpPageRoute extends PageRouteBuilder {
  final Widget page;

  _SlideUpPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}

