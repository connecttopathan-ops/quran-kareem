import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../providers/home_provider.dart';
import '../../../shop/presentation/widgets/product_card.dart';

class NewArrivalsGrid extends ConsumerWidget {
  const NewArrivalsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arrivalsAsync = ref.watch(newArrivalsProvider);

    return arrivalsAsync.when(
      loading: () => const ProductGridSkeleton(count: 4),
      error: (e, _) => Center(
        child: Text('Failed to load products: $e'),
      ),
      data: (state) => RepaintBoundary(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
          ),
          itemCount: state.products.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.products.length) {
              // Load-more trigger
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(newArrivalsProvider.notifier).loadMore();
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
      ),
    );
  }
}
