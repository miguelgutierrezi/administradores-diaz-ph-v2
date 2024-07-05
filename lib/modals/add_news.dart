import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';

class AddNewsPage extends StatefulWidget {
  const AddNewsPage({super.key});

  @override
  _AddNewsPageState createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final _formKey = GlobalKey<FormState>();
  final _noticiaController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();

  UserRole? _role;
  List<String> _buildings = [];
  String _selectedBuilding = '';
  PlatformFile? _pickedFile;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  @override
  void dispose() {
    _noticiaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    UserRole? userRole = await _authService.getCurrentUserRole();
    if (userRole == UserRole.admin) {
      List<String>? adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
      setState(() {
        _buildings = adminBuildings;
      });
    } else {
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Unsupported operation: $e");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error picking file: $e");
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      List<String> filesLinks = [];
      List<String> filesNames = [];
      _formKey.currentState!.save();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: SpinKitCircle(color: Colors.white));
        },
      );

      try {
        final data = {
          'noticia': _noticiaController.text,
          'descripcion': _descripcionController.text,
          'edificio': _selectedBuilding,
          'fecha': _selectedDate?.toIso8601String() ??
              DateTime.now().toIso8601String(),
        };

        DocumentReference newsRef =
            await _firestoreService.createDocument('news', data);

        if (_pickedFile != null) {
          String imageUrl = await _firestoreService.uploadFile(
              'news', newsRef.id, _pickedFile!.path!);
          filesLinks = [imageUrl];
          filesNames = [_pickedFile!.name];
        }

        final dataUp = {
          'noticia': _noticiaController.text,
          'descripcion': _descripcionController.text,
          'edificio': _selectedBuilding,
          'fecha': _selectedDate?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'filesLinks': filesLinks,
          'filesNames': filesNames,
        };

        await _firestoreService.updateDocument('news', newsRef.id, dataUp);

        Navigator.of(context).pop(); // Dismiss the loader
        _showAlert(
            context, 'Noticia agregada', 'Se ha creado una nueva noticia');
      } catch (e) {
        Navigator.of(context).pop(); // Dismiss the loader
        print("Error: $e");
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
          'Añadir noticia',
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
                controller: _noticiaController,
                decoration: const InputDecoration(
                  labelText: 'Noticia',
                  icon: Icon(Icons.article),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la noticia';
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
              ElevatedButton.icon(
                onPressed: () => _selectDate(context),
                icon: const Icon(Icons.calendar_today),
                label: const Text('Seleccionar fecha'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                _selectedDate != null
                    ? "Fecha seleccionada: ${DateFormat('dd-MM-yyyy').format(_selectedDate!)}"
                    : 'Ninguna fecha seleccionada',
                style: const TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Seleccionar archivo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                _pickedFile != null
                    ? _pickedFile!.name
                    : 'Ningún archivo seleccionado',
                style: const TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                label: const Text('Añadir noticia'),
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
