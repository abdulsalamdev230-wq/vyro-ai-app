/// VYRO AI — AI Image Generator Screen + Generated Images Gallery
///
/// Generates images via the configured AI providers (VYRO Worker first) and
/// shows a persistent "Your Generated Images" gallery below the generator.
/// Every image is streamed from the signed-in user's Firestore history so
/// previous generations survive reloads; nothing is faked — an honest error
/// is shown when generation fails.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';
import '../../core/animations/button_animations.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/image_download.dart';
import '../../models/user_model.dart';
import '../widgets/cors_image.dart';

class AIImageGeneratorScreen extends StatefulWidget {
  const AIImageGeneratorScreen({super.key});

  @override
  State<AIImageGeneratorScreen> createState() => _AIImageGeneratorScreenState();
}

class _AIImageGeneratorScreenState extends State<AIImageGeneratorScreen> {
  final _promptCtrl = TextEditingController();
  final _negativeCtrl = TextEditingController();

  bool _generating = false;
  String? _error;
  String? _resultUrl;

  /// Jobs streamed from Firestore (per-user history).
  List<AiJobModel> _history = [];
  bool _historyLoaded = false;
  StreamSubscription? _historySub;

  @override
  void initState() {
    super.initState();
    _subscribeHistory();
  }

  @override
  void dispose() {
    _historySub?.cancel();
    _promptCtrl.dispose();
    _negativeCtrl.dispose();
    super.dispose();
  }

