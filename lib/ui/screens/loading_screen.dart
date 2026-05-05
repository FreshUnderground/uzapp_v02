import 'package:flutter/material.dart';
import '../../core/res/uza_colors.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, UzaColors.primary.withValues(alpha: 0.05)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            Hero(
              tag: 'logo',
              child: Image.asset('assets/logo.png', width: 140, height: 140),
            ),
            const SizedBox(height: 24),
            const Text(
              'UZAAPP',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: UzaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "L'EXCELLENCE DU COMMERCE LOCAL",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(flex: 2),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(UzaColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Préparation de votre showroom...',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
