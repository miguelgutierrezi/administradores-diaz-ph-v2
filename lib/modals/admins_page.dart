import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
// import 'edit_admin_page.dart';

class AdminsListPage extends StatefulWidget {
  const AdminsListPage({super.key});

  @override
  _AdminsListPageState createState() => _AdminsListPageState();
}

class _AdminsListPageState extends State<AdminsListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _filterAdmins = [];
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    List<Map<String, dynamic>> users =
        await _firestoreService.getCollection('users');
    List<Map<String, dynamic>> admins =
        users.where((user) => user['rol'] == 'ADMINISTRADOR').toList();

    setState(() {
      _admins = admins;
      _filterAdmins = admins;
    });
  }

  void _setFilteredAdmins(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm.toLowerCase();
      _filterAdmins = _admins.where((admin) {
        return admin['nombre'].toLowerCase().contains(_searchTerm);
      }).toList();
    });
  }

  Future<void> _deleteAdmin(String adminId) async {
    await _firestoreService.deleteObject('users', adminId);
    await _showAlert(
        'Administrador eliminado', 'Se ha eliminado el administrador');
    _loadAdmins();
  }

  Future<void> _showAlert(String title, String message) async {
    await showDialog<void>(
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

  void _editAdmin(Map<String, dynamic> admin) {
    /* Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAdminPage(admin: admin, adminId: admin['id']),
      ),
    ).then((_) {
      _loadAdmins(); // Refresh list after edit
    }); */
  }

  Future<void> _doRefresh() async {
    await _loadAdmins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Administradores',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _doRefresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Filtrar administradores',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _setFilteredAdmins,
              ),
            ),
            Expanded(
              child: _filterAdmins.isEmpty
                  ? const Center(
                      child: Text('No hay administradores disponibles'))
                  : ListView.builder(
                      itemCount: _filterAdmins.length,
                      itemBuilder: (context, index) {
                        final admin = _filterAdmins[index];
                        return Dismissible(
                          key: Key(admin['id']),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            _deleteAdmin(admin['id']);
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundImage:
                                    AssetImage('assets/avatar-icon.png'),
                              ),
                              title: Text(admin['nombre']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text('Email: ${admin['email']}'),
                                ],
                              ),
                              onTap: () => _editAdmin(admin),
                            ),
                          ),
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
