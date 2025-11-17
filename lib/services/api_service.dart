import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/restaurant.dart';

class ApiService {
  // 🔐 Sécurisé : les valeurs viennent du fichier .env
  static final String baseUrl = dotenv.env['BASE_URL'] ?? "";
  static final String apiKey = dotenv.env['API_KEY'] ?? "";

  static Future<List<Restaurant>> fetchRestaurants() async {
    final response = await http.get(
      Uri.parse("$baseUrl/restaurants"),
      headers: {
        "x-api-key": apiKey,
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> restaurantsJson = data["restaurants"];
      return restaurantsJson.map((json) => Restaurant.fromJson(json)).toList();
    } else {
      throw Exception("Erreur ${response.statusCode}: ${response.body}");
    }
  }
}
