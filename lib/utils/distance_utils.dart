import 'dart:math';
import '../models/restaurant.dart';

const double MAX_DISTANCE_KM = 15.0;

/// 🔹 Calcule la distance entre deux points (latitude/longitude)
double calculDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371; // rayon de la Terre en km
  final dLat = (lat2 - lat1) * (pi / 180);
  final dLon = (lon2 - lon1) * (pi / 180);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * (pi / 180)) *
          cos(lat2 * (pi / 180)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

/// 🔹 Extrait les coordonnées d’un lien Google Maps
Map<String, double>? convertUrlToCordinate(String? url) {
  if (url == null || !url.contains("query=")) return null;
  final query = url.split("query=").last;
  final parts = query.split(",");
  if (parts.length != 2) return null;
  return {
    "lat": double.tryParse(parts[0].trim()) ?? 0.0,
    "lng": double.tryParse(parts[1].trim()) ?? 0.0,
  };
}

/// 🔹 Retourne uniquement les restaurants dont AU MOINS un sous-restaurant est à moins de 15 km
List<Restaurant> calculNearbyRestaurants(
    Map<String, dynamic> user, List<Restaurant> restaurants) {
  final userLat = double.parse(user["lat"]);
  final userLng = double.parse(user["lng"]);

  final nearbyRestaurants = <Restaurant>[];

  for (var restaurant in restaurants) {
    bool isNearby = false;

    for (var sub in restaurant.sousRestaurants) {
      final coords = convertUrlToCordinate(sub.localisation);
      if (coords != null) {
        final distance = calculDistance(
          userLat,
          userLng,
          coords["lat"]!,
          coords["lng"]!,
        );

        // 🟢 On ajoute la distance au sous-restaurant
        sub.distance = distance;

        if (distance <= MAX_DISTANCE_KM) {
          isNearby = true;
        }
      }
    }

    if (isNearby) {
      nearbyRestaurants.add(restaurant);
    }
  }

  // Trie les restaurants par distance du sous-restaurant le plus proche
  nearbyRestaurants.sort((a, b) {
    final aMin = a.sousRestaurants.map((s) => s.distance ?? double.infinity).reduce(min);
    final bMin = b.sousRestaurants.map((s) => s.distance ?? double.infinity).reduce(min);
    return aMin.compareTo(bMin);
  });

  return nearbyRestaurants;
}