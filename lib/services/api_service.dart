import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';

class ApiService {
  static const String baseUrl = "https://preprod.panel.tasty.ma/api";
  static const String apiKey = "NJqQbTiOlzjLTLBmk590P2lbDxfd0wQ4"; 

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
