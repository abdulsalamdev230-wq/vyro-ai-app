/// VYRO AI — Register Screen (dedicated)
///
/// Standalone create-account page: full name + email + password + confirm,
/// plus Google / Facebook / Apple options. "Sign in" navigates to the
/// separate Login screen. Uses shared auth widgets for a consistent look.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../widgets/auth_shared.dart';
import '../widgets/branding.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;
  bool _agreedToTerms = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  String? _message;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  AuthProvider get _auth => Provider.of<AuthProvider>(context, listen: false);

  void _setMessage(String? m) {
    if (!mounted) return;
    setState(() => _message = m);
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w\.\-+]+@([\w\-]+\.)+[a-zA-Z]{2,}$').hasMatch(email);

  // ============================ EMAIL SIGNUP =================================
  Future<void> _submitSignup() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmCtrl.text.trim();

    if (name.isEmpty) {
      _setMessage('Please enter your full name.');
      return;
    }
    if (name.length < 2) {
      _setMessage('Name looks too short.');
      return;
    }
    if (email.isEmpty) {
      _setMessage('Please enter your email address.');
      return;
    }
    if (!_isValidEmail(email)) {
      _setMessage('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _setMessage('Please choose a password.');
      return;
    }
    if (password != confirmPassword) {
      _setMessage('Passwords do not match.');
      return;
    }
    if (password.length < 6) {
      _setMessage('Password must be at least 6 characters.');
      return;
    }
    if (!_agreedToTerms) {
      _setMessage('Please accept the Terms of Service to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });
    final ok = await _auth.createAccount(email, password, name);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      _setMessage(_auth.error);
    }
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
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      _setMessage(_auth.error);
    }
  }

  // ================================= UI ======================================
  Widget _formCard() {
    return Container(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _brandRow(),
          const SizedBox(height: 32),
          const Text(
            'Create Your Vyro AI Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Join VYRO AI and start creating in minutes.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 28),
          SocialButtonsBlock(
            enabled: !_isLoading,
            onProvider: _signInWithProvider,
            orLabel: 'Or sign up with email',
          ),
          AuthMessage(message: _message),
          AuthInput(
            controller: _nameCtrl,
            label: 'Full name',
            icon: Icons.person_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
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
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthInput(
            controller: _confirmCtrl,
            label: 'Confirm password',
            icon: Icons.lock_outlined,
            obscure: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitSignup(),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'Create account',
            loading: _isLoading,
            onPressed: _submitSignup,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreedToTerms,
                  activeColor: VyroColors.primaryPurple,
                  checkColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF334155)),
                  onChanged: _isLoading
                      ? null
                      : (v) => setState(() => _agreedToTerms = v ?? false),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'I agree to the Terms of Service and Privacy Policy.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontFamily: 'Inter',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Email verification policy note — sent automatically on signup.
          const Text(
            'We will email you a verification link after registration.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontFamily: 'Inter',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Already have an account? ',
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
                      : () =>
                          Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                  child: Text(
                    'Sign in',
                    style: const TextStyle(
                      color: VyroColors.primaryPurpleLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(formPanel: _formCard());
  }
}
