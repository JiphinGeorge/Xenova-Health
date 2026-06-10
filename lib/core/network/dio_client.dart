import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/api_constants.dart';

/// Configures and provides the Dio HTTP client for API calls.
///
/// Includes interceptors for authentication, logging, and retry logic.
class DioClient {
  DioClient({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  /// Provides the configured Dio instance.
  Dio get dio => _dio;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
        headers: {
          'Content-Type': ApiConstants.contentTypeJson,
          'Accept': ApiConstants.acceptJson,
        },
      ),
    );

    // Add logging interceptor in debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    // Add retry interceptor
    dio.interceptors.add(_RetryInterceptor(dio));

    return dio;
  }

  /// Makes a GET request to the USDA API.
  Future<Response<T>> usdaGet<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final apiKey = dotenv.env['USDA_API_KEY'] ?? '';
    final params = {'api_key': apiKey, ...?queryParameters};

    return _dio.get(
      '${ApiConstants.usdaBaseUrl}$endpoint',
      queryParameters: params,
    );
  }

  /// Makes a POST request to the USDA API.
  Future<Response<T>> usdaPost<T>(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    final apiKey = dotenv.env['USDA_API_KEY'] ?? '';
    final params = {'api_key': apiKey, ...?queryParameters};

    return _dio.post(
      '${ApiConstants.usdaBaseUrl}$endpoint',
      data: data,
      queryParameters: params,
    );
  }

  /// Makes a generic GET request.
  Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
  }) async {
    return _dio.get(
      url,
      queryParameters: queryParameters,
      options: options ?? Options(headers: headers),
    );
  }

  /// Makes a generic POST request.
  Future<Response<T>> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
  }) async {
    return _dio.post(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options ?? Options(headers: headers),
    );
  }
}

/// Retry interceptor with exponential backoff.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only retry on network/timeout errors
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

      if (retryCount < ApiConstants.maxRetries) {
        final delay = Duration(
          milliseconds: ApiConstants.retryDelayMs * (retryCount + 1),
        );

        await Future<void>.delayed(delay);

        final options = err.requestOptions;
        options.extra['retryCount'] = retryCount + 1;

        try {
          final response = await _dio.fetch<dynamic>(options);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }

    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
