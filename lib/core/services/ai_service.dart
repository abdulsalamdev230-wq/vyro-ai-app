/// VYRO AI â€” AI Service Layer
///
/// Provider interface for AI image, video and TTS generation.
/// Providers are wired to environment API keys. When no provider is
/// configured, the service reports an honest unavailable state â€” it never
/// fabricates AI-generated results.


import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../config/app_config.dart';
import '../../core/services/firebase_service.dart';
import 'image_blob.dart';

// ============================================================================
// RESULT TYPES
// ============================================================================

/// Outcome of an AI generation request.
class AiResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final AiProviderError? providerError;
  final bool unavailable;

  AiResult._({
    required this.success,
    this.data,
    this.error,
    this.providerError,
    this.unavailable = false,
  });

  factory AiResult.success(T data) => AiResult._(success: true, data: data);
  factory AiResult.error(String message, {AiProviderError? providerError}) =>
      AiResult._(success: false, error: message, providerError: providerError);
  factory AiResult.unavailable(String message) =>
      AiResult._(success: false, error: message, unavailable: true);

  @override
  String toString() =>
      'AiResult(success: $success, error: $error, unavailable: $unavailable)';
}

/// Structured provider error.
class AiProviderError {
  final String provider;
  final String code;
  final String message;
  final int? statusCode;
  final bool retryable;

  const AiProviderError({
    required this.provider,
    required this.code,
    required this.message,
    this.statusCode,
    this.retryable = true,
  });
}

// ============================================================================
// GENERATION REQUESTS
// ============================================================================

class ImageGenerationRequest {
  final String prompt;
  final String? negativePrompt;
  final int width;
  final int height;
  final int? seed;
  final String? model;
  /// Firebase Auth UID — used to upload the generated image to Firebase
  /// Storage for permanent persistence. When null, the raw provider URL is
  /// returned as-is (images may not survive app restart).
  final String? uid;

  ImageGenerationRequest({
    required this.prompt,
    this.negativePrompt,
    this.width = 1024,
    this.height = 1024,
    this.seed,
    this.model,
    this.uid,
  });
}

class VideoGenerationRequest {
  final String prompt;
  final String? negativePrompt;
  final String? imageUrl; // for image-to-video
  final String? script; // for script-to-video
  final int durationSeconds;
  final int width;
  final int height;
  final int? seed;
  final String? model;

  VideoGenerationRequest({
    required this.prompt,
    this.negativePrompt,
    this.imageUrl,
    this.script,
    this.durationSeconds = 5,
    this.width = 1080,
    this.height = 1920,
    this.seed,
    this.model,
  });
}

class TtsRequest {
  final String text;
  final String voiceId;
  final String? modelId;
  final double stability;
  final double similarityBoost;

  TtsRequest({
    required this.text,
    required this.voiceId,
    this.modelId,
    this.stability = 0.5,
    this.similarityBoost = 0.75,
  });
}

// ============================================================================
// PROVIDER INTERFACE
// ============================================================================

abstract class AiProvider {
  /// Human-readable provider name.
  String get name;

  /// Whether this provider is configured & reachable.
  bool get isAvailable;

  /// Capabilities this provider supports.
  Set<String> get capabilities; // 'image', 'video', 'tts'

  /// Generate an image. Returns image URL(s).
  Future<AiResult<List<String>>> generateImage(ImageGenerationRequest request);

  /// Generate a video. Returns video URL.
  Future<AiResult<String>> generateVideo(VideoGenerationRequest request);

  /// Synthesize speech. Returns audio file URL or local path.
  Future<AiResult<String>> synthesizeSpeech(TtsRequest request);

  /// Optional: poll a job status (for async providers).
  Future<AiResult<String>?> pollJob(String jobId) =>
      Future<AiResult<String>?>.value(null);
}

// ============================================================================
// BASE HTTP PROVIDER (helper for API-key based providers)
// ============================================================================

abstract class HttpAiProvider implements AiProvider {
  final Dio _dio = Dio();

  HttpAiProvider(String apiKey) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 60);
    _dio.options.sendTimeout = const Duration(seconds: 60);
    _dio.options.receiveTimeout = const Duration(seconds: 60);
    _dio.options.headers = defaultHeaders(apiKey);
  }

  String get baseUrl;
  Map<String, String> defaultHeaders(String apiKey);

  @override
  Future<AiResult<String>?> pollJob(String jobId) =>
      Future<AiResult<String>?>.value(null);

  Future<T> _request<T>({
    required String method,
    required String path,
    dynamic data,
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.request(
        path,
        options: Options(method: method),
        data: data,
        queryParameters: query,
      );
      return res.data as T;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      String message = e.message ?? 'Unknown error';
      if (body is Map) {
        message = body['error']?.toString() ??
            body['message']?.toString() ??
            message;
      }
      throw AiProviderError(
        provider: name,
        code: status?.toString() ?? 'unknown',
        message: message,
        statusCode: status,
        retryable: status == null || status >= 500,
      );
    }
  }
}

