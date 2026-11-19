/// VYRO AI â€” Admin Dashboard
///
/// Secure admin dashboard for managing users, content, and platform stats.
/// Only users with role == 'admin' can access this screen.
///

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../widgets/unavailable_state.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _searchQuery = '';
  String _tab = 'users'; // users | content | credits | activity
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Only admins can access.
        if (!auth.isAdmin) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A101C),
            body: Center(
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFFEF4444), size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin Access Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your account is not authorized to view the admin dashboard.',
                      style: TextStyle(color: VyroColors.textMuted, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                        child: const Text('Go to Dashboard'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A101C),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Admin Dashboard', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  await auth.signOut();
                  if (mounted) Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Stats cards
              SizedBox(
                height: 110,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _fs.usersCollection().snapshots(),
                  builder: (context, snap) {
                    final total = snap.data?.size ?? 0;
                    return StreamBuilder<QuerySnapshot>(
                      stream: _fs.usersCollection().where('accountStatus', isEqualTo: 'active').snapshots(),
                      builder: (context, activeSnap) {
                        final active = activeSnap.data?.size ?? 0;
                        return StreamBuilder<QuerySnapshot>(
                          stream: _fs.userProjectsCollection().snapshots(),
                          builder: (context, projSnap) {
                            final projects = projSnap.data?.size ?? 0;
                            return StreamBuilder<QuerySnapshot>(
                              stream: _fs.generatedVideosCollection().snapshots(),
                              builder: (context, vidSnap) {
                                final videos = vidSnap.data?.size ?? 0;
                                return Row(
                                  children: [
                                    _statCard('Total Users', total.toString(), Colors.white),
                                    _statCard('Active', active.toString(), VyroColors.electricBlue),
                                    _statCard('Projects', projects.toString(), VyroColors.primaryPurple),
                                    _statCard('Videos', videos.toString(), VyroColors.accentPink),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Tabs
              Row(
                children: [
                  _tabButton('Users', 'users', Icons.people),
                  _tabButton('Content', 'content', Icons.video_library),
                  _tabButton('Credits', 'credits', Icons.card_giftcard),
                  _tabButton('Activity', 'activity', Icons.history),
                ],
              ),
              const SizedBox(height: 16),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search users by name or emailâ€¦',
                      hintStyle: TextStyle(color: VyroColors.textDim),
                      prefixIcon: const Icon(Icons.search, color: VyroColors.textDim),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _tab == 'users'
                        ? _buildUsersTab(auth)
                        : _tab == 'content'
                            ? _buildContentTab()
                            : _tab == 'credits'
                                ? _buildCreditsTab()
                                : _buildActivityTab(),
              ),
            ],
          ),
        );
      },
    );
  }

  final FirebaseService _fs = FirebaseService.instance;

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: GlassCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: VyroColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, String key, IconData icon) {
    final selected = _tab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = key),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected ? VyroColors.primaryPurple.withValues(alpha: 0.2) : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? VyroColors.primaryPurple : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? VyroColors.primaryPurple : VyroColors.textDim, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: selected ? VyroColors.primaryPurple : VyroColors.textDim, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // USERS TAB
  // ============================================================================

  Widget _buildUsersTab(AuthProvider auth) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.usersCollection().snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        var users = docs.map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id)).toList();

        // Filter by search query.
        if (_searchQuery.isNotEmpty) {
          users = users.where((u) {
            final name = (u.fullName ?? '').toLowerCase();
            final email = (u.email ?? '').toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();
        }

        // Sort: admins first, then by createdAt desc.
        users.sort((a, b) {
          if (a.role == 'admin' && b.role != 'admin') return -1;
          if (a.role != 'admin' && b.role == 'admin') return 1;
          return b.createdAt.compareTo(a.createdAt);
        });

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            final u = users[i];
            return _userRow(u, auth);
          },
        );
      },
    );
  }

  Widget _userRow(UserModel u, AuthProvider auth) {
    final isCurrentUser = u.id == auth.firebaseUser?.uid;
    return GlassCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: u.profileImage != null ? NetworkImage(u.profileImage!) : null,
          child: u.profileImage == null ? Text((u.fullName ?? 'U').isNotEmpty ? u.fullName![0].toUpperCase() : 'U', style: const TextStyle(fontWeight: FontWeight.w800)) : null,
        ),
        title: Text(u.fullName ?? u.email, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(u.email, style: TextStyle(color: VyroColors.textMuted, fontSize: 12)),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: u.accountStatus == 'active' ? VyroColors.success.withValues(alpha: 0.2) : VyroColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(u.accountStatus.toUpperCase(), style: TextStyle(color: u.accountStatus == 'active' ? VyroColors.success : VyroColors.error, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: u.role == 'admin' ? VyroColors.primaryPurple.withValues(alpha: 0.2) : VyroColors.electricBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(u.role.toUpperCase(), style: TextStyle(color: u.role == 'admin' ? VyroColors.primaryPurple : VyroColors.electricBlue, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
        trailing: isCurrentUser
            ? const Text('You', style: TextStyle(color: VyroColors.textDim, fontSize: 11))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(u.accountStatus == 'active' ? Icons.block : Icons.check_circle, color: u.accountStatus == 'active' ? VyroColors.error : VyroColors.success, size: 20),
                    onPressed: () => _toggleAccountStatus(u, auth),
                  ),
                  if (u.role != 'admin')
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings, color: VyroColors.primaryPurple, size: 20),
                      onPressed: () => _toggleAdminRole(u, auth),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _toggleAccountStatus(UserModel u, AuthProvider auth) async {
    setState(() => _isLoading = true);
    try {
      final newStatus = u.accountStatus == 'active' ? 'suspended' : 'active';
      await _fs.userDoc(u.id).update({
        'accountStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAdminRole(UserModel u, AuthProvider auth) async {
    setState(() => _isLoading = true);
    try {
      final newRole = u.role == 'admin' ? 'user' : 'admin';
      await _fs.userDoc(u.id).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (newRole == 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Admin role granted to ${u.fullName}')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Admin role revoked from ${u.fullName}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================================================================
  // CONTENT TAB
  // ============================================================================

  Widget _buildContentTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.generatedVideosCollection().snapshots(),
      builder: (context, snap) {
        final videos = snap.data?.docs ?? [];
        return ListView.builder(
          itemCount: videos.length,
          itemBuilder: (context, i) {
            final d = videos[i];
            final data = d.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: GlassCard(
                child: ListTile(
                  title: Text(data['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  subtitle: Text('User: ${data['userId'] ?? 'unknown'}', style: TextStyle(color: VyroColors.textMuted, fontSize: 12)),
                  trailing: Text(data['type'] ?? '', style: const TextStyle(color: VyroColors.primaryPurple, fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================================
  // CREDITS TAB
  // ============================================================================

  Widget _buildCreditsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.userCreditsCollection().snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: GlassCard(
                child: ListTile(
                  title: Text(data['uid'] ?? 'unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  subtitle: Text('Balance: ${data['balance'] ?? 0} credits', style: TextStyle(color: VyroColors.textMuted, fontSize: 12)),
                  trailing: Text('Spent: ${data['totalSpent'] ?? 0}', style: const TextStyle(color: VyroColors.accentPink, fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================================
  // ACTIVITY TAB
  // ============================================================================

  Widget _buildActivityTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.loginActivityCollection().snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: GlassCard(
                child: ListTile(
                  leading: Icon(data['success'] == true ? Icons.login : Icons.logout, color: data['success'] == true ? VyroColors.success : VyroColors.error, size: 20),
                  title: Text(data['userId'] ?? 'unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['provider'] ?? 'unknown', style: TextStyle(color: VyroColors.textMuted, fontSize: 12)),
                      if (data['failureReason'] != null)
                        Text(data['failureReason'], style: const TextStyle(color: VyroColors.error, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
