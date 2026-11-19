/// VYRO AI — AI Assistant Chat Service
///
/// Text chat completions for the AI Assistant screen.
/// Provider order:
///   1. OpenAI chat completions (OPENAI_API_KEY from .env) — when configured.
///   2. Pollinations free text API (openai-compatible, no key needed) — so the
///      assistant still works honestly without any paid key.
/// Responses are real model output — never faked. Errors surface the
/// provider's own message.
///
/// Streaming: providers are called non-streaming for cross-platform safety
/// (Dio SSE streams are unreliable on web); the UI applies a smooth typewriter
/// reveal so the experience still feels like live typing on every platform.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';

/// One turn in the conversation. [toolResult] renders system/tool context as a
/// distinct bubble style.
class ChatTurn {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime createdAt;
  final bool isError;
  final Uint8List? attachedBytes;
  final String attachedName;

  ChatTurn({
    required this.role,
    required this.content,
    DateTime? createdAt,
    this.isError = false,
    this.attachedBytes,
    this.attachedName = '',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toApiJson() => {'role': role, 'content': content};
}

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final Dio _dio = Dio()
    ..options.connectTimeout = const Duration(seconds: 30)
    ..options.receiveTimeout = const Duration(seconds: 120);

  /// Active request token — lets the UI stop an in-flight generation.
  CancelToken? _activeToken;

  /// Cancels the in-flight chat request (Stop Generation). The pending
  /// future completes with a cancelled DioException; callers treat that as
  /// a user-initiated stop, not an error.
  void cancelCurrent() {
    _activeToken?.cancel('stopped-by-user');
    _activeToken = null;
  }

  /// System prompt that shapes the assistant into the Vyro AI creative
  /// copilot: concise, formatted, video/image production savvy.
  static const String systemPrompt =
      'You are Vyro AI Assistant — a friendly, expert creative copilot inside '
      'the VYRO AI app (AI video, reels and image maker). Help users with '
      'video ideas, scripts, prompts, shot lists, captions and production '
      'tips. Format answers in clean Markdown: short headings, bold key '
      'points, bullet or numbered lists, and fenced code blocks with a '
      'language tag when showing code or JSON. Keep answers focused and '
      'practical. If the user asks for a video prompt, give a vivid, '
      'camera-aware description they can paste into the generators.';

  bool get _openAiConfigured => AppConfig.openAIApiKey.isNotEmpty;

  /// Provider label shown in the UI for transparency.
  String get providerLabel => 'Vyro Cloud (free)';

  /// Sends the full conversation and returns the assistant reply.
  ///
  /// Provider order:
  ///   1. Vyro worker `/chat` proxy — always reachable from browsers
  ///      (Pollinations Turnstile-blocks direct browser requests).
  ///   2. OpenAI chat completions when OPENAI_API_KEY is configured.
  ///   3. Direct Pollinations (works on mobile/desktop, no Origin header).
  Future<String> sendMessage(List<ChatTurn> history) async {
    final historyJson =
        history.where((t) => t.role != 'system').map((t) => t.toApiJson()).toList();
    if (historyJson.isEmpty) {
      throw ChatServiceError('Please write a message first.');
    }

    try {
      return await _workerChat(historyJson);
    } catch (e) {
      // Re-throw cancellations untouched so the UI can handle "stopped".
      if (e is DioException && e.type == DioExceptionType.cancel) rethrow;
      debugPrint('[VYRO AI] Worker chat failed, trying next provider: $e');
    }

    if (_openAiConfigured) {
      try {
        return await _openAiChat([
          {'role': 'system', 'content': systemPrompt},
          ...historyJson,
        ]);
      } catch (e) {
        debugPrint('[VYRO AI] OpenAI chat failed, trying Pollinations: $e');
        // fall through to the free provider so the user is never stuck.
      }
    }
    return _pollinationsChat([
      {'role': 'system', 'content': systemPrompt},
      ...historyJson,
    ]);
  }

  /// Vyro worker proxy: server-side fetch avoids the Pollinations
  /// browser-only Turnstile challenge.
  Future<String> _workerChat(List<Map<String, dynamic>> history) async {
    final base = AppConfig.vyroWorkerUrl;
    if (base.isEmpty) {
      throw ChatServiceError('Vyro worker URL is not configured.');
    }
    final token = CancelToken();
    _activeToken = token;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$base/chat',
        data: {'messages': history, 'system': systemPrompt},
        options: Options(responseType: ResponseType.json),
        cancelToken: token,
      );
      final ok = res.data?['success'] == true;
      final content = res.data?['content']?.toString();
      if (ok && content != null && content.trim().isNotEmpty) {
        return content.trim();
      }
      final err = res.data?['error']?.toString();
      throw ChatServiceError(
        err?.isNotEmpty == true
            ? err!
            : 'Assistant service returned an empty response.',
      );
    } finally {
      if (identical(_activeToken, token)) _activeToken = null;
    }
  }

  Future<String> _openAiChat(List<Map<String, dynamic>> messages) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'https://api.openai.com/v1/chat/completions',
      data: {
        'model': 'gpt-4o-mini',
        'messages': messages,
        'temperature': 0.7,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer ${AppConfig.openAIApiKey}',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );
    final choices = res.data?['choices'] as List?;
    final first = choices?.isNotEmpty == true
        ? choices!.first as Map<String, dynamic>
        : null;
    final content =
        (first?['message'] as Map<String, dynamic>?)?['content']?.toString();
    if (content != null && content.trim().isNotEmpty) {
      return content.trim();
    }
    throw 'OpenAI returned an empty response.';
  }

  /// Free fallback: Pollinations openai-compatible endpoint (no API key).
  Future<String> _pollinationsChat(List<Map<String, dynamic>> messages) async {
    try {
      final res = await _dio.post<dynamic>(
        'https://text.pollinations.ai/openai',
        data: {'model': 'openai', 'messages': messages},
        options: Options(responseType: ResponseType.json),
      );
      final data = res.data;
      if (data is Map) {
        final choices = data['choices'] as List?;
        final first = choices?.isNotEmpty == true
            ? choices!.first as Map<String, dynamic>
            : null;
        final content =
            (first?['message'] as Map<String, dynamic>?)?['content']?.toString();
        if (content != null && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
      if (data is String && data.trim().isNotEmpty) return data.trim();
      throw 'Pollinations returned an empty response.';
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      throw ChatServiceError(
        'Assistant service unavailable (HTTP ${status ?? e.type.name}). '
        'Please try again in a moment.',
      );
    } catch (e) {
      if (e is ChatServiceError) rethrow;
      throw ChatServiceError('Assistant request failed: $e');
    }
  }
}

class ChatServiceError implements Exception {
  final String message;
  ChatServiceError(this.message);
  @override
  String toString() => message;
}
