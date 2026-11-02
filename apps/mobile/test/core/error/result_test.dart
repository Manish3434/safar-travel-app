import 'package:flutter_test/flutter_test.dart';
import 'package:safar/core/error/failures.dart';
import 'package:safar/core/error/result.dart';

void main() {
  group('Result Type Tests', () {
    test('Success should hold data and return isSuccess = true', () {
      const data = 'destination_data';
      final result = Result.success(data);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, equals(data));
      expect(result.failureOrNull, isNull);

      final mapped = result.when(
        success: (d) => 'Found: $d',
        failure: (f) => 'Failed',
      );
      expect(mapped, equals('Found: destination_data'));
    });

    test('Failure should hold AppFailure and return isFailure = true', () {
      const failure = NetworkFailure('Connection timed out');
      final result = Result<String>.failure(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, equals(failure));

      final mapped = result.when(
        success: (d) => 'Success',
        failure: (f) => f.message,
      );
      expect(mapped, equals('Connection timed out'));
    });

    test('AppFailure toString returns descriptive type and message', () {
      const failure = ServerFailure('Internal Server Error', 500, 'DB timeout');
      expect(failure.toString(), contains('ServerFailure'));
      expect(failure.toString(), contains('Internal Server Error'));
      expect(failure.toString(), contains('500'));
    });
  });
}
