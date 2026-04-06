class ProductImage {
  final String url;
  final String? altText;

  const ProductImage({required this.url, this.altText});

  factory ProductImage.fromJson(Map<String, dynamic> json) => ProductImage(
    url: json['url'] as String,
    altText: json['altText'] as String?,
  );
}

class SelectedOption {
  final String name;
  final String value;

  const SelectedOption({required this.name, required this.value});

  factory SelectedOption.fromJson(Map<String, dynamic> json) => SelectedOption(
    name: json['name'] as String,
    value: json['value'] as String,
  );
}

class Money {
  final double amount;
  final String currencyCode;

  const Money({required this.amount, required this.currencyCode});

  factory Money.fromJson(Map<String, dynamic> json) => Money(
    amount: double.parse(json['amount'] as String),
    currencyCode: json['currencyCode'] as String,
  );
}

class ProductVariant {
  final String id;
  final String title;
  final bool availableForSale;
  final int? quantityAvailable;
  final Money price;
  final Money? compareAtPrice;
  final List<SelectedOption> selectedOptions;

  const ProductVariant({
    required this.id,
    required this.title,
    required this.availableForSale,
    this.quantityAvailable,
    required this.price,
    this.compareAtPrice,
    required this.selectedOptions,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    id: json['id'] as String,
    title: json['title'] as String,
    availableForSale: json['availableForSale'] as bool,
    quantityAvailable: json['quantityAvailable'] as int?,
    price: Money.fromJson(json['price'] as Map<String, dynamic>),
    compareAtPrice: json['compareAtPrice'] != null
        ? Money.fromJson(json['compareAtPrice'] as Map<String, dynamic>)
        : null,
    selectedOptions: (json['selectedOptions'] as List)
        .map((e) => SelectedOption.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  String? optionValue(String optionName) {
    for (final opt in selectedOptions) {
      if (opt.name.toLowerCase() == optionName.toLowerCase()) return opt.value;
    }
    return null;
  }
}

class ProductOption {
  final String id;
  final String name;
  final List<String> values;

  const ProductOption({
    required this.id,
    required this.name,
    required this.values,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) => ProductOption(
    id: json['id'] as String,
    name: json['name'] as String,
    values: List<String>.from(json['values'] as List),
  );
}

class Product {
  final String id;
  final String handle;
  final String title;
  final String? description;
  final String? descriptionHtml;
  final String? vendor;
  final String? productType;
  final List<String> tags;
  final Money minPrice;
  final Money? compareAtMinPrice;
  final List<ProductImage> images;
  final List<ProductVariant> variants;
  final List<ProductOption> options;

  const Product({
    required this.id,
    required this.handle,
    required this.title,
    this.description,
    this.descriptionHtml,
    this.vendor,
    this.productType,
    this.tags = const [],
    required this.minPrice,
    this.compareAtMinPrice,
    required this.images,
    required this.variants,
    this.options = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final priceRange = json['priceRange'] as Map<String, dynamic>;
    final compareAtRange = json['compareAtPriceRange'] as Map<String, dynamic>?;

    List<ProductImage> parseImages(Map<String, dynamic>? imagesNode) {
      if (imagesNode == null) return [];
      final edges = imagesNode['edges'] as List? ?? [];
      return edges
          .map((e) => ProductImage.fromJson((e as Map)['node'] as Map<String, dynamic>))
          .toList();
    }

    List<ProductVariant> parseVariants(Map<String, dynamic>? variantsNode) {
      if (variantsNode == null) return [];
      final edges = variantsNode['edges'] as List? ?? [];
      return edges
          .map((e) => ProductVariant.fromJson((e as Map)['node'] as Map<String, dynamic>))
          .toList();
    }

    List<ProductOption> parseOptions(List? opts) {
      if (opts == null) return [];
      return opts
          .map((e) => ProductOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Product(
      id: json['id'] as String,
      handle: json['handle'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      descriptionHtml: json['descriptionHtml'] as String?,
      vendor: json['vendor'] as String?,
      productType: json['productType'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
      minPrice: Money.fromJson(
        priceRange['minVariantPrice'] as Map<String, dynamic>,
      ),
      compareAtMinPrice: compareAtRange != null &&
              (compareAtRange['minVariantPrice'] as Map)['amount'] != '0.0'
          ? Money.fromJson(
              compareAtRange['minVariantPrice'] as Map<String, dynamic>,
            )
          : null,
      images: parseImages(json['images'] as Map<String, dynamic>?),
      variants: parseVariants(json['variants'] as Map<String, dynamic>?),
      options: parseOptions(json['options'] as List?),
    );
  }

  String? get firstImageUrl => images.isNotEmpty ? images.first.url : null;

  bool get isOnSale =>
      compareAtMinPrice != null &&
      compareAtMinPrice!.amount > minPrice.amount;

  int get discountPercent {
    if (!isOnSale) return 0;
    return ((compareAtMinPrice!.amount - minPrice.amount) /
            compareAtMinPrice!.amount *
            100)
        .round();
  }

  List<String> get sizeOptions {
    final sizeOpt = options.where(
      (o) => o.name.toLowerCase() == 'size',
    );
    return sizeOpt.isNotEmpty ? sizeOpt.first.values : [];
  }

  List<String> get colorOptions {
    final colorOpt = options.where(
      (o) => o.name.toLowerCase() == 'color' ||
             o.name.toLowerCase() == 'colour',
    );
    return colorOpt.isNotEmpty ? colorOpt.first.values : [];
  }
}
