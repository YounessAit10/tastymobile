class Product {
  final String id;
  final String nom;
  final String informations;
  final double prix;
  final String image;
  final String categorie;

  Product({
    required this.id,
    required this.nom,
    required this.informations,
    required this.prix,
    required this.image,
    required this.categorie,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["_id"] ?? "",
      nom: json["nom"] ?? "Produit inconnu",
      informations: json["informations"] ?? "",
      prix: (json["prix"] ?? 0).toDouble(),
      image: json["image"] ?? "https://via.placeholder.com/150",
      categorie: json["categorie"] ?? "Divers",
    );
  }
}
