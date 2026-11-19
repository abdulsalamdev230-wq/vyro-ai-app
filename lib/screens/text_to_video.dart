/// VYRO AI â€” Text-to-Video Screen


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';
import '../widgets/video_result_player.dart';
import '../../core/animations/button_animations.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/services/video_download.dart';
import '../../core/services/video_share.dart';

class TextToVideoScreen extends StatefulWidget {
  const TextToVideoScreen({super.key});

  @override
  State<TextToVideoScreen> createState() => _TextToVideoScreenState();
}

class _TextToVideoScreenState extends State<TextToVideoScreen> {
  final _promptCtrl = TextEditingController();
  String? _resultUrl;
  bool _generating = false;
  String? _error;
  int _duration = 5;

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a description.');
      return;
    }
    setState(() { _generating = true; _error = null; _resultUrl = null; });

    final result = await context.read<AiJobNotifier>().generateVideo(
      prompt: _promptCtrl.text.trim(),
      durationSeconds: _duration,
      width: 1080,
      height: 1920,
    );

    if (!mounted) return;
    setState(() => _generating = false);
    if (result.success && result.data != null) {
      setState(() => _resultUrl = result.data);
    } else if (result.unavailable) {
      setState(() => _error = result.error);
    } else {
      setState(() => _error = result.error ?? 'Video generation failed.');
    }
  }

  /// Downloads the finished video (web: direct file, mobile: honest link copy).
  Future<void> _download() async {
    if (_resultUrl == null) return;
    final message = await downloadVideo(_resultUrl!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message, style: const TextStyle(fontFamily: 'Inter'))),
    );
  }

  /// Opens the native / browser share sheet for the finished video.
  Future<void> _share() async {
    if (_resultUrl == null) return;
    final message = await shareVideo(_resultUrl!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message, style: const TextStyle(fontFamily: 'Inter'))),
    );
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Text-to-Video', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Consumer<AiJobNotifier>(
        builder: (context, ai, child) {
          if (ai.unavailable) {
            return UnavailableState(
              title: 'AI Video generation unavailable',
              message: ai.unavailableMessage ?? 'No video provider configured.',
              setupHint: 'Add an API key for Runware, Stability AI or fal.ai in the .env file.',
              icon: Icons.videocam_off,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      const Text('Describe your video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _promptCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'A cinematic drone shot of a futuristic city, flying cars, neon signs',
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
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text('Duration (seconds)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _duration,
                            dropdownColor: const Color(0xFF17243B),
                            style: const TextStyle(color: Colors.white),
                            items: [3, 5, 8, 10].map((d) => DropdownMenuItem(value: d, child: Text('$d s'))).toList(),
                            onChanged: (v) => setState(() => _duration = v!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: LoadingButton(
                          loading: _generating,
                          onPressed: _generate,
                          child: const Text('Generate Video', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Container(
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
                        Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
                      ],
                    ),
                  ),
                if (_resultUrl != null) ...[
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      children: [
                        const Text('Generated Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: VideoResultPlayer(url: _resultUrl!),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _download,
                                icon: const Icon(Icons.download_outlined, size: 18),
                                label: const Text('Download', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _share,
                                icon: const Icon(Icons.share_outlined, size: 18),
                                label: const Text('Share', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _generating ? null : _generate,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(onPressed: () => _navigatePreview(_resultUrl!), child: const Text('Open in Editor')),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigatePreview(String url) {
    Navigator.of(context).pushNamed(AppRoutes.videoPreview, arguments: {'videoUrl': url, 'type': 'video'});
  }
}
