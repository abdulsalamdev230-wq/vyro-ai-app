/// VYRO AI â€” REST API Service
///
/// Secure REST client for the Node.js backend. Auth tokens (Firebase ID tokens)
/// are injected automatically. Base URL comes from environment config â€” never
/// hardcoded. When the backend is unreachable, errors are surfaced honestly.


import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-App-Name': AppConfig.appName,
          'X-App-Version': AppConfig.version,
        },
      ),
    )
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // Inject Firebase ID token for authenticated requests.
            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final token = await user.getIdToken();
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (_) {
              // No user signed in â€” proceed without auth header.
            }
            return handler.next(options);
          },
          onError: (DioException e, handler) async {
            if (kDebugMode) {
              debugPrint(
                '[VYRO AI API] ${e.response?.statusCode} ${e.requestOptions.uri} ${e.message}',
              );
            }
            return handler.next(e);
          },
        ),
      );
  }

  // Factory-style init so we can keep a single static instance with constructor.
  factory ApiService() => instance;

  // ------ GET ------
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    final res = await _dio.get(path, queryParameters: query, options: options);
    return res.data;
  }

  // ------ POST ------
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    final res = await _dio.post(
      path,
      data: data,
      queryParameters: query,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return res.data;
  }

  // ------ PUT ------
  Future<dynamic> put(String path, {dynamic data, Options? options}) async {
    final res = await _dio.put(path, data: data, options: options);
    return res.data;
  }

  // ------ DELETE ------
  Future<dynamic> delete(String path, {Options? options}) async {
    final res = await _dio.delete(path, options: options);
    return res.data;
  }

  /// Multipart upload (e.g. video to backend for server-side processing).
  Future<dynamic> uploadMultipart(
    String path, {
    required String fileField,
    required String filePath,
    Map<String, dynamic>? fields,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      ...?fields,
      fileField: await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post(
      path,
      data: formData,
      options: Options(
        headers: {'content-type': 'multipart/form-data'},
      ),
      onSendProgress: onSendProgress,
    );
    return res.data;
  }

  /// Health check â€” returns true if backend is reachable.
  Future<bool> isHealthy() async {
    try {
      await _dio.get('/health', options: Options(receiveTimeout: const Duration(seconds: 5)));
      return true;
    } catch (_) {
      return false;
    }
  }

  void close() {
    _dio.close();
  }
}

// Keep a top-level ApiService() constructor alias.
ApiService get apiService => ApiService();
