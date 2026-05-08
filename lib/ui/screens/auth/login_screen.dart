import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/res/uza_colors.dart';
import '../../utils/page_transitions.dart';
import '../../components/tap_animator.dart';
import 'verification_screen.dart';
import '../../../data/repositories/shop_repository.dart';
import '../shop_dashboard_screen.dart';
import '../home_screen.dart';
import 'package:flutter/foundation.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        final isCurrent = index == currentStep - 1;
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive || isCurrent ? UzaColors.primary : Colors.grey[300],
          ),
        );
      }),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _phoneNumber = "";
  bool _isPhoneValid = false;
  final _formKey = GlobalKey<FormState>();
  bool _usePasswordLogin = true; // Password is default
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  void _onContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_usePasswordLogin) {
        // Password-based login
        final authService = context.read<AuthService>();
        authService.signInWithPassword(
          phoneNumber: _phoneNumber,
          password: _passwordController.text,
          onSuccess: () async {
            if (!mounted) return;

            // Wait a moment for shop reconnection to complete
            await Future.delayed(const Duration(milliseconds: 500));

            if (!mounted) return;

            try {
              // Check if user has a shop
              final shopRepo = context.read<ShopRepository>();
              final authService = context.read<AuthService>();
              final userId = authService.user?.uid ?? _phoneNumber;

              // Get user's shop
              final userShop = await shopRepo.watchUserShop(userId).first;

              if (!mounted) return;

              if (userShop != null) {
                // User has a shop, navigate to shop dashboard
                debugPrint('Login: User has shop, navigating to dashboard');
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const ShopDashboardScreen(),
                  ),
                  (route) => false,
                );
              } else {
                // No shop, navigate to home
                debugPrint('Login: User has no shop, navigating to home');
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            } catch (e) {
              debugPrint('Error checking for shop: $e');
              // Fallback to home screen
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            }
          },
          onFailed: (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Erreur: ${e.toString().replaceAll('Exception: ', '')}',
                  ),
                ),
              );
            }
          },
        );
      } else {
        // OTP-based login
        final authService = context.read<AuthService>();
        authService.verifyPhone(
          phoneNumber: _phoneNumber,
          onCodeSent: (verificationId) {
            Navigator.push(
              context,
              SlideUpRoute(
                page: VerificationScreen(
                  verificationId: verificationId,
                  phoneNumber: _phoneNumber,
                ),
              ),
            );
          },
          onFailed: (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erreur: ${e.message}')));
          },
        );
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      body: Stack(
        children: [
          // Subtle top gradient decoration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    UzaColors.primary.withValues(alpha: 0.08),
                    UzaColors.primary.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Curved decorative shape
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: UzaColors.secondary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: UzaColors.primary.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      // App Logo
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: UzaColors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.shopping_bag,
                                  size: 48,
                                  color: UzaColors.primary,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "Bienvenue sur Uzaapp",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: UzaColors.textPrimary,
                              fontSize: 28,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Connectez-vous pour retrouver votre boutique",
                        style: TextStyle(
                          color: UzaColors.textSecondary,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      const StepIndicator(currentStep: 1, totalSteps: 2),
                      const SizedBox(height: 48),
                      // Password login is the primary method for reconnection
                      Text(
                        'Connectez-vous avec votre mot de passe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: UzaColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vous avez déjà un compte? Entrez votre numéro et mot de passe',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Password input - shown by default
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          labelStyle: const TextStyle(fontSize: 16),
                          hintText: 'Entrez votre mot de passe',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: UzaColors.divider,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: UzaColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey[600],
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Entrez votre mot de passe';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Forgot password link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement password reset via OTP
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Pour réinitialiser votre mot de passe, veuillez contacter le support.',
                                ),
                                backgroundColor: Colors.orange[800],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Text(
                            'Mot de passe oublié ?',
                            style: TextStyle(
                              color: UzaColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Phone input - larger and more prominent
                      IntlPhoneField(
                        decoration: InputDecoration(
                          labelText: 'Numéro de téléphone',
                          labelStyle: const TextStyle(fontSize: 16),
                          hintText: 'XX XXX XX XX',
                          hintStyle: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: UzaColors.divider,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: UzaColors.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 22,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        initialCountryCode: 'CD',
                        disableLengthCheck: false,
                        invalidNumberMessage: 'Numéro invalide',
                        onChanged: (phone) {
                          setState(() {
                            _phoneNumber = phone.completeNumber;
                            _isPhoneValid = phone.number.length >= 9;
                          });
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.length < 9) {
                            return 'Entrez un numéro valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      // Continuer button
                      TapAnimator(
                        onTap: (_isPhoneValid && !authService.isLoading)
                            ? _onContinue
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: (_isPhoneValid && !authService.isLoading)
                                ? UzaColors.primary
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: authService.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  child: Center(
                                    child: SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Se connecter',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