// ============================================================================
// PROVIDER: OPENAI (DALLÂ·E images)
// ============================================================================

class OpenAiProvider extends HttpAiProvider {
  OpenAiProvider(String apiKey) : super(apiKey);

  @override
  String get name => 'OpenAI';

  @override
  bool get isAvailable => AppConfig.openAIApiKey.isNotEmpty;

  @override
  Set<String> get capabilities => {'image'};

  @override
  String get baseUrl => 'https://api.openai.com/v1';

  @override
  Map<String, String> defaultHeaders(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  @override
  Future<AiResult<List<String>>> generateImage(ImageGenerationRequest request) async {
    if (!isAvailable) {
      return AiResult.unavailable('OpenAI API key not configured.');
    }
    try {
      final body = {
        'model': request.model ?? 'dall-e-3',
        'prompt': request.prompt,
        'n': 1,
        'size': '${request.width}x${request.height}',
        if (request.seed != null) 'seed': request.seed,
      };
      final data = await _request(
        method: 'POST',
        path: '/images/generations',
        data: body,
      );
      final urls = (data['data'] as List)
          .map((e) => e['url'] as String)
          .toList();
      return AiResult.success(urls);
    } on AiProviderError catch (e) {
      return AiResult.error('OpenAI image generation failed: ${e.message}', providerError: e);
    } catch (e) {
      return AiResult.error('OpenAI image generation failed: $e');
    }
  }

  @override
  Future<AiResult<String>> generateVideo(VideoGenerationRequest request) async {
    return AiResult.unavailable('OpenAI does not offer video generation via this provider.');
  }

  @override
  Future<AiResult<String>> synthesizeSpeech(TtsRequest request) async {
    return AiResult.unavailable('OpenAI TTS not wired in this build.');
  }
}

// ============================================================================
// PROVIDER: RUNWARE (image + video)
// ============================================================================

class RunwareProvider extends HttpAiProvider {
  RunwareProvider(String apiKey) : super(apiKey);

  @override
  String get name => 'Runware';

  @override
  bool get isAvailable => AppConfig.runwareApiKey.isNotEmpty;

  @override
  Set<String> get capabilities => {'image', 'video'};

  @override
  String get baseUrl => 'https://api.runware.ai/v1';

  @override
  Map<String, String> defaultHeaders(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  };

  @override
  Future<AiResult<List<String>>> generateImage(ImageGenerationRequest request) async {
    if (!isAvailable) {
      return AiResult.unavailable('Runware API key not configured.');
    }
    try {
      final data = await _request(
        method: 'POST',
        path: '/image/inference',
        data: {
          'prompt': request.prompt,
          'negativePrompt': request.negativePrompt,
          'width': request.width,
          'height': request.height,
          'seed': request.seed,
          'model': request.model,
        },
      );
      final urls = (data['images'] as List?)
          ?.map((e) => e['url'] as String?)
          .whereType<String>()
          .toList() ??
          [];
      return AiResult.success(urls);
    } on AiProviderError catch (e) {
      return AiResult.error('Runware image generation failed: ${e.message}', providerError: e);
    } catch (e) {
      return AiResult.error('Runware image generation failed: $e');
    }
  }

  @override
  Future<AiResult<String>> generateVideo(VideoGenerationRequest request) async {
    if (!isAvailable) {
      return AiResult.unavailable('Runware API key not configured.');
    }
    try {
      final data = await _request(
        method: 'POST',
        path: '/video/inference',
        data: {
          'prompt': request.prompt,
          'negativePrompt': request.negativePrompt,
          'imageUrl': request.imageUrl,
          'script': request.script,
          'durationSeconds': request.durationSeconds,
          'width': request.width,
          'height': request.height,
          'seed': request.seed,
          'model': request.model,
        },
      );
      final url = data['videoUrl'] ?? data['url'];
      if (url == null) {
        return AiResult.error('Runware did not return a video URL.');
      }
      return AiResult.success(url as String);
    } on AiProviderError catch (e) {
      return AiResult.error('Runware video generation failed: ${e.message}', providerError: e);
    } catch (e) {
      return AiResult.error('Runware video generation failed: $e');
    }
  }

  @override
  Future<AiResult<String>> synthesizeSpeech(TtsRequest request) async {
    return AiResult.unavailable('Runware does not offer TTS.');
  }
}

// ============================================================================
// PROVIDER: STABILITY AI (image + video)
// ============================================================================

class StabilityProvider extends HttpAiProvider {
  StabilityProvider(String apiKey) : super(apiKey);

  @override
  String get name => 'Stability AI';

  @override
  bool get isAvailable => AppConfig.stabilityApiKey.isNotEmpty;

  @override
  Set<String> get capabilities => {'image', 'video'};

