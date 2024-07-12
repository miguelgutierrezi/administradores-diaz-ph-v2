import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/shared_preferences_service.dart';

class EditAdminPage extends StatefulWidget {
  final Map<String, dynamic> admin;
  final String adminId;

  const EditAdminPage({required this.admin, required this.adminId, super.key});

  @override
  _EditAdminPageState createState() => _EditAdminPageState();
}

class _EditAdminPageState extends State<EditAdminPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  List<String> _buildings = [];
  String? _selectedBuilding;

  final Map<String, dynamic> _updatedAdmin = {
    'nombre': '',
    'edificio': <String>[],
    'rol': '',
    'email': ''
  };

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });

    UserRole? role = await _authService.getCurrentUserRole();
    List<Map<String, dynamic>> buildings =
        await _firestoreService.getCollection('buildings');

    if (role == UserRole.superadmin) {
      _buildings =
          buildings.map((building) => building['nombre'] as String).toList();
    } else if (role == UserRole.admin) {
      List<String> adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
      _buildings = buildings
          .where((building) => adminBuildings.contains(building['nombre']))
          .map((building) => building['nombre'] as String)
          .toList();
    }

    setState(() {
      _updatedAdmin['nombre'] = widget.admin['nombre'];
      _updatedAdmin['edificio'] = List<String>.from(widget.admin['edificio']);
      _updatedAdmin['email'] = widget.admin['email'];
      _updatedAdmin['rol'] = widget.admin['rol'];
      _isLoading = false;
    });
  }

  void _addBuilding(String building) {
    setState(() {
      if (!_updatedAdmin['edificio'].contains(building)) {
        _updatedAdmin['edificio'].add(building);
      }
    });
  }

  void _removeBuilding(int index) {
    setState(() {
      _updatedAdmin['edificio'].removeAt(index);
    });
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _firestoreService.updateDocument(
          'users', widget.adminId, _updatedAdmin);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrador actualizado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _updatedAdmin['nombre'],
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              semanticLabel: 'Cerrar',
            ),
            onPressed: _onCancel,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Cargando...',
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    Center(
                      child: Semantics(
                        label: 'Avatar del administrador',
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/avatar-icon.png'),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Campo de texto para el nombre del administrador',
                      hint: 'Ingrese el nombre del administrador',
                      child: TextFormField(
                        initialValue: _updatedAdmin['nombre'],
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          icon: Icon(
                            Icons.document_scanner,
                            semanticLabel: 'Nombre del administrador',
                          ),
                        ),
                        onSaved: (value) {
                          _updatedAdmin['nombre'] = value!;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Campo requerido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Campo de texto para el correo electrónico',
                      hint: 'Correo electrónico del administrador',
                      child: TextFormField(
                        initialValue: _updatedAdmin['email'],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          icon: Icon(
                            Icons.email,
                            semanticLabel: 'Correo electrónico',
                          ),
                        ),
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edificios asociados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._updatedAdmin['edificio'].map<Widget>((building) {
                      int index = _updatedAdmin['edificio'].indexOf(building);
                      return ListTile(
                        title: Text(building),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                            semanticLabel: 'Eliminar edificio',
                          ),
                          onPressed: () => _removeBuilding(index),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Selector de edificio',
                      hint: 'Seleccione un edificio para agregar',
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Agregar edificio',
                          icon: Icon(
                            Icons.add,
                            semanticLabel: 'Agregar edificio',
                          ),
                        ),
                        items: _buildings.map((building) {
                          return DropdownMenuItem<String>(
                            value: building,
                            child: Text(building),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null &&
                              !_updatedAdmin['edificio'].contains(value)) {
                            _addBuilding(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Botón para guardar administrador',
                      hint: 'Presione para guardar el administrador',
                      child: ElevatedButton.icon(
                        onPressed: _onSave,
                        icon: const Icon(
                          Icons.check,
                          semanticLabel: 'Guardar',
                        ),
                        label: const Text('Guardar administrador'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 18),
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
