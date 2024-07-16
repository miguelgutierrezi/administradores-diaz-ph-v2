import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import '../services/shared_preferences_service.dart';
import '../utils/utils.dart';

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
  final DateTime _visitDate = DateTime.now();
  UserRole? _userRole;
  String? _userName;
  String? _userId;
  List<String>? _adminBuildings;
  List<PlatformFile> files = [];
  List<String> fileNames = [];
  List<String> fileLinks = [];

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
      _zones = List<String>.from(building['zones'])
          .map((zone) => {
                'nombre': zone,
                'novedad': 'sin novedad',
                'observacion': '',
                'filesNames': [],
                'files': []
              })
          .toList();
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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
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

  Future<void> _saveVisit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      _showLoadingDialog();

      try {
        final visitData = await _prepareVisitData();
        final visitRef =
            await _firestoreService.createDocument('visits', visitData);

        final updatedZones = await _uploadZoneFilesAndUpdateZones(visitRef.id);
        await _updateVisitDocument(visitRef.id, visitData, updatedZones);

        final updatedVisitData = {
          ...visitData,
          'zones': updatedZones,
        };

        // Generar y subir el PDF
        await _generateAndUploadPdf(visitRef.id, updatedVisitData);

        Navigator.of(context).pop(); // Dismiss the loader

        // Navigate back to the visits list page before showing the dialog
        Navigator.pop(context);

        // Show the dialog for downloading the PDF
        _showPdfDownloadDialog(visitRef.id);
      } catch (e) {
        Navigator.of(context).pop(); // Dismiss the loader
        Utils.debugPrint("Error: $e");
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<Map<String, dynamic>> _prepareVisitData() async {
    String userId = _userId!;
    String userName = _userName!;
    String selectedBuilding = _selectedBuilding!;
    DateTime visitDate = _visitDate;

    final filteredZones = _zones.map((zone) {
      final newZone = Map<String, dynamic>.from(zone);
      newZone.remove('files');
      newZone.remove('filesNames');
      newZone.remove('filesLinks');
      return newZone;
    }).toList();

    return {
      'date': Timestamp.fromDate(visitDate), // Convertir a Timestamp
      'edificio': selectedBuilding,
      'user': userId,
      'name': userName,
      'zones': filteredZones,
    };
  }

  Future<List<Map<String, dynamic>>> _uploadZoneFilesAndUpdateZones(
      String visitId) async {
    return await Future.wait(_zones.map((zone) async {
      final newZone = Map<String, dynamic>.from(zone);
      List<String> fileLinks = [];
      for (var file in zone['files']) {
        String imageUrl =
            await _firestoreService.uploadFile('visits', visitId, file.path!);
        fileLinks.add(imageUrl);
      }
      newZone['filesLinks'] = fileLinks;
      newZone['filesNames'] = List<String>.from(zone['filesNames']);
      newZone.remove('files');
      return newZone;
    }).toList());
  }

  Future<void> _updateVisitDocument(
      String visitId,
      Map<String, dynamic> visitData,
      List<Map<String, dynamic>> updatedZones) async {
    final dataUp = {
      ...visitData,
      'zones': updatedZones,
    };

    await FirebaseFirestore.instance
        .collection('visits')
        .doc(visitId)
        .update(dataUp);
  }

  Future<void> _generateAndUploadPdf(
      String visitId, Map<String, dynamic> visitData) async {
    final PdfService pdfService = PdfService();
    await pdfService.generateAndUploadPdf(visitId, visitData);
  }

  void _showPdfDownloadDialog(String visitId) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Visita añadida'),
          content: const Text(
            '¿Quiere descargar el PDF generado? Lo podrá ver luego en el detalle de la visita.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () async {
                DocumentSnapshot visitDoc = await FirebaseFirestore.instance
                    .collection('visits')
                    .doc(visitId)
                    .get();
                String pdfUrl = visitDoc['pdfUrl'];
                launchUrl(Uri.parse(pdfUrl));
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
          'Registrar visita',
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
                      _selectedBuilding = value;
                      _findZones();
                    });
                  },
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
                label: 'Botón para buscar zonas',
                hint:
                    'Presione para buscar las zonas del edificio seleccionado',
                child: ElevatedButton.icon(
                  onPressed: _findZones,
                  icon: const Icon(
                    Icons.search,
                    semanticLabel: 'Buscar zonas',
                  ),
                  label: const Text('Buscar zonas'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    textStyle: const TextStyle(fontSize: 18),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._zones.map((zone) {
                int index = _zones.indexOf(zone);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Divider(),
                    ListTile(
                      title: Text(
                        zone['nombre'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: RadioListTile(
                              title: const Text('Sin novedad'),
                              value: 'sin novedad',
                              groupValue: zone['novedad'],
                              onChanged: (value) {
                                _changeValue(value.toString(), index);
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile(
                              title: const Text('Con novedad'),
                              value: 'con novedad',
                              groupValue: zone['novedad'],
                              onChanged: (value) {
                                _changeValue(value.toString(), index);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (zone['novedad'] == 'con novedad')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Semantics(
                          label: 'Campo de texto para observaciones',
                          hint: 'Ingrese observaciones sobre la novedad',
                          child: TextField(
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Observaciones',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              _addObservation(value, index);
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Botón para seleccionar archivo',
                      hint: 'Presione para seleccionar un archivo adjunto',
                      child: ElevatedButton.icon(
                        onPressed: () => _pickFile(index),
                        icon: const Icon(
                          Icons.attach_file,
                          semanticLabel: 'Seleccionar archivo',
                        ),
                        label: const Text('Seleccionar archivo'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    ...zone['filesNames'].map<Widget>((fileName) {
                      int fileIndex = zone['filesNames'].indexOf(fileName);
                      return ListTile(
                        title: Text(fileName),
                        trailing: Semantics(
                          label: 'Botón para eliminar archivo',
                          hint: 'Presione para eliminar este archivo',
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removeFile(fileIndex, index);
                            },
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              }),
              const SizedBox(height: 16),
              Semantics(
                label: 'Botón para registrar visita',
                hint: 'Presione para registrar la visita',
                child: ElevatedButton.icon(
                  onPressed: _saveVisit,
                  icon: const Icon(
                    Icons.check,
                    semanticLabel: 'Registrar visita',
                  ),
                  label: const Text('Registrar visita'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
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
