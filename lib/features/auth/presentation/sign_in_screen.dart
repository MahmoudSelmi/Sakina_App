import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../data/auth_service.dart';
import '../data/cloud_sync_service.dart';

enum SignInMode { signIn, signUp }

/// شاشة تسجيل الدخول/إنشاء حساب - بتصميم عصري وهادي، اختيارية بالكامل،
/// بتفعّل بس مزامنة البيانات على السحاب لو المستخدم حب يستخدمها.
class SignInScreen extends StatefulWidget {
  final SignInMode mode;

  const SignInScreen({super.key, required this.mode});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  late SignInMode _mode;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'اكتب الإيميل وكلمة المرور الأول');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

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

    await CloudSyncService.instance.pushLocalData();

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isSignIn = _mode == SignInMode.signIn;
    final fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);

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
        child: Stack(
          children: [
            Positioned(
              top: -100.h,
              left: -70.w,
              child: Container(
                width: 260.w,
                height: 260.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentGold.withValues(alpha: 0.16),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: FadeTransition(
                  opacity: fade,
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
                            border: Border.all(
                                color: AppColors.glassBorder(brightness)),
                          ),
                          child: Icon(Icons.arrow_forward_rounded, size: 20.sp),
                        ),
                      ),
                      SizedBox(height: 28.h),
                      Container(
                        width: 68.w,
                        height: 68.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient:
                              LinearGradient(colors: AppColors.goldGradient),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.accentGold.withValues(alpha: 0.35),
                              blurRadius: 22,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          isSignIn
                              ? Icons.lock_open_rounded
                              : Icons.person_add_alt_1_rounded,
                          color: Colors.black87,
                          size: 30.sp,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        isSignIn ? 'أهلًا بيك تاني' : 'ابدأ رحلتك معانا',
                        style: GoogleFonts.amiri(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: brightness == Brightness.dark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'ده اختياري تمامًا - بس بيخليك تسترجع بياناتك من أي جهاز',
                        style: AppTypography.caption(brightness),
                      ),
                      SizedBox(height: 32.h),
                      _FieldLabel(brightness: brightness, text: 'الإيميل'),
                      SizedBox(height: 8.h),
                      _GlassField(
                        brightness: brightness,
                        controller: _emailController,
                        focusNode: _emailFocus,
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        hint: 'you@example.com',
                      ),
                      SizedBox(height: 18.h),
                      _FieldLabel(brightness: brightness, text: 'كلمة المرور'),
                      SizedBox(height: 8.h),
                      _GlassField(
                        brightness: brightness,
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        hint: '••••••••',
                        suffix: IconButton(
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 19.sp,
                            color: AppColors.accentGoldSoft,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        SizedBox(height: 14.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: AppColors.error, size: 16.sp),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                      color: AppColors.error, fontSize: 12.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 26.h),
                      SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? SizedBox(
                                  width: 22.w,
                                  height: 22.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text(
                                  isSignIn ? 'دخول' : 'إنشاء الحساب',
                                  style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() {
                            _mode = isSignIn
                                ? SignInMode.signUp
                                : SignInMode.signIn;
                            _error = null;
                          }),
                          child: Text(
                            isSignIn
                                ? 'لسه معندكش حساب؟ اعمل واحد'
                                : 'عندك حساب بالفعل؟ سجّل دخول',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final Brightness brightness;
  final String text;

  const _FieldLabel({required this.brightness, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.caption(brightness)
          .copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _GlassField extends StatelessWidget {
  final Brightness brightness;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData icon;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _GlassField({
    required this.brightness,
    required this.controller,
    required this.focusNode,
    required this.icon,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final focused = focusNode.hasFocus;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.glassFill(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: focused
                  ? AppColors.primary
                  : AppColors.glassBorder(brightness),
              width: focused ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 14.w),
              Icon(icon,
                  size: 18.sp,
                  color:
                      focused ? AppColors.primary : AppColors.accentGoldSoft),
              SizedBox(width: 10.w),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  style: AppTypography.body(brightness),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                    hintText: hint,
                    hintStyle: AppTypography.body(brightness).copyWith(
                      color: brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
              if (suffix != null) suffix!,
              SizedBox(width: 6.w),
            ],
          ),
        );
      },
    );
  }
}
