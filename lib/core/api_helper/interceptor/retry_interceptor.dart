
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, handler) async {
    int retries = int.tryParse(err.requestOptions.extra['retries'].toString() )?? 0;

    if (retries < 3) {
      err.requestOptions.extra['retries'] = retries + 1;
      await Future.delayed(Duration(seconds: 2 * (retries + 1)));
      final response = await Dio().fetch(err.requestOptions);
      return handler.resolve(response);
    }

    handler.next(err);
  }
}
