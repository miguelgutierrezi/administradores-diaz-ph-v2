import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_role.dart';

class VisitsListPage extends StatefulWidget {
  const VisitsListPage({super.key});

  @override
  _VisitsListPageState createState() => _VisitsListPageState();
}

class _VisitsListPageState extends State<VisitsListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  final AuthService _authService = AuthService();

  String _searchTerm = '';
  UserRole? _userRole;
  String? _userName;
  String? _userId;
  List<String>? _adminBuildings;
  String? _userBuilding;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userRole = await _authService.getCurrentUserRole();
    _userName = prefs.getString('nombre');
    _userId = prefs.getString('id');
    if (_userRole == UserRole.admin) {
      _adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
    }
    setState(() {});
  }

  Stream<List<Map<String, dynamic>>> _visitsStream() {
    Query query = FirebaseFirestore.instance.collection('visits');
    if (_userRole == UserRole.admin) {
      query = query.where('edificio', arrayContainsAny: _adminBuildings);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  void _filterVisits(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Visitas',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          if (_userRole == UserRole.superadmin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Filtrar visitas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _filterVisits,
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _visitsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error al cargar las visitas'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No hay visitas disponibles'));
                } else {
                  var visits = snapshot.data!;
                  if (_searchTerm.isNotEmpty) {
                    visits = visits.where((visit) {
                      return visit['edificio']
                          .toLowerCase()
                          .contains(_searchTerm.toLowerCase());
                    }).toList();
                  }
                  return ListView.builder(
                    itemCount: visits.length,
                    itemBuilder: (context, index) {
                      var visit = visits[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: ListTile(
                          title: Text(visit['edificio']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                  'Fecha: ${DateTime.fromMillisecondsSinceEpoch(visit['date'].seconds * 1000)}'),
                              Text(
                                  'Autor: ${_userRole == UserRole.superadmin ? visit['name'] : _userName}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/visits/detail',
                                arguments: visit['id']);
                          },
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/visits/add-visit');
        },
      ),
    );
  }
}
