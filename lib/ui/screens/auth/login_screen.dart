import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/tr.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/res/uza_colors.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../core/utils/post_auth_navigation.dart';
import '../../utils/page_transitions.dart';
import '../../components/tap_animator.dart';
import '../../components/uza_phone_field.dart';
import 'verification_screen.dart';

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
            color: isActive || isCurrent
                ? UzaColors.primary
                : (UzaColors.isDark(context)
                    ? Colors.white24
                    : Colors.grey[300]),
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
  bool _useAltIdentifier = false;
  final _identifierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final bool _usePasswordLogin = true; // Password is default
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _hasPassword = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    final hasPassword = _passwordController.text.isNotEmpty;
    if (hasPassword != _hasPassword) {
      setState(() => _hasPassword = hasPassword);
    }
  }

  void _onContinue() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_useAltIdentifier) {
        _phoneNumber = PhoneUtils.normalizeDrc(_identifierController.text);
      }
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
            ).showSnackBar(
              SnackBar(
                content: Text(
                  trf(context, 'error_with_message', {
                    'message': e.message ?? '',
                  }),
                ),
              ),
            );
          },
        );
      }
    }
  }

  Future<void> _goToBestDestination() async {
    if (!mounted) return;
    await goToPostAuthDestination(context);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidIdentifier(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3) return false;
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 9) return true;
    return RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(trimmed);
  }

  String _sanitizeLocalPhoneInput(String value) {
    var digits = PhoneUtils.digitsOnly(value);
    if (digits.startsWith(PhoneUtils.countryCode)) {
      digits = digits.substring(PhoneUtils.countryCode.length);
    }
    if (digits.startsWith('0') && digits.length > 1) {
      digits = digits.substring(1);
    }
    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }
    return digits;
  }

  void _onPhoneChanged(String value) {
    final local = _sanitizeLocalPhoneInput(value);
    if (local != value) {
      _identifierController.value = TextEditingValue(
        text: local,
        selection: TextSelection.collapsed(offset: local.length),
      );
    }
    setState(() {
      _phoneNumber = local.isEmpty ? '' : PhoneUtils.normalizeDrc(local);
      _isPhoneValid = PhoneUtils.isValidDrc(_phoneNumber);
    });
  }

  void _onAltIdentifierChanged(String value) {
    setState(() {
      _phoneNumber = value.trim();
      _isPhoneValid = _isValidIdentifier(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final canSubmit = _isPhoneValid &&
        (!_usePasswordLogin || _hasPassword) &&
        !authService.isLoading;
    final isDark = UzaColors.isDark(context);

    final gradientColors = isDark
        ? [
            UzaColors.primary.withValues(alpha: 0.20),
            const Color(0xFF0B0F17),
            UzaColors.secondary.withValues(alpha: 0.14),
          ]
        : [
            UzaColors.primary.withValues(alpha: 0.16),
            const Color(0xFFF7F8FB),
            UzaColors.secondary.withValues(alpha: 0.12),
          ];

    final cardColor = isDark
        ? const Color(0xFF161C2A).withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.94);

    final cardBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.white;

    final cardShadow = isDark
        ? [
            BoxShadow(
              color: UzaColors.primary.withValues(alpha: 0.10),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ];

    final fieldFill = isDark ? const Color(0xFF1F2738) : Colors.white;
    final fieldBorder = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.grey.shade200;
    final fieldFocusedBorder = isDark
        ? UzaColors.primary.withValues(alpha: 0.95)
        : UzaColors.primary;
    final hintColor = isDark ? Colors.white54 : Colors.grey.shade600;
    final subtleText = isDark ? Colors.white60 : Colors.grey.shade700;
    final backButtonColor = isDark
        ? const Color(0xFF1A2233).withValues(alpha: 0.88)
        : Colors.white.withValues(alpha: 0.92);
    final logoContainerColor = isDark ? const Color(0xFF1A2233) : Colors.white;
    final disabledButtonColor =
        isDark ? const Color(0xFF2E3648) : Colors.grey.shade300;
    final orbPrimary = UzaColors.primary.withValues(alpha: isDark ? 0.14 : 0.10);
    final orbSecondary =
        UzaColors.secondary.withValues(alpha: isDark ? 0.16 : 0.12);

    InputDecoration fieldDecoration({
      required String label,
      required String hint,
      required IconData icon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: UzaColors.onSurfaceSecondary(context),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: hintColor, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: UzaColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: fieldFocusedBorder, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F17) : const Color(0xFFF7F8FB),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
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
                color: orbPrimary,
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
                color: orbSecondary,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 12),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      final navigator = Navigator.of(context);
                      if (navigator.canPop()) {
                        navigator.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        color: backButtonColor,
                        borderRadius: BorderRadius.circular(16),
                        border: isDark
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              )
                            : null,
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: UzaColors.onSurface(context),
                        ),
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
                              color: logoContainerColor,
                              borderRadius: BorderRadius.circular(30),
                              border: isDark
                                  ? Border.all(
                                      color: Colors.white.withValues(alpha: 0.08),
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: UzaColors.primary.withValues(
                                    alpha: isDark ? 0.28 : 0.18,
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
                          tr(context, 'login_welcome'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: UzaColors.onSurface(context),
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr(context, 'login_subtitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: UzaColors.onSurfaceSecondary(context),
                            fontSize: 15.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: cardBorderColor),
                            boxShadow: cardShadow,
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
                                        alpha: isDark ? 0.18 : 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      border: isDark
                                          ? Border.all(
                                              color: UzaColors.primary
                                                  .withValues(alpha: 0.22),
                                            )
                                          : null,
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
                                          tr(context, 'login_shop_title'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: UzaColors.onSurface(context),
                                              ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          tr(context, 'login_shop_hint'),
                                          style: TextStyle(
                                            color: hintColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              if (!_useAltIdentifier)
                                TextFormField(
                                  controller: _identifierController,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(9),
                                  ],
                                  decoration: fieldDecoration(
                                    label: tr(context, 'login_phone_label'),
                                    hint: tr(context, 'login_phone_hint'),
                                    icon: Icons.phone_outlined,
                                  ).copyWith(
                                    prefixIcon: null,
                                    prefix: uzaLoginPhonePrefix(context),
                                  ),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                    color: UzaColors.onSurface(context),
                                  ),
                                  onChanged: _onPhoneChanged,
                                  validator: (value) {
                                    final normalized = PhoneUtils.normalizeDrc(
                                      value ?? '',
                                    );
                                    if (!PhoneUtils.isValidDrc(normalized)) {
                                      return tr(context, 'login_invalid_phone');
                                    }
                                    return null;
                                  },
                                )
                              else
                                TextFormField(
                                  controller: _identifierController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: fieldDecoration(
                                    label: tr(context, 'login_identifier_label'),
                                    hint: tr(context, 'login_identifier_hint'),
                                    icon: Icons.badge_outlined,
                                  ),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: UzaColors.onSurface(context),
                                  ),
                                  onChanged: _onAltIdentifierChanged,
                                  validator: (value) {
                                    if (!_isValidIdentifier(value ?? '')) {
                                      return tr(
                                        context,
                                        'login_invalid_identifier',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: UzaColors.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _useAltIdentifier = !_useAltIdentifier;
                                      _identifierController.clear();
                                      _phoneNumber = '';
                                      _isPhoneValid = false;
                                      _passwordController.clear();
                                      _hasPassword = false;
                                    });
                                  },
                                  child: Text(
                                    _useAltIdentifier
                                        ? 'Utiliser mon numéro'
                                        : tr(context, 'login_identifier_hint'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_showPassword,
                                decoration: fieldDecoration(
                                  label: tr(context, 'login_password_label'),
                                  hint: tr(context, 'login_password_hint'),
                                  icon: Icons.key_rounded,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_rounded
                                          : Icons.visibility_off_rounded,
                                      color: hintColor,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _showPassword = !_showPassword,
                                      );
                                    },
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: UzaColors.onSurface(context),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return tr(
                                      context,
                                      'login_password_required',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: UzaColors.primary,
                                  ),
                                  onPressed: () {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    if (!_useAltIdentifier) {
                                      _phoneNumber = PhoneUtils.normalizeDrc(
                                        _identifierController.text,
                                      );
                                    }
                                    if (_phoneNumber.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            tr(context, 'phone_number'),
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    final authService =
                                        context.read<AuthService>();
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
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e
                                                  .toString()
                                                  .replaceAll('Exception: ', ''),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: Text(tr(context, 'login_forgot_password')),
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
                                        : disabledButtonColor,
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
                                      : Text(
                                          tr(context, 'login_submit'),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: canSubmit
                                                ? Colors.white
                                                : (isDark
                                                    ? Colors.white38
                                                    : Colors.white),
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
                                tr(context, 'login_secure_hint'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: subtleText,
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
    ),
    );
  }
}
