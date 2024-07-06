import 'package:administradores_diaz_ph/modals/add_announce.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/platform_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  UserRole? _userRole;
  String _searchTerm = '';
  List<Map<String, dynamic>> _announces = [];
  List<Map<String, dynamic>> _filterAnnounces = [];
  String? _userId;
  String? _userBuilding;
  List<String>? _adminBuildings;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    UserRole? userRole = await _authService.getCurrentUserRole();
    String? id = FirebaseAuth.instance.currentUser?.uid;
    final prefs = await SharedPreferences.getInstance();
    if (userRole == UserRole.user) {
      _userBuilding = prefs.getString("edificio");
    } else if (userRole == UserRole.admin) {
      _adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
    }
    setState(() {
      _userRole = userRole;
      _userId = id;
    });
  }

  Stream<List<Map<String, dynamic>>> _announcesStream() {
    Query query = FirebaseFirestore.instance.collection('dashboard');
    if (_userRole == UserRole.user && _userBuilding != null) {
      query = query.where('edificio', isEqualTo: _userBuilding);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  void _setFilteredAnnounces(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm;
      _filterAnnounces = _announces.where((announce) {
        return announce['titulo']
            .toLowerCase()
            .contains(_searchTerm.toLowerCase());
      }).toList();
    });
  }

  void _displayImage(String url) {
    launchUrl(Uri.parse(url));
  }

  void _sendMessage(String url, String phoneNumber) {
    launchUrl(Uri.parse('$url$phoneNumber'));
  }

  Future<void> _deleteAnnounce(String announceId) async {
    await _firestoreService.deleteObject('dashboard', announceId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anuncio eliminado')),
    );
  }

  bool _isOwner(String propietario) {
    return _userId == propietario;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _announcesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Cargando anuncios...',
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error cargando anuncios',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay anuncios disponibles',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          _announces = snapshot.data!;
          _filterAnnounces = _announces;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Filtrar anuncios',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    _setFilteredAnnounces(value);
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filterAnnounces.length,
                  itemBuilder: (context, index) {
                    final item = _filterAnnounces[index];
                    return Dismissible(
                      key: Key(item['id']),
                      direction: _isOwner(item['propietario'])
                          ? DismissDirection.endToStart
                          : DismissDirection.none,
                      onDismissed: (direction) {
                        _deleteAnnounce(item['id']);
                        setState(() {
                          _filterAnnounces.removeAt(index);
                        });
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          semanticLabel: 'Eliminar anuncio',
                        ),
                      ),
                      child: Card(
                        margin: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item['filesLinks'] != null &&
                                item['filesLinks'].isNotEmpty)
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                                child: CarouselSlider(
                                  options: CarouselOptions(
                                    autoPlay: true,
                                    enlargeCenterPage: true,
                                    aspectRatio: 2.0,
                                  ),
                                  items: item['filesLinks']
                                      .map<Widget>((image) => GestureDetector(
                                            onTap: () => _displayImage(image),
                                            child: Center(
                                              child: Image.network(
                                                image,
                                                fit: BoxFit.cover,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                semanticLabel:
                                                    'Imagen del anuncio',
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ListTile(
                              title: Text(
                                item['titulo'],
                                style: const TextStyle(fontSize: 18),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['descripcion'],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (item['email'] != null)
                                    GestureDetector(
                                      onTap: () => launchUrl(
                                          Uri.parse('mailto:${item['email']}')),
                                      child: Text(
                                        item['email'],
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  if (item['celular'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          if (item['whatsapp'] == true)
                                            IconButton(
                                              icon: const Icon(
                                                  FontAwesomeIcons.whatsapp,
                                                  color: Colors.green),
                                              onPressed: () => _sendMessage(
                                                  'https://api.whatsapp.com/send/?phone=57',
                                                  item['celular']),
                                              tooltip:
                                                  'Enviar mensaje por WhatsApp',
                                            ),
                                          GestureDetector(
                                            onTap: () => launchUrl(Uri.parse(
                                                'tel:+57${item['celular']}')),
                                            child: Text(
                                              item['celular'],
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.black,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: (PlatformService.isMobile())
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAnnounce()),
                );
              },
              backgroundColor: Colors.black,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                semanticLabel: 'Agregar anuncio',
              ),
            )
          : null,
    );
  }
}