  // ==========================================================================
  // HISTORY STREAM — only this user's generated images, newest first
  // ==========================================================================
  void _subscribeHistory() {
    final uid = AuthProvider.instance.user?.id;
    if (uid == null || uid.isEmpty) {
      if (mounted) setState(() => _historyLoaded = true);
      return;
    }
    final fs = FirebaseService.instance;
    _historySub = fs.jobsCollection(uid).snapshots().listen((snap) {
      if (!mounted) return;
      final jobs = snap.docs
          .map((d) => AiJobModel.fromMap(
                Map<String, dynamic>.from(d.data() as Map<dynamic, dynamic>),
                d.id,
              ))
          .where((j) =>
              j.type == AiGenerationType.aiImage &&
              (j.resultUrl ?? '').isNotEmpty)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _history = jobs;
        _historyLoaded = true;
      });
    }, onError: (_) {
      if (mounted) setState(() => _historyLoaded = true);
    });
  }

  // ==========================================================================
  // GENERATION
  // ==========================================================================
  Future<void> _generate() async {
    if (_generating) return; // prevent duplicate requests
    if (_promptCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a prompt.');
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
      _resultUrl = null;
    });

    final result = await context.read<AiJobNotifier>().generateImage(
          prompt: _promptCtrl.text.trim(),
          negativePrompt:
              _negativeCtrl.text.trim().isEmpty ? null : _negativeCtrl.text.trim(),
          width: 1024,
          height: 1024,
        );

    if (!mounted) return;
    setState(() => _generating = false);
    if (result.success && result.data != null) {
      setState(() => _resultUrl = result.data!.first);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Image generated successfully!',
              style: TextStyle(fontFamily: 'Inter')),
        ),
      );
    } else if (result.unavailable) {
      setState(() => _error = result.error);
    } else {
      setState(() => _error = result.error ?? 'Image generation failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
          content: Text(_error!,
              style: const TextStyle(fontFamily: 'Inter', color: Colors.white)),
        ),
      );
    }
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================
  void _regenerate(String prompt) {
    _promptCtrl.text = prompt;
    _generate();
  }

  Future<void> _download(String url) async {
    final msg = await downloadImage(url);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(msg, style: const TextStyle(fontFamily: 'Inter')),
      ),
    );
  }

  void _copyPrompt(String prompt) {
    Clipboard.setData(ClipboardData(text: prompt));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Prompt copied to clipboard.',
            style: TextStyle(fontFamily: 'Inter')),
      ),
    );
  }

  Future<void> _deleteImage(AiJobModel job) async {
    final uid = AuthProvider.instance.user?.id;
    if (uid == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF101B35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete image?',
            style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
        content: const Text(
          'This removes the image from your gallery. This cannot be undone.',
          style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseService.instance.jobsCollection(uid).doc(job.id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Image deleted.',
              style: TextStyle(fontFamily: 'Inter')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
          content: Text('Delete failed: $e',
              style: const TextStyle(fontFamily: 'Inter', color: Colors.white)),
        ),
      );
    }
  }

  void _openFullscreen(AiJobModel job) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.92),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                maxScale: 5,
                child: CorsImage(url: job.resultUrl!, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 24,
              right: 24,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withValues(alpha: 0.65),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        job.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontFamily: 'Inter'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Download',
                      icon: const Icon(Icons.download_rounded,
                          color: Colors.white),
                      onPressed: () => _download(job.resultUrl!),
                    ),
                    IconButton(
                      tooltip: 'Copy prompt',
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      onPressed: () => _copyPrompt(job.prompt),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Image Generator',
            style: TextStyle(
                fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Consumer<AiJobNotifier>(
        builder: (context, ai, child) {
          if (ai.unavailable) {
            return UnavailableState(
              title: 'AI Image generation unavailable',
              message: ai.unavailableMessage ?? 'No image provider configured.',
              setupHint:
                  'Add an API key for OpenAI, Runware, Stability AI or fal.ai in the .env file.',
              icon: Icons.image_not_supported,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGeneratorCard(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBanner(),
                ],
                if (_resultUrl != null) ...[
                  const SizedBox(height: 20),
                  _buildFreshResult(),
                ],
                const SizedBox(height: 28),
                _buildGallery(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGeneratorCard() {
    return GlassCard(
      child: Column(
        children: [
          const Text('Describe your image',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: _promptCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'A cinematic cyberpunk cityscape at night, neon lights, 8k',
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF263750)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF8855FF)),
              ),
              filled: true,
              fillColor: const Color(0xFF101B35),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _negativeCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Negative prompt (optional)',
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF263750)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF8855FF)),
              ),
              filled: true,
              fillColor: const Color(0xFF101B35),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: LoadingButton(
              loading: _generating,
              onPressed: _generate,
              child: const Text('Generate Image',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontFamily: 'Inter')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!,
                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildFreshResult() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Result',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: CorsImage(url: _resultUrl!),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _navigatePreview(_resultUrl!),
                  child: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _navigatePreview(_resultUrl!),
                  child: const Text('Use in Video'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // GALLERY — "Your Generated Images"
  // ==========================================================================
  Widget _buildGallery() {
    // Merge streamed history with the fresh result so the newest image
    // appears immediately even before the Firestore snapshot round-trips.
    final streamedUrls = _history.map((j) => j.resultUrl).toSet();
    final extra = <AiJobModel>[];
    if (_resultUrl != null && !streamedUrls.contains(_resultUrl)) {
      extra.add(AiJobModel(
        id: 'fresh',
        userId: AuthProvider.instance.user?.id ?? '',
        type: AiGenerationType.aiImage,
        status: AiJobStatus.completed,
        prompt: _promptCtrl.text.trim(),
        resultUrl: _resultUrl,
        thumbnailUrl: _resultUrl,
        progressPercent: 100,
        createdAt: DateTime.now(),
      ));
    }
    final images = [...extra, ..._history];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8855FF), Color(0xFF00D5FF)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Your Generated Images (${images.length})',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  fontFamily: 'Inter'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_historyLoaded)
          _buildSkeletonGrid()
        else if (images.isEmpty)
          _buildEmptyState()
        else
          _buildResponsiveGrid(images),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFF101B35).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF263750)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF8855FF).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.image_outlined,
                color: Color(0xFF8855FF), size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'No images yet',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter a prompt above and tap Generate Image —\nyour creations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF64748B), fontSize: 13, fontFamily: 'Inter', height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _columnCount(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cols,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101B35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF263750)),
            ),
            child: const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Color(0xFF8855FF)),
              ),
            ),
          ),
        );
      },
    );
  }

  int _columnCount(double width) {
    if (width >= 1000) return 4;
    if (width >= 640) return 3;
    return 2;
  }

  Widget _buildResponsiveGrid(List<AiJobModel> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = _columnCount(constraints.maxWidth);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: images.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, i) => _ImageCard(
            job: images[i],
            onPreview: () => _openFullscreen(images[i]),
            onDownload: () => _download(images[i].resultUrl!),
            onCopyPrompt: () => _copyPrompt(images[i].prompt),
            onRegenerate: () => _regenerate(images[i].prompt),
            onDelete: () => _deleteImage(images[i]),
          ),
        );
      },
    );
  }

  void _navigatePreview(String url) {
    Navigator.of(context).pushNamed(AppRoutes.videoPreview, arguments: url);
  }
}

