import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsPrivacyPolicyScreen extends StatelessWidget {
  const TermsPrivacyPolicyScreen({super.key});

  static const _privacySections = <Map<String, String>>[
    {
      'title': 'Information We Collect',
      'body':
          'Farmlyt AI stores the information you provide during sign up such as your name, email, phone number, language preference, wallet balance, and profile photo. The app also processes crop images you upload for disease analysis and can read device location only for weather and nearby farming context.',
    },
    {
      'title': 'How We Use Information',
      'body':
          'We use your details to authenticate your account, verify OTP login, show wallet balance, power crop detection, improve app reliability, and deliver a personalized language experience throughout the app.',
    },
    {
      'title': 'Images And Predictions',
      'body':
          'Uploaded crop images and prediction outputs may be stored on the connected backend so that analysis history, result images, and treatment recommendations can be shown back inside the app.',
    },
    {
      'title': 'Payments',
      'body':
          'Wallet top-ups are processed through Razorpay. Farmlyt AI does not intentionally store your full card or banking details inside the app.',
    },
    {
      'title': 'User Control',
      'body':
          'You can log out at any time, update your profile name and photo, and change language preferences from Settings. If you need account support, contact the app operator managing the backend services.',
    },
  ];

  static const _termsSections = <Map<String, String>>[
    {
      'title': 'Service Scope',
      'body':
          'Farmlyt AI provides crop detection, farming tips, weather context, wallet credits, and account tools to support farmers. The app is designed to assist decision making and should not replace professional agricultural advice in critical cases.',
    },
    {
      'title': 'Account Access',
      'body':
          'Users must provide valid information during registration or login. OTP verification is required for email or phone based access. Once logged in, the app may keep the session active on the device until logout.',
    },
    {
      'title': 'Credits And Billing',
      'body':
          'Crop analysis may consume wallet credits. Recharge amounts, scan costs, and payment verification depend on the live backend configuration available at the time of use.',
    },
    {
      'title': 'Uploads',
      'body':
          'By uploading crop images, you confirm that you have permission to use the images for analysis. The service may store original and predicted images to return results and maintain scan history.',
    },
    {
      'title': 'Availability',
      'body':
          'Features depending on internet connectivity, third-party services, or backend APIs may occasionally be unavailable. Farmlyt AI may add or remove supported categories and crops as backend services evolve.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Terms & Privacy Policy',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          _sectionHeader('Terms of Service'),
          const SizedBox(height: 12),
          ..._termsSections.map(_LegalCard.new),
          const SizedBox(height: 18),
          _sectionHeader('Privacy Policy'),
          const SizedBox(height: 12),
          ..._privacySections.map(_LegalCard.new),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF2E7D32),
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  final Map<String, String> section;

  const _LegalCard(this.section);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section['title'] ?? '',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            section['body'] ?? '',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF5D4037),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
