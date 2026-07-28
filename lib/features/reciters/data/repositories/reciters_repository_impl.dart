import '../../domain/repositories/reciters_repository.dart';
import '../datasources/reciters_remote_data_source.dart';
import '../models/reciter_model.dart';

class RecitersRepositoryImpl implements RecitersRepository {
  final RecitersRemoteDataSource _remote;
  List<ReciterModel>? _cache;

  RecitersRepositoryImpl(this._remote);

  @override
  Future<List<ReciterModel>> getReciters({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    final result = await _remote.getReciters();
    _cache = result;
    return result;
  }
}
