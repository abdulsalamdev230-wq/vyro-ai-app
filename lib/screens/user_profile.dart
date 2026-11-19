/// VYRO AI â€” User Profile Screen


import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';
import '../widgets/user_avatar.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../models/user_model.dart';
import '../../config/app_config.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto(AuthProvider auth) async {
    if (_uploadingPhoto) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 88,
      );
      if (picked == null) return; // user cancelled
      final bytes = await picked.readAsBytes();
      // Derive content type from the file name extension (honest validation).
      final ext = picked.name.split('.').last.toLowerCase();
      final contentType = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      setState(() => _uploadingPhoto = true);
      final ok = await auth.updateProfilePhoto(bytes, contentType: contentType);
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          content: Text(
            ok
                ? 'Profile photo updated.'
                : (auth.error ?? 'Photo upload failed.'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
          content: Text(
            'Could not pick image: $e',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.user;
        return Scaffold(
          backgroundColor: const Color(0xFF0A101C),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Profile', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      // Avatar with a camera edit badge — tap to upload a new
                      // photo (Phase 8: secure Storage upload + Firestore sync).
                      GestureDetector(
                        onTap: () => _pickAndUploadPhoto(auth),
                        child: Stack(
                          children: [
                            UserAvatar(user: user, radius: 42),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8855FF), Color(0xFF00D5FF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF0A101C),
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.photo_camera,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the camera to change your photo',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 8),
                      // Real upload progress (0.0–1.0) while a photo uploads.
                      if (_uploadingPhoto)
                        Consumer<AuthProvider>(
                          builder: (context, a, _) {
                            final p = a.uploadProgress ?? 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: p <= 0 ? null : p,
                                      minHeight: 4,
                                      backgroundColor: const Color(0xFF263750),
                                      valueColor: const AlwaysStoppedAnimation(Color(0xFF8855FF)),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Uploading… ${(p * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 6),
                      Text(user?.fullName ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                      const SizedBox(height: 6),
                      Text(user?.email ?? 'guest@vyro.ai', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                      const SizedBox(height: 10),
                      ProviderChip(user: user),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Consumer<SubscriptionProvider>(
                  builder: (context, sub, child) {
                    return GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Subscription', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 12),
                          ListTile(
                            leading: const Icon(Icons.workspace_premium, color: Color(0xFF8855FF)),
                            title: Text(sub.tier.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            subtitle: Text('${sub.credits} credits remaining', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                            trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.subscription),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.history, color: Color(0xFF00D5FF)),
                            title: const Text('My Projects', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            subtitle: const Text('View and edit your projects', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                            trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                            onTap: () => Navigator.of(context).pushNamed(AppRoutes.myProjects),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI Providers (transparency)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...AppConfig.providerAvailability().entries.map((e) {
                        return ListTile(
                          leading: Icon(
                            e.value ? Icons.check_circle : Icons.error_outline,
                            color: e.value ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                          ),
                          title: Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            e.value ? 'Configured' : 'Not configured â€” feature unavailable',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      const Text(
                        'VYRO AI never fakes AI results. If no provider key is set, the feature shows this unavailable state.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () async {
                      await auth.signOut();
                      if (!mounted) return;
                      Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
                    },
                    child: const Text('Sign out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