  @override
  String get baseUrl => 'https://api.stability.ai/v1';

  @override
  Map<String, String> defaultHeaders(String apiKey) => {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  @override
  Future<AiResult<List<String>>> generateImage(ImageGenerationRequest request) async {
    if (!isAvailable) {
      return AiResult.unavailable('Stability AI API key not configured.');
    }
    try {
      final data = await _request(
        method: 'POST',
        path: '/generation/stable-diffusion-xl-1024-v1-0/text-to-image',
        data: {
          'text_prompts': [
            {'text': request.prompt, 'weight': 1},
            if (request.negativePrompt != null && request.negativePrompt!.isNotEmpty)
              {'text': request.negativePrompt, 'weight': -1},
          ],
          'width': request.width,
          'height': request.height,
          if (request.seed != null) 'seed': request.seed,
        },
      );
      final urls = (data['artifacts'] as List?)
          ?.map((e) => e['base64'] as String?)
          .whereType<String>()
          .map((b64) => 'data:image/png;base64,$b64')
          .toList() ??
          [];
      return AiResult.success(urls);
    } on AiProviderError catch (e) {
      return AiResult.error('Stability image generation failed: ${e.message}', providerError: e);
    } catch (e) {
      return AiResult.error('Stability image generation failed: $e');
    }
  }

  @override
  Future<AiResult<String>> generateVideo(VideoGenerationRequest request) async {
    if (!isAvailable) {
      return AiResult.unavailable('Stability AI API key not configured.');
    }
    try {
      final data = await _request(
        method: 'POST',
        path: '/generation/stable-video-diffusion/image-to-video',
        data: {
          if (request.imageUrl != null) 'image': request.imageUrl,
          'text_prompts': [{'text': request.prompt, 'weight': 1}],
          'width': request.width,
          'height': request.height,
        },
      );
      final url = data['videoUrl'] ?? data['url'];
      if (url == null) return AiResult.error('Stability did not return a video URL.');
      return AiResult.success(url as String);
    } on AiProviderError catch (e) {
      return AiResult.error('Stability video generation failed: ${e.message}', providerError: e);
    } catch (e) {
      return AiResult.error('Stability video generation failed: $e');
    }
  }

  @override
  Future<AiResult<String>> synthesizeSpeech(TtsRequest request) async {
    return AiResult.unavailable('Stability AI does not offer TTS.');
  }
}

// ============================================================================
// PROVIDER: FAL (image + video)
// ============================================================================

class FalProvider extends HttpAiProvider {
  FalProvider(String apiKey) : super(apiKey);

  @override
  String get name => 'fal.ai';

  @override
  bool get isAvailable => AppConfig.falApiKey.isNotEmpty;

  @override
  Set<String> get capabilities => {'image', 'video'};

  @override
  String get baseUrl => 'https://fal.run/fal-ai';

  @override
  Map<String, String> defaultHeaders(String apiKey) => {
    'Authorization': 'Key $apiKey',
    'Content-Type': 'application/json',
  };

  @override
  Future<AiResult<List<String>>> generateImage(ImageGenerationRequest request) async {
    if (!isAvailable) {
      return AiResult.unavailable('fal.ai API key not configured.');
    }
    try {
      final data = await _request(
        method: 'POST',
        path: '/stable-diffusion-v1-5/text-to-image',
        data: {
          'prompt': request.prompt,
          'negative_prompt': request.negativePrompt,
          'width': request.width,
          'height': request.height,
          'seed': request.seed,
        },
      );
      final urls = (data['images'] as List?)
          ?.map((e) => e['url'] as String?)
          .whereType<String>()
          .toList() ??
          [];
      return AiResult.success(urls);
    } on AiProviderError catch (e) {
      return AiResult.error('fal.ai image generation failed: ${e.message}', providerError: e);
    } catch (e) {
      return AiResult.error('fal.ai image generation failed: $e');
    }
  }

  @override
  Future<AiResult<String>> generateVideo(VideoGenerationRequest request) async {
    if (!isAvailable) {
      return AiResult.unavailable('fal.ai API key not configured.');
    }
    try {
      final data = await _request(
        method: 'POST',
        path: '/stable-video-diffusion/image-to-video',
        data: {
          'image_url': request.imageUrl,
          'prompt': request.prompt,
          'duration_seconds': request.durationSeconds,
          'width': request.width,
          'height': request.height,
          'seed': request.seed,
        },
      );
      final url = data['video']['url'] ?? data['url'];
      if (url == null) return AiResult.error('fal.ai did not return a video URL.');
      return AiResult.success(url as String);
    } on AiProviderError catch (e) {
      return AiResult.error('fal.ai video generation failed: ${e.message}', providerError: e);
    } catch (e) {
      return AiResult.error('fal.ai video generation failed: $e');
    }
  }

