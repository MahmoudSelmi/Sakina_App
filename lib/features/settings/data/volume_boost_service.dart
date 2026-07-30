import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/storage/local_storage.dart';

/// تسجيلات القراء المختلفة بتيجي أحيانًا بمستويات صوت مختلفة (واحد عالي
/// وواحد واطي) لأن مفيش بيانات "loudness" جاهزة من المصدر نقدر نطبّع
/// بيها الصوت تلقائيًا. الحل العملي هنا: خلي المستخدم يظبط مستوى صوت كل
/// قارئ مرة واحدة، والتطبيق بيفتكره ويطبّقه تلقائيًا في كل مرة بعد كده.
class VolumeBoostService {
  VolumeBoostService._internal();
  static final VolumeBoostService instance = VolumeBoostService._internal();

  final ValueNotifier<Map<int, double>> boosts = ValueNotifier<Map<int, double>>({});

  void load() {
    final raw = LocalStorage.instance.getString(StorageKeys.volumeBoosts);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      boosts.value = decoded.map((key, value) => MapEntry(int.parse(key), (value as num).toDouble()));
    } catch (_) {
      boosts.value = {};
    }
  }

  double getBoost(int reciterId) => boosts.value[reciterId] ?? 1.0;

  Future<void> setBoost(int reciterId, double value) async {
    final updated = Map<int, double>.from(boosts.value);
    if (value == 1.0) {
      updated.remove(reciterId);
    } else {
      updated[reciterId] = value;
    }
    boosts.value = updated;
    final encoded = jsonEncode(updated.map((key, value) => MapEntry(key.toString(), value)));
    await LocalStorage.instance.setString(StorageKeys.volumeBoosts, encoded);
  }
}
