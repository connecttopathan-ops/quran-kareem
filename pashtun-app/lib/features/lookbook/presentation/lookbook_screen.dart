import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LookbookEntry {
  final String title;
  final String? imageUrl;
  final List<LookbookPiece> pieces;
  final double totalPrice;
  final String currency;

  const LookbookEntry({
    required this.title,
    this.imageUrl,
    required this.pieces,
    required this.totalPrice,
    this.currency = 'INR',
  });
}

class LookbookPiece {
  final String name;
  final double price;
  final String productHandle;
  final double? hotspotX;
  final double? hotspotY;

  const LookbookPiece({
    required this.name,
    required this.price,
    required this.productHandle,
    this.hotspotX,
    this.hotspotY,
  });
}

// In production, fetch from Shopify metafields or a CMS
final lookbookProvider = Provider<List<LookbookEntry>>((ref) => const [
  LookbookEntry(
    title: 'Bridal Elegance',
    pieces: [
      LookbookPiece(
          name: 'Embroidered Lehenga',
          price: 24999,
          productHandle: 'embroidered-lehenga',
          hotspotX: 0.5,
          hotspotY: 0.6),
      LookbookPiece(
          name: 'Dupatta',
          price: 4999,
          productHandle: 'dupatta',
          hotspotX: 0.3,
          hotspotY: 0.3),
    ],
    totalPrice: 29998,
  ),
  LookbookEntry(
    title: 'Festive Glow',
    pieces: [
      LookbookPiece(
          name: 'Anarkali Suit',
          price: 14999,
          productHandle: 'anarkali-suit',
          hotspotX: 0.5,
          hotspotY: 0.5),
    ],
    totalPrice: 14999,
  ),
  LookbookEntry(
    title: 'Casual Luxe',
    pieces: [
      LookbookPiece(
          name: 'Printed Kurta Set',
          price: 7999,
          productHandle: 'printed-kurta-set',
          hotspotX: 0.5,
          hotspotY: 0.4),
    ],
    totalPrice: 7999,
  ),
]);

class LookbookScreen extends ConsumerStatefulWidget {
  const LookbookScreen({super.key});

  @override
  ConsumerState<LookbookScreen> createState() => _LookbookScreenState();
}

class _LookbookScreenState extends ConsumerState<LookbookScreen> {
  final _pageCtrl = PageController();
  int _current = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final looks = ref.watch(lookbookProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Lookbook',
          style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text: 'Check out the ${looks[_current].title} look on Pashtun Collections!\n'
                    'https://pashtuncollections.myshopify.com',
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: looks.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _LookPage(look: looks[i]),
          ),
          // Page indicators
          Positioned(
            top: 120,
            right: 16,
            child: Column(
              children: List.generate(looks.length, (i) {
                return Container(
                  width: 6,
                  height: i == _current ? 20 : 6,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: i == _current
                        ? AppColors.primary
                        : Colors.white.withAlpha(153),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _LookPage extends StatelessWidget {
  final LookbookEntry look;

  const _LookPage({required this.look});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        if (look.imageUrl != null)
          Image.network(look.imageUrl!, fit: BoxFit.cover)
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3D2B1F), AppColors.secondary],
              ),
            ),
          ),

        // Hotspot dots
        ...look.pieces
            .where((p) => p.hotspotX != null && p.hotspotY != null)
            .map(
              (p) => _HotspotDot(piece: p),
            ),

        // Bottom draggable sheet
        DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.15,
          maxChildSize: 0.6,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(look.title, style: AppTextStyles.headlineLarge),
                const SizedBox(height: 16),
                ...look.pieces.map(
                  (p) => _PieceTile(piece: p, currency: look.currency),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: AppTextStyles.titleLarge),
                    Text(
                      '₹${look.totalPrice.toStringAsFixed(0)}',
                      style: AppTextStyles.priceTag,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {/* TODO: add all pieces to cart */},
                  child: const Text('Shop This Look'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HotspotDot extends StatelessWidget {
  final LookbookPiece piece;

  const _HotspotDot({required this.piece});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width * piece.hotspotX!,
      top: MediaQuery.of(context).size.height * piece.hotspotY!,
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(piece.name),
            content:
                Text('₹${piece.price.toStringAsFixed(0)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(204),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}

class _PieceTile extends StatelessWidget {
  final LookbookPiece piece;
  final String currency;

  const _PieceTile({required this.piece, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(piece.name, style: AppTextStyles.bodyMedium),
          ),
          Text(
            '₹${piece.price.toStringAsFixed(0)}',
            style: AppTextStyles.labelLarge,
          ),
        ],
      ),
    );
  }
}
