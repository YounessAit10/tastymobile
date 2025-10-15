import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../providers/cart_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final SubRestaurant subRestaurant;

  const CartScreen({
    Key? key,
    required this.cartItems,
    required this.subRestaurant,
  }) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  void _increaseQuantity(int index) {
    setState(() {
      widget.cartItems[index].quantity++;
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if (widget.cartItems[index].quantity > 1) {
        widget.cartItems[index].quantity--;
      }
    });
  }

  double _calculateTotal() {
    return widget.cartItems.fold(
        0, (sum, item) => sum + item.product.prix * item.quantity);
  }

  Future<void> _sendWhatsAppMessage(String phone, String message) async {
    final formattedPhone = phone.replaceAll(' ', '').replaceAll('+', '');
    final url =
        Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d’ouvrir WhatsApp.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(title: const Text("Mon Panier")),
      body: widget.cartItems.isEmpty
          ? const Center(child: Text("Votre panier est vide 🛒"))
          : ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                final product = item.product;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: Image.network(
                      product.image,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.fastfood, size: 40),
                    ),
                    title: Text(product.nom),
                    subtitle: Text("${product.prix.toStringAsFixed(2)} DH"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _decreaseQuantity(index),
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _increaseQuantity(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total: ${total.toStringAsFixed(2)} DH",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                String message = "🛒 *Nouvelle commande :*\n\n";
                for (var item in widget.cartItems) {
                  message +=
                      "• ${item.product.nom} x${item.quantity} = ${(item.product.prix * item.quantity).toStringAsFixed(2)} DH\n";
                }
                message += "\nTotal : ${total.toStringAsFixed(2)} DH";

                await _sendWhatsAppMessage(widget.subRestaurant.telephone, message);
              },
              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
              label: const Text("Commander sur WhatsApp"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}