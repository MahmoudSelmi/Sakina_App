import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/reciter_model.dart';

abstract class RecitersRemoteDataSource {
  Future<List<ReciterModel>> getReciters();
}

class RecitersRemoteDataSourceImpl implements RecitersRemoteDataSource {
  final Dio _dio = DioClient.instance.client;

  @override
  Future<List<ReciterModel>> getReciters() async {
    try {
      final response = await _dio.get(ApiConstants.reciters);
      final data = response.data as Map<String, dynamic>;
      final list = data['reciters'] as List<dynamic>? ?? [];
      return list
          .map((e) => ReciterModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw RecitersFetchException(e.message ?? 'فشل تحميل القراء');
    }
  }
}

class RecitersFetchException implements Exception {
  final String message;
  RecitersFetchException(this.message);

  @override
  String toString() => message;
}
