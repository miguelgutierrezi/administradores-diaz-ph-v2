import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/shared_preferences_service.dart';

class EditClientPage extends StatefulWidget {
  final Map<String, dynamic> client;
  final String clientId;

  const EditClientPage({required this.client, required this.clientId, Key? key})
      : super(key: key);

  @override
  _EditClientPageState createState() => _EditClientPageState();
}

class _EditClientPageState extends State<EditClientPage> {
  final _firestoreService = FirestoreService();
  final _sharedPreferencesService = SharedPreferencesService();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  List<String> _buildings = [];
  bool _isLoading = false;

  final Map<String, dynamic> _updatedClient = {
    'nombre': '',
    'edificio': '',
    'rol': '',
    'email': '',
    'numeroApto': ''
  };

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
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
      _updatedClient['nombre'] = widget.client['nombre'];
      _updatedClient['edificio'] = widget.client['edificio'] is List
          ? widget.client['edificio'][0]
          : widget.client['edificio'];
      _updatedClient['email'] = widget.client['email'];
      _updatedClient['rol'] = widget.client['rol'];
      _updatedClient['numeroApto'] = widget.client['numeroApto'];
      _isLoading = false;
    });
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _firestoreService.updateDocument(
          'users', widget.clientId, _updatedClient);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente actualizado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.client['nombre'],
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
                        label: 'Avatar del cliente',
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/avatar-icon.png'),
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Campo de texto para el nombre del cliente',
                      hint: 'Ingrese el nombre del cliente',
                      child: TextFormField(
                        initialValue: _updatedClient['nombre'],
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          icon: Icon(
                            Icons.document_scanner,
                            semanticLabel: 'Nombre del cliente',
                          ),
                        ),
                        onSaved: (value) {
                          _updatedClient['nombre'] = value!;
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
                      label: 'Selector de edificio',
                      hint: 'Seleccione el edificio del cliente',
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Edificio',
                          icon: Icon(
                            Icons.business,
                            semanticLabel: 'Edificio del cliente',
                          ),
                        ),
                        items: _buildings.map((building) {
                          return DropdownMenuItem<String>(
                            value: building,
                            child: Text(building),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _updatedClient['edificio'] = value!;
                          });
                        },
                        value: _updatedClient['edificio'],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Seleccione un edificio';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      label: 'Campo de texto para el número de apartamento',
                      hint: 'Ingrese el número de apartamento del cliente',
                      child: TextFormField(
                        initialValue: _updatedClient['numeroApto'],
                        decoration: const InputDecoration(
                          labelText: 'Número apartamento',
                          icon: Icon(
                            Icons.home,
                            semanticLabel: 'Número de apartamento',
                          ),
                        ),
                        onSaved: (value) {
                          _updatedClient['numeroApto'] = value!;
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
                      label: 'Botón para guardar cliente',
                      hint: 'Presione para guardar los cambios del cliente',
                      child: ElevatedButton.icon(
                        onPressed: _onSave,
                        icon: const Icon(
                          Icons.check,
                          semanticLabel: 'Guardar',
                        ),
                        label: const Text('Guardar cliente'),
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
