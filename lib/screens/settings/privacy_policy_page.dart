import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
          'Privacy Policy',
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
            _PolicySection(
              title: '1. Introduction',
              content:
                  'RentEase ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and services.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _PolicySection(
              title: '2. Information We Collect',
              content:
                  'We collect information that you provide directly to us, including:\n\n'
                  '• Personal Information: Name, email address, phone number, and profile information\n'
                  '• Property Information: Property listings, photos, descriptions, and location data\n'
                  '• Account Credentials: Email and password for account authentication\n'
                  '• Communication Data: Messages, inquiries, and feedback you send through the app\n'
                  '• Usage Data: Information about how you use the app, including search history and preferences',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _PolicySection(
              title: '3. How We Use Your Information',
              content:
                  'We use the information we collect to:\n\n'
                  '• Provide and maintain our services\n'
                  '• Process and manage property listings and rental transactions\n'
                  '• Communicate with you about your account and our services\n'
                  '• Send you notifications, updates, and promotional materials (with your consent)\n'
                  '• Improve and personalize your experience\n'
                  '• Detect, prevent, and address technical issues and security threats\n'
                  '• Comply with legal obligations',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _PolicySection(
              title: '4. Information Sharing and Disclosure',
              content:
                  'We do not sell your personal information. We may share your information only in the following circumstances:\n\n'
                  '• With other users: Your profile information and property listings are visible to other users as part of the service\n'
                  '• Service Providers: We may share information with third-party service providers who assist us in operating the app\n'
                  '• Legal Requirements: We may disclose information if required by law or to protect our rights and safety\n'
                  '• Business Transfers: In the event of a merger, acquisition, or sale, your information may be transferred',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _PolicySection(
              title: '5. Data Security',
              content:
                  'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _PolicySection(
              title: '6. Your Rights and Choices',
              content:
                  'You have the right to:\n\n'
                  '• Access and update your personal information through your account settings\n'
                  '• Delete your account and request deletion of your personal data\n'
                  '• Opt-out of marketing communications\n'
                  '• Request a copy of your data\n'
                  '• Withdraw consent for data processing where applicable',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _PolicySection(
              title: '7. Cookies and Tracking Technologies',
              content:
                  'We use cookies and similar tracking technologies to track activity on our app and store certain information. You can instruct your device to refuse all cookies, but some features may not function properly.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _PolicySection(
              title: '8. Children\'s Privacy',
              content:
                  'Our services are not intended for individuals under the age of 18. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _PolicySection(
              title: '9. Changes to This Privacy Policy',
              content:
                  'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
              textColor: textColor,
              subtextColor: subtextColor,
            ),
            const SizedBox(height: 24),
            _PolicySection(
              title: '10. Contact Us',
              content:
                  'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                  'Email: privacy@rentease.app\n'
                  'Address: RentEase Privacy Team\n'
                  'We will respond to your inquiry within 30 days.',
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

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  final Color textColor;
  final Color subtextColor;

  const _PolicySection({
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

