import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../utils/utils.dart';

class AddVotingPage extends StatefulWidget {
  const AddVotingPage({super.key});

  @override
  _AddVotingPageState createState() => _AddVotingPageState();
}

class _AddVotingPageState extends State<AddVotingPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _linkController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _sharedPreferencesService = SharedPreferencesService();

  UserRole? _role;
  List<String> _buildings = [];
  String? _selectedBuilding;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    UserRole? userRole = await _authService.getCurrentUserRole();
    if (userRole == UserRole.admin) {
      List<String>? adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
      setState(() {
        _buildings = adminBuildings ?? [];
      });
    } else if (userRole == UserRole.superadmin) {
      List<Map<String, dynamic>> buildingsData =
          await _firestoreService.getCollection('buildings');
      setState(() {
        _buildings =
            buildingsData.map((data) => data['nombre'].toString()).toList();
      });
    }
    setState(() {
      _role = userRole;
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Mostrar loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        final data = {
          'titulo': _tituloController.text,
          'descripcion': _descripcionController.text,
          'edificio': _selectedBuilding,
          'link': _linkController.text,
        };

        await _firestoreService.createDocument('votings', data);

        Navigator.of(context).pop(); // Ocultar loader
        _showAlert(
            context, 'Votación agregada', 'Se ha creado una nueva votación');
      } catch (e) {
        Navigator.of(context).pop(); // Ocultar loader
        Utils.debugPrint("Error: $e");
      }
    }
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
                Navigator.pop(context);
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
          'Añadir votación',
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
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  icon: Icon(
                    Icons.article,
                    semanticLabel: 'Título de la votación',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              if (_role != UserRole.user)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Edificio',
                    icon: Icon(
                      Icons.location_city,
                      semanticLabel: 'Seleccionar edificio',
                    ),
                  ),
                  items: _buildings.map((building) {
                    return DropdownMenuItem<String>(
                      value: building,
                      child: Text(building, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBuilding = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Enlace',
                  icon: Icon(
                    Icons.link,
                    semanticLabel: 'Enlace de la votación',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el enlace';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  icon: Icon(
                    Icons.description,
                    semanticLabel: 'Descripción de la votación',
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                  semanticLabel: 'Añadir votación',
                ),
                label: const Text('Añadir votación'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
