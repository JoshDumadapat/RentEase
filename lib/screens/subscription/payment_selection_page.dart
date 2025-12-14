import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/backend/BUserService.dart';
import 'package:rentease_app/backend/BBankService.dart';
import 'package:rentease_app/models/bank_model.dart';
import 'package:rentease_app/widgets/confetti_widget.dart';

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);
const Color _themeColorLight = Color(0xFFE5F9FF);

/// Payment Selection Page
/// 
/// Allows users to select their preferred payment method.
class PaymentSelectionPage extends StatelessWidget {
  final String planName;
  final String price;
  final String planId;

  const PaymentSelectionPage({
    super.key,
    required this.planName,
    required this.price,
    required this.planId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Select Payment Method',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plan Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _themeColorDark,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.verified,
                    color: _themeColorDark,
                    size: 32,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Choose Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // GCash
            _PaymentMethodCard(
              isDark: isDark,
              icon: Icons.account_balance_wallet,
              title: 'GCash',
              subtitle: 'Pay using GCash wallet',
              color: const Color(0xFF007BFF),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentProcessingPage(
                      planName: planName,
                      price: price,
                      planId: planId,
                      paymentMethod: 'GCash',
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // PayMaya
            _PaymentMethodCard(
              isDark: isDark,
              icon: Icons.payment,
              title: 'PayMaya',
              subtitle: 'Pay using PayMaya wallet',
              color: const Color(0xFF00D4AA),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentProcessingPage(
                      planName: planName,
                      price: price,
                      planId: planId,
                      paymentMethod: 'PayMaya',
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Bank Transfer
            _PaymentMethodCard(
              isDark: isDark,
              icon: Icons.account_balance,
              title: 'Bank Transfer',
              subtitle: 'Pay via bank deposit or transfer',
              color: const Color(0xFF6C757D),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentProcessingPage(
                      planName: planName,
                      price: price,
                      planId: planId,
                      paymentMethod: 'Bank Transfer',
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // ePay
            _PaymentMethodCard(
              isDark: isDark,
              icon: Icons.credit_card,
              title: 'ePay',
              subtitle: 'Pay using ePay online',
              color: const Color(0xFF28A745),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentProcessingPage(
                      planName: planName,
                      price: price,
                      planId: planId,
                      paymentMethod: 'ePay',
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PaymentMethodCard({
    required this.isDark,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Payment Processing Page
/// 
/// Mock payment processing screen with forms for different payment methods.
class PaymentProcessingPage extends StatefulWidget {
  final String planName;
  final String price;
  final String planId;
  final String paymentMethod;

  const PaymentProcessingPage({
    super.key,
    required this.planName,
    required this.price,
    required this.planId,
    required this.paymentMethod,
  });

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  bool _isSuccess = false;
  
  // Form controllers
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  
  // Bank selection
  BankModel? _selectedBank;
  List<BankModel> _banks = [];
  bool _isLoadingBanks = true;
  final BBankService _bankService = BBankService();
  
  bool _showPin = false;
  bool _showOtp = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() => _isLoadingBanks = true);
    try {
      final banks = await _bankService.getAllBanks();
      debugPrint('📊 [PaymentProcessingPage] Loaded ${banks.length} banks');
      for (var bank in banks) {
        debugPrint('  - ${bank.name}: ${bank.logoUrl}');
      }
      setState(() {
        _banks = banks;
        _isLoadingBanks = false;
      });
    } catch (e) {
      setState(() => _isLoadingBanks = false);
      debugPrint('❌ [PaymentProcessingPage] Error loading banks: $e');
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _cardNumberController.dispose();
    _cvvController.dispose();
    _expiryController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // Validate bank selection for bank transfer
    if (widget.paymentMethod == 'Bank Transfer' && _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank')),
      );
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);
    
    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      // Update verification status in Firestore
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userService = BUserService();
          await userService.updateVerificationStatus(user.uid, true);
        }
      } catch (e) {
        debugPrint('Error updating verification status: $e');
      }
      
      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });
      
      // Show success screen with confetti for 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        // Navigate back - the real-time listener in profile will update verification status
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _sendOtp() {
    if (_mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number first')),
      );
      return;
    }
    setState(() {
      _otpSent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent to your mobile number')),
    );
  }

  Widget _buildGCashForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GCash Payment',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your GCash mobile number and PIN',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Mobile Number
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              hintText: '09XX XXX XXXX',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your mobile number';
              }
              if (value.length < 11) {
                return 'Please enter a valid mobile number';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // PIN
          TextFormField(
            controller: _pinController,
            obscureText: !_showPin,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'GCash MPIN',
              hintText: 'Enter your 4-digit MPIN',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPin = !_showPin),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your MPIN';
              }
              if (value.length != 4) {
                return 'MPIN must be 4 digits';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPayMayaForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PayMaya Payment',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your PayMaya mobile number',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Mobile Number
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              hintText: '09XX XXX XXXX',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your mobile number';
              }
              if (value.length < 11) {
                return 'Please enter a valid mobile number';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // OTP
          TextFormField(
            controller: _otpController,
            obscureText: !_showOtp,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'OTP',
              hintText: 'Enter 6-digit OTP',
              prefixIcon: const Icon(Icons.sms),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_showOtp ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showOtp = !_showOtp),
                  ),
                  TextButton(
                    onPressed: _otpSent ? null : _sendOtp,
                    child: Text(_otpSent ? 'Resend' : 'Send OTP'),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter OTP';
              }
              if (value.length != 6) {
                return 'OTP must be 6 digits';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBankTransferForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank Transfer',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your bank and enter account details',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Bank Selection
          if (_isLoadingBanks)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else
            _BankSelector(
              isDark: isDark,
              banks: _banks,
              selectedBank: _selectedBank,
              onBankSelected: (bank) {
                setState(() {
                  _selectedBank = bank;
                });
              },
            ),
          
          if (_selectedBank == null && !_isLoadingBanks)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                'Please select a bank',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[400],
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Account Number
          TextFormField(
            controller: _accountNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Account Number',
              hintText: 'Enter your account number',
              prefixIcon: const Icon(Icons.numbers),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter account number';
              }
              if (value.length < 10) {
                return 'Please enter a valid account number';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Account Name
          TextFormField(
            controller: _accountNameController,
            decoration: InputDecoration(
              labelText: 'Account Holder Name',
              hintText: 'Enter account holder name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter account holder name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEPayForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ePay Payment',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your card details',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          // Card Number
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter card number';
              }
              final cleaned = value.replaceAll(' ', '');
              if (cleaned.length < 16) {
                return 'Please enter a valid card number';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Cardholder Name
          TextFormField(
            controller: _cardholderNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              hintText: 'Enter name as on card',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter cardholder name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          // Expiry and CVV Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    hintText: 'MM/YY',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return 'MM/YY format';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (value.length < 3) {
                      return 'Invalid CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;

    if (_isSuccess) {
      return Scaffold(
        backgroundColor: _themeColorLight,
        body: Stack(
          children: [
            // Confetti Animation
            const ConfettiWidget(
              particleCount: 80,
              duration: Duration(seconds: 4),
            ),
            // Success Content
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Success Icon
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _themeColorDark,
                                  _themeColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _themeColorDark.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 80,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _themeColorDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your ${widget.planName} subscription is now active',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _themeColorDark,
                            _themeColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _themeColorDark.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Verified Badge Activated',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Your profile is now verified!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.paymentMethod,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: _isProcessing
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: _isProcessing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _themeColorDark.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_themeColorDark),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Processing Payment...',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please wait while we process your ${widget.paymentMethod} payment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.planName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.price,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _themeColorDark,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.verified,
                          color: _themeColorDark,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Payment Form
                  if (widget.paymentMethod == 'GCash')
                    _buildGCashForm()
                  else if (widget.paymentMethod == 'PayMaya')
                    _buildPayMayaForm()
                  else if (widget.paymentMethod == 'Bank Transfer')
                    _buildBankTransferForm()
                  else if (widget.paymentMethod == 'ePay')
                    _buildEPayForm(),
                  
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _themeColorDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Pay Now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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

/// Bank Selector Widget
/// 
/// Displays a grid of banks with logos for selection.
class _BankSelector extends StatelessWidget {
  final bool isDark;
  final List<BankModel> banks;
  final BankModel? selectedBank;
  final Function(BankModel) onBankSelected;

  const _BankSelector({
    required this.isDark,
    required this.banks,
    required this.selectedBank,
    required this.onBankSelected,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [BankSelector] Building with ${banks.length} banks');
    if (banks.isEmpty) {
      debugPrint('⚠️ [BankSelector] No banks available!');
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            'No banks available',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Bank',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: banks.length,
          itemBuilder: (context, index) {
            final bank = banks[index];
            final isSelected = selectedBank?.id == bank.id;
            debugPrint('🏦 [BankSelector] Building bank card: ${bank.name}, logoUrl: ${bank.logoUrl}');

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onBankSelected(bank),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _themeColorDark.withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _themeColorDark
                          : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                      width: isSelected ? 2 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _themeColorDark.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.05),
                              blurRadius: 4,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Bank Logo
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: bank.logoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  bank.logoUrl,
                                  fit: BoxFit.contain,
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('❌ [BankSelector] Error loading logo for ${bank.name}: $error');
                                    debugPrint('   URL: ${bank.logoUrl}');
                                    return Icon(
                                      Icons.account_balance,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      size: 30,
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      debugPrint('✅ [BankSelector] Loaded logo for ${bank.name}');
                                      return child;
                                    }
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _themeColorDark,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.account_balance,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                size: 30,
                              ),
                      ),
                      const SizedBox(height: 8),
                      // Bank Name
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          bank.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? _themeColorDark
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
