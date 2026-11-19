/// VYRO AI — Login Screen (dedicated)
///
/// Standalone sign-in page: Google / Facebook / Apple, email + password,
/// forgot password, phone OTP and guest mode. "Create account" navigates to
/// the separate Register screen. Uses shared auth widgets for a consistent
/// professional look with the Register page.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/auth_shared.dart';
import '../widgets/branding.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _phoneStage = false; // phone-number entry step of the OTP flow

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  String? _message;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  AuthProvider get _auth => Provider.of<AuthProvider>(context, listen: false);

  void _setMessage(String? m) {
    if (!mounted) return;
    setState(() => _message = m);
  }

  Future<void> _finish(bool ok, {String? successMessage}) async {
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      _setMessage(_auth.error);
    }
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(email);

  // ============================== EMAIL LOGIN ================================
  Future<void> _submitEmailLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _setMessage('Please enter email and password.');
      return;
    }
    if (!_isValidEmail(email)) {
      _setMessage('Please enter a valid email address.');
      return;
    }
    setState(() {
      _isLoading = true;
      _message = null;
    });
    final ok = await _auth.signInWithEmailPassword(email, password);
    await _finish(ok);
  }

  // ============================= SOCIAL LOGIN ================================
  Future<void> _signInWithProvider(String provider) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    bool ok;
    switch (provider) {
      case 'google':
        ok = await _auth.signInWithGoogle();
      case 'facebook':
        ok = await _auth.signInWithFacebook();
      case 'apple':
        ok = await _auth.signInWithApple();
      default:
        ok = false;
    }
    await _finish(ok);
  }

  // =============================== PHONE OTP =================================
  Future<void> _requestOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _setMessage('Please enter your phone number.');
      return;
    }
    setState(() {
      _isLoading = true;
      _message = null;
    });
    final ok = await _auth.sendOtp(phone);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _setMessage('OTP sent to $phone');
    } else {
      _setMessage(_auth.error);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.isEmpty) {
      _setMessage('Please enter the OTP code.');
      return;
    }
    setState(() {
      _isLoading = true;
      _message = null;
    });
    final ok = await _auth.verifyOtp(code);
    await _finish(ok);
  }

  Future<void> _resendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _setMessage('Please enter your phone number.');
      return;
    }
    setState(() {
      _isLoading = true;
      _message = null;
    });
    final ok = await _auth.resendOtp(phone);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _setMessage('OTP resent to $phone');
    } else {
      _setMessage(_auth.error);
    }
  }

  // ================================ GUEST ====================================
  Future<void> _continueAsGuest() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    final ok = await _auth.signInAnonymously();
    await _finish(ok);
  }

  // ================================= UI ======================================
  Widget _formCard() {
    final otpSent = _auth.phoneOtpSent;
    final heading = otpSent
        ? 'Verify your phone'
        : _phoneStage
            ? 'Sign in with phone'
            : 'Welcome Back';
    final subheading = otpSent
        ? 'Enter the OTP code sent to your number.'
        : _phoneStage
            ? 'We will send a one-time code to your phone.'
            : 'Sign in to continue creating with AI.';

    return Container(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandRow(),
          const SizedBox(height: 32),
          Text(
            heading,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subheading,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 28),
          if (!_phoneStage && !otpSent)
            SocialButtonsBlock(
              enabled: !_isLoading,
              onProvider: _signInWithProvider,
              orLabel: 'Or sign in with email',
            ),
          const SizedBox(height: 8),
          AuthMessage(message: _message),
          if (!_phoneStage && !otpSent)
            ..._emailSection()
          else if (_phoneStage && !otpSent)
            ..._phoneSection()
          else
            ..._otpSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _brandRow() {
    return Row(
      children: [
        const VyroLogo(size: 44, borderRadius: 12, glow: false),
        const SizedBox(width: 12),
        const VyroWordmark(fontSize: 20, letterSpacing: -0.5),
      ],
    );
  }

  List<Widget> _emailSection() {
    return [
      AuthInput(
        controller: _emailCtrl,
        label: 'Email address',
        icon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 16),
      AuthInput(
        controller: _passwordCtrl,
        label: 'Password',
        icon: Icons.lock_outlined,
        obscure: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submitEmailLogin(),
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: VyroColors.primaryPurple,
                  checkColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF334155)),
                  onChanged: _isLoading
                      ? null
                      : (v) => setState(() => _rememberMe = v ?? false),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Remember me',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: _isLoading
                ? null
                : () => Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
            child: Text(
              'Forgot password?',
              style: TextStyle(
                color: VyroColors.primaryPurpleLight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      AuthPrimaryButton(
        label: 'Sign in',
        loading: _isLoading,
        onPressed: _submitEmailLogin,
      ),
      const SizedBox(height: 20),
      AuthGhostButton(
        label: 'Continue as guest',
        enabled: !_isLoading,
        onPressed: _continueAsGuest,
      ),
      const SizedBox(height: 12),
      AuthGhostButton(
        label: 'Sign in with phone',
        icon: Icons.phone_outlined,
        enabled: !_isLoading,
        onPressed: () => setState(() {
          _phoneStage = true;
          _message = null;
        }),
      ),
      const SizedBox(height: 20),
      Center(child: _registerLink()),
    ];
  }

  List<Widget> _phoneSection() {
    return [
      AuthInput(
        controller: _phoneCtrl,
        label: 'Phone number',
        icon: Icons.phone_outlined,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _requestOtp(),
      ),
      const SizedBox(height: 20),
      AuthPrimaryButton(
        label: 'Send OTP',
        loading: _isLoading,
        onPressed: _requestOtp,
      ),
      const SizedBox(height: 16),
      const Text(
        'Standard messaging rates may apply.',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontFamily: 'Inter',
        ),
      ),
      const SizedBox(height: 20),
      AuthGhostButton(
        label: 'Back',
        enabled: !_isLoading,
        onPressed: () => setState(() {
          _phoneStage = false;
          _message = null;
        }),
      ),
      const SizedBox(height: 20),
      Center(child: _registerLink()),
    ];
  }

  List<Widget> _otpSection() {
    return [
      AuthInput(
        controller: _otpCtrl,
        label: 'OTP code',
        icon: Icons.vpn_key_outlined,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _verifyOtp(),
      ),
      const SizedBox(height: 20),
      AuthPrimaryButton(
        label: 'Verify OTP',
        loading: _isLoading,
        onPressed: _verifyOtp,
      ),
      const SizedBox(height: 14),
      Center(
        child: TextButton(
          onPressed: _isLoading ? null : _resendOtp,
          child: Text(
            'Resend OTP',
            style: TextStyle(
              color: VyroColors.primaryPurpleLight,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      AuthGhostButton(
        label: 'Back',
        enabled: !_isLoading,
        onPressed: () => setState(() {
          _phoneStage = false;
          _message = null;
        }),
      ),
      const SizedBox(height: 20),
      Center(child: _registerLink()),
    ];
  }

  Widget _registerLink() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            "Don't have an account? ",
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
              fontFamily: 'Inter',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: _isLoading
              ? null
              : () => Navigator.of(context).pushReplacementNamed(AppRoutes.register),
          child: Text(
            'Create account',
            style: const TextStyle(
              color: VyroColors.primaryPurpleLight,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(formPanel: _formCard());
  }
}
