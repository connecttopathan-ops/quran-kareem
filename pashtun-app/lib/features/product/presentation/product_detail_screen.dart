import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/whatsapp_button.dart';
import '../providers/product_provider.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../../features/wishlist/providers/wishlist_provider.dart';
import 'widgets/product_gallery.dart';
import 'widgets/size_selector.dart';
import 'widgets/color_swatch.dart';
import 'widgets/price_tag.dart';
import 'widgets/complete_the_look.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String handle;

  const ProductDetailScreen({super.key, required this.handle});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends ConsumerState<ProductDetailScreen> {
  bool _descriptionExpanded = false;
  String? _selectedSize;
  String? _selectedColor;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.handle));
    final wishlist = ref.watch(wishlistProvider);

    return productAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Failed to load product: $e')),
      ),
      data: (product) {
        if (product == null) {
          return const Scaffold(
            body: Center(child: Text('Product not found')),
          );
        }

        final isWishlisted = wishlist.contains(product.id);

        // Determine selected variant
        final variant = product.variants.firstWhere(
          (v) {
            if (_selectedSize != null &&
                v.optionValue('Size') != _selectedSize) return false;
            if (_selectedColor != null &&
                v.optionValue('Color') != _selectedColor) return false;
            return true;
          },
          orElse: () => product.variants.first,
        );

        final whatsappMsg =
            'Hi, I\'m interested in: ${product.title} — '
            'https://pashtuncollections.myshopify.com/products/${widget.handle}';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            actions: [
              IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted
                      ? AppColors.saleRed
                      : AppColors.textSecondary,
                ),
                onPressed: () => ref
                    .read(wishlistProvider.notifier)
                    .toggle(product.id),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text: '${product.title} — Shop at Pashtun Collections\n'
                        'https://pashtuncollections.myshopify.com/products/${widget.handle}',
                  ),
                ),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // Gallery
              SliverToBoxAdapter(
                child: ProductGallery(images: product.images),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title
                    Text(product.title, style: AppTextStyles.displayMedium)
                        .animate()
                        .fadeIn(duration: 400.ms),

                    if (product.vendor != null) ...[
                      const SizedBox(height: 4),
                      Text(product.vendor!,
                          style: AppTextStyles.bodySmall),
                    ],

                    const SizedBox(height: 12),

                    // Price
                    PriceTag(
                      price: variant.price,
                      compareAtPrice: variant.compareAtPrice,
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                    const SizedBox(height: 20),

                    // Sizes
                    if (product.sizeOptions.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Size', style: AppTextStyles.titleLarge),
                          TextButton(
                            onPressed: () {/* TODO: size guide */},
                            child: const Text('Size Guide'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizeSelector(
                        sizes: product.sizeOptions,
                        selectedSize: _selectedSize,
                        onSelect: (s) =>
                            setState(() => _selectedSize = s),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Colors
                    if (product.colorOptions.isNotEmpty) ...[
                      Text('Color', style: AppTextStyles.titleLarge),
                      const SizedBox(height: 8),
                      ColorSwatch(
                        colors: product.colorOptions,
                        selectedColor: _selectedColor,
                        onSelect: (c) =>
                            setState(() => _selectedColor = c),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Description
                    GestureDetector(
                      onTap: () => setState(
                        () => _descriptionExpanded = !_descriptionExpanded,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Description',
                              style: AppTextStyles.titleLarge),
                          Icon(
                            _descriptionExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                          ),
                        ],
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: _descriptionExpanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          product.description ?? '',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 24),

                    // Complete the look
                    CompleteTheLook(handle: widget.handle),

                    const SizedBox(height: 100), // Space for sticky bar
                  ]),
                ),
              ),
            ],
          ),

          // Sticky bottom bar
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: variant.availableForSale
                          ? () {
                              ref
                                  .read(cartProvider.notifier)
                                  .addItem(variant.id, 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Added to cart!')),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: variant.availableForSale
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                      child: Text(
                        variant.availableForSale
                            ? 'Add to Cart'
                            : 'Out of Stock',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          floatingActionButton: WhatsappButton(message: whatsappMsg),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.startFloat,
        );
      },
    );
  }
}
