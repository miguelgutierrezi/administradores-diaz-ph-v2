import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:rxdart/rxdart.dart';

import '../models/user_role.dart';

class ClientsListPage extends StatefulWidget {
  const ClientsListPage({Key? key}) : super(key: key);

  @override
  _ClientsListPageState createState() => _ClientsListPageState();
}

class _ClientsListPageState extends State<ClientsListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  
  String _searchTerm = '';
  UserRole? _userRole;
  List<String>? _adminBuildings;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _userRole = await _authService.getCurrentUserRole();
    if (_userRole == UserRole.admin) {
      _adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
    }
    setState(() {});
  }

  Stream<List<Map<String, dynamic>>> _clientsStream() {
    Query queryForString = FirebaseFirestore.instance
        .collection('users')
        .where('rol', isEqualTo: 'CLIENTE')
        .where('edificio', whereIn: _adminBuildings);

    Query queryForArray = FirebaseFirestore.instance
        .collection('users')
        .where('rol', isEqualTo: 'CLIENTE')
        .where('edificio', arrayContainsAny: _adminBuildings);

    Stream<List<Map<String, dynamic>>> stringQueryStream =
        queryForString.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });

    Stream<List<Map<String, dynamic>>> arrayQueryStream =
        queryForArray.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });

    // Combine both streams using StreamZip from the rxdart package
    return Rx.combineLatest2(stringQueryStream, arrayQueryStream,
        (List<Map<String, dynamic>> stringResults,
            List<Map<String, dynamic>> arrayResults) {
      return [...stringResults, ...arrayResults];
    });
  }

  void _filterClients(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm;
    });
  }

  void _deleteClient(String clientId) async {
    await _firestoreService.deleteObject('users', clientId);
    _showAlert('Cliente eliminado', 'Se ha eliminado el cliente');
  }

  void _showAlert(String title, String message) {
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

  void _editClient(Map<String, dynamic> client) {
    // Navigate to the edit client page with the client data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Clientes',
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Filtrar clientes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                _filterClients(value);
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _clientsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error al cargar los clientes'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No hay clientes disponibles'));
                } else {
                  var clients = snapshot.data!;
                  if (_searchTerm.isNotEmpty) {
                    clients = clients.where((client) {
                      return client['nombre']
                          .toLowerCase()
                          .contains(_searchTerm.toLowerCase());
                    }).toList();
                  }
                  return ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      var client = clients[index];
                      return Dismissible(
                        key: Key(client['id']),
                        background: Container(color: Colors.red),
                        onDismissed: (direction) {
                          _deleteClient(client['id']);
                        },
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundImage:
                                AssetImage('assets/avatar-icon.png'),
                          ),
                          title: Text(client['nombre']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Email: ${client['email']}'),
                              Text(
                                  'Edificio: ${client['edificio']} - Apto: ${client['numeroApto']}'),
                            ],
                          ),
                          onTap: () => _editClient(client),
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
    );
  }
}
