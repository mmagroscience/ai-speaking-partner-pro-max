import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/constants.dart';
import '../../widgets/app_background.dart';
import '../../widgets/common.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              HeaderBar(
                title: 'Privacy & data',
                subtitle: 'Plain-language policy',
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _IntroCard(),
                      SizedBox(height: 18),
                      _PolicySection(
                        icon: Icons.phone_android_rounded,
                        title: 'Everything stays on your device',
                        body:
                            'Your name, goals, session history, favourites, custom topics and admin PIN are stored locally on this phone. There is no account, no cloud sync and no analytics server operated by this app.',
                      ),
                      _PolicySection(
                        icon: Icons.mic_rounded,
                        title: 'Microphone and speech',
                        body:
                            'Speech recognition runs through your device\'s speech service. Audio is used only to turn your voice into text during a call or IELTS answer. The app does not keep recordings.',
                      ),
                      _PolicySection(
                        icon: Icons.videocam_outlined,
                        title: 'Camera and photos',
                        body:
                            'Camera access powers the self-view during calls, and the photo picker is used only when you choose an avatar or a familiar-person photo. Images are saved inside the app\'s private storage.',
                      ),
                      _PolicySection(
                        icon: Icons.cloud_outlined,
                        title: 'Optional Gemini keys',
                        body:
                            'If you add a Gemini API key, your typed or transcribed text is sent to Google\'s Gemini API to generate a reply. Without a key, the built-in offline coach answers locally. Keys are kept in the platform keystore on mobile, or browser storage on the web.',
                      ),
                      _PolicySection(
                        icon: Icons.record_voice_over_outlined,
                        title: 'Text-to-speech and voice demo',
                        body:
                            'Spoken replies use the voices installed on your device. The voice-cloning screen is a local demo: an uploaded clip is previewed on-device and is not uploaded to a cloning service.',
                      ),
                      _PolicySection(
                        icon: Icons.delete_outline_rounded,
                        title: 'Deleting your data',
                        body:
                            'Settings → Data lets you reset learning progress or erase everything, including API keys and custom topics. Uninstalling the app also removes local data.',
                      ),
                      _PolicySection(
                        icon: Icons.child_care_outlined,
                        title: 'Age and safety',
                        body:
                            'The app is designed for learners aged 13 and above. AI replies can occasionally be wrong; treat them as practice feedback, not professional or exam advice.',
                      ),
                      _PolicySection(
                        icon: Icons.mail_outline_rounded,
                        title: 'Questions',
                        body:
                            'This is an independent learning project. For privacy questions, contact the person who installed the app on this device.',
                      ),
                      SizedBox(height: 10),
                      _BanglaSummary(),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Version ${AppInfo.versionName} • ${AppInfo.edition}',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          SizedBox(height: 10),
          Text(
            'Your voice is yours',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'No account. No tracking. No server required. Practice without handing over your personal data.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.pale,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.purple),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BanglaSummary extends StatelessWidget {
  const _BanglaSummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'বাংলায় সংক্ষেপে',
            style: TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.mintDeep,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'আপনার নাম, প্রগ্রেস, ছবি ও API key শুধু এই ডিভাইসেই থাকে। অ্যাপ কোনো সার্ভারে আপনার ভয়েস বা ব্যক্তিগত তথ্য পাঠায় না। মাইক ও ক্যামেরা শুধু প্র্যাকটিসের সময় ব্যবহার হয়। Settings → Data থেকে যেকোনো সময় সব ডেটা মুছে ফেলতে পারবেন।',
            style: TextStyle(
              fontFamily: 'HindSiliguri',
              fontSize: 10.5,
              height: 1.6,
              color: AppColors.mintDeep,
            ),
          ),
        ],
      ),
    );
  }
}
