import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../widgets/wavy_background.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDownloading = false;

  void _simulateModelDownload(AppProvider provider) {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });
    provider.setModelDownloadStatus("Downloading", 0.0);

    double progress = 0.0;
    Timer.periodic(const Duration(milliseconds: 150), (timer) {
      progress += 0.05;
      if (progress >= 1.0) {
        timer.cancel();
        provider.setModelDownloadStatus("Ready", 1.0);
        setState(() {
          _isDownloading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local LLM engine initialized successfully!'),
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        provider.setModelDownloadStatus("Downloading", progress);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Wavy Header
            ClipPath(
              clipper: WavyHeaderClipper(),
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 55),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'SMRITI SECURITY',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'All intelligence is local. No data, files, or indexes ever sync to the cloud. Complete privacy by architecture.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Settings Fields
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOCAL SETTINGS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Dark Mode Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F0F0F) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF222222) : AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dark Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'High-contrast obsidian theme style.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: provider.isDarkMode,
                          activeColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          onChanged: (val) {
                            provider.toggleDarkMode(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Toggle Simulation Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F0F0F) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF222222) : AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.settings_suggest_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Simulated Inference',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Use mock vectors for fast Q&A simulation.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: provider.isMockMode,
                          activeColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          onChanged: (val) {
                            provider.toggleMockMode(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Model Weights card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F0F0F) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF222222) : AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.download_for_offline_rounded, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gemma 2B Engine',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Size: 1.3 GB (Requires 6GB+ RAM)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              provider.modelDownloadStatus == "Ready" ? "READY" : "DOWNLOADING",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        if (provider.modelDownloadStatus == "Downloading") ...[
                          const SizedBox(height: 15),
                          LinearProgressIndicator(
                            value: provider.modelDownloadProgress,
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFF3F4F6),
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Downloading: ${(provider.modelDownloadProgress * 100).toInt()}%',
                                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                              ),
                              const Text(
                                'Speed: 8.5 MB/s',
                                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                        if (provider.modelDownloadStatus == "Download Needed") ...[
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 38,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                                ),
                              ),
                              onPressed: () => _simulateModelDownload(provider),
                              child: const Text('Download LLM Weights'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'MAINTENANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F0F0F) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF222222) : AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.cleaning_services_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black),
                          title: const Text('Clear Chat Sessions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Removes all message history.', style: TextStyle(fontSize: 11)),
                          onTap: () {
                            _showConfirmDialog(
                              context,
                              'Clear Chat Logs',
                              'Delete all assistant message histories? Notes index will remain untouched.',
                              () => provider.clearChatHistory(),
                            );
                          },
                        ),
                        Divider(height: 1, color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF222222) : AppTheme.border),
                        ListTile(
                          leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          title: const Text('Reset Application Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          subtitle: const Text('Clears all notes, vectors, settings and onboarding status.', style: TextStyle(fontSize: 11)),
                          onTap: () {
                            _showConfirmDialog(
                              context,
                              'Perform Full Reset',
                              'This will purge all local files, indexing vectors, chats and onboarding configurations.',
                              () => provider.clearAllData(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black, width: 1.2)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
