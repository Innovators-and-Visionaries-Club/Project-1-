import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/app_provider.dart';
import 'features/home_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const SmritiApp(),
    ),
  );
}

class SmritiApp extends StatelessWidget {
  const SmritiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Smriti - Offline AI Notebook',
          debugShowCheckedModeBanner: false,
          theme: provider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: child,
        );
      },
      child: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isInitialized) {
            return const HomeScreen();
          } else {
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
