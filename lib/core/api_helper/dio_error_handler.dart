import 'package:dio/dio.dart';
import 'dart:io';

abstract class DioErrorHandler {
  static Failure handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        return Failure('Request was cancelled by user.');
      case DioExceptionType.connectionTimeout:
        return Failure('Connection timeout.');
      case DioExceptionType.receiveTimeout:
        return Failure('Receive timeout.');
      case DioExceptionType.sendTimeout:
        return Failure('Send timeout.');
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return Failure('No internet connection.');
        }
        return Failure('Connection error.');
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return Failure('No internet connection.');
        }
        return Failure('Unexpected network error.');
      case DioExceptionType.badCertificate:
        // TODO: Handle this case.
        return Failure('incorrect certificate');
    }
  }

  static Failure _handleBadResponse(Response? response) {
    if (response == null) return Failure('Unknown server error.');
    final code = response.statusCode ?? 0;

    String message;
    switch (code) {
      case 400:
        message = 'Bad request.';
        break;
      case 401:
        message = 'Unauthorized.';
        break;
      case 403:
        message = 'Forbidden.';
        break;
      case 404:
        message = 'Not found.';
        break;
      case 500:
        message = 'Internal server error.';
        break;
      default:
        message = 'Unexpected error. Code: $code';
    }

    return Failure(message, code);
  }
}
class Failure {
  final String message;
  final int? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}
