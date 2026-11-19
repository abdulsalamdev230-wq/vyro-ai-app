/// VYRO AI â€” Text-to-Speech Service
///
/// High-level TTS orchestration over AI providers. Saves synthesized audio
/// locally via path_provider. Reports honest unavailable state when no TTS
/// provider is configured.


import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'ai_service.dart';

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final AiService _ai = AiService.instance;

  /// Directory for cached TTS audio.
  Future<Directory> _audioDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory(p.join(dir.path, 'tts_audio'));
    await audioDir.create(recursive: true);
    return audioDir;
  }

  /// Synthesize text to speech and save as an MP3 file.
  /// Returns the local file path on success, or an AiResult error/unavailable.
  Future<AiResult<String>> synthesizeToFile({
    required String text,
    required String voiceId,
    String? modelId,
    double stability = 0.5,
    double similarityBoost = 0.75,
  }) async {
    if (!_ai.hasTtsProvider) {
      return AiResult.unavailable(
        'No TTS provider configured. Add an ElevenLabs or Google TTS API key in .env to enable voice generation.',
      );
    }
    if (text.trim().isEmpty) {
      return AiResult.error('Text cannot be empty.');
    }

    final result = await _ai.synthesizeSpeech(
      TtsRequest(
        text: text,
        voiceId: voiceId,
        modelId: modelId,
        stability: stability,
        similarityBoost: similarityBoost,
      ),
    );

    if (!result.success || result.data == null) {
      return result;
    }

    // Persist audio data (base64 data URL or remote URL) to a local file.
    final data = result.data!;
    final fileName = 'tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final file = File(p.join((await _audioDir()).path, fileName));

    if (data.startsWith('data:audio/mp3;base64,')) {
      final base64 = data.substring('data:audio/mp3;base64,'.length);
      await file.writeAsBytes(base64Decode(base64));
    } else {
      // Remote URL: download and save.
      final uri = Uri.parse(data);
      final resp = await _httpGetBytes(uri);
      if (resp == null) {
        return AiResult.error('Failed to download synthesized audio.');
      }
      await file.writeAsBytes(resp);
    }

    return AiResult.success(file.path);
  }

  Future<List<int>?> _httpGetBytes(Uri uri) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// List of cached TTS files.
  Future<List<File>> listCachedAudio() async {
    try {
      final dir = await _audioDir();
      return dir.listSync()
          .whereType<File>()
          .where((f) => p.extension(f.path) == '.mp3')
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    } catch (_) {
      return [];
    }
  }

  /// Clear cached TTS audio.
  Future<void> clearCache() async {
    try {
      final dir = await _audioDir();
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    } catch (_) {}
  }
}
