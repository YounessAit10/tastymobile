import 'product.dart';

class Restaurant {
  final String id;
  final String nom;
  final String email;
  final String title;
  final String description;
  final String image;
  final String type;
  final String tags;
  final List<SubRestaurant> sousRestaurants;
  final List<Product> products;

  Restaurant({
    required this.id,
    required this.nom,
    required this.email,
    required this.title,
    required this.description,
    required this.image,
    required this.type,
    required this.tags,
    required this.sousRestaurants,
    required this.products,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    var sousRestaurantsJson = json['restaurants'] as List? ?? [];
    var productsJson = json['products'] as List? ?? [];

    return Restaurant(
      id: json["_id"] ?? "",
      nom: json["nom"] ?? "",
      email: json["email"] ?? "",
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      image: json["image"] ?? "",
      type: json["type"] ?? "",
      tags: json["tags"] ?? "",
      sousRestaurants: sousRestaurantsJson.map((e) => SubRestaurant.fromJson(e)).toList(),
      products: productsJson.map((e) => Product.fromJson(e)).toList(),
    );
  }
}

class SubRestaurant {
  final String id;
  final String adresse;
  final String ville;
  final String image;
  final double rating;
  final String localisation;
  final String telephone;
  double? distance;

  SubRestaurant({
    required this.id,
    required this.adresse,
    required this.ville,
    required this.image,
    required this.rating,
    required this.localisation,
    required this.telephone,
    this.distance,
  });

  factory SubRestaurant.fromJson(Map<String, dynamic> json) {
    return SubRestaurant(
      id: json["_id"] ?? "",
      adresse: json["adresse"] ?? "",
      ville: json["ville"] ?? "",
      image: json["image"] ?? "",
      rating: (json["rating"] ?? 0).toDouble(),
      localisation: json["localisation"] ?? "",
      telephone: json["telephone"] ?? "",
    );
  }
}

class Product {
  final String id;
  final String nom;
  final String informations;
  final String image;
  final double prix;

  Product({
    required this.id,
    required this.nom,
    required this.informations,
    required this.image,
    required this.prix,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["_id"] ?? "",
      nom: json["nom"] ?? "",
      informations: json["informations"] ?? "",
      image: json["image"] ?? "",
      prix: (json["prix"] ?? 0).toDouble(),
    );
  }
}
