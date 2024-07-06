import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:administradores_diaz_ph/services/platform_service.dart';
import 'package:administradores_diaz_ph/utils/utils.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import 'handlers/alarm_permission_handler.dart';
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
    if (PlatformService.isAndroid()) {
      _requestExactAlarmPermission();
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    try {
      final bool granted =
          await AlarmPermissionHandler.requestExactAlarmPermission();
      if (granted) {
        Utils.debugPrint('Exact Alarm Permission Granted');
      } else {
        Utils.debugPrint('Exact Alarm Permission Denied');
      }
    } catch (e) {
      Utils.debugPrint('Failed to request exact alarm permission: $e');
    }
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
            tooltip:
                'Iniciar sesión', // Agregar etiqueta de herramienta para accesibilidad
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
                semanticLabel:
                    'Logo de Administradores Diaz PH SAS', // Agregar descripción semántica
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
                  return const Center(child: Text('No se encontraron datos'));
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
                                semanticLabel:
                                    'Imagen del edificio ${doc['nombre'] ?? 'sin título'}', // Agregar descripción semántica
                              ),
                              const SizedBox(height: 10),
                              Text(
                                doc['nombre'] ?? 'Sin título',
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                doc['direccion'] ?? 'Sin dirección',
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
