import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/user_role.dart';

class AddBillPage extends StatefulWidget {
  const AddBillPage({super.key});

  @override
  _AddBillPageState createState() => _AddBillPageState();
}

class _AddBillPageState extends State<AddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _sharedPreferencesService = SharedPreferencesService();

  final List<String> _monthsList = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  final int _currentYear = DateTime.now().year;
  List<int> _yearsList = [];
  List<Map<String, dynamic>> _buildings = [];
  String? _selectedMonth;
  int? _selectedYear;
  String? _selectedBuilding;
  String? _numeroApto;
  PlatformFile? _file;
  PlatformFile? _accountStatus;
  String? _fileName;
  String? _accountStatusName;

  @override
  void initState() {
    super.initState();
    _yearsList = [_currentYear - 1, _currentYear, _currentYear + 1];
    _selectedYear = _currentYear;
    _selectedMonth = _monthsList[0];
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    List<Map<String, dynamic>> buildings = await _firestoreService.getCollection('buildings');
    UserRole? role = await _authService.getCurrentUserRole();

    if (role == UserRole.superadmin) {
      setState(() {
        _buildings = buildings;
      });
    } else if (role == UserRole.admin) {
      List<String>? adminBuildings = await _sharedPreferencesService.getDynamicList('edificio');
      setState(() {
        _buildings = buildings
            .where((building) => adminBuildings.contains(building['nombre'].toString()))
            .toList();
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _file = result.files.first;
        _fileName = _file!.name;
      });
    }
  }

  Future<void> _pickFileAccountStatus() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _accountStatus = result.files.first;
        _accountStatusName = _accountStatus!.name;
      });
    }
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
        final buildingKey = _buildings.firstWhere(
            (building) => building['nombre'] == _selectedBuilding)['id'];

        final data = {
          'anho': _selectedYear,
          'mes': _selectedMonth,
          'edificio': _selectedBuilding,
          'numeroApto': _numeroApto,
        };

        DocumentReference billRef = await _firestoreService.createDocument(
          'bills',
          {'buildingId': buildingKey, ...data},
        );

        final fileUrl = await _firestoreService.uploadFile(
          'bills',
          billRef.id,
          _file!.path!,
        );

        final statusUrl = _accountStatus != null
            ? await _firestoreService.uploadFile(
                'bills',
                billRef.id,
                _accountStatus!.path!,
              )
            : '';

        final billData = {
          ...data,
          'fileUrl': fileUrl,
          'statusUrl': statusUrl,
          'fileName': _fileName,
          'accountStatusName': _accountStatusName,
        };

        await _firestoreService.updateDocument('bills', billRef.id, billData);

        Navigator.of(context).pop(); // Dismiss the loader
        _showAlert(
            context, 'Factura agregada', 'Se ha agregado una nueva factura');
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
          'Agregar factura',
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        icon: Icon(Icons.calendar_today),
                      ),
                      items: _yearsList.map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                      value: _selectedYear,
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un año';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                        icon: Icon(Icons.calendar_today),
                      ),
                      items: _monthsList.map((month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      },
                      value: _selectedMonth,
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un mes';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Edificio',
                  icon: Icon(Icons.business),
                ),
                items: _buildings.map((building) {
                  return DropdownMenuItem<String>(
                    value: building['nombre'],
                    child: Text(building['nombre']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBuilding = value;
                  });
                },
                value: _selectedBuilding,
                validator: (value) {
                  if (value == null) {
                    return 'Seleccione un edificio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Número apartamento',
                  icon: Icon(Icons.home),
                ),
                onSaved: (value) {
                  _numeroApto = value;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Seleccionar factura'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                _fileName != null ? _fileName! : 'Ningún archivo seleccionado',
                style: const TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: _pickFileAccountStatus,
                icon: const Icon(Icons.attach_file),
                label: const Text('Seleccionar estado de cuenta'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                _accountStatusName != null
                    ? _accountStatusName!
                    : 'Ningún archivo seleccionado',
                style: const TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      _file != null &&
                      _file!.path != null) {
                    _submitForm();
                  }
                },
                icon: const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
                label: const Text('Agregar factura'),
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
