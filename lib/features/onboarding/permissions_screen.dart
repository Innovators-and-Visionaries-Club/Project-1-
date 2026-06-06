import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../widgets/wavy_background.dart';
import '../../core/theme.dart';
import 'onboarding_screen.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  void _proceedToDownloader(BuildContext context, AppProvider provider) {
    provider.completeOnboardingStep();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
      (route) => false, // Clears navigation history so they can't go back
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      body: WavyBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Visual Graphic representing files check
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF3F4F6),
                          border: Border.all(color: AppTheme.border, width: 1),
                        ),
                      ),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_shared_outlined,
                            size: 64,
                            color: Colors.black,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'STORAGE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Title
                const Text(
                  'local storage access',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Explanation
                const Text(
                  'To load your textbooks, PDF guides, and recordings, Smriti needs file access permission. All file processing and analysis occur entirely on this phone—nothing is transmitted to any servers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.55,
                  ),
                ),

                const Spacer(),

                // Action Buttons
                ElevatedButton(
                  onPressed: () => _proceedToDownloader(context, provider),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Grant Storage Access'),
                      SizedBox(width: 8),
                      Icon(Icons.shield_outlined, size: 16),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                  ),
                  onPressed: () => _proceedToDownloader(context, provider),
                  child: const Text(
                    'Continue Offline',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
