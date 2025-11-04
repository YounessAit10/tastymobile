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

  bool _isRestaurantOpen(Restaurant restaurant) {
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

    if (restaurant.horaires.joursOff.contains(jourActuel)) return false;

    final openParts = restaurant.horaires.ouverture.split(":");
    final closeParts = restaurant.horaires.fermeture.split(":");

    if (openParts.length < 2 || closeParts.length < 2) return true;

    final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
    final nowMinutes = now.hour * 60 + now.minute;

    if (openMinutes > closeMinutes) {
      return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
    }

    return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final products = restaurant.products
      .where((p) => p.isActive) // ✅ Filtre ici
      .toList();
    products.sort((a, b) {
      if (a.isBestSeller == b.isBestSeller) return 0;
      return b.isBestSeller ? 1 : -1;
    });

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
                        restaurant: restaurant,
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
                final isOpen = _isRestaurantOpen(restaurant);

                return Card(
                  color: product.isBestSeller ? Colors.yellow.shade50 : Colors.white,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                 //  enabled: product.isAvailable, // ✅ désactive le tap si indisponible

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
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.nom,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),

                          // 🔸 Badge "Best Seller"
                          if (product.isBestSeller)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "⭐ Meilleure vente",
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),

                          // 🔸 Badge de réduction
                          if (product.reduction.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "-${product.reduction}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    subtitle: Text(product.informations),
                        trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                            // si reduction existe, affiche le prix réduit sinon prix normal
                            product.reduction.isNotEmpty
                                ? "${(product.prix * (1 - double.parse(product.reduction.replaceAll('%', '')) / 100)).toStringAsFixed(2)} DH"
                                : "${product.prix.toStringAsFixed(2)} DH",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),


                    onTap: () {
                      if (!isOpen) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("🚫 Ce restaurant est fermé pour le moment."),
                          ),
                        );
                        return;
                      }
                      // if (!product.isAvailable) {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     const SnackBar(content: Text("❌ Ce produit n’est pas disponible pour le moment.")),
                      //   );
                      //   return;
                      // }

                      // ✅ Fiche produit avec extras et options
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) {
                          final selectedExtras = <Extra>[];
                          final selectedOptions = <String, List<String>>{};

                          return StatefulBuilder(
                            builder: (context, setState) {
                              // 🔹 Vérifie si toutes les options requises sont choisies
                              bool allRequiredSelected = true;
                              if (product.optionsRequises != null &&
                                  product.optionsRequises!.isNotEmpty) {
                                for (var option in product.optionsRequises!) {
                                  final selected = selectedOptions[option.titre] ?? [];
                                  if (selected.length < option.nombre) {
                                    allRequiredSelected = false;
                                    break;
                                  }
                                }
                              }

                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(product.nom,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 10),
                                      Text(product.informations),
                                      const SizedBox(height: 20),

                                      if (product.ingredients.isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Ingrédients :",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          Text(product.ingredients.join(", ")),
                                          const SizedBox(height: 10),
                                        ],
                                      ),

                                      // 🔹 Options requises
                                      if (product.optionsRequises != null &&
                                          product.optionsRequises!.isNotEmpty)
                                        ...product.optionsRequises!.map((opt) {
                                          final selected =
                                              selectedOptions[opt.titre] ?? [];

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${opt.titre} (choisir ${opt.nombre})",
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              ...opt.element.map((el) {
                                                return CheckboxListTile(
                                                  title: Text(el),
                                                  value: selected.contains(el),
                                                  onChanged: (val) {
                                                    setState(() {
                                                      final current =
                                                          selectedOptions[opt.titre] ?? [];
                                                      if (val == true) {
                                                        if (current.length <
                                                            opt.nombre) {
                                                          current.add(el);
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(SnackBar(
                                                                  content: Text(
                                                                      "Tu peux choisir maximum ${opt.nombre} option(s) pour ${opt.titre}.")));
                                                        }
                                                      } else {
                                                        current.remove(el);
                                                      }
                                                      selectedOptions[opt.titre] =
                                                          current;
                                                    });
                                                  },
                                                );
                                              }).toList(),
                                            ],
                                          );
                                        }),

                                      const SizedBox(height: 20),

                                      // 🔹 Extras (facultatifs)
                                      if (product.extras.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text("Extras disponibles :",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                            ...product.extras.map((extra) =>
                                                CheckboxListTile(
                                                  title: Text(
                                                      "${extra.nom} (+${extra.prix} DH)"),
                                                  value: selectedExtras
                                                      .contains(extra),
                                                  onChanged: (val) {
                                                    setState(() {
                                                      if (val == true) {
                                                        selectedExtras.add(extra);
                                                      } else {
                                                        selectedExtras
                                                            .remove(extra);
                                                      }
                                                    });
                                                  },
                                                )),
                                          ],
                                        ),

                                      const SizedBox(height: 20),

                                      // 🔹 Bouton "Ajouter au panier"
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.add_shopping_cart),
                                        label: Text(allRequiredSelected
                                            ? "Ajouter au panier"
                                            : "Veuillez choisir toutes les options requises"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: allRequiredSelected
                                              ? Colors.green
                                              : Colors.grey,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 16),
                                        ),
                                        onPressed: allRequiredSelected
                                            ? () {
                                                final totalExtras =
                                                    selectedExtras.fold(
                                                        0.0,
                                                        (sum, e) =>
                                                            sum + e.prix);
                                                final total = product.prix +
                                                    totalExtras;

                                                final cart =
                                                    Provider.of<CartProvider>(
                                                        context,
                                                        listen: false);
                                                cart.addToCart(product, extras: selectedExtras, options: selectedOptions ?? {});

                                                Navigator.pop(context);

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        "${product.nom} ajouté au panier (${total.toStringAsFixed(2)} DH)"),
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
                    },
                  ),
                );
              },
            ),
    );
  }
}
