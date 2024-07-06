import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class EditBuildingPage extends StatefulWidget {
  final Map<String, dynamic> building;
  final String buildingId;

  const EditBuildingPage(
      {required this.building, required this.buildingId, super.key});

  @override
  _EditBuildingPageState createState() => _EditBuildingPageState();
}

class _EditBuildingPageState extends State<EditBuildingPage> {
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _zoneController = TextEditingController();
  bool _isLoading = false;

  final Map<String, dynamic> _updatedBuilding = {
    'nombre': '',
    'direccion': '',
    'descripcion': '',
    'imageUrl': '',
    'imageName': '',
    'zones': []
  };

  @override
  void initState() {
    super.initState();
    _loadBuildingData();
  }

  Future<void> _loadBuildingData() async {
    setState(() {
      _isLoading = true;
    });

    setState(() {
      _updatedBuilding['nombre'] = widget.building['nombre'];
      _updatedBuilding['direccion'] = widget.building['direccion'];
      _updatedBuilding['descripcion'] = widget.building['descripcion'];
      _updatedBuilding['imageName'] = widget.building['imageName'];
      _updatedBuilding['imageUrl'] = widget.building['imageUrl'];
      _updatedBuilding['zones'] = List<String>.from(widget.building['zones']);
      _isLoading = false;
    });
  }

  void _addZone() {
    setState(() {
      _updatedBuilding['zones'].add(_zoneController.text);
      _zoneController.clear();
    });
  }

  void _removeZone(int index) {
    setState(() {
      _updatedBuilding['zones'].removeAt(index);
    });
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _firestoreService.updateDocument(
          'buildings', widget.buildingId, _updatedBuilding);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edificio actualizado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _updatedBuilding['nombre'],
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
                    Semantics(
                      label: 'Imagen del edificio',
                      child: Image.network(
                        _updatedBuilding['imageUrl'] ??
                            'https://cdn-icons-png.flaticon.com/512/85/85488.png',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.network(
                            'https://cdn-icons-png.flaticon.com/512/85/85488.png',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _updatedBuilding['nombre'],
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        icon: Icon(
                          Icons.document_scanner,
                          semanticLabel: 'Nombre del edificio',
                        ),
                      ),
                      onSaved: (value) {
                        _updatedBuilding['nombre'] = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _updatedBuilding['direccion'],
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        icon: Icon(
                          Icons.location_on,
                          semanticLabel: 'Dirección del edificio',
                        ),
                      ),
                      onSaved: (value) {
                        _updatedBuilding['direccion'] = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _updatedBuilding['descripcion'],
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        icon: Icon(
                          Icons.description,
                          semanticLabel: 'Descripción del edificio',
                        ),
                      ),
                      maxLines: 3,
                      onSaved: (value) {
                        _updatedBuilding['descripcion'] = value!;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Espacios asociados:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._updatedBuilding['zones'].map<Widget>((zone) {
                      int index = _updatedBuilding['zones'].indexOf(zone);
                      return ListTile(
                        title: Text(zone),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                            semanticLabel: 'Eliminar zona',
                          ),
                          onPressed: () => _removeZone(index),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _zoneController,
                            decoration: const InputDecoration(
                              labelText: 'Añadir zona',
                              icon: Icon(
                                Icons.add,
                                semanticLabel: 'Añadir zona',
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.black,
                            semanticLabel: 'Añadir zona',
                          ),
                          onPressed: _addZone,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _onSave,
                      icon: const Icon(
                        Icons.check,
                        semanticLabel: 'Guardar',
                      ),
                      label: const Text('Guardar edificio'),
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
