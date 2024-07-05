import 'package:administradores_diaz_ph/modals/add_voting.dart';
import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_role.dart';
import '../services/shared_preferences_service.dart';

class VotingsListPage extends StatefulWidget {
  const VotingsListPage({super.key});

  @override
  _VotingsListPageState createState() => _VotingsListPageState();
}

class _VotingsListPageState extends State<VotingsListPage> {
  final AuthService _authService = AuthService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  final FirestoreService _firestoreService = FirestoreService();
  String? _userBuilding;
  List<String>? _adminBuildings;
  String _searchTerm = '';
  UserRole? _userRole;

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

  Stream<List<Map<String, dynamic>>> _votingsStream() {
    Query query = FirebaseFirestore.instance.collection('votings');
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

  Future<void> _deleteVoting(String voteKey) async {
    await _firestoreService.deleteObject('votings', voteKey);
    _showAlert(context, 'Votación eliminada', 'Se ha eliminado la votación');
  }

  void _showAlert(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
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

  void _downloadFile(String url) {
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Votaciones',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Filtrar votaciones',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _votingsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var votaciones = snapshot.data ?? [];
                if (_searchTerm.isNotEmpty) {
                  votaciones = votaciones.where((item) {
                    return item['titulo']
                        .toLowerCase()
                        .contains(_searchTerm.toLowerCase());
                  }).toList();
                }

                if (votaciones.isEmpty) {
                  return const Center(
                    child: Text('No hay votaciones activas'),
                  );
                }

                return ListView.builder(
                  itemCount: votaciones.length,
                  itemBuilder: (context, index) {
                    var item = votaciones[index];
                    return Dismissible(
                      key: Key(item['id']),
                      background: Container(color: Colors.red),
                      onDismissed: (direction) {
                        if (_userRole == UserRole.admin ||
                            _userRole == UserRole.superadmin) {
                          _deleteVoting(item['id']);
                        } else {
                          setState(() {
                            votaciones.insert(index, item);
                          });
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        child: ListTile(
                          title: Text(item['titulo']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['edificio']),
                              Text(item['descripcion']),
                            ],
                          ),
                          onTap: () => _downloadFile(item['link']),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _userRole != UserRole.user
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddVotingPage()),
                );
              },
              backgroundColor: Colors.black,
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
