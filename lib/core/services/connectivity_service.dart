import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// بيتابع حالة الاتصال بالإنترنت لحظيًا، عشان نقدر نوريك بانر واضح لو
/// النت مقطوع بدل ما نستنى الطلب يفشل من غير تفسير.
class ConnectivityService {
  ConnectivityService._internal() {
    _init();
  }

  static final ConnectivityService instance = ConnectivityService._internal();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _init() async {
    try {
      final result = await Connectivity().checkConnectivity();
      isOnline.value = !result.contains(ConnectivityResult.none);
    } catch (_) {
      // نسيب القيمة الافتراضية (متصل) لو حصل أي خطأ في القراءة الأولى
    }

    _sub = Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    });
  }

  void dispose() => _sub?.cancel();
}
