import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safar/core/error/failures.dart';
import 'package:safar/core/network/api_client.dart';

class MockHttpAdapter implements HttpClientAdapter {
  ResponseBody? responseBody;
  DioException? errorToThrow;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    return responseBody ??
        ResponseBody.fromString(
          jsonEncode({'success': true, 'data': 'ok'}),
          200,
          headers: {
            'content-type': ['application/json'],
          },
        );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiClient Tests', () {
    late Dio dio;
    late MockHttpAdapter adapter;
    late ApiClient apiClient;

    setUp(() {
      dio = Dio();
      adapter = MockHttpAdapter();
      dio.httpClientAdapter = adapter;
      apiClient = ApiClientImpl(dio);
    });

    test('get() unpacks standard { success: true, data: ... } envelope', () async {
      adapter.responseBody = ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {'id': 'tn-001', 'name': 'Ooty'},
        }),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );

      final result = await apiClient.get<Map<String, dynamic>>(
        '/api/v1/places/tn-001',
        fromJson: (data) => data as Map<String, dynamic>,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?['id'], equals('tn-001'));
      expect(result.dataOrNull?['name'], equals('Ooty'));
    });

    test('get() maps 404 response to NotFoundFailure', () async {
      adapter.errorToThrow = DioException(
        requestOptions: RequestOptions(path: '/api/v1/places/unknown'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/places/unknown'),
          statusCode: 404,
          data: {'message': 'Place not found'},
        ),
      );

      final result = await apiClient.get<Map<String, dynamic>>('/api/v1/places/unknown');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(result.failureOrNull?.message, contains('Place not found'));
    });

    test('get() maps connection timeout to NetworkFailure', () async {
      adapter.errorToThrow = DioException(
        requestOptions: RequestOptions(path: '/api/v1/places'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = await apiClient.get<dynamic>('/api/v1/places');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('post() sends body and parses response successfully', () async {
      adapter.responseBody = ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {'token': 'jwt_test_token_123'},
        }),
        201,
        headers: {
          'content-type': ['application/json'],
        },
      );

      final result = await apiClient.post<String>(
        '/api/v1/auth/login',
        data: {'email': 'test@safar.in', 'password': 'pass'},
        fromJson: (data) => (data as Map<String, dynamic>)['token'] as String,
      );

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals('jwt_test_token_123'));
    });
  });
}
