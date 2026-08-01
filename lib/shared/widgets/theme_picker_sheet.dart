import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_controller.dart';

/// شيت اختيار الثيم - بيعرض الأربع ثيمات كـ"كروت" بمعاينة ألوان حقيقية،
/// وتختار منها بضغطة واحدة وتتطبق فورًا على كل الشاشات.
class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ThemePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ValueListenableBuilder<AppThemeVariant>(
      valueListenable: ThemeController.instance,
      builder: (context, activeVariant, _) {
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 28.h),
          decoration: BoxDecoration(
            color: brightness == Brightness.dark
                ? AppColors.darkSurfaceElevated
                : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder(brightness),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: 16.h),
              Text('اختار ثيم التطبيق', style: AppTypography.title(brightness)),
              SizedBox(height: 4.h),
              Text('كل ثيم بيتطبّق فورًا على كل الشاشات', style: AppTypography.caption(brightness)),
              SizedBox(height: 18.h),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                childAspectRatio: 1.15,
                children: AppThemeVariant.values.map((variant) {
                  final palette = AppPalettes.of(variant);
                  final selected = variant == activeVariant;
                  return _ThemeCard(
                    palette: palette,
                    selected: selected,
                    onTap: () => ThemeController.instance.setVariant(variant),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({required this.palette, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: palette.heroGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? palette.accentGold : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: palette.accentGold.withOpacity(0.35), blurRadius: 14)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: palette.goldGradient),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: palette.primary),
                ),
                const Spacer(),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: palette.accentGold, size: 18.sp),
              ],
            ),
            const Spacer(),
            Text(
              palette.label,
              style: TextStyle(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              palette.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.textSecondary, fontSize: 10.5.sp),
            ),
          ],
        ),
      ),
    );
  }
}
