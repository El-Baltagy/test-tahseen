
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final Future<String?> Function()? getAccessToken;
  final Future<String?> Function()? refreshToken;

  AuthInterceptor({
    required this.dio,
    required this.getAccessToken,
    required this.refreshToken,
  });

  @override
  void onRequest(RequestOptions options, handler) async {
if(getAccessToken!=null){
  final token = await getAccessToken!();
  if (token != null) {
    options.headers['Authorization'] = 'Bearer $token';
  }
}

handler.next(options);
  }

  @override
  void onError(DioException err, handler) async {
    if (err.response?.statusCode == 401) {
     if(refreshToken!=null){
       final newToken = await refreshToken!();
       if (newToken != null) {
         err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
         final response = await dio.fetch(err.requestOptions);
         return handler.resolve(response);
       }
     }
    }
    handler.next(err);
  }
}
