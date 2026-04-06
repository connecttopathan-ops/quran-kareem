import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/collection.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../providers/home_provider.dart';

class CollectionsRow extends ConsumerWidget {
  const CollectionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsAsync = ref.watch(collectionsProvider);

    return SizedBox(
      height: 100,
      child: collectionsAsync.when(
        loading: () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, __) => const CollectionChipSkeleton(),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (collections) => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: collections.length,
          separatorBuilder: (_, __) => const SizedBox(width: 16),
          itemBuilder: (_, i) => _CollectionChip(collection: collections[i]),
        ),
      ),
    );
  }
}

class _CollectionChip extends StatelessWidget {
  final Collection collection;

  const _CollectionChip({required this.collection});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/collection/${collection.handle}'),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: ClipOval(
                child: collection.image != null
                    ? CachedNetworkImage(
                        imageUrl: collection.image!.url,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.accent),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.accent),
                      )
                    : Container(
                        color: AppColors.accent,
                        child: const Icon(Icons.category,
                            color: AppColors.primary),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              collection.title,
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
