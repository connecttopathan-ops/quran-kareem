import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/collection.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../home/providers/home_provider.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Shop', style: AppTextStyles.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {/* TODO: search */},
          ),
        ],
      ),
      body: collectionsAsync.when(
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => const SkeletonBox(borderRadius: 12),
        ),
        error: (_, __) =>
            const Center(child: Text('Failed to load collections')),
        data: (collections) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
          ),
          itemCount: collections.length,
          itemBuilder: (_, i) => _CollectionTile(collection: collections[i]),
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final Collection collection;

  const _CollectionTile({required this.collection});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/collection/${collection.handle}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (collection.image != null)
              CachedNetworkImage(
                imageUrl: collection.image!.url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: AppColors.accent),
                errorWidget: (_, __, ___) =>
                    Container(color: AppColors.accent),
              )
            else
              Container(color: AppColors.accent),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(153),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                collection.title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
