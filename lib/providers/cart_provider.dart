import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/restaurant.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  void addToCart(
    Product product, {
    List<Extra> extras = const [],
    Map<String, List<String>> options = const {},
  }) {
    // Vérifie si le produit avec les mêmes extras/options existe déjà
    final existingIndex = _items.indexWhere((item) =>
        item.product.id == product.id &&
        _compareExtras(item.extras, extras) &&
        _compareOptions(item.options, options));

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(
        product: product,
        extras: extras,
        options: options,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void increaseQuantity(int index) {
    _items[index].quantity++;
    notifyListeners();
  }

  void decreaseQuantity(int index) {
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  double get total {
    double total = 0;
    for (var item in _items) {
      total += item.total;
    }
    return total;
  }

  bool _compareExtras(List<Extra> a, List<Extra> b) {
    if (a.length != b.length) return false;
    for (final extra in a) {
      if (!b.any((e) => e.nom == extra.nom && e.prix == extra.prix)) {
        return false;
      }
    }
    return true;
  }

  bool _compareOptions(Map<String, List<String>> a, Map<String, List<String>> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      final aValues = a[key] ?? [];
      final bValues = b[key] ?? [];
      if (aValues.length != bValues.length) return false;
      for (final v in aValues) {
        if (!bValues.contains(v)) return false;
      }
    }
    return true;
  }
}
