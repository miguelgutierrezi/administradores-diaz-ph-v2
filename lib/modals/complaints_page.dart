import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_role.dart';

class ComplaintsListPage extends StatefulWidget {
  const ComplaintsListPage({super.key});

  @override
  _ComplaintsListPageState createState() => _ComplaintsListPageState();
}

class _ComplaintsListPageState extends State<ComplaintsListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();

  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _unreadComplaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  List<Map<String, dynamic>> _filteredUnreadComplaints = [];

  String? _userId;
  UserRole? _userRole;
  List<String>? _adminBuildings;
  String _searchTerm = '';
  bool _childNoLeidos = true;
  bool _childLeidos = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    UserRole? role = await _authService.getCurrentUserRole();

    if (role == UserRole.admin) {
      _adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
    } else {
      _adminBuildings = [];
    }

    setState(() {
      _userRole = role;
      _userId = FirebaseAuth.instance.currentUser?.uid;
    });
  }

  Stream<List<Map<String, dynamic>>> _complaintsStream() {
    Query query = FirebaseFirestore.instance.collection('complaints');
    if (_userRole == UserRole.admin &&
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

  void _setFilteredComplaints(String searchTerm) {
    setState(() {
      _filteredComplaints = _complaints
          .where((complaint) => complaint['nombre']
              .toLowerCase()
              .contains(searchTerm.toLowerCase()))
          .toList();
      _filteredUnreadComplaints = _unreadComplaints
          .where((complaint) => complaint['nombre']
              .toLowerCase()
              .contains(searchTerm.toLowerCase()))
          .toList();
    });
  }

  void _markAsRead(String complaintId, bool isRead) async {
    await _firestoreService
        .updateDocument('complaints', complaintId, {'leido': !isRead});
  }

  void _deleteComplaint(String complaintId) async {
    await _firestoreService.deleteObject('complaints', complaintId);
    _showAlert(context, 'Queja eliminada', 'Se ha eliminado la queja');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Quejas y reclamos',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            semanticLabel: 'Regresar',
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: 'Filtrar quejas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  semanticLabel: 'Buscar quejas',
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _complaintsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Cargando quejas...',
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  var data = snapshot.data ?? [];
                  var complaints =
                      data.where((complaint) => complaint['leido']).toList();
                  var unreadComplaints =
                      data.where((complaint) => !complaint['leido']).toList();

                  var filteredComplaints = complaints.where((complaint) {
                    return complaint['nombre']
                        .toLowerCase()
                        .contains(_searchTerm.toLowerCase());
                  }).toList();

                  var filteredUnreadComplaints =
                      unreadComplaints.where((complaint) {
                    return complaint['nombre']
                        .toLowerCase()
                        .contains(_searchTerm.toLowerCase());
                  }).toList();

                  return ListView(
                    children: [
                      ExpansionTile(
                        title: const Text(
                          'Quejas no respondidas',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: _childNoLeidos,
                        onExpansionChanged: (bool expanded) {
                          setState(() {
                            _childNoLeidos = expanded;
                          });
                        },
                        children: filteredUnreadComplaints.map((complaint) {
                          return Dismissible(
                            key: Key(complaint['id']),
                            background: Container(
                              color: Colors.green,
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                semanticLabel: 'Marcar como leída',
                              ),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                semanticLabel: 'Eliminar queja',
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                _markAsRead(
                                    complaint['id'], complaint['leido']);
                              } else if (direction ==
                                  DismissDirection.endToStart) {
                                _deleteComplaint(complaint['id']);
                              }
                              return false;
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              child: ListTile(
                                title: Text(complaint['edificio']),
                                subtitle: Text(
                                    'Nombre: ${complaint['nombre']}\nCorreo: ${complaint['correo']}'),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (filteredUnreadComplaints.isEmpty)
                        const Center(
                          child: Text(
                            'No tienes quejas no respondidas',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ExpansionTile(
                        title: const Text(
                          'Quejas respondidas',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: _childLeidos,
                        onExpansionChanged: (bool expanded) {
                          setState(() {
                            _childLeidos = expanded;
                          });
                        },
                        children: filteredComplaints.map((complaint) {
                          return Dismissible(
                            key: Key(complaint['id']),
                            background: Container(
                              color: Colors.green,
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                semanticLabel: 'Marcar como leída',
                              ),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                semanticLabel: 'Eliminar queja',
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                _markAsRead(
                                    complaint['id'], complaint['leido']);
                              } else if (direction ==
                                  DismissDirection.endToStart) {
                                _deleteComplaint(complaint['id']);
                              }
                              return false;
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 15),
                              child: ListTile(
                                title: Text(complaint['edificio']),
                                subtitle: Text(
                                    'Nombre: ${complaint['nombre']}\nCorreo: ${complaint['correo']}'),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (filteredComplaints.isEmpty)
                        const Center(
                          child: Text(
                            'No tienes quejas respondidas',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
