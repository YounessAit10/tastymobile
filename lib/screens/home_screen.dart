import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../models/restaurant.dart';
import '../utils/distance_utils.dart';
import 'sub_restaurant_screen.dart';

class HomeScreen extends StatefulWidget {
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

  /// 🔹 Obtenir la position actuelle de l’utilisateur
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

  @override
  Widget build(BuildContext context) {
    if (_loadingLocation) {
      return Scaffold(
        appBar: AppBar(title: Text("Restaurants proches")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userPosition == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Erreur localisation")),
        body: Center(child: Text("Impossible d’obtenir votre position")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Restaurants proches")),
      body: FutureBuilder<List<Restaurant>>(
        future: futureNearbyRestaurants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Aucun restaurant proche trouvé"));
          } else {
            final restaurants = snapshot.data!;
            return ListView.builder(
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                final restaurant = restaurants[index];
                final sub = restaurant.sousRestaurants.isNotEmpty
                    ? restaurant.sousRestaurants.first
                    : null;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    leading: sub != null
                        ? Image.network(
                            sub.image,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, _, __) =>
                                Icon(Icons.storefront, size: 40),
                          )
                        : const Icon(Icons.storefront, size: 40),
                    title: Text(restaurant.nom),
                    subtitle: Text(
                      sub != null
                          ? "${sub.ville} • ${sub.adresse}"
                          : "Aucune adresse disponible",
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
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