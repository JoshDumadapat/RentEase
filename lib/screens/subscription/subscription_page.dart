import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentease_app/widgets/shimmer_effect.dart';
import 'package:rentease_app/screens/subscription/payment_selection_page.dart';
import 'package:rentease_app/screens/subscription/manage_subscription_page.dart';

const Color _themeColorDark = Color(0xFF00B8E6);
const Color _themeColor = Color(0xFF00D1FF);

/// Subscription Page
/// 
/// Page where users can subscribe to get a verified badge.
/// Features subscription plans and benefits.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  String? _selectedPlan;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (mounted) {
          final isVerified = userDoc.data()?['isVerified'] ?? false;
          setState(() {
            _isVerified = isVerified;
          });
          
          // Redirect verified users to manage subscription page
          if (isVerified) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const ManageSubscriptionPage(),
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking verification status: $e');
    }
  }

  Future<void> _handleSubscribe(String planId) async {
    // Get plan details
    String planName;
    String price;
    
    switch (planId) {
      case 'monthly':
        planName = 'Monthly';
        price = '₱199';
        break;
      case 'quarterly':
        planName = 'Quarterly';
        price = '₱549';
        break;
      case 'yearly':
        planName = 'Yearly';
        price = '₱1,999';
        break;
      default:
        planName = 'Monthly';
        price = '₱199';
    }

    // Navigate to payment selection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSelectionPage(
          planName: planName,
          price: price,
          planId: planId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Get Verified Badge',
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // Logo
            Image.asset(
              'assets/logo.png',
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: _themeColorDark.withValues(alpha: isDark ? 0.2 : 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified,
                    size: 40,
                    color: _themeColorDark,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Get Verified',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Subtitle
            Text(
              'Build trust and credibility with a verified badge',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Benefits Section
            _BenefitsSection(isDark: isDark),
            
            const SizedBox(height: 40),
            
            // Subscription Plans
            Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Monthly Plan
            _SubscriptionPlanCard(
              isDark: isDark,
              planName: 'Monthly',
              price: '₱199',
              period: 'per month',
              planId: 'monthly',
              isSelected: _selectedPlan == 'monthly',
              isLoading: false,
              onTap: () => _handleSubscribe('monthly'),
            ),
            
            const SizedBox(height: 16),
            
            // Quarterly Plan
            _SubscriptionPlanCard(
              isDark: isDark,
              planName: 'Quarterly',
              price: '₱549',
              period: 'per 3 months',
              planId: 'quarterly',
              isSelected: _selectedPlan == 'quarterly',
              isLoading: false,
              onTap: () => _handleSubscribe('quarterly'),
              savings: 'Save 8%',
            ),
            
            const SizedBox(height: 16),
            
            // Yearly Plan (Best Value)
            _SubscriptionPlanCard(
              isDark: isDark,
              planName: 'Yearly',
              price: '₱1,999',
              period: 'per year',
              planId: 'yearly',
              isSelected: _selectedPlan == 'yearly',
              isLoading: false,
              onTap: () => _handleSubscribe('yearly'),
              isPopular: true,
              promoText: 'Free 7 days trial',
              savings: 'Save 16%',
            ),
            
            const SizedBox(height: 32),
            
            // Info Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Your subscription will auto-renew. You can cancel anytime from your account settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  final bool isDark;

  const _BenefitsSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final benefits = [
      {
        'icon': Icons.verified,
        'title': 'Verified Badge',
        'description': 'Display a verified badge on your profile',
      },
      {
        'icon': Icons.people,
        'title': 'Build Trust',
        'description': 'Increase credibility with potential renters',
      },
      {
        'icon': Icons.trending_up,
        'title': 'More Visibility',
        'description': 'Get priority in search results',
      },
      {
        'icon': Icons.support_agent,
        'title': 'Priority Support',
        'description': 'Get faster response from our support team',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _themeColorDark.withValues(alpha: isDark ? 0.15 : 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      benefit['icon'] as IconData,
                      color: _themeColorDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          benefit['title'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          benefit['description'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

class _SubscriptionPlanCard extends StatelessWidget {
  final bool isDark;
  final String planName;
  final String price;
  final String period;
  final String planId;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isPopular;
  final String? promoText;
  final String? savings;

  const _SubscriptionPlanCard({
    required this.isDark,
    required this.planName,
    required this.price,
    required this.period,
    required this.planId,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
    this.isPopular = false,
    this.promoText,
    this.savings,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: EdgeInsets.only(
        top: isPopular ? 12 : 0,
        bottom: isPopular ? 12 : 0,
      ),
      decoration: BoxDecoration(
        gradient: isPopular
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1A3A4A),
                        const Color(0xFF2A2A2A),
                      ]
                    : [
                        _themeColorDark.withValues(alpha: 0.25),
                        _themeColor.withValues(alpha: 0.18),
                        Colors.white,
                      ],
              )
            : null,
        color: isPopular
            ? null
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? _themeColorDark
              : isPopular
                  ? _themeColorDark.withValues(alpha: isDark ? 0.6 : 1.0)
                  : (isDark ? Colors.grey[700]! : Colors.grey[400]!),
          width: isSelected ? 2.5 : (isPopular ? 2 : 1.5),
        ),
        boxShadow: isSelected || isPopular
            ? [
                BoxShadow(
                  color: _themeColorDark.withValues(alpha: isPopular ? (isDark ? 0.4 : 0.5) : (isDark ? 0.3 : 0.4)),
                  blurRadius: isPopular ? 16 : 12,
                  spreadRadius: 0,
                  offset: Offset(0, isPopular ? 6 : 4),
                ),
              ]
            : isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                planName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              if (savings != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? Colors.green.withValues(alpha: 0.25)
                                        : Colors.green.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark 
                                          ? Colors.green.withValues(alpha: 0.4)
                                          : Colors.green.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    savings!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.green[300] : Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                price,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: _themeColorDark,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  period,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _themeColorDark,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _themeColorDark.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                  ],
                ),
                if (promoText != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  _themeColorDark.withValues(alpha: 0.25),
                                  _themeColor.withValues(alpha: 0.2),
                                ]
                              : [
                                  _themeColorDark.withValues(alpha: 0.4),
                                  _themeColor.withValues(alpha: 0.3),
                                ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _themeColorDark.withValues(alpha: isDark ? 0.5 : 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer,
                          size: 15,
                          color: _themeColorDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          promoText!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _themeColorDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isPopular) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? _themeColorDark.withValues(alpha: isDark ? 0.25 : 0.4)
                          : _themeColorDark.withValues(alpha: isDark ? 0.2 : 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _themeColorDark.withValues(alpha: isDark ? 0.4 : 0.7),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'MOST POPULAR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _themeColorDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular ? _themeColorDark : _themeColorDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isPopular ? 3 : 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Subscribe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Shimmer effect wrapper for best value plan
        if (isPopular)
          ShimmerEffect(
            child: card,
          )
        else
          card,
        // BEST VALUE badge - positioned lower to prevent clipping
        if (isPopular)
          Positioned(
            top: 8,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_themeColorDark, _themeColor],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _themeColorDark.withValues(alpha: isDark ? 0.4 : 0.5),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'BEST VALUE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
