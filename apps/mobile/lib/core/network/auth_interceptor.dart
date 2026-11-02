import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Appends Bearer token to requests and manages authentication headers.
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    return super.onRequest(options, handler);
  }
}
