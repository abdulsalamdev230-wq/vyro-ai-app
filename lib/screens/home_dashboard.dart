/// VYRO AI â€” Home Dashboard
///
/// Main hub: floating AI orb, animated gradient background, feature cards,
/// recent projects and quick actions. Bottom navigation switches sections.


import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';
import '../widgets/user_avatar.dart';
import '../../core/animations/dashboard_animations.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/video_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../models/user_model.dart';
import '../../core/services/firebase_service.dart';
import 'ai_assistant.dart';
import 'ai_history_screen.dart';
import 'create_hub_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _index = 0;

  // Real Firestore-backed dashboard stats (null = not loaded / unavailable).
  int? _imageCount;
  int? _videoCount;
  int? _credits;
  bool _statsUnavailable = false;

  // Newest completed generations for the home "Recent Creations" strip.
  List<AiJobModel> _recentJobs = [];
  StreamSubscription? _recentSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().initialize();
      context.read<SubscriptionProvider>().initialize();
      _loadStats();
      _subscribeRecent();
    });
  }

  @override
  void dispose() {
    _recentSub?.cancel();
    super.dispose();
  }

  /// Live stream of the user's newest completed generations for the home
  /// recent-creations strip. Best-effort: failures just leave the strip out.
  void _subscribeRecent() {
    final fs = FirebaseService.instance;
    final uid = context.read<AuthProvider>().user?.id;
    if (!fs.isInitialized || uid == null || uid.isEmpty) return;
    _recentSub = fs.jobsCollection(uid).snapshots().listen((snap) {
      if (!mounted) return;
      final jobs = snap.docs
          .map((d) =>
              AiJobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .where((j) => j.status == AiJobStatus.completed)
          .toList();
      jobs.sort((a, b) =>
          (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));
      setState(() => _recentJobs = jobs.take(10).toList());
    }, onError: (_) {});
  }

  /// Phase 9: dashboard numbers come from real application data — count
  /// aggregations on the user's generated images/videos plus their credit
  /// balance. When Firebase is not configured the row shows an honest
  /// unavailable state instead of fake numbers.
  Future<void> _loadStats() async {
    final fs = FirebaseService.instance;
    final uid = context.read<AuthProvider>().user?.id;
    if (!fs.isInitialized || uid == null || uid.isEmpty) {
      if (mounted) setState(() => _statsUnavailable = true);
      return;
    }
    try {
      // NOTE: count() aggregations fail with a 404 runAggregationQuery error
      // on the web SDK setup used by this project, so plain limited queries
      // are used and counted client-side (collections stay small).
      // Jobs are written to users/{uid}/aiJobs (not the top-level
      // generated_images/generated_videos collections), so we count from
      // jobsCollection and filter by type client-side.
      final jobsSnap = await fs.jobsCollection(uid).limit(200).get();
      final imageDocs = <QueryDocumentSnapshot<Object?>>[];
      final videoDocs = <QueryDocumentSnapshot<Object?>>[];
      for (final d in jobsSnap.docs) {
        try {
          final job = AiJobModel.fromMap(
              d.data() as Map<String, dynamic>, d.id);
          switch (job.type) {
            case AiGenerationType.aiImage:
              imageDocs.add(d);
            case AiGenerationType.textToVideo:
            case AiGenerationType.imageToVideo:
            case AiGenerationType.scriptToVideo:
              videoDocs.add(d);
            case AiGenerationType.aiVoice:
              break;
          }
        } catch (_) {
          // Skip malformed docs.
        }
      }
      if (!mounted) return;
      final creditsDoc = await fs.userCreditsDoc(uid).get();
      setState(() {
        _imageCount = imageDocs.length;
        _videoCount = videoDocs.length;
        if (creditsDoc.exists) {
          _credits =
              (creditsDoc.data() as Map<String, dynamic>)['balance'] as int? ?? 0;
        } else {
          _credits = 0;
        }
      });
    } catch (_) {
      // Firestore read failed (rules/offline) — show honest unavailable state.
      if (mounted) setState(() => _statsUnavailable = true);
    }
  }

  Widget _statCard({
    required String label,
    required IconData icon,
    required Color color,
    int? value,
  }) {
    return Container(
      width: 108,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF17243B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            _statsUnavailable || value == null
                ? '—' // honest: no data available
                : '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 0),
        children: [
          _statCard(
            label: 'Images',
            icon: Icons.image_outlined,
            color: const Color(0xFF00D5FF),
            value: _imageCount,
          ),
          const SizedBox(width: 12),
          _statCard(
            label: 'Videos',
            icon: Icons.videocam_outlined,
            color: const Color(0xFF8855FF),
            value: _videoCount,
          ),
          const SizedBox(width: 12),
          _statCard(
            label: 'Credits',
            icon: Icons.bolt_outlined,
            color: const Color(0xFF10B981),
            value: _credits,
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        child: IndexedStack(
          index: _index,
          children: [
            _homeTab(context),
            const AiAssistantScreen(embedded: true),
            const CreateHub(),
            const AiHistoryScreen(embedded: true),
            _profileTab(context),
          ],
        ),
      ),
      bottomNavigationBar: SmoothBottomNav(
        currentIndex: _index,
        items: [
          BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', color: Color(0xFF8855FF)),
          BottomNavItem(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'AI Chat', color: Color(0xFF00D5FF)),
          BottomNavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'Create', color: Color(0xFFEC4899)),
          BottomNavItem(icon: Icons.history_rounded, activeIcon: Icons.history_rounded, label: 'History', color: Color(0xFF10B981)),
          BottomNavItem(icon: Icons.person_outlined, activeIcon: Icons.person, label: 'Profile', color: Color(0xFF94A3B8)),
        ],
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  // ============ HOME TAB ============
  Widget _homeTab(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.fullName ?? '';
    final greeting = _timeGreeting();
    return CustomScrollView(
      slivers: [
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 44, 20, 16)),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName.isEmpty
                    ? 'Good day, Creator'
                    : '$greeting, ${userName.split(' ').first}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 4),
              GradientText(
                text: 'Welcome to VYRO AI',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 20),
              // Floating AI orb
              Center(
                child: FloatingAIOrb(
                  size: 120,
                  onTap: () => _navigate(context, AppRoutes.aiVideoGenerator),
                ),
              ),
              const SizedBox(height: 24),
              // Real Firestore-backed stats: images, videos, credits.
              _statsRow(),
              const SizedBox(height: 20),
              // Quick action chips
              _quickRow(context),
              const SizedBox(height: 28),
              _recentCreations(context),
              const SizedBox(height: 28),
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: SectionHeader(title: 'Feature Studio', subtitle: 'Start creating with AI'),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _featureCard(
                  context,
                  title: 'Creation History',
                  subtitle: 'Every image, video and voice you generated.',
                  icon: Icons.history_rounded,
                  color: const Color(0xFF94A3B8),
                  onTap: () => setState(() => _index = 3),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _timeGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Newest completed generations streamed live from the user's private
  /// Firestore history. Tapping one opens the History tab filtered on it.
  Widget _recentCreations(BuildContext context) {
    if (_recentJobs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Creations', subtitle: 'Your latest AI results'),
        const SizedBox(height: 14),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recentJobs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final job = _recentJobs[i];
              final isImage = job.type == AiGenerationType.aiImage;
              final isVoice = job.type == AiGenerationType.aiVoice;
              final thumb = job.imageUrl ?? job.thumbnailUrl ?? '';
              return GestureDetector(
                onTap: () => setState(() => _index = 3),
                child: Container(
                  width: 108,
                  decoration: BoxDecoration(
                    color: const Color(0xFF17243B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isImage && thumb.isNotEmpty)
                        Image.network(
                          thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _recentPlaceholder(isVoice),
                        )
                      else
                        _recentPlaceholder(isVoice),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Color(0xCC0B1220), Colors.transparent],
                            ),
                          ),
                          child: Text(
                            isImage
                                ? 'Image'
                                : isVoice
                                    ? 'Voice'
                                    : 'Video',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _recentPlaceholder(bool isVoice) {
    return Container(
      color: const Color(0xFF101B35),
      child: Center(
        child: Icon(
          isVoice ? Icons.mic_none_rounded : Icons.movie_creation_outlined,
          color: const Color(0xFF46587A),
          size: 26,
        ),
      ),
    );
  }

  Widget _quickRow(BuildContext context) {
    final actions = [
      _chip('Assistant', Icons.chat_bubble_rounded, const Color(0xFF00D5FF), () => _navigate(context, AppRoutes.aiAssistant)),
      _chip('AI Video', Icons.play_circle, const Color(0xFF8855FF), () => _navigate(context, AppRoutes.aiVideoGenerator)),
      _chip('AI Image', Icons.image, const Color(0xFF00D5FF), () => _navigate(context, AppRoutes.aiImageGenerator)),
      _chip('AI Voice', Icons.mic, const Color(0xFFEC4899), () => _navigate(context, AppRoutes.aiVoiceGenerator)),
      _chip('Editor', Icons.edit, const Color(0xFF10B981), () => _navigate(context, AppRoutes.videoEditor)),
    ];
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: actions,
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF17243B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, spreadRadius: 0)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ============ PROFILE TAB ============
  Widget _profileTab(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.user;
        final showVerifyBanner = auth.isSignedIn &&
            !auth.isAnonymous &&
            (user?.authProvider == 'password' || user?.authProvider == 'email') &&
            !auth.isEmailVerified;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(title: 'Profile', subtitle: 'Account & subscription'),
            const SizedBox(height: 16),
            if (showVerifyBanner)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_unread_outlined,
                          color: Color(0xFFF59E0B), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Verify your email to secure your account.',
                          style: TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await auth.sendVerificationEmail();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'Verification email sent. Check your inbox.',
                                style: TextStyle(fontFamily: 'Inter'),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Resend',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            GlassCard(
              child: Column(
                children: [
                  UserAvatar(user: user, radius: 34),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? 'guest@vyro.ai', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                  const SizedBox(height: 16),
                  Consumer<SubscriptionProvider>(
                    builder: (context, sub, child) {
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: sub.isPro ? const Color(0xFF10B981).withValues(alpha: 0.2) : const Color(0xFF94A3B8).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${sub.tier.label} â€¢ ${sub.credits} credits',
                              style: TextStyle(
                                color: sub.isPro ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _navigate(context, AppRoutes.subscription),
                            child: const Text('Upgrade', style: TextStyle(color: Color(0xFF8855FF), fontWeight: FontWeight.w700)),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () async {
                        await AuthProvider.instance.signOut();
                        if (mounted) Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
                      },
                      child: const Text('Sign out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _featureCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
        ],
      ),
    );
  }
}

