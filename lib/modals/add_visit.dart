import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/shared_preferences_service.dart';

class AddVisitPage extends StatefulWidget {
  const AddVisitPage({super.key});

  @override
  _AddVisitPageState createState() => _AddVisitPageState();
}

class _AddVisitPageState extends State<AddVisitPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  final AuthService _authService = AuthService();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  List<Map<String, dynamic>> _zones = [];
  final List<String> _buildings = [];
  final _formKey = GlobalKey<FormState>();
  String? _selectedBuilding;
  DateTime _visitDate = DateTime.now();
  UserRole? _userRole;
  String? _userName;
  String? _userId;
  List<String>? _adminBuildings;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userRole = await _authService.getCurrentUserRole();
    _userName = prefs.getString('nombre');
    _userId = prefs.getString('id');
    if (_userRole == UserRole.superadmin) {
      List<Map<String, dynamic>> buildings =
          await _firestoreService.getCollection('buildings');
      setState(() {
        _buildings.addAll(buildings.map((building) => building['nombre']));
      });
    } else if (_userRole == UserRole.admin) {
      _adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
      List<Map<String, dynamic>> buildings =
          await _firestoreService.getCollection('buildings');
      setState(() {
        _buildings.addAll(buildings
            .where((building) =>
                _adminBuildings!.contains(building['nombre'].toString()))
            .map((building) => building['nombre']));
      });
    }
  }

  Future<void> _findZones() async {
    if (_selectedBuilding == null) return;
    List<Map<String, dynamic>> buildings =
        await _firestoreService.getCollection('buildings');
    Map<String, dynamic> building =
        buildings.firstWhere((b) => b['nombre'] == _selectedBuilding);
    setState(() {
      _zones = List<Map<String, dynamic>>.from(building['zones']);
    });
  }

  void _changeValue(String value, int index) {
    setState(() {
      _zones[index]['novedad'] = value;
      if (value == 'sin novedad') {
        _zones[index]['observacion'] = '';
      }
    });
  }

  void _addObservation(String value, int index) {
    setState(() {
      _zones[index]['observacion'] = value;
    });
  }

  Future<void> _pickFile(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _zones[index]['files'].add(result.files.first);
        _zones[index]['filesNames'].add(result.files.first.name);
      });
    }
  }

  void _removeFile(int fileIndex, int zoneIndex) {
    setState(() {
      _zones[zoneIndex]['files'].removeAt(fileIndex);
      _zones[zoneIndex]['filesNames'].removeAt(fileIndex);
    });
  }

  Future<Uint8List> _downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download file');
    }
  }

  Future<void> _generateAndUploadPdf(String visitId) async {
    final pdf = pw.Document();

    List<pw.Widget> zoneWidgets = [];

    for (var zone in _zones) {
      List<pw.Widget> widgets = [
        pw.Text('Zona: ${zone['nombre']}',
            style: const pw.TextStyle(fontSize: 18)),
        pw.Text('Novedad: ${zone['novedad']}'),
        pw.Text('Observaciones: ${zone['observacion']}'),
        pw.SizedBox(height: 10),
      ];

      for (var fileLink in zone['filesLinks']) {
        final imageData = await _downloadFile(fileLink);
        widgets.add(pw.Image(pw.MemoryImage(imageData)));
      }

      widgets.add(pw.SizedBox(height: 20));
      zoneWidgets.add(pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets));
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text('Reporte de Visita',
                style: const pw.TextStyle(fontSize: 24)),
            pw.Text('Edificio: $_selectedBuilding'),
            pw.Text('Fecha: ${_dateFormat.format(_visitDate)}'),
            pw.Text('Usuario: $_userName'),
            pw.SizedBox(height: 20),
            ...zoneWidgets,
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    String pdfUrl =
        await _firestoreService.uploadPdf('visits', '$visitId.pdf', pdfBytes);
    await _firestoreService
        .updateDocument('visits', visitId, {'fileUrl': pdfUrl});
  }

  void _showPdfAlert(String visitId) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Visita añadida'),
          content: const Text(
            '¿Quiere visualizar el reporte generado en PDF? Lo podrá consultar luego en la lista de visitas.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () async {
                Navigator.of(context).pop();
                DocumentSnapshot visitDoc = await _firestoreService
                    .getDocumentSnapshot('visits', visitId);
                String pdfUrl = visitDoc['fileUrl'];
                launchUrl(Uri.parse(pdfUrl));
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveVisit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      String userId = _userId!;
      String userName = _userName!;
      String selectedBuilding = _selectedBuilding!;
      DateTime visitDate = _visitDate;

      final data = {
        'date': visitDate,
        'edificio': selectedBuilding,
        'user': userId,
        'name': userName,
        'zones': _zones,
      };

      DocumentReference visitRef =
          await _firestoreService.createDocument('visits', data);
      await _generateAndUploadPdf(visitRef.id);
      _showPdfAlert(visitRef.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Registrar visita',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              ListTile(
                title:
                    Text('Fecha de visita: ${_dateFormat.format(_visitDate)}'),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Edificio',
                  icon: Icon(Icons.business),
                ),
                items: _buildings.map((building) {
                  return DropdownMenuItem<String>(
                    value: building,
                    child: Text(building),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBuilding = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleccione un edificio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _findZones,
                icon: const Icon(Icons.search),
                label: const Text('Buscar zonas'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ..._zones.map((zone) {
                int index = _zones.indexOf(zone);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                      title: Text(zone['nombre']),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: RadioListTile(
                              title: const Text('Sin novedad'),
                              value: 'sin novedad',
                              groupValue: zone['novedad'],
                              onChanged: (value) {
                                setState(() {
                                  _zones[index]['novedad'] = value;
                                  if (value == 'sin novedad') {
                                    _zones[index]['observacion'] = '';
                                  }
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile(
                              title: const Text('Con novedad'),
                              value: 'con novedad',
                              groupValue: zone['novedad'],
                              onChanged: (value) {
                                setState(() {
                                  _zones[index]['novedad'] = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (zone['novedad'] == 'con novedad')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Observaciones',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _zones[index]['observacion'] = value;
                            });
                          },
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _pickFile(index),
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Seleccionar archivo'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                    ...zone['filesNames'].map<Widget>((fileName) {
                      int fileIndex = zone['filesNames'].indexOf(fileName);
                      return ListTile(
                        title: Text(fileName),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _removeFile(fileIndex, index);
                          },
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                );
              }),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveVisit,
                icon: const Icon(Icons.check),
                label: const Text('Registrar visita'),
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
