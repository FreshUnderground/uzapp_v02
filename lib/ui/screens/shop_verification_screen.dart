import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/services/auth_service.dart';
import '../../../core/res/uza_colors.dart';
import '../../../core/l10n/tr.dart';
import '../../../data/local/uza_database.dart';
import '../../../data/repositories/shop_repository.dart';
import '../../../data/services/sync_service.dart';

class ShopVerificationScreen extends StatefulWidget {
  final Shop shop;

  const ShopVerificationScreen({super.key, required this.shop});

  @override
  State<ShopVerificationScreen> createState() => _ShopVerificationScreenState();
}

class _ShopVerificationScreenState extends State<ShopVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  int _countdown = 30;
  Timer? _countdownTimer;
  bool _canResend = false;
  String? _otpErrorMessage;
  String? _phoneNumber;

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _phoneNumber = widget.shop.phone;
    if (_phoneNumber != null && _phoneNumber!.isNotEmpty) {
      _sendOtp();
    }
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

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  bool get _isOtpComplete {
    return _otpCode.length == 6 &&
        _otpCode.runes.every((r) => r >= 48 && r <= 57);
  }

  Future<void> _sendOtp() async {
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'phone_unavailable'))),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _otpErrorMessage = null;
    });

    final authService = context.read<AuthService>();
    authService.verifyPhone(
      phoneNumber: _phoneNumber!,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _isSendingOtp = false;
            _otpSent = true;
          });
          _startCountdown();
        }
      },
      onFailed: (e) {
        if (mounted) {
          setState(() {
            _isSendingOtp = false;
          });
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
        }
      },
    );
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

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete) return;

    setState(() {
      _isVerifyingOtp = true;
      _otpErrorMessage = null;
    });

    final authService = context.read<AuthService>();
    try {
      await authService.signInWithOTP(_phoneNumber!, _otpCode);

      // Update shop verification status
      final shopRepo = context.read<ShopRepository>();
      await shopRepo.updateShop(
        ShopsCompanion(
          id: drift.Value(widget.shop.id),
          isVerified: drift.Value(true),
        ),
      );

      // Queue for server sync
      final syncService = context.read<SyncService>();
      await syncService.addToQueue('UPDATE', 'shops', {
        'local_id': widget.shop.id,
        'id': (widget.shop.remoteId != null && widget.shop.remoteId!.isNotEmpty)
            ? (int.tryParse(widget.shop.remoteId!) ?? widget.shop.id)
            : widget.shop.id,
        'isVerified': true,
      });
      syncService.forcePush();

      if (mounted) {
        setState(() {
          _otpVerified = true;
          _isVerifyingOtp = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'shop_verified_success')),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _otpErrorMessage = e.toString().replaceAll('Exception: ', '');
          _isVerifyingOtp = false;
        });
        _shakeController.forward().then((_) => _shakeController.reset());
        for (final c in _otpControllers) {
          c.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_otpVerified) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.green,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Boutique Vérifiée!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.shop.name} a maintenant le badge vérifié',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, 'verify_shop')),
        foregroundColor: UzaColors.onSurface(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Shop info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: UzaColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: UzaColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.store,
                        color: UzaColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.shop.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _phoneNumber ?? 'Numero non disponible',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (!_otpSent) ...[
                // Waiting for OTP to be sent
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Envoi du code de verification...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // OTP Input
                const Text(
                  'Entrez le code reçu par SMS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Un code a 6 chiffres a été envoyé au $_phoneNumber',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // OTP Fields
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeController.value * 10, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 48,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: UzaColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _otpFocusNodes[index + 1].requestFocus();
                            }
                            if (_isOtpComplete) {
                              _verifyOtp();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),

                if (_otpErrorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _otpErrorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 32),

                // Resend code
                Center(
                  child: _canResend
                      ? TextButton(
                          onPressed: _isSendingOtp ? null : _sendOtp,
                          child: Text(
                            _isSendingOtp ? 'Envoi...' : 'Renvoyer le code',
                            style: const TextStyle(
                              color: UzaColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : Text(
                          'Renvoyer le code dans $_countdown s',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                ),

                const SizedBox(height: 24),

                // Verify button
                ElevatedButton(
                  onPressed: _isVerifyingOtp || !_isOtpComplete
                      ? null
                      : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: UzaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifyingOtp
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Vérifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
