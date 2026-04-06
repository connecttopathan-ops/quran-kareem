import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/products_provider.dart';
import 'widgets/product_card.dart';
import 'widgets/filter_bottom_sheet.dart';
import '../../../shared/widgets/skeleton_loader.dart';

class CollectionScreen extends ConsumerWidget {
  final String handle;

  const CollectionScreen({super.key, required this.handle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(collectionProductsProvider(handle));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          handle.replaceAll('-', ' ').toUpperCase(),
          style: AppTextStyles.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final current = productsAsync.valueOrNull?.filter ??
                  const FilterOptions();
              final result = await showFilterSheet(context, current);
              if (result != null) {
                ref
                    .read(collectionProductsProvider(handle).notifier)
                    .applyFilter(result);
              }
            },
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ProductGridSkeleton(),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.saleRed, size: 40),
              const SizedBox(height: 12),
              Text('Failed to load products',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(collectionProductsProvider(handle)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) {
          if (state.products.isEmpty) {
            return const Center(child: Text('No products found.'));
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async =>
                ref.invalidate(collectionProductsProvider(handle)),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
              ),
              itemCount:
                  state.products.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.products.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref
                        .read(collectionProductsProvider(handle).notifier)
                        .loadMore();
                  });
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return ProductCard(product: state.products[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
