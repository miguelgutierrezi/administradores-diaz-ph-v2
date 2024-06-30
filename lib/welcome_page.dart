import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  Future<List<Map<String, dynamic>>>? _buildingsData;

  @override
  void initState() {
    super.initState();
    _buildingsData = _firestoreService.getCollection('buildings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Administradores Diaz PH SAS',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.login, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'assets/Logo_Diaz_Administradores.jpeg',
                height: 200,
                width: 200,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(thickness: 2),
            const SizedBox(height: 20),
            const Text(
              'NUESTROS EDIFICIOS',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _buildingsData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data found'));
                } else {
                  return CarouselSlider(
                    options: CarouselOptions(
                      height: 400.0,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      autoPlayAnimationDuration:
                          const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      pauseAutoPlayOnTouch: true,
                    ),
                    items: snapshot.data!.map((doc) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Column(
                            children: [
                              Image.network(
                                doc['imageUrl'] ??
                                    'https://cdn-icons-png.flaticon.com/512/85/85488.png',
                                height: 200,
                                width: 200,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/Logo_Diaz_Administradores.jpeg',
                                    height: 200,
                                    width: 200,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              Text(
                                doc['nombre'] ?? 'No title',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                doc['direccion'] ?? 'No subtitle',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          );
                        },
                      );
                    }).toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
