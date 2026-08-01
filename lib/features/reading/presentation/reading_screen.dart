import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../favorites/data/ayah_favorites_service.dart';
import '../data/ayah_model.dart';
import '../data/quran_text_service.dart';

/// شاشة "وضع القراءة" - بتعرض نص السورة كاملة بشكل يشبه صفحة المصحف،
/// عشان تقدر تقرا وانت سامع، أو حتى من غير صوت خالص.
class ReadingScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const ReadingScreen({super.key, required this.surahNumber, required this.surahName});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late Future<List<AyahModel>> _future;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _future = QuranTextService.instance.getSurahText(widget.surahNumber);
  }

  void _retry() {
    setState(() {
      _future = QuranTextService.instance.getSurahText(widget.surahNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // البسملة بتتقال في بداية كل سورة ماعدا سورة التوبة.
    final showBasmala = widget.surahNumber != 9;

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
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 4.h),
                child: Row(
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
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text('سورة ${widget.surahName}', style: AppTypography.title(brightness)),
                    ),
                    _fontSizeButton(brightness, Icons.text_decrease_rounded, () {
                      setState(() => _fontScale = (_fontScale - 0.1).clamp(0.7, 1.6));
                    }),
                    SizedBox(width: 6.w),
                    _fontSizeButton(brightness, Icons.text_increase_rounded, () {
                      setState(() => _fontScale = (_fontScale + 0.1).clamp(0.7, 1.6));
                    }),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<AyahModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off_rounded,
                                size: 40.sp,
                                color: brightness == Brightness.dark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                            SizedBox(height: 10.h),
                            Text('تعذر تحميل نص السورة', style: AppTypography.body(brightness)),
                            SizedBox(height: 10.h),
                            TextButton(onPressed: _retry, child: const Text('حاول تاني')),
                          ],
                        ),
                      );
                    }

                    final ayahs = snapshot.data ?? [];
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: AppColors.glassFill(brightness),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.glassBorder(brightness)),
                        ),
                        child: Column(
                          children: [
                            if (showBasmala) ...[
                              Text(
                                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.amiriQuran(
                                  fontSize: 22.sp * _fontScale,
                                  color: AppColors.accentGoldSoft,
                                ),
                              ),
                              SizedBox(height: 18.h),
                              Divider(color: AppColors.glassBorder(brightness)),
                              SizedBox(height: 18.h),
                            ],
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: RichText(
                                textAlign: TextAlign.justify,
                                text: TextSpan(
                                  children: [
                                    for (final ayah in ayahs) ...[
                                      TextSpan(
                                        text: '${ayah.text} ',
                                        style: GoogleFonts.amiriQuran(
                                          fontSize: 21.sp * _fontScale,
                                          height: 2.0,
                                          color: brightness == Brightness.dark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                        ),
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: _ayahBadge(brightness, ayah.numberInSurah),
                                      ),
                                      const TextSpan(text: '  '),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _fontSizeButton(Brightness brightness, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill(brightness),
          border: Border.all(color: AppColors.glassBorder(brightness)),
        ),
        child: Icon(icon, size: 16.sp, color: AppColors.accentGoldSoft),
      ),
    );
  }

  Widget _ayahBadge(Brightness brightness, int number) {
    return GestureDetector(
      onTap: () => _showAyahActions(number),
      child: ValueListenableBuilder<Set<String>>(
        valueListenable: AyahFavoritesService.instance.favorites,
        builder: (context, favs, _) {
          final isFav = AyahFavoritesService.instance.isFavorite(widget.surahNumber, number);
          return Container(
            width: 26.w,
            height: 26.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: AppColors.goldGradient),
              border: isFav ? Border.all(color: AppColors.error, width: 2) : null,
            ),
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          );
        },
      ),
    );
  }

  void _showAyahActions(int ayahNumber) {
    final brightness = Theme.of(context).brightness;
    final isFav = AyahFavoritesService.instance.isFavorite(widget.surahNumber, ayahNumber);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFav ? AppColors.error : AppColors.accentGoldSoft,
                ),
                title: Text(isFav ? 'إزالة من المفضلة' : 'إضافة للمفضلة'),
                onTap: () {
                  AyahFavoritesService.instance.toggle(widget.surahNumber, ayahNumber);
                  Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.ios_share_rounded, color: AppColors.accentGoldSoft),
                title: const Text('مشاركة الآية'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  SharePlus.instance.share(ShareParams(
                    text: 'سورة ${widget.surahName} - الآية $ayahNumber\nمن تطبيق جَنَّتَكَ 🌙',
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
