import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:tahseen/core/api_helper/dio_error_handler.dart';
import 'package:tahseen/core/base/base_cubit.dart';

abstract class BaseService{

}
class RequestCallbackObserver<T, P> {
  RequestCallbackObserver({
    required this.baseRequestBackType,
    required this.parameter,
    required this.onLoadCallback,
    required this.onRightCallback,
    required this.onLeftCallback,
    this.cancelToken,
  });

  final BaseRequestBackType baseRequestBackType;
  final P? parameter;
  final void Function() onLoadCallback;
  final void Function(T? data) onRightCallback;
  final void Function(Failure failure) onLeftCallback;
  final CancelToken? cancelToken;
}

extension RequestHandler<T, P> on RequestCallbackObserver<T, P> {
  Future<void> handleRequest({
    required Future<Either<Failure, T>> Function(CancelToken? token) fetchFromClient,
    // ── Local storage hooks (optional) ──────────────────────────────────────
    Future<T?> Function()? fetchLocal,
    Future<void> Function(T? old, T? newData)? saveLocal,
    Future<void> Function()? clearLocal,
  }) async {
    final type = baseRequestBackType;

    // ── Guard by request type ──────────────────────────────────────────────
    if (type is Init) {
      if (fetchLocal != null) {
        final localData = await fetchLocal();
        if (localData != null) {
          onRightCallback(localData);
          return;
        }
      }
    } else if (type is Reload) {
      await clearLocal?.call();
    } else if (type is Pagination) {
      if (type.currentPage >= type.lastPage) return;
    }

    // ── Notify loading ─────────────────────────────────────────────────────
    onLoadCallback();

    // ── Fetch from remote repo ─────────────────────────────────────────────
    // Pass the cancelToken from the observer to the fetch function
    final result = await fetchFromClient(cancelToken);

    // ── Handle result ──────────────────────────────────────────────────────
    result.fold(
          onLeftCallback,
          (data) async {
        if (fetchLocal != null) {
          var local;
          if (type is Pagination) {
            local = await fetchLocal.call();
          }
          await saveLocal?.call(local, data);
        }
        onRightCallback(data);
      },
    );
  }
}
