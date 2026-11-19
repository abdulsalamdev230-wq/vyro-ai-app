/// VYRO AI â€” AI Voice Generator (TTS) Screen


import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../widgets/unavailable_state.dart';
import '../../core/animations/button_animations.dart';
import '../../core/providers/ai_provider.dart';

class AIVoiceGeneratorScreen extends StatefulWidget {
  const AIVoiceGeneratorScreen({super.key});

  @override
  State<AIVoiceGeneratorScreen> createState() => _AIVoiceGeneratorScreenState();
}

class _AIVoiceGeneratorScreenState extends State<AIVoiceGeneratorScreen> {
  final _textCtrl = TextEditingController();
  String _voiceId = 'Rachel';
  String? _audioPath;
  bool _generating = false;
  bool _playing = false;
  String? _error;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<String> _voices = const ['Rachel', 'Bella', 'Antoni', 'Adam', 'Josh', 'Alice'];

  Future<void> _generate() async {
    if (_textCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter text to speak.');
      return;
    }
    setState(() { _generating = true; _error = null; _audioPath = null; });

    final result = await context.read<AiJobNotifier>().synthesizeVoice(
      text: _textCtrl.text.trim(),
      voiceId: _voiceId,
    );

    if (!mounted) return;
    setState(() => _generating = false);
    if (result.success && result.data != null) {
      setState(() => _audioPath = result.data);
    } else if (result.unavailable) {
      setState(() => _error = result.error);
    } else {
      setState(() => _error = result.error ?? 'Voice generation failed.');
    }
  }

  Future<void> _play() async {
    if (_audioPath == null) return;
    setState(() => _playing = true);
    try {
      final src = _audioPath!.startsWith('http')
          ? UrlSource(_audioPath!)
          : DeviceFileSource(_audioPath!);
      await _audioPlayer.play(src);
    } catch (e) {
      setState(() => _error = 'Could not play audio: $e');
    } finally {
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Voice Generator', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Consumer<AiJobNotifier>(
        builder: (context, ai, child) {
          if (ai.unavailable) {
            return UnavailableState(
              title: 'Text-to-Speech unavailable',
              message: ai.unavailableMessage ?? 'No TTS provider configured.',
              setupHint: 'Add an ElevenLabs or Google TTS API key in the .env file.',
              icon: Icons.mic_off,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      const Text('Enter text to speak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _textCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Hello! Welcome to VYRO AI. Create amazing videos with AI.',
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
                      const Text('Choose AI voice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
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
                          child: const Text('Generate Voice', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
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
                if (_audioPath != null) ...[
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      children: [
                        const Text('Generated Voice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF8855FF), Color(0xFF00D5FF)]),
                                shape: BoxShape.circle,
                                boxShadow: const [BoxShadow(color: Color(0x408B5CF6), blurRadius: 16, spreadRadius: 2)],
                              ),
                              child: Icon(
                                _playing ? Icons.stop : Icons.play_circle,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _playing ? null : _play,
                            child: Text(_playing ? 'Playing...' : 'Play Voice'),
                          ),
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
}
