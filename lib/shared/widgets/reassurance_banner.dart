import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// شريط "لحظة طمأنينة" - بيفضل شغال تحت في الشاشة الرئيسية، بيدور على
/// آيات قصيرة فيها سكينة وتفريج، مع نقطة بتنبض بهدوء زي إيقاع التنفس.
/// الهدف إنه يديك سكون بصري بسيط وسط أي يوم مزحوم أو ضايق.
class ReassuranceBanner extends StatefulWidget {
  final VoidCallback? onDismiss;

  const ReassuranceBanner({super.key, this.onDismiss});

  @override
  State<ReassuranceBanner> createState() => _ReassuranceBannerState();
}

class _ReassuranceBannerState extends State<ReassuranceBanner>
    with SingleTickerProviderStateMixin {
  static const List<_Ayah> _ayat = [
    _Ayah('لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا', 'سورة البقرة - 286'),
    _Ayah('إِنَّ مَعَ الْعُسْرِ يُسْرًا', 'سورة الشرح - 6'),
    _Ayah('حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ', 'سورة آل عمران - 173'),
    _Ayah('وَبَشِّرِ الصَّابِرِينَ', 'سورة البقرة - 155'),
    _Ayah('أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ', 'سورة الرعد - 28'),
    _Ayah('فَإِنَّ مَعَ الْعُسْرِ يُسْرًا', 'سورة الشرح - 5'),
    _Ayah('وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ', 'سورة الحديد - 4'),
  ];

  late final AnimationController _breathe;
  late final _Ayah _current;

  @override
  void initState() {
    super.initState();
    _current = _ayat[DateTime.now().millisecond % _ayat.length];
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.glassFill(brightness),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder(brightness)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _breathe,
            builder: (context, child) {
              final scale = 0.8 + (_breathe.value * 0.4);
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppColors.goldGradient),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _current.text,
                  style: GoogleFonts.amiri(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: brightness == Brightness.dark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(_current.reference, style: AppTypography.caption(brightness)),
              ],
            ),
          ),
          if (widget.onDismiss != null)
            GestureDetector(
              onTap: widget.onDismiss,
              child: Icon(
                Icons.close_rounded,
                size: 16.sp,
                color: brightness == Brightness.dark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
        ],
      ),
    );
  }
}

class _Ayah {
  final String text;
  final String reference;
  const _Ayah(this.text, this.reference);
}
