import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// بيبعت تذكير لطيف بالمصري لو المستخدم سايب التطبيق فترة من غير ما
/// يسمع، عشان يرجعله برسالة بجميلة مش بإلحاح.
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const int _reminderNotificationId = 1001;
  bool _initialized = false;

  static const List<String> _messages = [
    'افتقدناك 🌙 تعال اسمع بس دقيقتين، القرآن مستنيك',
    'يوم من غير قرآن يوم ناقصه بركة.. يلا بينا نرجع لـ جَنَّتَكَ 🤍',
    'قلبك محتاج شوية طمأنينة النهارده، اسمع آية وارتاح 🌙',
    'مشتاقين لصوتك وانت بتسمع معانا.. جرّب ترجع النهارده',
    'دقيقة واحدة مع كتاب ربنا تغيّر يومك كله - تعال جرّب',
  ];

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(
            android: androidSettings, iOS: iosSettings),
      );

      // نطلب إذن الإشعارات (لازم في أندرويد 13+ وiOS).
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _initialized = true;
    } catch (_) {
      // لو حصل أي مشكلة في تهيئة الإشعارات، التطبيق يكمل عادي من غيرها.
    }
  }

  /// بيجدول تذكير لطيف بعد 24 ساعة من آخر مرة استخدم فيها التطبيق - بيتلغي
  /// ويتجدد تلقائي كل ما المستخدم يفتح التطبيق أو يسمع، عشان ميوصلوش
  /// إشعار وهو مستخدم بالفعل.
  Future<void> scheduleComeBackReminder() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_reminderNotificationId);
      final message = _messages[Random().nextInt(_messages.length)];
      final scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(hours: 24));

      await _plugin.zonedSchedule(
        _reminderNotificationId,
        'جَنَّتَكَ 🌙',
        message,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'come_back_reminders',
            'تذكير بالرجوع للاستماع',
            channelDescription:
                'تذكير لطيف لما تسيب التطبيق فترة من غير استماع',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // تجاهل أي خطأ جدولة (زي رفض صلاحية الإشعارات) من غير ما نكسر التطبيق
    }
  }

  Future<void> cancelComeBackReminder() async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_reminderNotificationId);
    } catch (_) {
      // تجاهل
    }
  }
}
