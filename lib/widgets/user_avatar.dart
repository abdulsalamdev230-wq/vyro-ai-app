/// VYRO AI — User Avatar Widget
///
/// Instagram-style profile avatar: shows the sign-in provider's profile
/// picture (e.g. Google account photo) when available, and gracefully falls
/// back to a gradient initial-letter avatar if the image is missing or fails
/// to load (bad network, revoked URL, etc.).

import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;

  const UserAvatar({super.key, required this.user, this.radius = 40});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (user?.profileImage ?? '').trim();
    if (imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF17243B),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            // Graceful fallback: if the Google photo fails to load, show the
            // letter avatar instead of a broken image or blank circle.
            errorBuilder: (context, error, stackTrace) =>
                _initialAvatar(radius),
            frameBuilder: (context, child, frame, wasSync) {
              if (wasSync) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: child,
              );
            },
          ),
        ),
      );
    }
    return _initialAvatar(radius);
  }

  Widget _initialAvatar(double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8855FF), Color(0xFF00D5FF)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.72,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  String _initial() {
    final name = (user?.fullName ?? 'U').trim();
    if (name.isEmpty) return 'U';
    return name.substring(0, 1).toUpperCase();
  }
}

/// A small chip that shows which provider the user signed in with
/// (e.g. "Signed in with Google"), Instagram-account-style.
class ProviderChip extends StatelessWidget {
  final UserModel? user;

  const ProviderChip({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = (user?.authProvider ?? 'guest').toLowerCase();
    final (label, icon) = switch (provider) {
      'google' => ('Signed in with Google', Icons.g_mobiledata),
      'facebook' => ('Signed in with Facebook', Icons.facebook),
      'apple' => ('Signed in with Apple', Icons.apple),
      'phone' => ('Signed in with Phone', Icons.phone_outlined),
      'password' => ('Signed in with Email', Icons.email_outlined),
      _ => ('Guest account', Icons.person_outline),
    };
    final isGuest = provider == 'guest' || provider == 'anonymous';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isGuest
            ? const Color(0xFF94A3B8).withValues(alpha: 0.2)
            : const Color(0xFF10B981).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGuest
              ? const Color(0xFF94A3B8).withValues(alpha: 0.5)
              : const Color(0xFF10B981).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isGuest ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isGuest ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
