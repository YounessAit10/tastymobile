import '../models/restaurant.dart';

class CartItem {
  final Product product;
  int quantity;
  List<Extra> extras;
  Map<String, List<String>> options;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.extras = const [],
    this.options = const {},
  });

  double get totalExtras => extras.fold(0.0, (sum, e) => sum + e.prix);

  double get total =>
      (product.prix + totalExtras) * quantity; // tu peux ajouter le prix des options ici si besoin

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'extras': extras.map((e) => e.toJson()).toList(),
      'options': options,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'] ?? 1,
      extras: (json['extras'] as List<dynamic>?)
              ?.map((e) => Extra.fromJson(e))
              .toList() ??
          [],
      options: (json['options'] as Map<String, dynamic>?)
              ?.map((key, value) =>
                  MapEntry(key, List<String>.from(value as List)))
          ?? {},
    );
  }
}
