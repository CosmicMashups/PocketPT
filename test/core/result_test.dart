import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/result.dart';

void main() {
  group('Result', () {
    test('should create success result', () {
      const result = Result.success('test data');
      
      expect(result.isSuccess, true);
      expect(result.isError, false);
      expect(result.data, 'test data');
      expect(result.errorMessage, null);
    });
    
    test('should create error result', () {
      const result = Result.error('test error');
      
      expect(result.isSuccess, false);
      expect(result.isError, true);
      expect(result.data, null);
      expect(result.errorMessage, 'test error');
    });
    
    test('should map success result', () {
      const result = Result.success(42);
      final mapped = result.map((data) => data * 2);
      
      expect(mapped.isSuccess, true);
      expect(mapped.data, 84);
    });
    
    test('should not map error result', () {
      const result = Result.error('test error');
      final mapped = result.map((data) => data * 2);
      
      expect(mapped.isError, true);
      expect(mapped.errorMessage, 'test error');
    });
    
    test('should flatMap success result', () {
      const result = Result.success(42);
      final flatMapped = result.flatMap((data) => Result.success(data * 2));
      
      expect(flatMapped.isSuccess, true);
      expect(flatMapped.data, 84);
    });
    
    test('should not flatMap error result', () {
      const result = Result.error('test error');
      final flatMapped = result.flatMap((data) => Result.success(data * 2));
      
      expect(flatMapped.isError, true);
      expect(flatMapped.errorMessage, 'test error');
    });
    
    test('should execute onSuccess callback', () {
      const result = Result.success('test');
      String? callbackData;
      
      result.onSuccess((data) {
        callbackData = data;
      });
      
      expect(callbackData, 'test');
    });
    
    test('should execute onError callback', () {
      const result = Result.error('test error');
      String? callbackMessage;
      
      result.onError((message, error, stackTrace) {
        callbackMessage = message;
      });
      
      expect(callbackMessage, 'test error');
    });
    
    test('should getOrThrow success result', () {
      const result = Result.success('test data');
      
      expect(result.getOrThrow(), 'test data');
    });
    
    test('should throw on getOrThrow error result', () {
      const result = Result.error('test error');
      
      expect(() => result.getOrThrow(), throwsException);
    });
    
    test('should getOrElse success result', () {
      const result = Result.success('test data');
      
      expect(result.getOrElse('default'), 'test data');
    });
    
    test('should getOrElse error result', () {
      const result = Result.error('test error');
      
      expect(result.getOrElse('default'), 'default');
    });
  });
  
  group('ResultHelper', () {
    test('should tryCatch successful computation', () {
      final result = ResultHelper.tryCatch(() => 42);
      
      expect(result.isSuccess, true);
      expect(result.data, 42);
    });
    
    test('should tryCatch failed computation', () {
      final result = ResultHelper.tryCatch(() => throw Exception('test error'));
      
      expect(result.isError, true);
      expect(result.errorMessage, contains('test error'));
    });
    
    test('should tryCatchAsync successful computation', () async {
      final result = await ResultHelper.tryCatchAsync(() async => 42);
      
      expect(result.isSuccess, true);
      expect(result.data, 42);
    });
    
    test('should tryCatchAsync failed computation', () async {
      final result = await ResultHelper.tryCatchAsync(() async => throw Exception('test error'));
      
      expect(result.isError, true);
      expect(result.errorMessage, contains('test error'));
    });
    
    test('should fromNullable with value', () {
      final result = ResultHelper.fromNullable('test', 'error message');
      
      expect(result.isSuccess, true);
      expect(result.data, 'test');
    });
    
    test('should fromNullable with null', () {
      final result = ResultHelper.fromNullable<String>(null, 'error message');
      
      expect(result.isError, true);
      expect(result.errorMessage, 'error message');
    });
  });
}
