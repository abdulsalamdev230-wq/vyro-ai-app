/// VYRO AI â€” Script-to-Video Screen


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';
import '../../core/animations/button_animations.dart';
import '../../core/providers/ai_provider.dart';

class ScriptToVideoScreen extends StatefulWidget {
  const ScriptToVideoScreen({super.key});

  @override
  State<ScriptToVideoScreen> createState() => _ScriptToVideoScreenState();
}

class _ScriptToVideoScreenState extends State<ScriptToVideoScreen> {
  final _scriptCtrl = TextEditingController();
  String _voiceId = 'Rachel';
  String? _resultUrl;
  bool _generating = false;
  String? _error;

  final List<String> _voices = const ['Rachel', 'Bella', 'Antoni', 'Adam', 'Josh'];

  Future<void> _generate() async {
    if (_scriptCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a script.');
      return;
    }
    setState(() { _generating = true; _error = null; _resultUrl = null; });

    // First, synthesize voice.
    final tts = await context.read<AiJobNotifier>().synthesizeVoice(
      text: _scriptCtrl.text.trim(),
      voiceId: _voiceId,
    );

    if (!mounted) return;
    if (!tts.success) {
      setState(() {
        _generating = false;
        _error = tts.error ?? 'Voice synthesis failed.';
      });
      return;
    }

    // Then generate video from script.
    final result = await context.read<AiJobNotifier>().generateVideo(
      prompt: _scriptCtrl.text.trim(),
      script: _scriptCtrl.text.trim(),
      durationSeconds: 8,
      width: 1080,
      height: 1920,
    );

    setState(() => _generating = false);
    if (!mounted) return;
    if (result.success && result.data != null) {
      setState(() => _resultUrl = result.data);
    } else if (result.unavailable) {
      setState(() => _error = result.error);
    } else {
      setState(() => _error = result.error ?? 'Video generation failed.');
    }
  }

  @override
  void dispose() {
    _scriptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Script-to-Video', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Consumer<AiJobNotifier>(
        builder: (context, ai, child) {
          if (ai.unavailable) {
            return UnavailableState(
              title: 'AI Video generation unavailable',
              message: ai.unavailableMessage ?? 'No video provider configured.',
              setupHint: 'Add an API key for Runware, Stability AI or fal.ai in the .env file.',
              icon: Icons.description,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      const Text('1. Enter your script', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _scriptCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: 'Write a short script... The AI will narrate it and generate matching visuals.',
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
                      const Text('2. Choose AI voice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _voices.map((v) {
                          final selected = _voiceId == v;
                          return ChoiceChip(
                            label: Text(v),
                            selected: selected,
                            onSelected: (_) => setState(() => _voiceId = v),
                            selectedColor: const Color(0xFF8855FF),
                            backgroundColor: const Color(0xFF17243B),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: LoadingButton(
                          loading: _generating,
                          onPressed: _generate,
                          child: const Text('Generate Narrated Video', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
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
                        const Text('Narrated Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _resultUrl!,
                            height: 320,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 320, color: const Color(0xFF263750),
                              child: const Center(child: Icon(Icons.play_circle, color: Color(0xFF64748B), size: 48)),
                            ),
                          ),
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