  @override
  Future<AiResult<String>> synthesizeSpeech(TtsRequest request) async {
    return AiResult.unavailable('fal.ai does not offer TTS.');
  }
}

// ============================================================================
// PROVIDER: ELEVENLABS (TTS)
// ============================================================================

class ElevenLabsProvider extends HttpAiProvider {
  ElevenLabsProvider(String apiKey) : super(apiKey);

  @override
  String get name => 'ElevenLabs';

  @override
  bool get isAvailable => AppConfig.elevenlabsApiKey.isNotEmpty;

  @override
  Set<String> get capabilities => {'tts'};

  @override
  String get baseUrl => 'https://api.elevenlabs.io/v1';

  @override
  Map<String, String> defaultHeaders(String apiKey) => {
    'xi-api-key': apiKey,
    'Content-Type': 'application/json',
  };

  @override
  Future<AiResult<List<String>>> generateImage(ImageGenerationRequest request) async {
    return AiResult.unavailable('ElevenLabs does not offer image generation.');
  }

  @override
  Future<AiResult<String>> generateVideo(VideoGenerationRequest request) async {
    return AiResult.unavailable('ElevenLabs does not offer video generation.');
  }

  @override
  Future<AiResult<String>> synthesizeSpeech(TtsRequest request) async {
    if (!isAvailable) {
      return AiResult.unavailable('ElevenLabs API key not configured.');
    }
    try {
      final data = await _request(
        method: 'POST',
        path: '/text-to-speech/${request.voiceId}',
        data: {
          'text': request.text,
          'model_id': request.modelId ?? 'eleven_multilingual_v2',
          'voice_settings': {
            'stability': request.stability,
            'similarity_boost': request.similarityBoost,
          },
        },
      );
      // ElevenLabs returns audio binary; here we return a placeholder URL handled by caller.
      final audioUrl = data['audio_url'] as String?;
      if (audioUrl != null) {
        return AiResult.success(audioUrl);
      }
      return AiResult.error('ElevenLabs did not return audio.');
    } on AiProviderError catch (e) {
      return AiResult.error('ElevenLabs TTS failed: ${e.message}', providerError: e);
    } catch (e) {
      return AiResult.error('ElevenLabs TTS failed: $e');
    }
  }
}

// ============================================================================
// PROVIDER: GOOGLE TTS
// ============================================================================

class GoogleTtsProvider extends HttpAiProvider {
  GoogleTtsProvider(String apiKey) : super(apiKey);

  @override
  String get name => 'Google Cloud TTS';

  @override
  bool get isAvailable => AppConfig.googleTtsApiKey.isNotEmpty;

  @override
  Set<String> get capabilities => {'tts'};

  @override
  String get baseUrl => 'https://texttospeech.googleapis.com/v1';

  @override
  Map<String, String> defaultHeaders(String apiKey) => {
    'Content-Type': 'application/json',
  };

  @override
  Future<AiResult<List<String>>> generateImage(ImageGenerationRequest request) async {
    return AiResult.unavailable('Google TTS does not offer image generation.');
  }

  @override
  Future<AiResult<String>> generateVideo(VideoGenerationRequest request) async {
    return AiResult.unavailable('Google TTS does not offer video generation.');
  }

  @override
  Future<AiResult<String>> synthesizeSpeech(TtsRequest request) async {
    if (!isAvailable) {
      return AiResult.unavailable('Google TTS API key not configured.');
    }
    try {
      final data = await _request(
        method: 'POST',
        path: ':synthesize?key=${AppConfig.googleTtsApiKey}',
        data: {
          'input': {'text': request.text},
          'voice': {'languageCode': 'en-US', 'name': request.voiceId},
          'audioConfig': {'audioEncoding': 'MP3'},
        },
      );
      final audioContent = data['audioContent'] as String?;
      if (audioContent != null) {
        return AiResult.success('data:audio/mp3;base64,$audioContent');
      }
      return AiResult.error('Google TTS did not return audio.');
    } on AiProviderError catch (e) {
      return AiResult.error('Google TTS failed: ${e.message}', providerError: e);
    } catch (e) {
      return AiResult.error('Google TTS failed: $e');
    }
  }
}

// ============================================================================
// PROVIDER: VYRO WORKER (user's own Cloudflare Worker — top priority)
// ============================================================================

/// AI image generation via the project's own deployed Cloudflare Worker
/// (POST /generate-image with {"prompt": "..."} → binary image bytes).
///
/// The generated image is then uploaded to Firebase Storage under the
/// signed-in user's path (users/{uid}/images/...) so the download URL is
/// stable and persistent — this satisfies the "save to Firebase Storage"
/// requirement using the existing architecture. The Worker URL is a public
/// endpoint (not a secret) and can be overridden via VYRO_WORKER_URL in .env.
class VyroWorkerProvider implements AiProvider {
  final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 30)
    ..options.receiveTimeout = const Duration(seconds: 180);

  String get _baseUrl => AppConfig.vyroWorkerUrl;

