import 'package:administradores_diaz_ph/models/user_role.dart';
import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class AddAnnounce extends StatefulWidget {
  const AddAnnounce({super.key});

  @override
  _AddAnnounceState createState() => _AddAnnounceState();
}

class _AddAnnounceState extends State<AddAnnounce> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  List<String> _buildings = [];
  String? _selectedBuilding;
  bool _whatsapp = true;
  List<PlatformFile> _files = [];
  List<String> _fileNames = [];
  List<String> _fileLinks = [];
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');
    UserRole? role = await _authService.getCurrentUserRole();
    List<String> buildings = [];

    if (role == UserRole.user) {
      String? building = prefs.getString("edificio");
      if (building != null) {
        buildings = [building];
      }
    } else if (role == UserRole.admin) {
      buildings = await _sharedPreferencesService.getDynamicList('edificio');
    } else {
      List<Map<String, dynamic>> buildingsData =
          await _firestoreService.getCollection('buildings');
      buildings =
          buildingsData.map((data) => data['nombre'].toString()).toList();
    }

    setState(() {
      _buildings = buildings;
      _userId = userId;
    });
  }

  Future<void> _pickFile() async {
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

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Show loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        String? userId = FirebaseAuth.instance.currentUser?.uid;
        final data = {
          'titulo': _titleController.text,
          'descripcion': _descriptionController.text,
          'propietario': userId,
          'email': _emailController.text,
          'celular': _phoneController.text,
          'edificio': _selectedBuilding,
          'whatsapp': _whatsapp,
        };

        DocumentReference announceRef =
            await FirebaseFirestore.instance.collection('dashboard').add(data);

        for (var file in _files) {
          String imageUrl = await _firestoreService.uploadFile(
              'dashboard', announceRef.id, file.path!);
          _fileLinks.add(imageUrl);
        }

        final dataUp = {
          ...data,
          'filesLinks': _fileLinks,
          'filesNames': _fileNames,
        };

        await FirebaseFirestore.instance
            .collection('dashboard')
            .doc(announceRef.id)
            .update(dataUp);

        Navigator.of(context).pop(); // Dismiss the loader
        _showAlert('Anuncio agregado', 'Se ha creado un nuevo anuncio');
      } catch (e) {
        Navigator.of(context).pop(); // Dismiss the loader
        Utils.debugPrint("Error: $e");
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
          'Añadir anuncio',
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
              Semantics(
                label: 'Campo de texto para título del anuncio',
                hint: 'Ingrese el título del anuncio',
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    icon: Icon(
                      Icons.document_scanner,
                      semanticLabel: 'Título del anuncio',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              Semantics(
                label: 'Campo de texto para correo electrónico',
                hint: 'Ingrese su correo electrónico',
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    icon: Icon(
                      Icons.mail,
                      semanticLabel: 'Correo electrónico',
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return 'Por favor provea una dirección de email válida';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 16.0),
              Semantics(
                label: 'Selector de edificio',
                hint: 'Seleccione el edificio',
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Edificio',
                    icon: Icon(
                      Icons.business,
                      semanticLabel: 'Seleccionar edificio',
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
              ),
              const SizedBox(height: 16.0),
              Semantics(
                label: 'Campo de texto para número de celular',
                hint: 'Ingrese su número de celular',
                child: TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Celular',
                    icon: Icon(
                      Icons.phone,
                      semanticLabel: 'Número de celular',
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !RegExp(r'^[0-9]*$').hasMatch(value)) {
                      return 'Por favor provea un número válido';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Semantics(
                    label: 'Contactar por WhatsApp',
                    child: Checkbox(
                      value: _whatsapp,
                      onChanged: (value) {
                        setState(() {
                          _whatsapp = value!;
                        });
                      },
                    ),
                  ),
                  const Text('¿Te pueden contactar por WhatsApp?'),
                ],
              ),
              const SizedBox(height: 16.0),
              Semantics(
                label: 'Campo de texto para descripción del anuncio',
                hint: 'Ingrese la descripción del anuncio',
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    icon: Icon(
                      Icons.description,
                      semanticLabel: 'Descripción del anuncio',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              Semantics(
                label: 'Botón para seleccionar archivo',
                hint: 'Presione para seleccionar un archivo adjunto',
                child: ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(
                    Icons.attach_file,
                    semanticLabel: 'Seleccionar archivo',
                  ),
                  label: const Text('Seleccionar archivo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Semantics(
                label: 'Archivos adjuntos',
                hint: 'Lista de archivos adjuntos seleccionados',
                child: Wrap(
                  children: _fileNames.map((fileName) {
                    int index = _fileNames.indexOf(fileName);
                    return Semantics(
                      label: 'Archivo adjunto: $fileName',
                      hint: 'Toque dos veces para eliminar este archivo',
                      child: Chip(
                        label: Text(fileName),
                        deleteIcon: const Icon(Icons.close),
                        onDeleted: () => _removeFile(index),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Botón para añadir anuncio',
                hint: 'Presione para añadir el anuncio',
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(
                    Icons.check,
                    color: Colors.white,
                    semanticLabel: 'Añadir anuncio',
                  ),
                  label: const Text('Añadir anuncio'),
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
