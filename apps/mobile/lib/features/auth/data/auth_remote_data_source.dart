import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/auth_session.dart';

abstract class AuthRemoteDataSource {
  Future<Result<AuthSession>> login({required String email, required String password});
  Future<Result<AuthSession>> register({required String email, required String password});
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthRemoteDataSourceImpl(client);
});

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<Result<AuthSession>> login({required String email, required String password}) {
    return _client.post<AuthSession>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
      fromJson: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<AuthSession>> register({required String email, required String password}) {
    return _client.post<AuthSession>(
      ApiEndpoints.register,
      data: {'email': email, 'password': password},
      fromJson: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    );
  }
}