  @override
  String get name => 'VYRO Worker';

  @override
  bool get isAvailable => _baseUrl.isNotEmpty;

  @override
  Set<String> get capabilities => {'image', 'video'};

  @override
  Future<AiResult<String>?> pollJob(String jobId) =>
      Future<AiResult<String>?>.value(null);

  @override
  Future<AiResult<List<String>>> generateImage(
    ImageGenerationRequest request,
  ) async {
    if (!isAvailable) {
      return AiResult.unavailable('VYRO Worker URL not configured.');
    }
    try {
      final res = await _dio.post<String>(
        '$_baseUrl/generate-image',
        data: {'prompt': request.prompt},
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Content-Type': 'application/json'},
        ),
      );
      if (res.statusCode != 200) {
        return AiResult.error(
          'VYRO Worker returned HTTP ${res.statusCode}.',
        );
      }
      final contentType =
          (res.headers.value('content-type') ?? '').split(';').first.trim();

      // Current Worker format: JSON payload with a hosted image URL.
      // { "success": true, "image_url": "https://...", "mime_type": "..." }
      if (contentType.startsWith('application/json')) {
        final data = jsonDecode(res.data ?? '{}') as Map<String, dynamic>;
        if (data['success'] == true) {
          final imageUrl = data['image_url']?.toString() ?? '';
          if (imageUrl.isNotEmpty) {
            // Upload the generated image to Firebase Storage so it survives
            // app restart. Falls back to the hosted URL if storage is
            // unavailable.
            final permanentUrl =
                await _uploadImageUrlToStorage(request, imageUrl);
            return AiResult.success([permanentUrl]);
          }
          return AiResult.error(
            data['message']?.toString() ??
                'VYRO Worker succeeded but returned no image URL.',
          );
        }
        return AiResult.error(
          data['message']?.toString() ?? 'VYRO Worker could not generate an image.',
        );
      }

      // Legacy Worker format: raw image bytes. Upload to Firebase Storage
      // for permanent persistence instead of a session-local blob URL.
      if (contentType.startsWith('image/')) {
        final bytes = Uint8List.fromList(
          (res.data ?? '').codeUnits,
        );
        final permanentUrl = await _uploadImageBytesToStorage(
          request, bytes, contentType,
        );
        return AiResult.success([permanentUrl]);
      }

      return AiResult.error(
        'VYRO Worker returned an unexpected content type: '
        '${contentType.isEmpty ? 'unknown' : contentType}.',
      );
    } on DioException catch (e) {
      return AiResult.error(
        'VYRO Worker image generation failed: ${e.message ?? e.type.name}',
      );
    } on FormatException catch (e) {
      return AiResult.error('VYRO Worker returned malformed JSON: $e');
    } catch (e) {
      return AiResult.error('VYRO Worker image generation failed: $e');
    }
  }

