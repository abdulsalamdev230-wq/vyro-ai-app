/// VYRO AI — Unified AI History
///
/// Every AI generation the signed-in user has created — images, videos and
/// voice — streamed live from their private Firestore `aiJobs` collection.
/// Includes type filters, prompt search, date grouping and per-item actions
/// (preview, download, share, delete). Honest empty/error states.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/firebase_service.dart';
import '../../core/services/image_download.dart';
import '../../core/services/video_download.dart';
import '../../models/user_model.dart';
import '../widgets/cors_image.dart';
import '../widgets/unavailable_state.dart';
import '../widgets/video_result_player.dart';

class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({super.key, this.embedded = false});

  /// When true, renders without its own Scaffold for the bottom-nav shell.
  final bool embedded;

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  String _filter = 'all'; // all | image | video | voice
  String _query = '';
  StreamSubscription? _sub;
  List<AiJobModel> _jobs = [];
  bool _loaded = false;
  bool _unavailable = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _subscribe() {
    final fs = FirebaseService.instance;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (!fs.isInitialized || uid == null || uid.isEmpty) {
      setState(() => _unavailable = true);
      return;
    }
    _sub = fs
        .jobsCollection(uid)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            final jobs = snap.docs
                .map(
                  (d) => AiJobModel.fromMap(
                    d.data() as Map<String, dynamic>,
                    d.id,
                  ),
                )
                .toList();
            // Newest first.
            jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            setState(() {
              _jobs = jobs;
              _loaded = true;
            });
          },
          onError: (_) {
            if (mounted) {
              setState(() {
                _loaded = true;
                _unavailable = true;
              });
            }
          },
        );
  }

  List<AiJobModel> get _filtered {
    Iterable<AiJobModel> jobs = _jobs;
    if (_filter == 'image') {
      jobs = jobs.where((j) => j.type == AiGenerationType.aiImage);
    } else if (_filter == 'video') {
      jobs = jobs.where(
        (j) => const {
          AiGenerationType.textToVideo,
          AiGenerationType.imageToVideo,
          AiGenerationType.scriptToVideo,
        }.contains(j.type),
      );
    } else if (_filter == 'voice') {
      jobs = jobs.where((j) => j.type == AiGenerationType.aiVoice);
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      jobs = jobs.where((j) => j.prompt.toLowerCase().contains(q));
    }
    return jobs.toList();
  }

  String _dateLabel(DateTime t) {
    final now = DateTime.now();
    final diff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(t.year, t.month, t.day)).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This week';
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF17243B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF263750)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _query = v),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontFamily: 'Inter',
                          ),
                          cursorColor: const Color(0xFF00D5FF),
                          decoration: const InputDecoration(
                            hintText: 'Search your generations…',
                            hintStyle: TextStyle(
                              color: Color(0xFF5B6B85),
                              fontSize: 13.5,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _chip('All', 'all', const Color(0xFF8855FF)),
              _chip('Images', 'image', const Color(0xFF00D5FF)),
              _chip('Videos', 'video', const Color(0xFF8855FF)),
              _chip('Voice', 'voice', const Color(0xFFEC4899)),
            ],
          ),
        ),
        Expanded(child: _buildList()),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1220),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'AI History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _chip(String label, String value, Color color) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.18)
                : const Color(0xFF17243B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : const Color(0xFF263750),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_unavailable) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          UnavailableState(
            title: 'History unavailable',
            message:
                'Your generation history lives in your private cloud storage. '
                'Sign in and try again.',
            icon: Icons.cloud_off_outlined,
          ),
        ],
      );
    }
    if (!_loaded) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D5FF)),
      );
    }
    final jobs = _filtered;
    if (jobs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          UnavailableState(
            title: _query.isEmpty ? 'Nothing here yet' : 'No matches',
            message: _query.isEmpty
                ? 'Create something in AI Chat, Image, Video or Voice and it '
                      'will appear here automatically.'
                : 'Try a different search term or filter.',
            icon: _query.isEmpty
                ? Icons.auto_awesome_mosaic_outlined
                : Icons.search_off_rounded,
          ),
        ],
      );
    }

    // Group by date bucket.
    final groups = <String, List<AiJobModel>>{};
    for (final j in jobs) {
      groups.putIfAbsent(_dateLabel(j.createdAt), () => []).add(j);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Text(
              entry.key,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                letterSpacing: 0.6,
                fontFamily: 'Inter',
              ),
            ),
          ),
          ...entry.value.map(_buildTile),
        ],
      ],
    );
  }

  Widget _buildTile(AiJobModel job) {
    final (icon, color, typeLabel) = _typeMeta(job.type);
    final completed = job.status == AiJobStatus.completed;
    final thumbnail = job.imageUrl ?? job.thumbnailUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF17243B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF263750)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF101B35),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: thumbnail != null && thumbnail.isNotEmpty
                ? (thumbnail.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: thumbnail,
                          fit: BoxFit.cover,
                          httpHeaders: const {'User-Agent': 'VyroAI/1.0'},
                          errorWidget: (_, _, _) =>
                              Icon(icon, color: color, size: 24),
                        )
                      : Icon(icon, color: color, size: 24))
                : Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.prompt.isEmpty ? typeLabel : job.prompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    height: 1.3,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusLabel(job),
                  style: TextStyle(
                    color: completed
                        ? const Color(0xFF10B981)
                        : job.status == AiJobStatus.failed
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF94A3B8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          if (completed) ...[
            IconButton(
              tooltip: 'Preview',
              icon: Icon(Icons.visibility_outlined, color: color, size: 20),
              onPressed: () => _preview(job),
            ),
          ],
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
            onPressed: () => _confirmDelete(job),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AiJobModel job) {
    switch (job.status) {
      case AiJobStatus.completed:
        final t = job.completedAt ?? job.createdAt;
        return '${_typeMeta(job.type).$3} • ${_ago(t)}';
      case AiJobStatus.failed:
        return 'Failed • ${_ago(job.createdAt)}';
      case AiJobStatus.cancelled:
        return 'Cancelled • ${_ago(job.createdAt)}';
      default:
        return 'Processing…';
    }
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  (IconData, Color, String) _typeMeta(AiGenerationType type) {
    switch (type) {
      case AiGenerationType.aiImage:
        return (Icons.image_outlined, const Color(0xFF00D5FF), 'Image');
      case AiGenerationType.aiVoice:
        return (Icons.mic_none_outlined, const Color(0xFFEC4899), 'Voice');
      default:
        return (Icons.movie_outlined, const Color(0xFF8855FF), 'Video');
    }
  }

  // ==========================================================================
  // PREVIEW + ACTIONS
  // ==========================================================================

  void _preview(AiJobModel job) {
    final url = job.resultUrl ?? job.imageUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('This generation has no stored result.'),
        ),
      );
      return;
    }
    if (job.type == AiGenerationType.aiVoice) {
      _playAudio(url);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1420),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (context, scrollCtrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      job.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  if (job.type != AiGenerationType.aiImage)
                    IconButton(
                      icon: const Icon(
                        Icons.download_rounded,
                        color: Color(0xFF00D5FF),
                      ),
                      onPressed: () => _downloadFile(url, job),
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.share_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: () =>
                        Share.share(job.prompt, subject: 'Vyro AI'),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: job.type == AiGenerationType.aiImage
                  ? InteractiveViewer(
                      maxScale: 4,
                      child: Center(
                        child: url.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: url,
                                httpHeaders: const {'User-Agent': 'VyroAI/1.0'},
                              )
                            : CorsImage(url: url),
                      ),
                    )
                  : VideoResultPlayer(url: url),
            ),
          ],
        ),
      ),
    );
  }

  void _playAudio(String url) async {
    try {
      if (_playingId != null) {
        await _audioPlayer.stop();
        if (_playingId == 'playing') {
          setState(() => _playingId = null);
          return;
        }
      }
      setState(() => _playingId = 'playing');
      if (url.startsWith('http')) {
        await _audioPlayer.play(UrlSource(url));
      } else if (url.startsWith('data:audio')) {
        final bytes = Uint8List.fromList(base64Decode(url.split(',').last));
        await _audioPlayer.play(BytesSource(bytes));
      }
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingId = null);
      });
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not play this audio.'),
        ),
      );
    }
  }

  Future<void> _downloadFile(String url, AiJobModel job) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Downloading…'),
        ),
      );
      final note = job.type == AiGenerationType.aiImage
          ? await downloadImage(url)
          : await downloadVideo(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(note)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Download failed: $e'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(AiJobModel job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17243B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete this generation?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontFamily: 'Inter',
          ),
        ),
        content: Text(
          job.prompt.isEmpty ? 'This item will be removed.' : '"${job.prompt}"',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final fs = FirebaseService.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        await fs.jobsCollection(uid).doc(job.id).delete();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Delete failed: $e'),
        ),
      );
    }
  }
}
