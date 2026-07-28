import 'package:dio/dio.dart';

class DioClient {
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false),
    );
  }

  static final DioClient instance = DioClient._internal();
  late final Dio _dio;

  Dio get client => _dio;
}