// ============================================================================
// IMAGE CARD — hover animations + full action set
// ============================================================================

class _ImageCard extends StatefulWidget {
  const _ImageCard({
    required this.job,
    required this.onPreview,
    required this.onDownload,
    required this.onCopyPrompt,
    required this.onRegenerate,
    required this.onDelete,
  });

  final AiJobModel job;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onCopyPrompt;
  final VoidCallback onRegenerate;
  final VoidCallback onDelete;

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> {
  bool _hovering = false;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101B35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovering
                  ? const Color(0xFF8855FF).withValues(alpha: 0.55)
                  : const Color(0xFF263750),
            ),
            boxShadow: [
              if (_hovering)
                BoxShadow(
                  color: const Color(0xFF8855FF).withValues(alpha: 0.25),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CorsImage(url: widget.job.resultUrl!),
                      // Tap layer above the native <img> platform view so
                      // taps open the full-screen preview on web too.
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: widget.onPreview,
                          child: const SizedBox.expand(),
                        ),
                      ),
                      // Desktop hover overlay: quick actions
                      Positioned.fill(
                        child: AnimatedOpacity(
                          opacity: _hovering ? 1 : 0,
                          duration: const Duration(milliseconds: 160),
                          child: IgnorePointer(
                            ignoring: !_hovering,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.45),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _overlayIcon(Icons.fullscreen,
                                      'Preview', widget.onPreview),
                                  const SizedBox(width: 10),
                                  _overlayIcon(Icons.download_rounded,
                                      'Download', widget.onDownload),
                                  const SizedBox(width: 10),
                                  _overlayIcon(Icons.refresh_rounded,
                                      'Regenerate', widget.onRegenerate),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  color: const Color(0xFF0B0E1A),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.job.prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Inter',
                            height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _actionIcon(Icons.download_rounded, 'Download',
                              widget.onDownload),
                          _actionIcon(Icons.copy_rounded, 'Copy prompt',
                              widget.onCopyPrompt),
                          _actionIcon(Icons.refresh_rounded, 'Regenerate',
                              widget.onRegenerate),
                          const Spacer(),
                          _actionIcon(
                            Icons.delete_outline_rounded,
                            'Delete',
                            _deleting ? () {} : widget.onDelete,
                            color: const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _overlayIcon(IconData icon, String tooltip, VoidCallback onTap) {
    return _HoverPillButton(
      icon: icon,
      tooltip: tooltip,
      onTap: onTap,
    );
  }

  Widget _actionIcon(IconData icon, String tooltip, VoidCallback onTap,
      {Color color = const Color(0xFF94A3B8)}) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 19, color: color),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 30),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _HoverPillButton extends StatefulWidget {
  const _HoverPillButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_HoverPillButton> createState() => _HoverPillButtonState();
}

class _HoverPillButtonState extends State<_HoverPillButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hover
                  ? const Color(0xFF8855FF)
                  : Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                color: _hover
                    ? const Color(0xFF8855FF)
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}