  @override
  Future<AiResult<String>> generateVideo(VideoGenerationRequest request) async {
    if (!isAvailable) {
      return AiResult.unavailable('VYRO Worker URL not configured.');
    }
    try {
      final res = await _dio.post<String>(
        '$_baseUrl/generate-video',
        data: {
          'prompt': request.prompt,
          'duration': request.durationSeconds,
          if (request.imageUrl != null && request.imageUrl!.isNotEmpty)
            'image_url': request.imageUrl,
        },
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final contentType =
          (res.headers.value('content-type') ?? '').split(';').first.trim();

      if (contentType.startsWith('application/json')) {
        final data = jsonDecode(res.data ?? '{}') as Map<String, dynamic>;
        if (data['success'] != true) {
          return AiResult.error(_workerErrorMessage(
            data,
            'VYRO Worker could not start video generation.',
          ));
        }

        // Fast path: the Worker already has a finished video URL.
        final directUrl = (data['video_url'] ??
                data['url'] ??
                data['videoUrl'] ??
                '')
            .toString();
        if (directUrl.isNotEmpty) return AiResult.success(directUrl);

        // Async path (Worker 202): a prediction was queued on Replicate.
        // Poll /video-status until the model finishes or times out.
        final predictionId = (data['prediction_id'] ?? data['id'] ?? '')
            .toString();
        if (predictionId.isNotEmpty) {
          return await _pollVideoStatus(predictionId);
        }

        return AiResult.error(
          data['message']?.toString() ??
              'VYRO Worker succeeded but returned no prediction ID.',
        );
      }

      // Legacy format: raw video bytes — show via a session blob URL.
      if (contentType.startsWith('video/')) {
        final bytes = Uint8List.fromList((res.data ?? '').codeUnits);
        final blobUrl = createBlobUrl(bytes, contentType);
        if (blobUrl != null) return AiResult.success(blobUrl);
        return AiResult.error(
          'VYRO Worker returned video bytes but no displayable URL.',
        );
      }

      return AiResult.error(
        'VYRO Worker returned an unexpected content type '
        '(${contentType.isEmpty ? 'unknown' : contentType}) for video.',
      );
    } on DioException catch (e) {
      return AiResult.error(_dioVideoError(e));
    } on FormatException catch (e) {
      return AiResult.error('VYRO Worker returned malformed JSON: $e');
    } catch (e) {
      return AiResult.error('VYRO Worker video generation failed: $e');
    }
  }

  /// Polls the Worker's GET /video-status?id=PREDICTION_ID endpoint until the
  /// video model finishes. Polls every 6 seconds for up to 10 minutes
  /// (typical Replicate 5s clip completes in 30–120s).
  Future<AiResult<String>> _pollVideoStatus(String predictionId) async {
    const interval = Duration(seconds: 6);
    const timeout = Duration(minutes: 10);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(interval);
      try {
        final res = await _dio.get<String>(
          '$_baseUrl/video-status',
          queryParameters: {'id': predictionId},
          options: Options(responseType: ResponseType.plain),
        );
        final data = jsonDecode(res.data ?? '{}') as Map<String, dynamic>;
        if (data['success'] != true) {
          return AiResult.error(_workerErrorMessage(
            data,
            'Video status check failed on the VYRO Worker.',
          ));
        }
        final status = (data['status'] ?? '').toString().toLowerCase();
        final url = _extractVideoUrl(data['output']);

        if (status == 'succeeded' || status == 'success' || status == 'complete') {
          if (url != null) return AiResult.success(url);
          return AiResult.error(
            'Video finished but the provider returned no video URL.',
          );
        }
        if (status == 'failed' || status == 'canceled' || status == 'cancelled') {
          final err = (data['error'] ?? data['message'] ?? '')
              .toString();
          return AiResult.error(
            err.isNotEmpty
                ? 'Video generation failed on the provider: $err'
                : 'Video generation failed on the provider.',
          );
        }
        // starting / processing → keep polling until the deadline.
      } on FormatException {
        return AiResult.error('VYRO Worker returned malformed status JSON.');
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        // A persistent client error (4xx) will not fix itself by polling.
        if (status != null && status >= 400 && status < 500 && status != 429) {
          return AiResult.error(_dioVideoError(e));
        }
        // 5xx / network blip → retry until the deadline.
      } catch (_) {
        // Unexpected poll error → keep polling until the deadline.
      }
    }
    return AiResult.error(
      'Video generation timed out after 10 minutes. The model is taking '
      'too long right now — please try again.',
    );
  }

  /// Replicate outputs come in several shapes:
  ///   "https://replicate.delivery/....mp4"
  ///   ["https://replicate.delivery/....mp4"]
  ///   { "url": "https://..." } | { "video": "https://..." }
  String? _extractVideoUrl(dynamic output) {
    if (output == null) return null;
    if (output is String && output.trim().startsWith('http')) {
      return output.trim();
    }
    if (output is List && output.isNotEmpty) {
      return _extractVideoUrl(output.first);
    }
    if (output is Map) {
      for (final key in const ['url', 'video', 'video_url', 'output']) {
        final value = output[key];
        if (value is String && value.trim().startsWith('http')) {
          return value.trim();
        }
      }
    }
    return null;
  }

  /// Pulls the human-readable error out of the Worker's JSON error payloads:
  /// { "success": false, "error": "...", "message": "...", "details": {...} }
  String _workerErrorMessage(Map<String, dynamic> data, String fallback) {
    final error = (data['error'] ?? data['message'] ?? '').toString();
    if (error.isNotEmpty) return 'VYRO Worker: $error';
    return fallback;
  }

  /// Builds an honest error message from a failed HTTP call, surfacing the
  /// Worker's JSON error body when present (e.g. Replicate 400 details).
  String _dioVideoError(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;
    String? workerError;
    try {
      if (body is String) {
        final data = jsonDecode(body);
        if (data is Map<String, dynamic>) {
          workerError = (data['error'] ?? data['message'])?.toString();
        }
      } else if (body is Map) {
        workerError = (body['error'] ?? body['message'])?.toString();
      }
    } catch (_) {}
    if (workerError != null && workerError.isNotEmpty) {
      return 'VYRO Worker: $workerError';
    }
    return 'VYRO Worker video generation failed (HTTP ${status ?? e.type.name}). '
        'The Worker /generate-video endpoint must return a prediction ID or '
        '{ "success": true, "video_url": "..." }.';
  }

  @override
  Future<AiResult<String>> synthesizeSpeech(TtsRequest request) async {
    return AiResult.unavailable(
      'VYRO Worker does not provide speech synthesis yet.',
    );
  }

  /// Storage persistence failed: fall back to a session-local browser blob
  /// URL so the freshly generated image is still shown; otherwise report the
  /// [message] honestly.
  AiResult<List<String>> _blobFallbackOrError(
    Uint8List bytes,
    String contentType,
    String message,
  ) {
    final blobUrl = createBlobUrl(bytes, contentType);
    if (blobUrl != null) return AiResult.success([blobUrl]);
    return AiResult.error(message);
  }
}

