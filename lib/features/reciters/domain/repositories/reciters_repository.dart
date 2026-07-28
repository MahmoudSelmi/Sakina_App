import '../../data/models/reciter_model.dart';

abstract class RecitersRepository {
  Future<List<ReciterModel>> getReciters({bool forceRefresh = false});
}
