import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for 1 second
    await Future.delayed(const Duration(seconds: 1));
    
    // Check if the widget is still mounted before navigating
    if (!mounted) return;
    
    // Navigate to the dashboard
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                // Fallback in case the image fails to load
                return Icon(
                  Icons.spa,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                );
              },
            ),
            const SizedBox(height: 24),
            // Optional: App Name (can be removed if the logo has text)
            Text(
              'Life OS',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
