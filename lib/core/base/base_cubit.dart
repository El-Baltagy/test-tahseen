// lib/core/base/base_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:tahseen/core/api_helper/cancel/cancel_annotation.dart';
import 'package:tahseen/core/api_helper/cancel/cancel_manager.dart';


abstract class BaseCubit<T> extends Cubit<T> {
  BaseCubit(super.initialState);

  bool _isDisposed = false;

init();
  @protected
  void safeEmit(T state) {
    if (!_isDisposed && !isClosed) emit(state);
  }

  @protected
  void handleError(Object error, [StackTrace? stackTrace]) {
    debugPrint('[$runtimeType] Cubit error: $error');
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    return super.close();
  }





// void cancelRequest(int id) => CancelManager.cancel(id);

}



enum RequestTypeBackV1 { init, reload, pagination }

extension RequestTypeBack on RequestTypeBackV1 {
  BaseRequestBackType toRequestType({
    required int currentPage,
    required int lastPage,
  }) {
    return switch (this) {
      RequestTypeBackV1.init => Init(),
      RequestTypeBackV1.reload => Reload(),
      RequestTypeBackV1.pagination => Pagination(
        currentPage: currentPage,
        lastPage: lastPage,
      ),
    };
  }
}

enum RequestTypeBackV2 { init, reload }

extension RequestTypeBack2 on RequestTypeBackV2 {
  BaseRequestBackType toRequestType() {
    return switch (this) {
      RequestTypeBackV2.init => Init(),
      RequestTypeBackV2.reload => Reload(),
    };
  }
}

abstract class BaseRequestBackType {}

class Init extends BaseRequestBackType {
  Init._();
  static final Init _instance = Init._();
  factory Init() => _instance;
}

class Reload extends BaseRequestBackType {
  Reload._();
  static final Reload _instance = Reload._();
  factory Reload() => _instance;
}

class Pagination extends BaseRequestBackType {
  final int currentPage;
  final int lastPage;
  Pagination({required this.currentPage, required this.lastPage});
}
