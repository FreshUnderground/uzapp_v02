import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/res/uza_colors.dart';
import '../../components/tap_animator.dart';

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

class VerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const VerificationScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  int _countdown = 30;
  Timer? _countdownTimer;
  bool _canResend = false;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 30;
      _canResend = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String _formatPhone(String phone) {
    // Format +243 XX XXX XX XX
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 9) {
      final countryCode = digits.length > 9
          ? digits.substring(0, digits.length - 9)
          : '';
      final local = digits.length > 9
          ? digits.substring(digits.length - 9)
          : digits;
      if (local.length == 9) {
        final formatted =
            '${local.substring(0, 2)} ${local.substring(2, 5)} ${local.substring(5, 7)} ${local.substring(7, 9)}';
        return countryCode.isNotEmpty ? '+$countryCode $formatted' : formatted;
      }
    }
    return phone;
  }

  String get _otpCode {
    return _otpControllers.map((c) => c.text).join();
  }

  bool get _isOtpComplete {
    return _otpCode.length == 6 &&
        _otpCode.runes.every((r) => r >= 48 && r <= 57);
  }

  void _onOtpChanged(int index, String value) {
    setState(() {
      _errorMessage = null;
    });

    if (value.length == 1) {
      // Move to next field
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
      // Auto-submit when complete
      if (_isOtpComplete) {
        _onVerify();
      }
    } else if (value.isEmpty && index > 0) {
      // Move to previous on backspace
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _onOtpKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_otpControllers[index].text.isEmpty && index > 0) {
          _otpControllers[index - 1].clear();
          _otpFocusNodes[index - 1].requestFocus();
        }
      }
    }
  }

  Future<void> _onVerify() async {
    if (!_isOtpComplete || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final authService = context.read<AuthService>();
    try {
      await authService.signInWithOTP(widget.verificationId, _otpCode);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        _shakeController.forward().then((_) => _shakeController.reset());
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
        debugPrint('Verification error: $e');
        // Clear OTP fields
        for (final c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _onResend() async {
    if (!_canResend) return;
    final authService = context.read<AuthService>();
    authService.verifyPhone(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (verificationId) {
        _startCountdown();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Code renvoyé')));
        }
      },
      onFailed: (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: ${e.message}')));
        }
      },
    );
  }

  Future<void> _onSkipOTP() async {
    final authService = context.read<AuthService>();
    await authService.signInWithoutOTP(widget.phoneNumber);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Numéro non vérifié. La création de boutique nécessite une vérification.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[800],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: UzaColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StepIndicator(currentStep: 2, totalSteps: 2),
                const SizedBox(height: 40),
                Text(
                  "Vérifie ton téléphone",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: UzaColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Code envoyé au ${_formatPhone(widget.phoneNumber)}",
                  style: TextStyle(
                    color: UzaColors.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // OTP Boxes
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final shakeOffset = _shakeAnimation.value > 0
                        ? 10 *
                              (1 - _shakeAnimation.value) *
                              (_shakeController.status ==
                                      AnimationStatus.forward
                                  ? (_shakeAnimation.value * 2 - 1).abs()
                                  : 0)
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(
                        shakeOffset * (shakeOffset > 0 ? 1 : -1),
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: SizedBox(
                          width: 48,
                          height: 56,
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) => _onOtpKeyEvent(index, event),
                            child: TextFormField(
                              controller: _otpControllers[index],
                              focusNode: _otpFocusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: _errorMessage != null
                                    ? Colors.red.withValues(alpha: 0.05)
                                    : Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _errorMessage != null
                                        ? Colors.redAccent
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _errorMessage != null
                                        ? Colors.redAccent
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: UzaColors.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) => _onOtpChanged(index, value),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 40),
                // Verify button
                TapAnimator(
                  onTap: (_isOtpComplete && !_isVerifying) ? _onVerify : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: (_isOtpComplete && !_isVerifying)
                          ? UzaColors.primary
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _isVerifying || authService.isLoading
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
                            'Vérifier',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Resend code
                Center(
                  child: TextButton(
                    onPressed: _canResend ? _onResend : null,
                    child: Text(
                      _canResend
                          ? "Renvoyer le code"
                          : "Renvoyer le code dans ${_countdown}s",
                      style: TextStyle(
                        color: _canResend ? UzaColors.primary : Colors.grey,
                        fontWeight: _canResend
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Skip OTP
                Center(
                  child: TextButton(
                    onPressed: _isVerifying || authService.isLoading
                        ? null
                        : _onSkipOTP,
                    child: const Text(
                      "Passer (non vérifié)",
                      style: TextStyle(
                        color: UzaColors.secondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Change number link
                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text(
                      "Changer de numéro",
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
