import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../utils/distance_utils.dart';
import 'menu_screen.dart';

class SubRestaurantsScreen extends StatelessWidget {
  final Restaurant restaurant;
  final double userLat;
  final double userLng;

  const SubRestaurantsScreen({
    Key? key,
    required this.restaurant,
    required this.userLat,
    required this.userLng,
  }) : super(key: key);

  Map<String, double>? _parseCoords(String? url) {
    if (url == null || !url.contains("query=")) return null;
    try {
      final query = url.split("query=").last;
      final parts = query.split(",");
      if (parts.length < 2) return null;
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat == null || lng == null) return null;
      return {"lat": lat, "lng": lng};
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subsWithDistance = <Map<String, dynamic>>[];

    for (var sub in restaurant.sousRestaurants) {
      final coords = _parseCoords(sub.localisation);
      if (coords == null) continue;
      final distance = calculDistance(userLat, userLng, coords["lat"]!, coords["lng"]!);
      subsWithDistance.add({
        "sub": sub,
        "distance": distance,
      });
    }

    final nearbySubs = subsWithDistance
        .where((e) => (e["distance"] as double) <= MAX_DISTANCE_KM)
        .toList();

    
    nearbySubs.sort((a, b) => (a["distance"] as double).compareTo(b["distance"] as double));

    return Scaffold(
      appBar: AppBar(title: Text("Sous-restaurants — ${restaurant.nom}")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: nearbySubs.isEmpty
            ? Center(
                child: Text(
                  "Aucun sous-restaurant dans un rayon de ${MAX_DISTANCE_KM.toInt()} km.",
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                itemCount: nearbySubs.length,
                itemBuilder: (context, index) {
                  final sub = nearbySubs[index]["sub"] as SubRestaurant;
                  final distance = nearbySubs[index]["distance"] as double;

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          sub.image,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) =>
                              const Icon(Icons.storefront, size: 48),
                        ),
                      ),
                      title: Text(sub.ville,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        "${sub.adresse}\n📍 À ${distance.toStringAsFixed(1)} km de vous",
                        style: const TextStyle(height: 1.4),
                      ),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MenuScreen(
                              restaurant: restaurant,
                              subRestaurant: sub,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}