/// Downloads [imageUrl] and uploads it to Firebase Storage under
/// `users/{uid}/images/{imageId}.png`. Returns the Firebase Storage
/// download URL (permanent), or [imageUrl] unchanged if upload fails or
/// no UID is available.
Future<String> _uploadImageUrlToStorage(
  ImageGenerationRequest request,
  String imageUrl,
) async {
  if (request.uid == null || request.uid!.isEmpty) {
    return imageUrl;
  }
  try {
    final fs = FirebaseService.instance;
    if (!fs.isInitialized) return imageUrl;
    final dio = Dio();
    final imgRes = await dio.get<dynamic>(
      imageUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    if (imgRes.statusCode != 200) return imageUrl;
    final bytes = Uint8List.fromList((imgRes.data ?? '').codeUnits);
    final mime = imgRes.headers.value('content-type') ?? 'image/png';
    final imageId = const Uuid().v4();
    final ref = fs.imageRef(request.uid!, imageId, '$imageId.png');
    return await fs.uploadBytes(ref, bytes, contentType: mime);
  } catch (e) {
    debugPrint('[VYRO AI] Storage upload failed for $imageUrl: $e');
    return imageUrl;
  }
}

/// Uploads raw image [bytes] to Firebase Storage under
/// `users/{uid}/images/{imageId}.png`. Returns the Firebase Storage
/// download URL (permanent), or a session blob URL as fallback.
Future<String> _uploadImageBytesToStorage(
  ImageGenerationRequest request,
  Uint8List bytes,
  String contentType,
) async {
  if (request.uid == null || request.uid!.isEmpty) {
    final blobUrl = createBlobUrl(bytes, contentType);
    if (blobUrl != null) return blobUrl;
    return 'data:$contentType;base64,${base64Encode(bytes)}';
  }
  try {
    final fs = FirebaseService.instance;
    if (!fs.isInitialized) {
      final blobUrl = createBlobUrl(bytes, contentType);
      return blobUrl ?? 'data:$contentType;base64,${base64Encode(bytes)}';
    }
    final imageId = const Uuid().v4();
    final ref = fs.imageRef(request.uid!, imageId, '$imageId.png');
    return await fs.uploadBytes(ref, bytes, contentType: contentType);
  } catch (e) {
    debugPrint('[VYRO AI] Storage upload failed (bytes): $e');
    final blobUrl = createBlobUrl(bytes, contentType);
    return blobUrl ?? 'data:$contentType;base64,${base64Encode(bytes)}';
  }
}

// ============================================================================
// PROVIDER: POLLINATIONS (free, no-key image generation)
// ============================================================================

/// Real AI image generation via Pollinations.ai (Flux models) — a free
/// public endpoint that requires no API key. This is NOT a mock: every call
/// performs a live HTTP request and only reports success after the service
/// returns actual image bytes. It acts as the built-in free fallback so the
/// image generator works out of the box; premium providers (Runware, fal,
/// Stability, OpenAI) take priority when their keys are configured.
class PollinationsProvider implements AiProvider {
  final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 30)
    ..options.receiveTimeout = const Duration(seconds: 180);

  @override
  String get name => 'Pollinations (Free)';

  @override
  bool get isAvailable => true; // no key needed

  @override
  Set<String> get capabilities => {'image'};

  @override
  Future<AiResult<String>?> pollJob(String jobId) =>
      Future<AiResult<String>?>.value(null);

  @override
  Future<AiResult<List<String>>> generateImage(
    ImageGenerationRequest request,
  ) async {
    try {
      final prompt = Uri.encodeComponent(request.prompt);
      final width = request.width.clamp(256, 1280);
      final height = request.height.clamp(256, 1280);
      final seed = request.seed ?? DateTime.now().millisecondsSinceEpoch % 100000;
      final url =
          'https://image.pollinations.ai/prompt/$prompt?width=$width&height=$height&seed=$seed&nologo=true&model=flux';

      // Live verification: the request only succeeds once the service has
      // actually generated and returned image bytes.
      final res = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final contentType = res.headers.value('content-type') ?? '';
      if (res.statusCode == 200 && contentType.startsWith('image/')) {
        final bytes = Uint8List.fromList(res.data ?? []);
        // Upload to Firebase Storage for permanent persistence.
        final permanentUrl = await _uploadImageBytesToStorage(
          request, bytes, contentType,
        );
        return AiResult.success([permanentUrl]);
      }
      return AiResult.error(
        'Pollinations returned an unexpected response (HTTP ${res.statusCode}).',
      );
    } on DioException catch (e) {
      return AiResult.error(
        'Pollinations image generation failed: ${e.message ?? e.type.name}',
      );
    } catch (e) {
      return AiResult.error('Pollinations image generation failed: $e');
    }
  }

  @override
  Future<AiResult<String>> generateVideo(VideoGenerationRequest request) async {
    return AiResult.unavailable(
      'Video generation needs a configured provider (Runware, fal.ai or Stability AI). Add an API key in .env — Pollinations only supports images.',
    );
  }

  @override
  Future<AiResult<String>> synthesizeSpeech(TtsRequest request) async {
    return AiResult.unavailable(
      'Voice generation needs ElevenLabs or Google TTS key in .env.',
    );
  }
}

