import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

void showAboutLpuModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: SingleChildScrollView(child: AboutLpuContent()),
      ),
    ),
  );
}

class AboutLpuPage extends StatelessWidget {
  const AboutLpuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About LPU-Cavite'),
        backgroundColor: AppTokens.maroonPrimary,
        foregroundColor: Colors.white,
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: AboutLpuContent(),
        ),
      ),
    );
  }
}

class AboutLpuContent extends StatelessWidget {
  const AboutLpuContent({super.key});

  static Widget _buildSection({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTokens.textDark : AppTokens.textLight;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTokens.maroonOnDark : AppTokens.maroonPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.55,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTokens.textDark : AppTokens.textLight;
    final secondaryTextColor = isDark
        ? AppTokens.textSecondaryDark
        : AppTokens.textSecondaryLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // University Brand Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/img/lpu-logo.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.school,
                color: AppTokens.maroonPrimary,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lyceum of the Philippines University',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Cavite Campus · General Trias, Cavite',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),

        _buildSection(
          context: context,
          title: 'Vision',
          description: 'To be a recognized and accredited quality institution by 2030, distinguished by our commitment to quality systems and continuous improvement, dedicated to innovation, excellence and integrity in the service of God and country.',
        ),
        const Divider(height: 1),
        _buildSection(
          context: context,
          title: 'Mission',
          description:
              'The Lyceum of the Philippines University Cavite Inc., espousing the ideals of Jose P. Laurel, is committed to:\n\n'
              '• Provide industry-based knowledge and skills\n'
              '• Undertake multidisciplinary research\n'
              '• Support community engagement and social responsibility\n'
              '• Establish local and international linkages\n'
              '• Produce sustainability advocates for global action',
        ),
        const Divider(height: 1),
        _buildSection(
          context: context,
          title: 'Core Values (4L)',
          description:
              'L — Love of God\n'
              'P — Professional Integrity\n'
              'U — Unity\n'
              'N — Nationalism\n'
              'J — Justice\n'
              'P — Perseverance\n'
              'L — Leadership',
        ),
      ],
    );
  }
}
