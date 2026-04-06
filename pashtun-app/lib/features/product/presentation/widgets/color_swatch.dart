import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ColorSwatch extends StatelessWidget {
  final List<String> colors;
  final String? selectedColor;
  final ValueChanged<String> onSelect;

  const ColorSwatch({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onSelect,
  });

  // Attempt to map color name to a Flutter Color
  static Color? _colorFromName(String name) {
    const map = {
      'red': Color(0xFFD94F3D),
      'blue': Color(0xFF4A90D9),
      'green': Color(0xFF4CAF50),
      'black': Color(0xFF1A1A1A),
      'white': Color(0xFFFFFFFF),
      'gold': Color(0xFFC8860A),
      'pink': Color(0xFFE91E8C),
      'purple': Color(0xFF9C27B0),
      'orange': Color(0xFFFF9800),
      'yellow': Color(0xFFFFEB3B),
      'grey': Color(0xFF9E9E9E),
      'gray': Color(0xFF9E9E9E),
      'beige': Color(0xFFF5ECD7),
      'cream': Color(0xFFFFF8E1),
      'maroon': Color(0xFF800000),
      'navy': Color(0xFF001F5B),
      'teal': Color(0xFF009688),
    };
    return map[name.toLowerCase().trim()];
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((color) {
        final isSelected = color == selectedColor;
        final swatchColor = _colorFromName(color);

        return GestureDetector(
          onTap: () => onSelect(color),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: swatchColor ?? AppColors.accent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.divider,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(77),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: swatchColor == null
                    ? Center(
                        child: Text(
                          color.substring(0, 1).toUpperCase(),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              Text(color, style: AppTextStyles.labelSmall),
            ],
          ),
        );
      }).toList(),
    );
  }
}
