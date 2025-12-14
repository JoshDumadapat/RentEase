import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Terms of Service',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Updated: January 2024',
              style: TextStyle(
                fontSize: 12,
                color: subtextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using RentEase, you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '2. Description of Service',
              content:
                  'RentEase is a property rental platform that connects property owners and renters. We provide a platform for listing properties, searching for rentals, and facilitating communication between users.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '3. User Accounts',
              content:
                  'To use certain features of RentEase, you must create an account. You agree to:\n\n'
                  '• Provide accurate, current, and complete information\n'
                  '• Maintain and update your information to keep it accurate\n'
                  '• Maintain the security of your account credentials\n'
                  '• Accept responsibility for all activities under your account\n'
                  '• Notify us immediately of any unauthorized use',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '4. User Conduct',
              content:
                  'You agree not to:\n\n'
                  '• Post false, misleading, or fraudulent information\n'
                  '• Violate any laws or regulations\n'
                  '• Infringe on intellectual property rights\n'
                  '• Harass, abuse, or harm other users\n'
                  '• Use the service for any illegal or unauthorized purpose\n'
                  '• Transmit viruses or malicious code\n'
                  '• Attempt to gain unauthorized access to the service',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '5. Property Listings',
              content:
                  'Property owners are responsible for:\n\n'
                  '• Ensuring all listing information is accurate and up-to-date\n'
                  '• Complying with all applicable laws and regulations\n'
                  '• Responding to inquiries in a timely manner\n'
                  '• Maintaining the condition of listed properties as described\n'
                  '• We reserve the right to remove any listing that violates these terms',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '6. Fees and Payments',
              content:
                  'RentEase may charge fees for certain services. All fees are clearly disclosed before you commit to a transaction. You are responsible for all applicable taxes. Refund policies are outlined in our payment terms.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '7. Intellectual Property',
              content:
                  'All content on RentEase, including text, graphics, logos, and software, is the property of RentEase or its licensors. You may not reproduce, distribute, or create derivative works without our written permission.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '8. Disclaimers',
              content:
                  'RentEase is provided "as is" without warranties of any kind. We do not guarantee:\n\n'
                  '• The accuracy of property listings\n'
                  '• The availability of properties\n'
                  '• The conduct of users\n'
                  '• The outcome of any rental transaction\n'
                  'You use the service at your own risk.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '9. Limitation of Liability',
              content:
                  'To the maximum extent permitted by law, RentEase shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the service.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '10. Termination',
              content:
                  'We may terminate or suspend your account immediately, without prior notice, for any violation of these terms. You may also terminate your account at any time through your account settings.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '11. Changes to Terms',
              content:
                  'We reserve the right to modify these terms at any time. We will notify users of significant changes. Continued use of the service after changes constitutes acceptance of the new terms.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '12. Governing Law',
              content:
                  'These terms shall be governed by and construed in accordance with the laws of the jurisdiction in which RentEase operates, without regard to its conflict of law provisions.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _TermsSection(
              title: '13. Contact Information',
              content:
                  'If you have any questions about these Terms of Service, please contact us at:\n\n'
                  'Email: legal@rentease.app\n'
                  'Address: RentEase Legal Department',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  final String title;
  final String content;
  final Color textColor;
  final Color subtextColor;

  const _TermsSection({
    required this.title,
    required this.content,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: subtextColor,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

