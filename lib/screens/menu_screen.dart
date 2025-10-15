import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MenuScreen extends StatelessWidget {
  final Restaurant restaurant;
  final SubRestaurant subRestaurant;

  const MenuScreen({
    Key? key,
    required this.restaurant,
    required this.subRestaurant,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final products = restaurant.products;
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Menu — ${subRestaurant.ville}'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(
                        cartItems: cart.items,
                        subRestaurant: subRestaurant,
                      ),
                    ),
                  );
                },
              ),
              if (cart.items.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.white,
                    child: Text(
                      '${cart.items.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: products.isEmpty
          ? const Center(child: Text("Aucun produit disponible"))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fastfood, size: 40),
                      ),
                    ),
                    title: Text(product.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(product.informations),
                    trailing: Text(
                      "${product.prix.toStringAsFixed(2)} DH",
                      style: const TextStyle(color: Colors.green),
                    ),
                    onTap: () {
                      cart.addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${product.nom} ajouté au panier 🛒")),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}