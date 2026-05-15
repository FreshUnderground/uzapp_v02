import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/res/uza_colors.dart';
import '../../utils/page_transitions.dart';
import '../../components/tap_animator.dart';
import 'verification_screen.dart';
import '../home_screen.dart';

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
  final bool _usePasswordLogin = true; // Password is default
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
          onSuccess: () => _goToBestDestination(),
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

  Future<void> _goToBestDestination() async {
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 3)),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final canSubmit = _isPhoneValid && !authService.isLoading;

    InputDecoration fieldDecoration({
      required String label,
      required String hint,
      required IconData icon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: UzaColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: UzaColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    UzaColors.primary.withValues(alpha: 0.16),
                    Colors.white,
                    UzaColors.secondary.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -70,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: UzaColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: UzaColors.secondary.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      if (navigator.canPop()) {
                        navigator.pop();
                      } else {
                        navigator.pushReplacement(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    },
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: UzaColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: UzaColors.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.storefront_rounded,
                                    size: 46,
                                    color: UzaColors.primary,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'Bienvenue sur Uzaapp',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: UzaColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Connectez-vous pour gérer votre boutique, vos produits et vos statistiques.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: UzaColors.textSecondary,
                            fontSize: 15.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: UzaColors.primary.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.lock_open_rounded,
                                      color: UzaColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Connexion boutique',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: UzaColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Même numéro que lors de la création',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              IntlPhoneField(
                                decoration: fieldDecoration(
                                  label: 'Numéro de téléphone',
                                  hint: 'XX XXX XX XX',
                                  icon: Icons.phone_rounded,
                                ),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
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
                                  if (phone == null ||
                                      phone.number.length < 9) {
                                    return 'Entrez un numéro valide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                decoration: fieldDecoration(
                                  label: 'Mot de passe',
                                  hint: 'Entrez votre mot de passe',
                                  icon: Icons.key_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _showPassword = !_showPassword,
                                      );
                                    },
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Entrez votre mot de passe';
                                  }
                                  return null;
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Si vous avez oublié le mot de passe, connectez-vous par OTP ou contactez le support.',
                                        ),
                                        backgroundColor: Colors.orange.shade800,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  child: const Text('Mot de passe oublié ?'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TapAnimator(
                                onTap: canSubmit ? _onContinue : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 17,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: canSubmit
                                        ? const LinearGradient(
                                            colors: [
                                              UzaColors.primary,
                                              UzaColors.secondary,
                                            ],
                                          )
                                        : null,
                                    color: canSubmit
                                        ? null
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: canSubmit
                                        ? [
                                            BoxShadow(
                                              color: UzaColors.primary
                                                  .withValues(alpha: 0.28),
                                              blurRadius: 18,
                                              offset: const Offset(0, 10),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: authService.isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : const Text(
                                          'Se connecter',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 18,
                              color: UzaColors.primary.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Accès sécurisé à votre espace vendeur',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
