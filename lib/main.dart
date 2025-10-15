import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'providers/cart_provider.dart'; // ✅ Ajout pour le panier

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Vérifie si l'utilisateur est connecté (numéro de téléphone sauvegardé)
  Future<bool> _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.containsKey("phone");
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()), // ✅ Fournisseur global du panier
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Tasty App',
        theme: ThemeData(
          primarySwatch: Colors.red,
          scaffoldBackgroundColor: Colors.white,
        ),

        // 🔹 Page d’accueil selon l’état de connexion
        home: FutureBuilder<bool>(
          future: _checkLogin(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.data == true) {
              return const MainScreen(); // ✅ connecté
            } else {
              return const LoginScreen(); // ❌ non connecté
            }
          },
        ),

        // 🔹 Routes globales
        routes: {
          "/home": (context) => const MainScreen(),
          "/login": (context) => const LoginScreen(),
        },
      ),
    );
  }
}