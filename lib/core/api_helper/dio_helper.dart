import 'package:dio/dio.dart';
import 'package:tahseen/flavor_config.dart';
class DioHelper {
  late Dio _dio;
  Dio get dio => _dio;


  DioHelper call() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppFlavorConfig.instance.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'X-App-Flavor': AppFlavorConfig.instance.flavor.name,
        },
      ),
    );

    _dio.interceptors.addAll(AppFlavorConfig.instance.interceptors);

    return this;
  }

  Future<dynamic> getData({
    required String uri,
    CancelToken? cancelToken,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    final res = await _dio.get(
      uri,
      cancelToken: cancelToken,
      queryParameters: query,
      options: Options(
        responseType: ResponseType.plain,
        headers: headers,
      ),
    );
    return res.data;
  }

  Future<dynamic> postData({
    required String uri,
    CancelToken? cancelToken,
    dynamic data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    final res = await _dio.post(
      uri,
      cancelToken: cancelToken,
      data: data,
      queryParameters: query,
      options: Options(
        responseType: ResponseType.plain,
        headers: headers,
      ),
    );
    return res.data;
  }

  Future<dynamic> deleteData({
    required String uri,
    CancelToken? cancelToken,
    dynamic data,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    final res = await _dio.delete(
      uri,
      cancelToken: cancelToken,
      data: data,
      queryParameters: query,
      options: Options(
        responseType: ResponseType.plain,
        headers: headers,
      ),
    );
    return res.data;
  }

  Future<String?> Function()? get getToken => null;
  Future<String?> Function()? get refreshToken => null;
}
