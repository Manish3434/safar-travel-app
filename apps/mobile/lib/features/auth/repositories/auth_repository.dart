import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/error/result.dart';
import '../data/auth_remote_data_source.dart';
import '../models/auth_session.dart';

abstract class AuthRepository {
  Future<Result<AuthSession>> login({required String email, required String password});
  Future<Result<AuthSession>> register({required String email, required String password});
  Future<void> logout();
  Future<String?> getToken();
  Future<bool> isAuthenticated();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remote);
});

class AuthRepositoryImpl implements AuthRepository {
  static const _tokenKey = 'jwt_token';
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<AuthSession>> login({required String email, required String password}) async {
    final result = await _remoteDataSource.login(email: email, password: password);
    if (result.isSuccess) {
      await _persistToken(result.dataOrNull!.token);
    }
    return result;
  }

  @override
  Future<Result<AuthSession>> register({required String email, required String password}) async {
    final result = await _remoteDataSource.register(email: email, password: password);
    if (result.isSuccess) {
      await _persistToken(result.dataOrNull!.token);
    }
    return result;
  }

  @override
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}
  }

  @override
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _persistToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}
  }
}
