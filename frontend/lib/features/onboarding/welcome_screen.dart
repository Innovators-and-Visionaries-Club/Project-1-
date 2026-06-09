import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/wavy_background.dart';
import '../../widgets/smriti_logo_painter.dart';
import '../../core/theme.dart';
import 'permissions_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStorageWarningIfNeeded();
    });
  }

  Future<void> _showStorageWarningIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWarning = prefs.getBool('hasSeenStorageWarning') ?? false;

    if (!hasSeenWarning) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.storage_rounded, color: Colors.black),
              SizedBox(width: 10),
              Text('Storage Requirement'),
            ],
          ),
          content: const Text(
            'Smriti is a 100% offline AI notebook.\n\nTo ensure complete privacy and speed, the app requires a minimum of 2GB of free permanent storage to securely house the offline LLM brain and your PDF chat backups.\n\nPlease ensure you have enough space before continuing.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('I Understand'),
            ),
          ],
        ),
      );
      await prefs.setBool('hasSeenStorageWarning', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WavyBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Vector Organic Logo
                const Center(
                  child: SmritiLogoWidget(size: 160),
                ),
                
                const Spacer(),

                // Title
                const Text(
                  'welcome to smriti',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Concept explanation
                const Text(
                  'An offline AI notebook — your second memory, on your phone. Drop textbooks, lecture notes, and study recordings to query them locally with 100% privacy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                // Bottom Action Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PermissionsScreen(),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Get Started'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
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
