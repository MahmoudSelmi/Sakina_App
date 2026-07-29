import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/surah_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/arabic_text.dart';
import '../../../shared/widgets/page_transitions.dart';
import '../../../shared/widgets/staggered_fade_in.dart';
import '../../reciters/data/models/reciter_model.dart';
import 'surah_reciters_screen.dart';

/// شاشة "تصفح بالسورة": المستخدم بيختار السورة الأول، وبعدين يختار مين
/// يقرأها له من كل القراء المتاحين - عكس رحلة "قارئ ثم سورة" المعتادة.
class SurahBrowseScreen extends StatefulWidget {
  final List<ReciterModel> reciters;

  const SurahBrowseScreen({super.key, required this.reciters});

  @override
  State<SurahBrowseScreen> createState() => _SurahBrowseScreenState();
}

class _SurahBrowseScreenState extends State<SurahBrowseScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _readerCountFor(int surahNumber) {
    return widget.reciters
        .where((r) => r.moshaf.any((m) => m.hasSurah(surahNumber)))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final filtered = SurahData.all.where((s) {
      if (_query.isEmpty) return true;
      if (s.number.toString() == _query) return true;
      return ArabicText.contains(s.arabicName, _query);
    }).toList();

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
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                child: Row(
                  children: [
                    _BackCircle(brightness: brightness),
                    SizedBox(width: 12.w),
                    Text('تصفح بالسورة',
                        style: AppTypography.title(brightness)),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.glassFill(brightness),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: AppColors.glassBorder(brightness)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          size: 20.sp, color: AppColors.accentGoldSoft),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: AppTypography.body(brightness),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: 'دور على سورة بالاسم أو الرقم...',
                          ),
                          onChanged: (v) => setState(() => _query = v.trim()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    final surah = filtered[index];
                    final count = _readerCountFor(surah.number);
                    return StaggeredFadeIn(
                      index: index,
                      stepDelay: const Duration(milliseconds: 18),
                      child: _SurahTile(
                        number: surah.number,
                        name: surah.arabicName,
                        readerCount: count,
                        onTap: count == 0
                            ? null
                            : () => Navigator.of(context).push(fadeScaleRoute(
                                  SurahRecitersScreen(
                                    surahNumber: surah.number,
                                    surahName: surah.arabicName,
                                    reciters: widget.reciters,
                                  ),
                                )),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackCircle extends StatelessWidget {
  final Brightness brightness;

  const _BackCircle({required this.brightness});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

class _SurahTile extends StatelessWidget {
  final int number;
  final String name;
  final int readerCount;
  final VoidCallback? onTap;

  const _SurahTile({
    required this.number,
    required this.name,
    required this.readerCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final disabled = onTap == null;

    return Material(
      color: AppColors.glassFill(brightness),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: disabled ? 0.45 : 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: AppColors.goldGradient),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                    child: Text(name, style: AppTypography.body(brightness))),
                Text(
                  disabled ? 'مفيش تسجيلات' : '$readerCount قارئ',
                  style: AppTypography.caption(brightness),
                ),
                SizedBox(width: 6.w),
                if (!disabled)
                  Icon(Icons.chevron_left_rounded,
                      color: AppColors.primary, size: 22.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
