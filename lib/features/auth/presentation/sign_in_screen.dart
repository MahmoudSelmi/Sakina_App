import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/auth_service.dart';
import '../data/cloud_sync_service.dart';

enum SignInMode { signIn, signUp }

/// شاشة تسجيل الدخول/إنشاء حساب - اختيارية بالكامل، بتفعّل بس مزامنة
/// البيانات على السحاب لو المستخدم حب يستخدمها.
class SignInScreen extends StatefulWidget {
  final SignInMode mode;

  const SignInScreen({super.key, required this.mode});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  late SignInMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    final error = _mode == SignInMode.signIn
        ? await AuthService.instance.signIn(email, password)
        : await AuthService.instance.signUp(email, password);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _loading = false;
        _error = error;
      });
      return;
    }

    // بعد أي دخول ناجح، بنرفع نسخة من البيانات المحلية على السحاب.
    await CloudSyncService.instance.pushLocalData();

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isSignIn = _mode == SignInMode.signIn;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: brightness == Brightness.dark
                ? AppColors.heroGradientDark
                : AppColors.heroGradientLight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.glassFill(brightness),
                      border: Border.all(color: AppColors.glassBorder(brightness)),
                    ),
                    child: Icon(Icons.arrow_forward_rounded, size: 20.sp),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  isSignIn ? 'تسجيل الدخول' : 'حساب جديد',
                  style: AppTypography.headline(brightness),
                ),
                SizedBox(height: 6.h),
                Text(
                  'ده اختياري - بس بيخليك تسترجع بياناتك من أي جهاز',
                  style: AppTypography.caption(brightness),
                ),
                SizedBox(height: 28.h),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.body(brightness),
                  decoration: const InputDecoration(labelText: 'الإيميل'),
                ),
                SizedBox(height: 14.h),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: AppTypography.body(brightness),
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                ),
                if (_error != null) ...[
                  SizedBox(height: 12.h),
                  Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 12.sp)),
                ],
                SizedBox(height: 22.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(isSignIn ? 'دخول' : 'إنشاء الحساب'),
                  ),
                ),
                SizedBox(height: 14.h),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _mode = isSignIn ? SignInMode.signUp : SignInMode.signIn;
                      _error = null;
                    }),
                    child: Text(
                      isSignIn ? 'لسه معندكش حساب؟ اعمل واحد' : 'عندك حساب بالفعل؟ سجّل دخول',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
