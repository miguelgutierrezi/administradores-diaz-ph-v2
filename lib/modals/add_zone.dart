import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';

class AddZonePage extends StatefulWidget {
  const AddZonePage({super.key});

  @override
  _AddZonePageState createState() => _AddZonePageState();
}

class _AddZonePageState extends State<AddZonePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  List<String> _buildings = [];
  String? _selectedBuilding;
  bool _reservasTrue = false;
  bool _reservasTodoElDia = false;
  List<PlatformFile> _files = [];
  List<String> _fileNames = [];

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    UserRole? role = await _authService.getCurrentUserRole();
    List<String> buildings = [];

    if (role == UserRole.admin) {
      buildings = await _sharedPreferencesService.getDynamicList('edificio');
    } else {
      List<Map<String, dynamic>> buildingsData =
          await _firestoreService.getCollection('buildings');
      buildings =
          buildingsData.map((data) => data['nombre'].toString()).toList();
    }

    setState(() {
      _buildings = buildings;
    });
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _files.addAll(result.files);
        _fileNames.addAll(result.files.map((file) => file.name).toList());
      });
    }
  }

  Future<void> _removeFile(int index) async {
    setState(() {
      _files.removeAt(index);
      _fileNames.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        final data = {
          'nombre': _nombreController.text,
          'descripcion': _descripcionController.text,
          'edificio': _selectedBuilding,
          'reservasTrue': _reservasTrue,
          'reservasTodoElDia': _reservasTodoElDia
        };

        DocumentReference zoneRef =
            await _firestoreService.createDocument('zonas', data);

        List<String> fileLinks = [];
        for (var file in _files) {
          String fileUrl = await _firestoreService.uploadFile(
              'zonas', zoneRef.id, file.path!);
          fileLinks.add(fileUrl);
        }

        final dataUp = {
          'filesLinks': fileLinks,
          'filesNames': _fileNames,
        };

        await _firestoreService.updateDocument('zonas', zoneRef.id, dataUp);

        Navigator.of(context).pop(); // Dismiss the loader
        _showAlert('Zona agregada', 'Se ha creado una nueva zona');
      } catch (e) {
        Navigator.of(context).pop(); // Dismiss the loader
        print("Error: $e");
      }
    }
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
                Navigator.pop(context); // Navigate back to the dashboard
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
          'Añadir zona',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  icon: Icon(Icons.article),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre de la zona';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Edificio',
                  icon: Icon(Icons.location_city),
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
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  icon: Icon(Icons.description),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              CheckboxListTile(
                title: const Text('¿Se pueden realizar reservas?'),
                value: _reservasTrue,
                onChanged: (bool? value) {
                  setState(() {
                    _reservasTrue = value!;
                    if (!_reservasTrue) {
                      _reservasTodoElDia = false;
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('¿Se pueden realizar reservas todo el día?'),
                value: _reservasTodoElDia,
                onChanged: _reservasTrue
                    ? (bool? value) {
                        setState(() {
                          _reservasTodoElDia = value!;
                        });
                      }
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file),
                label: const Text('Seleccionar archivos'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                children: _fileNames.map((fileName) {
                  int index = _fileNames.indexOf(fileName);
                  return Chip(
                    label: Text(fileName),
                    deleteIcon: const Icon(Icons.close),
                    onDeleted: () => _removeFile(index),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
                label: const Text('Añadir zona'),
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
