import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/shared_preferences_service.dart';
import '../utils/utils.dart';

class AddBuildingPage extends StatefulWidget {
  const AddBuildingPage({super.key});

  @override
  _AddBuildingPageState createState() => _AddBuildingPageState();
}

class _AddBuildingPageState extends State<AddBuildingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  List<String> _zones = [];
  PlatformFile? _selectedFile;
  String? _imageUrl;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _selectedFileName = _selectedFile!.name;
      });
      Utils.debugPrint('Archivo seleccionado: $_selectedFileName');
    } else {
      setState(() {
        _selectedFile = null;
        _selectedFileName = null;
      });
      Utils.debugPrint('No se seleccionó ningún archivo');
    }
  }

  Future<void> _removeZone(int index) async {
    setState(() {
      _zones.removeAt(index);
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
          'direccion': _direccionController.text,
          'descripcion': _descripcionController.text,
          'zones': _zones,
        };

        DocumentReference buildingRef =
            await _firestoreService.createDocument('buildings', data);

        if (_selectedFile != null) {
          _imageUrl = await _firestoreService.uploadFile(
              'buildings', buildingRef.id, _selectedFile!.path!);
        }

        final dataUp = {
          'imageUrl': _imageUrl,
          'imageName': _selectedFile?.name,
        };

        await _firestoreService.updateDocument(
            'buildings', buildingRef.id, dataUp);

        Navigator.of(context).pop(); // Dismiss the loader
        _showAlert('Edificio agregado', 'Se ha creado un nuevo edificio');
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
          'Añadir edificio',
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
                label: 'Campo de texto para el nombre del edificio',
                hint: 'Ingrese el nombre del edificio',
                child: TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    icon: Icon(
                      Icons.document_scanner,
                      semanticLabel: 'Nombre del edificio',
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
                label: 'Campo de texto para la dirección del edificio',
                hint: 'Ingrese la dirección del edificio',
                child: TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    icon: Icon(
                      Icons.location_on,
                      semanticLabel: 'Dirección del edificio',
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
                label: 'Campo de texto para la descripción del edificio',
                hint: 'Ingrese la descripción del edificio',
                child: TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    icon: Icon(
                      Icons.description,
                      semanticLabel: 'Descripción del edificio',
                    ),
                  ),
                  maxLines: 5,
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
                label: 'Campo de texto para añadir espacios de reporte',
                hint:
                    'Ingrese el nombre del espacio de reporte y presione enter',
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Espacios de reporte',
                    icon: Icon(
                      Icons.business,
                      semanticLabel: 'Añadir espacios de reporte',
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    setState(() {
                      _zones.add(value);
                    });
                  },
                ),
              ),
              Wrap(
                children: _zones.map((zone) {
                  int index = _zones.indexOf(zone);
                  return Semantics(
                    label: 'Zona: $zone',
                    hint:
                        'Toque dos veces para eliminar este espacio de reporte',
                    child: Chip(
                      label: Text(zone),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => _removeZone(index),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0),
              Semantics(
                label: 'Botón para seleccionar una imagen',
                hint: 'Presione para seleccionar una imagen',
                child: ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(
                    Icons.attach_file,
                    semanticLabel: 'Seleccionar imagen',
                  ),
                  label: const Text('Seleccionar imagen'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (_selectedFileName != null) ...[
                const SizedBox(height: 8.0),
                Text('Archivo seleccionado: $_selectedFileName'),
              ],
              const SizedBox(height: 20),
              Semantics(
                label: 'Botón para añadir edificio',
                hint: 'Presione para añadir el edificio',
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(
                    Icons.check,
                    color: Colors.white,
                    semanticLabel: 'Añadir edificio',
                  ),
                  label: const Text('Añadir edificio'),
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
