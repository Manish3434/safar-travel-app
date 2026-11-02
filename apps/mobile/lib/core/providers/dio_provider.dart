import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../network/auth_interceptor.dart';
import '../network/retry_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  // On Web, 10.0.2.2 is unreachable (it's Android emulator-specific).
  // Automatically route to http://localhost:3000 when running in the browser.
  final defaultBaseUrl = kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  final configuredUrl = dotenv.maybeGet('BACKEND_BASE_URL');
  final baseUrl = (kIsWeb && (configuredUrl == null || configuredUrl.contains('10.0.2.2')))
      ? 'http://localhost:3000'
      : (configuredUrl ?? defaultBaseUrl);

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Enterprise interceptor pipeline
  dio.interceptors.addAll([
    AuthInterceptor(),
    RetryInterceptor(dio: dio),
  ]);

  return dio;
});
