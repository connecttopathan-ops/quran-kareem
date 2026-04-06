class CollectionHandles {
  CollectionHandles._();

  static const bridal       = 'bridal';
  static const casualWear   = 'casual-wear';
  static const festive      = 'festive';
  static const salwarKameez = 'salwar-kameez';
  static const luxuryZari   = 'luxury-zari';
  static const newArrivals  = 'new-arrivals';
  static const saleItems    = 'sale';

  static const List<CollectionMeta> featured = [
    CollectionMeta(
      handle: bridal,
      label: 'Bridal',
      emoji: '👰',
    ),
    CollectionMeta(
      handle: casualWear,
      label: 'Casual',
      emoji: '🌸',
    ),
    CollectionMeta(
      handle: festive,
      label: 'Festive',
      emoji: '✨',
    ),
    CollectionMeta(
      handle: salwarKameez,
      label: 'Salwar',
      emoji: '🪷',
    ),
    CollectionMeta(
      handle: luxuryZari,
      label: 'Luxury',
      emoji: '💎',
    ),
  ];
}

class CollectionMeta {
  final String handle;
  final String label;
  final String emoji;

  const CollectionMeta({
    required this.handle,
    required this.label,
    required this.emoji,
  });
}
