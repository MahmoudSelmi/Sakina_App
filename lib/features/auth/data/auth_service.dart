import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// طبقة فوق Firebase Auth - تسجيل الدخول هنا **اختياري تمامًا** ومش شرط
/// لاستخدام التطبيق. لو Firebase لسه مش متظبط بمفاتيح حقيقية (مفيش
/// google-services.json مثلًا)، كل دوال الكلاس ده بترجع فشل بهدوء من غير
/// ما تكسر التطبيق، والمستخدم بيفضل يستخدم التطبيق عادي كـ"ضيف".
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);
  bool _listening = false;

  /// هل فايربيز مهيّأ فعليًا بمفاتيح حقيقية؟ (يعتمد على firebase_options.dart)
  bool get isAvailable => Firebase.apps.isNotEmpty;

  void _ensureListening() {
    if (_listening || !isAvailable) return;
    _listening = true;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      currentUser.value = user;
    });
    currentUser.value = FirebaseAuth.instance.currentUser;
  }

  Future<String?> signUp(String email, String password) async {
    if (!isAvailable) return 'المزامنة السحابية مش متاحة دلوقتي';
    _ensureListening();
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _arabicError(e.code);
    } catch (_) {
      return 'حصل خطأ غير متوقع، حاول تاني';
    }
  }

  Future<String?> signIn(String email, String password) async {
    if (!isAvailable) return 'المزامنة السحابية مش متاحة دلوقتي';
    _ensureListening();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _arabicError(e.code);
    } catch (_) {
      return 'حصل خطأ غير متوقع، حاول تاني';
    }
  }

  Future<void> signOut() async {
    if (!isAvailable) return;
    await FirebaseAuth.instance.signOut();
  }

  String _arabicError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'الإيميل ده متسجل بالفعل، جرّب تسجّل دخول بدل ما تعمل حساب جديد';
      case 'invalid-email':
        return 'صيغة الإيميل مش صحيحة';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، لازم تكون 6 حروف/أرقام على الأقل';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'الإيميل أو كلمة المرور غلط';
      default:
        return 'حصل خطأ، حاول تاني';
    }
  }
}
