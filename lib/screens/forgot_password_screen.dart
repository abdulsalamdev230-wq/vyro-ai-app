/// VYRO AI — Forgot Password Screen (dedicated)
///
/// Professional password-reset page: enter email → receive reset link →
/// confirmation state → back to Login. Uses shared auth widgets.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/auth_shared.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool get _emailValid {
    final email = _emailCtrl.text.trim();
    return RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _sendResetLink() async {
    if (!_emailValid) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final ok = await context
        .read<AuthProvider>()
        .forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _sent = ok;
      if (!ok) _error = context.read<AuthProvider>().error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      body: Stack(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0A101C), Color(0xFF0D1420)],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar: back to login
                    TextButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.login),
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'Back to sign in',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8855FF), Color(0xFF00D5FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF8855FF).withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _sent ? 'Check your inbox' : 'Reset password',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sent
                          ? 'We sent a password reset link to your email. '
                              'Open it and follow the steps to set a new password.'
                          : 'Enter your account email and we will send you a '
                              'secure reset link.',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (!_sent) ...[
                      AuthMessage(message: _error),
                      AuthInput(
                        controller: _emailCtrl,
                        label: 'Email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _sendResetLink(),
                      ),
                      const SizedBox(height: 24),
                      AuthPrimaryButton(
                        label: 'Send reset link',
                        loading: _isLoading,
                        onPressed: _sendResetLink,
                      ),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Icon(
                                Icons.mark_email_read_outlined,
                                color: Color(0xFF10B981),
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.of(context)
                                  .pushReplacementNamed(AppRoutes.login),
                              child: Text(
                                'Back to sign in',
                                style: TextStyle(
                                  color: VyroColors.primaryPurpleLight,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
