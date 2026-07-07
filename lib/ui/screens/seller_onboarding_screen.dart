import 'package:flutter/material.dart';
import '../../core/l10n/tr.dart';
import '../../core/res/uza_colors.dart';
import '../utils/page_transitions.dart';
import 'auth/login_screen.dart';
import 'create_shop_screen.dart';

/// Gate screen for guests: create a shop or log in to an existing account.
class SellerOnboardingScreen extends StatelessWidget {
  const SellerOnboardingScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      SlideUpRoute(page: const SellerOnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'create_shop')),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront, size: 72, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                tr(context, 'sell_on_uzaapp'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    SlideUpRoute(page: const CreateShopScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UzaColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    tr(context, 'create_shop'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  SlideUpRoute(page: const LoginScreen()),
                ),
                child: Text(tr(context, 'already_have_account')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
