// ملف مؤقت - محتاج تستبدله بالملف الحقيقي.
//
// عشان تفعّل المزامنة السحابية (تسجيل الدخول + حفظ بياناتك في فايربيز)،
// المفروض تعمل الخطوات دي:
//
// 1. اعمل مشروع على https://console.firebase.google.com
// 2. ثبّت الأداة الرسمية: `dart pub global activate flutterfire_cli`
// 3. من جوه مجلد المشروع شغّل: `flutterfire configure`
//    ده هيسألك تختار المشروع، وهيولّد الملف ده تلقائيًا بمفاتيحك الحقيقية
//    (ويحل محل الملف ده تمامًا).
// 4. فعّل "Email/Password" من Firebase Console > Authentication > Sign-in method
// 5. اعمل قاعدة بيانات Firestore (وضع Test mode مبدئيًا وقت التطوير)
//
// من غير الخطوات دي، التطبيق هيفضل شغال عادي بس من غير تسجيل دخول
// (لأن AuthService.isAvailable هترجع false)، ومفيش أي كراش هيحصل.

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'لسه محتاج تشغّل `flutterfire configure` عشان تولّد المفاتيح الحقيقية '
      'بتاعت مشروع Firebase بتاعك. راجع التعليمات فوق الملف ده.',
    );
  }
}
