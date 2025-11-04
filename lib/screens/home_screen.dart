import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../models/restaurant.dart';
import '../utils/distance_utils.dart';
import 'sub_restaurant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Restaurant>> futureNearbyRestaurants;
  Position? userPosition;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _loadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _loadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _loadingLocation = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      userPosition = position;
      _loadingLocation = false;
      futureNearbyRestaurants = _loadNearbyRestaurants();
    });
  }

  Future<List<Restaurant>> _loadNearbyRestaurants() async {
    final allRestaurants = await ApiService.fetchRestaurants();
    final user = {
      "lat": userPosition!.latitude.toString(),
      "lng": userPosition!.longitude.toString(),
    };
    return calculNearbyRestaurants(user, allRestaurants);
  }

  /// ✅ Fonction pour savoir si un restaurant est ouvert
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

  // Si le jour actuel est dans la liste des jours off => fermé
  if (restaurant.horaires.joursOff.contains(jourActuel)) return false;

  final openParts = restaurant.horaires.ouverture.split(":");
  final closeParts = restaurant.horaires.fermeture.split(":");

  if (openParts.length < 2 || closeParts.length < 2) return true;

  final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
  final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
  final nowMinutes = now.hour * 60 + now.minute;

  // Si l’horaire traverse minuit (ex: 22:00 - 02:00)
  if (openMinutes > closeMinutes) {
    return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
  }

  // Cas normal
  return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
}

  @override
  Widget build(BuildContext context) {
    if (_loadingLocation) {
      return Scaffold(
        appBar: AppBar(title: const Text("Restaurants proches")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (userPosition == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Erreur localisation")),
        body: const Center(child: Text("Impossible d’obtenir votre position")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Restaurants proches")),
      body: FutureBuilder<List<Restaurant>>(
        future: futureNearbyRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun restaurant proche trouvé"));
          } else {
            final restaurants = snapshot.data!;
            return ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                final sub = restaurant.sousRestaurants.isNotEmpty
                    ? restaurant.sousRestaurants.first
                    : null;

                final isOpen = _isRestaurantOpen(restaurant);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: sub != null
                        ? Image.network(
                            sub.image,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.storefront),
                          )
                        : const Icon(Icons.storefront, size: 40),
                    title: Text(restaurant.nom),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sub?.ville ?? ""),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              isOpen ? Icons.access_time : Icons.lock,
                              color: isOpen ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOpen ? "Ouvert maintenant" : "Fermé",
                              style: TextStyle(
                                color: isOpen ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubRestaurantsScreen(
                            restaurant: restaurant,
                            userLat: userPosition!.latitude,
                            userLng: userPosition!.longitude,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}