import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/welcome_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final AuthService _authService = AuthService();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Page'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _authService.signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const WelcomePage()));
              },
            ),
          ],
        ),
        body: const Center(
          child: Text(
            'Bienvenido a la Home Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
