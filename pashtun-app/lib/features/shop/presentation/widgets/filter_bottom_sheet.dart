import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';

class FilterOptions {
  final String? sortBy;
  final RangeValues? priceRange;
  final List<String> sizes;
  final bool onSaleOnly;

  const FilterOptions({
    this.sortBy,
    this.priceRange,
    this.sizes = const [],
    this.onSaleOnly = false,
  });

  FilterOptions copyWith({
    String? sortBy,
    RangeValues? priceRange,
    List<String>? sizes,
    bool? onSaleOnly,
  }) =>
      FilterOptions(
        sortBy: sortBy ?? this.sortBy,
        priceRange: priceRange ?? this.priceRange,
        sizes: sizes ?? this.sizes,
        onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      );
}

class FilterBottomSheet extends StatefulWidget {
  final FilterOptions current;

  const FilterBottomSheet({super.key, required this.current});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterOptions _options;

  static const _sortOptions = [
    ('PRICE_ASC',  'Price: Low to High'),
    ('PRICE_DESC', 'Price: High to Low'),
    ('TITLE_ASC',  'Name: A–Z'),
    ('CREATED_AT', 'Newest First'),
  ];

  static const _sizeOptions = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Custom'];

  @override
  void initState() {
    super.initState();
    _options = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter & Sort', style: AppTextStyles.headlineMedium),
                  TextButton(
                    onPressed: () => setState(
                      () => _options = const FilterOptions(),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Sort
                  Text('Sort By', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),
                  ..._sortOptions.map((opt) => RadioListTile<String>(
                    value: opt.$1,
                    groupValue: _options.sortBy,
                    onChanged: (v) => setState(
                      () => _options = _options.copyWith(sortBy: v),
                    ),
                    title: Text(opt.$2, style: AppTextStyles.bodyMedium),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  )),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Size
                  Text('Size', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sizeOptions.map((size) {
                      final selected = _options.sizes.contains(size);
                      return GestureDetector(
                        onTap: () {
                          final newSizes = List<String>.from(_options.sizes);
                          selected
                              ? newSizes.remove(size)
                              : newSizes.add(size);
                          setState(
                            () => _options = _options.copyWith(sizes: newSizes),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.surface,
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.divider,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            size,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // On Sale
                  SwitchListTile(
                    value: _options.onSaleOnly,
                    onChanged: (v) => setState(
                      () => _options = _options.copyWith(onSaleOnly: v),
                    ),
                    title: Text('Sale Items Only',
                        style: AppTextStyles.bodyMedium),
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: AppButton(
                label: 'Apply Filters',
                onPressed: () => Navigator.of(context).pop(_options),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<FilterOptions?> showFilterSheet(
  BuildContext context,
  FilterOptions current,
) {
  return showModalBottomSheet<FilterOptions>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FilterBottomSheet(current: current),
  );
}
