/// VYRO AI â€” AI Generation Provider
///
/// Manages AI image/video/voice generation jobs, tracking progress and
/// results. Uses AiService which reports honest unavailable states when no
/// provider API key is configured â€” it never fakes AI-generated results.


import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';
import 'auth_provider.dart';

class AiJobNotifier extends ChangeNotifier {
  AiJobNotifier._();
  static final AiJobNotifier instance = AiJobNotifier._();

  final AiService _ai = AiService.instance;
  final StorageService _storage = StorageService.instance;

  AiJobModel? _currentJob;
  List<AiJobModel> _history = [];
  bool _isGenerating = false;
  String? _error;
  bool _unavailable = false;
  String? _unavailableMessage;

  AiJobModel? get currentJob => _currentJob;
  List<AiJobModel> get history => _history;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  bool get unavailable => _unavailable;
  String? get unavailableMessage => _unavailableMessage;

  String? get _uid => AuthProvider.instance.firebaseUser?.uid;

  // ------ Provider availability (honest transparency) ------

  bool get hasImageProvider => _ai.hasImageProvider;
  bool get hasVideoProvider => _ai.hasVideoProvider;
  bool get hasTtsProvider => _ai.hasTtsProvider;
  List<String> get configuredProviders => _ai.configuredProviders;

  // ------ Image generation ------

  Future<AiResult<List<String>>> generateImage({
    required String prompt,
    String? negativePrompt,
    int width = 1024,
    int height = 1024,
  }) async {
    _clear();
    final uid = _uid;
    if (uid == null) {
      _setError('Please sign in to generate images.');
      return AiResult.error('');
    }
    if (!_ai.hasImageProvider) {
      _setUnavailable('No AI image provider is configured. Add an API key (OpenAI, Runware, Stability AI or fal.ai) in .env to enable image generation.');
      return AiResult.error('');
    }

    _setGenerating(true);
    try {
      final result = await _ai.generateImage(
        ImageGenerationRequest(
          prompt: prompt,
          negativePrompt: negativePrompt,
          width: width,
          height: height,
          uid: uid,
        ),
      );
      if (result.success && result.data != null) {
        final urls = result.data!;
        final imageId = const Uuid().v4();
        final job = AiJobModel(
          id: imageId,
          userId: uid,
          type: AiGenerationType.aiImage,
          status: AiJobStatus.completed,
          prompt: prompt,
          resultUrl: urls.first,
          thumbnailUrl: urls.first,
          progressPercent: 100,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        _currentJob = job;
        _history.insert(0, job);
        // Await the Firestore write so the job record is guaranteed to be
        // saved before the UI reports success. This fixes images disappearing
        // after app restart when the process exited before the write completed.
        await _persistJob(job);
        return AiResult.success(urls);
      }
      _setError(result.error ?? 'Image generation failed.');
      return result;
    } catch (e) {
      _setError(e.toString());
      return AiResult.error('');
    } finally {
      _setGenerating(false);
    }
  }

  // ------ Video generation (text, image, script) ------

  Future<AiResult<String>> generateVideo({
    required String prompt,
    String? imageUrl,       // image-to-video
    String? script,         // script-to-video
    int durationSeconds = 5,
    int width = 1080,
    int height = 1920,
  }) async {
    _clear();
    final uid = _uid;
    if (uid == null) {
      _setError('Please sign in to generate videos.');
      return AiResult.error('');
    }
    if (!_ai.hasVideoProvider) {
      _setUnavailable('No AI video provider is configured. Add an API key (Runware, Stability AI or fal.ai) in .env to enable video generation.');
      return AiResult.error('');
    }

    _setGenerating(true);
    try {
      final result = await _ai.generateVideo(
        VideoGenerationRequest(
          prompt: prompt,
          imageUrl: imageUrl,
          script: script,
          durationSeconds: durationSeconds,
          width: width,
          height: height,
        ),
      );
      if (result.success && result.data != null) {
        final job = AiJobModel(
          id: const Uuid().v4(),
          userId: uid,
          type: AiGenerationType.textToVideo,
          status: AiJobStatus.completed,
          prompt: prompt,
          imageUrl: imageUrl,
          resultUrl: result.data!,
          progressPercent: 100,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        _currentJob = job;
        _history.insert(0, job);
        // Fire-and-forget (see generateImage comment above).
        unawaited(_persistJob(job));
        return AiResult.success(result.data!);
      }
      _setError(result.error ?? 'Video generation failed.');
      return result;
    } catch (e) {
      _setError(e.toString());
      return AiResult.error('');
    } finally {
      _setGenerating(false);
    }
  }

  // ------ TTS ------

  Future<AiResult<String>> synthesizeVoice({
    required String text,
    required String voiceId,
    String? modelId,
  }) async {
    _clear();
    final uid = _uid;
    if (uid == null) {
      _setError('Please sign in to generate voice.');
      return AiResult.error('');
    }
    if (!_ai.hasTtsProvider) {
      _setUnavailable('No TTS provider is configured. Add an ElevenLabs or Google TTS API key in .env to enable voice generation.');
      return AiResult.error('');
    }

    _setGenerating(true);
    try {
      final result = await _ai.synthesizeSpeech(
        TtsRequest(text: text, voiceId: voiceId, modelId: modelId),
      );
      if (result.success && result.data != null) {
        final job = AiJobModel(
          id: const Uuid().v4(),
          userId: uid,
          type: AiGenerationType.aiVoice,
          status: AiJobStatus.completed,
          prompt: text,
          resultUrl: result.data!,
          progressPercent: 100,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
        _currentJob = job;
        _history.insert(0, job);
        // Fire-and-forget (see generateImage comment above).
        unawaited(_persistJob(job));
        return AiResult.success(result.data!);
      }
      _setError(result.error ?? 'Voice generation failed.');
      return result;
    } catch (e) {
      _setError(e.toString());
      return AiResult.error('');
    } finally {
      _setGenerating(false);
    }
  }

  // ------ History ------

  Future<void> loadHistory() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseService.instance
          .jobsCollection(uid)
          .orderBy('createdAt', descending: true)
          .get();
      _history = snap.docs
          .map((d) => AiJobModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('[AiProvider] loadHistory: $e');
    }
    notifyListeners();
  }

  Future<void> _persistJob(AiJobModel job) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await FirebaseService.instance.jobsCollection(uid).doc(job.id).set(job.toMap());
    } catch (e) {
      if (kDebugMode) debugPrint('[AiProvider] persistJob: $e');
    }
  }

  void _clear() {
    _error = null;
    _unavailable = false;
    _unavailableMessage = null;
    _currentJob = null;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _unavailable = false;
    notifyListeners();
  }

  void _setUnavailable(String message) {
    _unavailable = true;
    _unavailableMessage = message;
    _error = null;
    notifyListeners();
  }

  void _setGenerating(bool value) {
    _isGenerating = value;
    notifyListeners();
  }

  void clearCurrentJob() {
    _currentJob = null;
    _error = null;
    notifyListeners();
  }
}

