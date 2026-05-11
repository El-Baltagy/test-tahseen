import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tahseen/core/shared/methods/print.dart';
import 'package:tahseen/core/api_helper/dio_error_handler.dart';

// Threshold for background processing: 100KB
const int threshold = 100 * 1024;
/// Handles the API response by potentially offloading heavy JSON parsing 
/// and model mapping to a background isolate.

Future<Either<Failure, T>> handleResponse<T>({
  required Future<dynamic> onCallData,
  required T Function(Map<String, dynamic> map) asObject,
}) async {
  try {
    final dynamic data = await onCallData;
    

    final String jsonString = data is String ? data : data.toString();
    final int size = jsonString.length;

    PrintHelper().loggerPrint(
      '''✅ [API SUCCESS]\n   └─ Size: ${size} bytes\n   └─ Preview: ${size > 500 ? '${jsonString.substring(0, 500)}...' : jsonString}''',
      LoggerType.info,
    );

    final T result;
    if (size > threshold) {
      // Use compute to handle both jsonDecode and model mapping in an isolate
      result = await compute(_parseAndMapIsolate<T>, _ParseParams<T>(jsonString, asObject));
    } else {
      // Synchronous parse and map for small data
      final Map<String, dynamic> jsonMap = _ensureMap(jsonString);
      result = asObject(jsonMap);
    }

    return right(result);
  } on DioException catch (e) {
    PrintHelper().loggerPrint(
      '''💥 [API DIO ERROR]\n   └─ Status: ${e.response?.statusCode}\n   └─ Msg: ${e.message}\n   └─ Data: ${e.response?.data}''',
      LoggerType.error,
    );
    return left(DioErrorHandler.handleError(e));
  } catch (e, s) {
    PrintHelper().loggerPrint(
      '''⚠️ [API PARSE/OTHER ERROR]\n   └─ Error: $e\n   └─ Stack: ${s.toString().split('\n').take(3).join('\n')}''',
      LoggerType.fatal,
    );
    return left(Failure("Format Error or Unknown Error: $e", -2));
  }
}

/// Helper function for isolate execution
T _parseAndMapIsolate<T>(_ParseParams<T> params) {
  final Map<String, dynamic> jsonMap = _ensureMap(params.jsonString);
  return params.asObject(jsonMap);
}

/// Ensures the input is converted to a Map
Map<String, dynamic> _ensureMap(String jsonString) {
  final decoded = jsonDecode(jsonString);
  if (decoded is Map<String, dynamic>) return decoded;
  // if (decoded is List) return {'data': decoded};
  return {'data': decoded};
}

/// Parameters for isolate communication
class _ParseParams<T> {
  _ParseParams(this.jsonString, this.asObject);
  final String jsonString;
  final T Function(Map<String, dynamic> map) asObject;
}
