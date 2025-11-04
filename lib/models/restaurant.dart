// lib/models/restaurant.dart

class Extra {
  final String nom;
  final double prix;

  Extra({
    required this.nom,
    required this.prix,
  });

  factory Extra.fromJson(Map<String, dynamic> json) {
    return Extra(
      nom: json['nom'] ?? '',
      prix: (json['prix'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prix': prix,
      };
}

class Product {
  final String id;
  final String nom;
  final String informations;
  final String image;
  final double prix;
  final List<Extra> extras; // ✅ Liste d'extras possibles
  final List<OptionRequise>? optionsRequises;
  final List<String> ingredients; // ✅ ajouté ici
  final bool isBestSeller;
  final bool isActive;
  final String reduction; // ✅ nouvelle propriété



  Product({
    required this.id,
    required this.nom,
    required this.informations,
    required this.image,
    required this.prix,
    this.extras = const [], // ✅ par défaut 
    this.optionsRequises,
    this.ingredients = const [],
    this.isBestSeller = false,
    this.isActive = true,
    this.reduction = "",
  
  });

  double get prixReduit {
  if (reduction.isEmpty) return prix;
  final pourcentage = double.tryParse(reduction.replaceAll("%", "")) ?? 0;
  return prix * (1 - pourcentage / 100);
}


  factory Product.fromJson(Map<String, dynamic> json) {
    final extrasJson = json['extras'] as List<dynamic>? ?? [];
    final optionsJson = json['optionsRequises'] as List<dynamic>? ?? [];
    final ingredientsJson = json['ingredients'] as List<dynamic>? ?? [];

    return Product(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      informations: json['informations'] ?? '',
      image: json['image'] ?? '',
      prix: (json['prix'] ?? 0).toDouble(),
      ingredients: List<String>.from(ingredientsJson), // ✅ converti en liste de String
      extras: extrasJson.map((e) => Extra.fromJson(e as Map<String, dynamic>)).toList(),
      isBestSeller: json['isBestSeller'] ?? false,
      optionsRequises: optionsJson.map((e) => OptionRequise.fromJson(e)).toList(),
      reduction: json['reduction']?.toString() ?? "", // ✅ récupérée du JSON
      isActive: json['isActive'] ?? true,


    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'nom': nom,
        'informations': informations,
        'image': image,
        'prix': prix,
        'ingredients': ingredients,
        'extras': extras.map((e) => e.toJson()).toList(),
        'isBestSeller': isBestSeller,
        'optionsRequises': optionsRequises?.map((e) => e.toJson()).toList(),
        'reduction': reduction, // ✅ ajouté ici
        'isActive': isActive,

      };
}

class SubRestaurant {
  final String id;
  final String adresse;
  final String ville;
  final String image;
  final double rating;
  final String telephone;
  final String localisation;
  double? distance;

  SubRestaurant({
    required this.id,
    required this.adresse,
    required this.ville,
    required this.image,
    required this.rating,
    required this.telephone,
    required this.localisation,
    this.distance,
  });

  factory SubRestaurant.fromJson(Map<String, dynamic> json) {
    return SubRestaurant(
      id: json['_id'] ?? '',
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '',
      image: json['image'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      telephone: json['telephone'] ?? '',
      localisation: json['localisation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'adresse': adresse,
        'ville': ville,
        'image': image,
        'rating': rating,
        'telephone': telephone,
        'localisation': localisation,
      };
}

class Horaires {
  final String ouverture;
  final String fermeture;
  final List<String> joursOff;

  Horaires({
    required this.ouverture,
    required this.fermeture,
    required this.joursOff,
  });

  factory Horaires.fromJson(Map<String, dynamic> json) {
    return Horaires(
      ouverture: json['ouverture'] ?? '09:00',
      fermeture: json['fermeture'] ?? '23:00',
      joursOff: List<String>.from(json['joursOff'] ?? []),
    );
  }
}

class OptionRequise {
  final String titre;
  final int nombre;
  final List<String> element;

  OptionRequise({
    required this.titre,
    required this.nombre,
    required this.element,
  });

  factory OptionRequise.fromJson(Map<String, dynamic> json) {
    return OptionRequise(
      titre: json['titre'] ?? '',
      nombre: json['nombre'] ?? 1,
      element: List<String>.from(json['element'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'titre': titre,
        'nombre': nombre,
        'element': element,
      };
}


class Restaurant {
  final String id;
  final String nom;
  final String image;
  final String description;
  final List<SubRestaurant> sousRestaurants;
  final List<Product> products;
  final Horaires horaires; // 🕐 nouveau champ


  Restaurant({
    required this.id,
    required this.nom,
    required this.image,
    required this.description,
    required this.sousRestaurants,
    required this.products,
    required this.horaires,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final sousJson = json['restaurants'] as List<dynamic>? ?? [];
    final productsJson = json['products'] as List<dynamic>? ?? [];

    return Restaurant(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      sousRestaurants:
          sousJson.map((e) => SubRestaurant.fromJson(e as Map<String, dynamic>)).toList(),
      products: productsJson.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
      horaires: json['horaires'] != null
          ? Horaires.fromJson(json['horaires'])
          : Horaires(ouverture: '09:00', fermeture: '23:00', joursOff: []),
    );
  }
}

//   Map<String, dynamic> toJson() => {
//         '_id': id,
//         'nom': nom,
//         'image': image,
//         'description': description,
//         'restaurants': sousRestaurants.map((e) => e.toJson()).toList(),
//         'products': products.map((e) => e.toJson()).toList(),
//       };
// }