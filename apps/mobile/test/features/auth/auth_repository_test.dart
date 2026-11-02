import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safar/core/error/failures.dart';
import 'package:safar/core/error/result.dart';
import 'package:safar/features/auth/data/auth_remote_data_source.dart';
import 'package:safar/features/auth/models/auth_session.dart';
import 'package:safar/features/auth/repositories/auth_repository.dart';

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  Result<AuthSession>? mockResult;

  @override
  Future<Result<AuthSession>> login({required String email, required String password}) async {
    return mockResult ?? Result.success(const AuthSession(token: 'mock_jwt_token', email: 'test@safar.in'));
  }

  @override
  Future<Result<AuthSession>> register({required String email, required String password}) async {
    return mockResult ?? Result.success(const AuthSession(token: 'mock_registered_jwt', email: 'new@safar.in'));
  }
}

void main() {
  group('AuthRepository Tests', () {
    late FakeAuthRemoteDataSource remote;
    late AuthRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      remote = FakeAuthRemoteDataSource();
      repository = AuthRepositoryImpl(remote);
    });

    test('login persists token on success', () async {
      remote.mockResult = Result.success(const AuthSession(token: 'jwt_abc_123', email: 'user@safar.in'));

      final result = await repository.login(email: 'user@safar.in', password: 'secret');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.token, equals('jwt_abc_123'));

      final storedToken = await repository.getToken();
      expect(storedToken, equals('jwt_abc_123'));
      expect(await repository.isAuthenticated(), isTrue);
    });

    test('login does not persist token on failure', () async {
      remote.mockResult = Result.failure(const UnauthorizedFailure('Invalid credentials'));

      final result = await repository.login(email: 'user@safar.in', password: 'wrong');

      expect(result.isFailure, isTrue);
      final storedToken = await repository.getToken();
      expect(storedToken, isNull);
      expect(await repository.isAuthenticated(), isFalse);
    });

    test('logout clears stored JWT token', () async {
      SharedPreferences.setMockInitialValues({'jwt_token': 'existing_token'});
      expect(await repository.isAuthenticated(), isTrue);

      await repository.logout();

      expect(await repository.getToken(), isNull);
      expect(await repository.isAuthenticated(), isFalse);
    });
  });
}
