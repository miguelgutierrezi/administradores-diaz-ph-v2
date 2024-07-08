import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'edit_building.dart';

class BuildingsListPage extends StatefulWidget {
  const BuildingsListPage({super.key});

  @override
  _BuildingsListPageState createState() => _BuildingsListPageState();
}

class _BuildingsListPageState extends State<BuildingsListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _buildings = [];
  List<Map<String, dynamic>> _filterBuildings = [];
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    List<Map<String, dynamic>> buildings =
        await _firestoreService.getCollection('buildings');
    setState(() {
      _buildings = buildings;
      _filterBuildings = buildings;
    });
  }

  void _setFilteredBuildings(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm.toLowerCase();
      _filterBuildings = _buildings.where((building) {
        return building['nombre'].toLowerCase().contains(_searchTerm);
      }).toList();
    });
  }

  Future<void> _deleteBuilding(String buildingId) async {
    await _firestoreService.deleteObject('buildings', buildingId);
    await _showAlert('Edificio eliminado', 'Se ha eliminado el edificio');
    _loadBuildings();
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

  Future<void> _onEdit(Map<String, dynamic> building) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBuildingPage(
          building: building,
          buildingId: building['id'],
        ),
      ),
    );
    if (result == true) {
      _loadBuildings();
    }
  }

  Future<void> _doRefresh() async {
    await _loadBuildings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Mis edificios',
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
      body: RefreshIndicator(
        onRefresh: _doRefresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Filtrar edificios',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    semanticLabel: 'Buscar edificios',
                  ),
                ),
                onChanged: _setFilteredBuildings,
              ),
            ),
            Expanded(
              child: _filterBuildings.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay edificios disponibles',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filterBuildings.length,
                      itemBuilder: (context, index) {
                        final building = _filterBuildings[index];
                        final imageUrl = building['imageUrl'] ??
                            'https://cdn-icons-png.flaticon.com/512/85/85488.png';
                        return Dismissible(
                          key: Key(building['id']),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            _deleteBuilding(building['id']);
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              semanticLabel: 'Eliminar edificio',
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            child: ListTile(
                              leading: Semantics(
                                label: 'Imagen del edificio',
                                child: Image.network(
                                  imageUrl,
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/Logo_Diaz_Administradores.jpeg',
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              title: Text(building['nombre']),
                              subtitle: Text(building['direccion']),
                              onTap: () => _onEdit(building),
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
