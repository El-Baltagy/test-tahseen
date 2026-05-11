import 'package:dio/dio.dart';
import 'package:tahseen/core/shared/methods/print.dart';

class CancelManager {
  static final Map<int, CancelToken> _tokens = {};

  static CancelToken create(int id) {
    final token = CancelToken();
    _tokens[id] = token;
    return token;
  }

  static CancelToken? get(int id) => _tokens[id];

  static void cancel(int id, [String? reason]) {
    final token = _tokens[id];
    if (token != null && !token.isCancelled) {
      token.cancel(reason ?? "Cancelled by user");
      PrintHelper().ordinaryPrint("Request with ID $id was cancelled");
    } else {
      PrintHelper().ordinaryPrint("No active request found with ID $id");
    }
  }



  static void remove(int id) => _tokens.remove(id);
  static Future<T> runCancelableFun<T>(int id, Future<T> Function(CancelToken token) action) async {
    final token = CancelManager.create(id);
    try {
      final result = await action(token);
      return result;
    } finally {
      CancelManager.remove(id);
    }
  }
}
