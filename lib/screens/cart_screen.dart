import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../providers/cart_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cart_item.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final SubRestaurant subRestaurant;
  final Restaurant restaurant;

  const CartScreen({
    Key? key,
    required this.cartItems,
    required this.subRestaurant,
    required this.restaurant,
  }) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  void _openEditItemModal(BuildContext context, CartItem item, int index) {
  final selectedExtras = List<Extra>.from(item.extras);
  final selectedOptions = Map<String, List<String>>.from(item.options ?? {});

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool allRequiredSelected = true;
          if (item.product.optionsRequises != null &&
              item.product.optionsRequises!.isNotEmpty) {
            for (var option in item.product.optionsRequises!) {
              final selected = selectedOptions[option.titre] ?? [];
              if (selected.length < option.nombre) {
                allRequiredSelected = false;
                break;
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Modifier ${item.product.nom}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(item.product.informations),
                  const SizedBox(height: 20),

                  // 🔹 Options requises
                  if (item.product.optionsRequises != null &&
                      item.product.optionsRequises!.isNotEmpty)
                    ...item.product.optionsRequises!.map((opt) {
                      final selected = selectedOptions[opt.titre] ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${opt.titre} (choisir ${opt.nombre})",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...opt.element.map((el) {
                            return CheckboxListTile(
                              title: Text(el),
                              value: selected.contains(el),
                              onChanged: (val) {
                                setState(() {
                                  final current = selectedOptions[opt.titre] ?? [];
                                  if (val == true) {
                                    if (current.length < opt.nombre) {
                                      current.add(el);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(
                                          "Tu peux choisir maximum ${opt.nombre} option(s) pour ${opt.titre}.",
                                        ),
                                      ));
                                    }
                                  } else {
                                    current.remove(el);
                                  }
                                  selectedOptions[opt.titre] = current;
                                });
                              },
                            );
                          }).toList(),
                        ],
                      );
                    }),

                  const SizedBox(height: 15),

                  // 🔹 Extras
                  if (item.product.extras.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Extras disponibles :",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        ...item.product.extras.map((extra) => CheckboxListTile(
                              title:
                                  Text("${extra.nom} (+${extra.prix.toStringAsFixed(2)} DH)"),
                              value: selectedExtras.contains(extra),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedExtras.add(extra);
                                  } else {
                                    selectedExtras.remove(extra);
                                  }
                                });
                              },
                            )),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // 🔹 Bouton de sauvegarde
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Enregistrer les modifications"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                    onPressed: allRequiredSelected
                        ? () {
                            setState(() {
                              item.extras = selectedExtras;
                              item.options = selectedOptions;
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Le produit a été mis à jour dans le panier ✅"),
                              ),
                            );
                          }
                        : null,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  /// 🔹 Vérifie si le restaurant est ouvert
  bool _isRestaurantOpen(Restaurant resto) {
    final now = DateTime.now();
    final jourActuel = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche'
    ][now.weekday - 1];

    if (resto.horaires.joursOff.contains(jourActuel)) return false;

    final openParts = resto.horaires.ouverture.split(":");
    final closeParts = resto.horaires.fermeture.split(":");

    if (openParts.length < 2 || closeParts.length < 2) return true;

    final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
    final nowMinutes = now.hour * 60 + now.minute;

    if (openMinutes > closeMinutes) {
      return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
    }

    return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  }

  /// 🔹 Calcule le total avec extras (et plus tard, prix d’options si nécessaire)
