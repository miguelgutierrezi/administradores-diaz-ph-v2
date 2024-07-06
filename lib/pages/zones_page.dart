import 'package:administradores_diaz_ph/modals/add_zone.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modals/calendar_page.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/platform_service.dart';
import '../services/shared_preferences_service.dart';

class ZonesPage extends StatefulWidget {
  const ZonesPage({super.key});

  @override
  _ZonesPageState createState() => _ZonesPageState();
}

class _ZonesPageState extends State<ZonesPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();

  List<Map<String, dynamic>> _zonas = [];
  List<Map<String, dynamic>> _filterZones = [];
  String _searchTerm = '';
  UserRole? _userRole;
  String? _userBuilding;
  List<String>? _adminBuildings;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    UserRole? userRole = await _authService.getCurrentUserRole();
    final prefs = await SharedPreferences.getInstance();
    if (userRole == UserRole.user) {
      _userBuilding = prefs.getString("edificio");
    } else if (userRole == UserRole.admin) {
      _adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
    }
    setState(() {
      _userRole = userRole;
    });
  }

  Stream<List<Map<String, dynamic>>> _zonesStream() {
    Query query = FirebaseFirestore.instance.collection('zonas');
    if (_userRole == UserRole.user && _userBuilding != null) {
      query = query.where('edificio', isEqualTo: _userBuilding);
    } else if (_userRole == UserRole.admin &&
        _adminBuildings != null &&
        _adminBuildings!.isNotEmpty) {
      query = query.where('edificio', whereIn: _adminBuildings);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  void _setFilteredZones(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm;
    });
  }

  void _displayImage(String url) {
    launchUrl(Uri.parse(url));
  }

  Future<void> _deleteZone(String zoneId) async {
    await _firestoreService.deleteObject('zonas', zoneId);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Zona eliminada'),
          content: const Text('Se ha eliminado la zona'),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar zonas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                hintText: 'Buscar zonas',
                prefixIcon: const Icon(
                  Icons.search,
                  semanticLabel: 'Buscar',
                ),
              ),
              onChanged: (value) {
                _setFilteredZones(value);
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _zonesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Cargando zonas',
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error al cargar las zonas',
                      semanticsLabel: 'Error al cargar las zonas',
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay zonas disponibles',
                      semanticsLabel: 'No hay zonas disponibles',
                    ),
                  );
                } else {
                  List<Map<String, dynamic>> zonas = snapshot.data!;
                  List<Map<String, dynamic>> filteredZonas =
                      zonas.where((zona) {
                    return zona['nombre']
                        .toLowerCase()
                        .contains(_searchTerm.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredZonas.length,
                    itemBuilder: (context, index) {
                      final zona = filteredZonas[index];
                      return Dismissible(
                        key: Key(zona['id']),
                        direction: _userRole == UserRole.superadmin ||
                                _userRole == UserRole.admin
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        onDismissed: (direction) {
                          _deleteZone(zona['id']);
                          setState(() {
                            filteredZonas.removeAt(index);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Zona eliminada')),
                          );
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (zona['filesLinks'] != null &&
                                  zona['filesLinks'].isNotEmpty)
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
                                  child: CarouselSlider(
                                    options: CarouselOptions(
                                      autoPlay: true,
                                      enlargeCenterPage: true,
                                      aspectRatio: 2.0,
                                      onPageChanged: (index, reason) {},
                                    ),
                                    items: zona['filesLinks']
                                        .map<Widget>((item) => GestureDetector(
                                              onTap: () => _displayImage(item),
                                              child: Center(
                                                child: Image.network(
                                                  item,
                                                  fit: BoxFit.cover,
                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.red,
                                                      semanticLabel:
                                                          'Imagen no disponible',
                                                    );
                                                  },
                                                  semanticLabel:
                                                      'Imagen de la zona',
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ListTile(
                                title: Text(
                                  zona['nombre'],
                                  semanticsLabel:
                                      'Nombre de la zona: ${zona['nombre']}',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Edificio: ${zona['edificio']}',
                                      semanticsLabel:
                                          'Edificio: ${zona['edificio']}',
                                    ),
                                    Text(
                                      'Descripción: ${zona['descripcion']}',
                                      semanticsLabel:
                                          'Descripción: ${zona['descripcion']}',
                                    ),
                                  ],
                                ),
                                trailing: Wrap(
                                  spacing: 12,
                                  children: <Widget>[
                                    if (zona['reservasTrue'] == true)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.calendar_today,
                                          semanticLabel:
                                              'Abrir calendario de reservas',
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CalendarUiPage(
                                                      zoneId: zona['id']),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ((_userRole == UserRole.admin ||
                  _userRole == UserRole.superadmin) &&
              PlatformService.isMobile())
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddZonePage()),
                );
              },
              backgroundColor: Colors.black,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                semanticLabel: 'Agregar zona',
              ),
            )
          : null,
    );
  }
}
