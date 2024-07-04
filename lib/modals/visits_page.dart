import 'package:administradores_diaz_ph/modals/visit_detail.dart';
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

  List<DocumentSnapshot> _visits = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _documentLimit = 10;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      _getVisits();
    });
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
  }

  Future<void> _getVisits() async {
    if (!_hasMore) {
      print('No More Visits');
      return;
    }
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    Query query = FirebaseFirestore.instance.collection('visits');
    if (_userRole == UserRole.admin) {
      query = query.where('edificio', arrayContainsAny: _adminBuildings);
    }
    query = query.orderBy('date', descending: true).limit(_documentLimit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();
    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
      _visits.addAll(querySnapshot.docs);
      if (querySnapshot.docs.length < _documentLimit) {
        _hasMore = false;
      }
    } else {
      _hasMore = false;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterVisits(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<DocumentSnapshot> filteredVisits = _visits;
    if (_searchTerm.isNotEmpty) {
      filteredVisits = _visits.where((visit) {
        return (visit.data() as Map<String, dynamic>)['edificio']
            .toLowerCase()
            .contains(_searchTerm.toLowerCase());
      }).toList();
    }

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
            child: ListView.builder(
              itemCount: filteredVisits.length + 1,
              itemBuilder: (context, index) {
                if (index == filteredVisits.length) {
                  return _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _hasMore
                          ? TextButton(
                              onPressed: _getVisits,
                              child: const Text('Cargar más visitas'),
                            )
                          : const Center(child: Text('No hay más visitas'));
                }
                var visit = filteredVisits[index];
                var data = visit.data() as Map<String, dynamic>;
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: ListTile(
                    title: Text(data['edificio']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                            'Fecha: ${DateTime.fromMillisecondsSinceEpoch(data['date'].seconds * 1000)}'),
                        Text(
                            'Autor: ${_userRole == UserRole.superadmin ? data['name'] : _userName}'),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VisitDetailPage(
                            visitId: data['id'],
                          ),
                        ),
                      );
                    },
                  ),
                );
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