double _calculateTotal() {
  double total = 0;
  for (var item in widget.cartItems) {
    // 🔹 Calcule le total des extras
    double extrasTotal = item.extras.fold(0.0, (sum, extra) => sum + extra.prix);

    // 🔹 Applique la réduction si elle existe
    double prixProduit = item.product.prix;
    if (item.product.reduction.isNotEmpty) {
      final reductionValue = double.tryParse(
        item.product.reduction.replaceAll('%', ''),
      );
      if (reductionValue != null) {
        prixProduit = prixProduit * (1 - reductionValue / 100);
      }
    }

    // 🔹 Ajoute au total (produit + extras) * quantité
    total += (prixProduit + extrasTotal) * item.quantity;
  }
  return total;
}


  /// 🔹 Envoi WhatsApp
  Future<void> _sendWhatsAppMessage(String phone, String message) async {
    final formattedPhone = phone.replaceAll(' ', '').replaceAll('+', '');
    final url = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d’ouvrir WhatsApp.';
    }
  }

  /// 🔹 Augmenter quantité
  void _increaseQuantity(int index) {
    setState(() {
      widget.cartItems[index].quantity++;
    });
  }

  /// 🔹 Diminuer quantité (supprime si = 0)
  void _decreaseQuantity(int index) {
    setState(() {
      if (widget.cartItems[index].quantity > 1) {
        widget.cartItems[index].quantity--;
      } else {
        widget.cartItems.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _isRestaurantOpen(widget.restaurant);
    final total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(title: const Text("🛒 Mon Panier")),
      body: widget.cartItems.isEmpty
          ? const Center(child: Text("Votre panier est vide 🛍️"))
          : Column(
              children: [
                if (!isOpen)
                  Container(
                    color: Colors.red.shade100,
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    child: const Text(
                      "🚫 Ce restaurant est actuellement fermé.\nLes commandes sont désactivées.",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      final product = item.product;
                      final extras = item.extras;
                      final options = item.options; // ✅ ajout support options

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: ListTile(
                          onTap: () {
                            _openEditItemModal(context, item, index); // 👈 ouvre la fenêtre d’édition
                          },
                          leading: Image.network(
                            product.image,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.fastfood, size: 40),
                          ),
                          title: Text(product.nom),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🔹 Prix avec ou sans réduction
                                if (product.reduction.isNotEmpty)
                                  Text(
                                    "${product.prix.toStringAsFixed(2)} DH",
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(
                                  product.reduction.isNotEmpty
                                      ? "${(product.prix * (1 - double.parse(product.reduction.replaceAll('%', '')) / 100)).toStringAsFixed(2)} DH"
                                      : "${product.prix.toStringAsFixed(2)} DH",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                // 🔹 Options choisies
                                if (item.options != null && item.options!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.options!.entries
                                          .map((e) => "${e.key} : ${e.value.join(', ')}")
                                          .join("\n"),
                                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                    ),
                                  ),

                                // 🔹 Extras ajoutés
                                if (item.extras.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      item.extras.map((e) => "+ ${e.nom} (${e.prix} DH)").join("\n"),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),


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
                ),
              ],
            ),
      bottomNavigationBar: widget.cartItems.isEmpty
          ? null
          : Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total: ${total.toStringAsFixed(2)} DH",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                 ElevatedButton.icon(
                  onPressed: () async {
                    String message = "🛒 *Nouvelle commande :*\n\n";

                    for (var item in widget.cartItems) {
                      final product = item.product;

                      // 🔹 Application de la réduction
                      double prixReduit = product.prix;
                      if (product.reduction.isNotEmpty) {
                        final pourcentage =
                            double.tryParse(product.reduction.replaceAll('%', '')) ?? 0;
                        prixReduit = product.prix * (1 - pourcentage / 100);
                      }

                      // 🔹 Calcul du total des extras
                      final totalExtras =
                          item.extras.fold(0.0, (sum, extra) => sum + extra.prix);

                      // 🔹 Prix total (produit réduit + extras)
                      final totalProduit = (prixReduit + totalExtras) * item.quantity;

                      message +=
                          "• ${product.nom} x${item.quantity} = ${totalProduit.toStringAsFixed(2)} DH\n";

                      // 🔹 Détail des options choisies
                      if (item.options != null && item.options!.isNotEmpty) {
                        message += item.options!.entries
                            .map((e) => "   ▫️ ${e.key}: ${e.value.join(', ')}")
                            .join("\n");
                        message += "\n";
                      }

                      // 🔹 Détail des extras
                      if (item.extras.isNotEmpty) {
                        message += item.extras
                            .map((e) => "   ➕ ${e.nom} (+${e.prix} DH)")
                            .join("\n");
                        message += "\n";
                      }

                      // 🔹 Affiche la réduction si elle existe
                      if (product.reduction.isNotEmpty) {
                        message += "   🔻 Réduction appliquée : ${product.reduction}\n";
                      }

                      message += "\n";
                    }

                    // 🔹 Calcul total global
                    final total = widget.cartItems.fold(0.0, (sum, item) {
                      double prix = item.product.prix;
                      if (item.product.reduction.isNotEmpty) {
                        final pourcentage =
                            double.tryParse(item.product.reduction.replaceAll('%', '')) ?? 0;
                        prix = item.product.prix * (1 - pourcentage / 100);
                      }
                      final extrasTotal =
                          item.extras.fold(0.0, (s, e) => s + e.prix);
                      return sum + (prix + extrasTotal) * item.quantity;
                    });

                    message += "💰 *Total : ${total.toStringAsFixed(2)} DH*\n";
                    message += "\n📍 *Restaurant :* ${widget.subRestaurant.ville}\n";
                    message += "📞 *Téléphone :* ${widget.subRestaurant.telephone}\n";

                    // 🔹 Envoi WhatsApp
                    final formattedPhone =
                        widget.subRestaurant.telephone.replaceAll(' ', '').replaceAll('+', '');
                    final url = Uri.parse(
                        'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');

                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Impossible d’ouvrir WhatsApp.")),
                      );
                    }
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