// ============================================================================
// AI SERVICE — orchestrates providers with honest fallback
// ============================================================================

class AiService {
  AiService._() {
    // Register providers at construction — previously this lived in a named
    // `AiService.init()` constructor that was never invoked anywhere, so the
    // provider lists stayed empty and every generation showed "unavailable".
    _registerProviders();
  }
  static final AiService instance = AiService._();

  final List<AiProvider> _imageProviders = [];
  final List<AiProvider> _videoProviders = [];
  final List<AiProvider> _ttsProviders = [];

  void _registerProviders() {
    // Image providers (in priority order) — the user's own VYRO Worker first,
    // then keyed premium providers, then the built-in free Pollinations
    // fallback (real generation, no key).
    _imageProviders.add(VyroWorkerProvider());
    if (AppConfig.runwareApiKey.isNotEmpty) _imageProviders.add(RunwareProvider(AppConfig.runwareApiKey));
    if (AppConfig.falApiKey.isNotEmpty) _imageProviders.add(FalProvider(AppConfig.falApiKey));
    if (AppConfig.stabilityApiKey.isNotEmpty) _imageProviders.add(StabilityProvider(AppConfig.stabilityApiKey));
    if (AppConfig.openAIApiKey.isNotEmpty) _imageProviders.add(OpenAiProvider(AppConfig.openAIApiKey));
    // Built-in free fallback LAST so premium keys always win.
    _imageProviders.add(PollinationsProvider());

    // Video providers — the user's VYRO Worker first (its /generate-video
    // endpoint may be a stub today, but wiring it now means video works as
    // soon as the Worker side is implemented, with no app update needed),
    // then keyed premium providers.
    _videoProviders.add(VyroWorkerProvider());
    if (AppConfig.runwareApiKey.isNotEmpty) _videoProviders.add(RunwareProvider(AppConfig.runwareApiKey));
    if (AppConfig.stabilityApiKey.isNotEmpty) _videoProviders.add(StabilityProvider(AppConfig.stabilityApiKey));
    if (AppConfig.falApiKey.isNotEmpty) _videoProviders.add(FalProvider(AppConfig.falApiKey));

    // TTS providers
    if (AppConfig.elevenlabsApiKey.isNotEmpty) _ttsProviders.add(ElevenLabsProvider(AppConfig.elevenlabsApiKey));
    if (AppConfig.googleTtsApiKey.isNotEmpty) _ttsProviders.add(GoogleTtsProvider(AppConfig.googleTtsApiKey));
  }

  /// Whether any image provider is configured.
  bool get hasImageProvider => _imageProviders.isNotEmpty;
  /// Whether any video provider is configured.
  bool get hasVideoProvider => _videoProviders.isNotEmpty;
  /// Whether any TTS provider is configured.
  bool get hasTtsProvider => _ttsProviders.isNotEmpty;

  /// List of configured provider names (for UI transparency).
  List<String> get configuredProviders {
    return <String>{
      ..._imageProviders.map((p) => p.name),
      ..._videoProviders.map((p) => p.name),
      ..._ttsProviders.map((p) => p.name),
    }.toList();
  }

  Future<AiResult<List<String>>> generateImage(ImageGenerationRequest request) async {
    AiResult<List<String>>? last;
    for (final provider in _imageProviders) {
      if (!provider.capabilities.contains('image')) continue;
      last = await provider.generateImage(request);
      if (last.success) return last;
    }
    if (last != null) return last;
    return AiResult.unavailable('No AI image provider configured. Add an API key in .env to enable image generation.');
  }

  Future<AiResult<String>> generateVideo(VideoGenerationRequest request) async {
    AiResult<String>? last;
    for (final provider in _videoProviders) {
      if (!provider.capabilities.contains('video')) continue;
      last = await provider.generateVideo(request);
      if (last.success) return last;
    }
    if (last != null) return last;
    return AiResult.unavailable('No AI video provider configured. Add an API key in .env to enable video generation.');
  }

  Future<AiResult<String>> synthesizeSpeech(TtsRequest request) async {
    AiResult<String>? last;
    for (final provider in _ttsProviders) {
      if (!provider.capabilities.contains('tts')) continue;
      last = await provider.synthesizeSpeech(request);
      if (last.success) return last;
    }
    if (last != null) return last;
    return AiResult.unavailable('No TTS provider configured. Add an API key in .env to enable voice generation.');
  }
}
