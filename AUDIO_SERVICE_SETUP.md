# تشغيل الصوت في الخلفية + شاشة القفل (audio_service)

الكود بتاع الـ Dart جاهز بالكامل (`AudioPlayerHandler` في
`lib/features/player/data/audio_player_handler.dart`)، لكن الزيب ده متسلّم
كـ **lib-only** (من غير مجلدات `android/` و `ios/`). لو لسه ملحقتش
تعمل `flutter create .` على المشروع أو عندك نسخة أصلية بالمجلدات دي،
محتاج تضيف الإعدادات التالية بعد ما تتولّد:

## Android (`android/app/src/main/AndroidManifest.xml`)

جوه `<application>`:

```xml
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true">
  <intent-filter>
    <action android:name="android.media.browse.MediaBrowserService" />
  </intent-filter>
</service>

<receiver
    android:name="com.ryanheise.audioservice.MediaButtonReceiver"
    android:exported="true">
  <intent-filter>
    <action android:name="android.intent.action.MEDIA_BUTTON" />
  </intent-filter>
</receiver>
```

وتأكد إن الصلاحيات دي موجودة فوق `<application>`:

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## iOS (`ios/Runner/Info.plist`)

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

## إشعارات التذكير بالرجوع (flutter_local_notifications)

جوه `<application>` في نفس ملف `AndroidManifest.xml`، ضيف صلاحية الإشعارات:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

بدونها، التذكير اللي بيوصل لو التطبيق اتسابه فترة من غير استماع مش هيظهر
على أندرويد 13 فأكتر.

## المزامنة السحابية الاختيارية (Firebase)

تسجيل الدخول وحفظ بياناتك على السحاب حاجة **اختيارية بالكامل** ومبنيّة
بحيث لو مش عاوزها التطبيق يشتغل عادي من غيرها. لو عاوز تفعّلها:

1. اعمل مشروع على https://console.firebase.google.com
2. ثبّت الأداة الرسمية: `dart pub global activate flutterfire_cli`
3. من جوه مجلد المشروع شغّل: `flutterfire configure`
   (ده هيستبدل ملف `lib/firebase_options.dart` تلقائيًا بمفاتيحك الحقيقية)
4. من Firebase Console > Authentication > Sign-in method، فعّل
   "Email/Password"
5. اعمل قاعدة بيانات Firestore (Test mode مبدئيًا وقت التطوير)

من غير الخطوات دي، شاشة البروفايل مش هتعرض خيار تسجيل الدخول أصلًا (بدل
ما تعرضلك حاجة مش شغالة)، والتطبيق يشتغل عادي بالكامل محليًا.

