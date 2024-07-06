import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/utils.dart';

class AddComplaintPage extends StatefulWidget {
  const AddComplaintPage({super.key});

  @override
  _AddComplaintPageState createState() => _AddComplaintPageState();
}

class _AddComplaintPageState extends State<AddComplaintPage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _firestoreService = FirestoreService();
  String? _nombre;
  String? _edificio;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nombre = prefs.getString('nombre');
      _edificio = prefs.getString('edificio');
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      try {
        final data = {
          'correo': FirebaseAuth.instance.currentUser?.email,
          'nombre': _nombre,
          'edificio': _edificio,
          'descripcion': _descripcionController.text,
          'leido': false,
        };

        await _firestoreService.createDocument('complaints', data);

        Navigator.pop(context); // Dismiss the loading dialog
        _showAlert(context, 'Queja enviada', 'Se ha enviado la queja');
      } catch (e) {
        Navigator.pop(context); // Dismiss the loading dialog
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
          'Añadir queja',
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
              if (_nombre != null)
                Text(
                  'Hola $_nombre',
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  icon: Icon(
                    Icons.description,
                    semanticLabel: 'Descripción de la queja',
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
                  Icons.add,
                  color: Colors.white,
                  semanticLabel: 'Añadir queja',
                ),
                label: const Text('Añadir queja'),
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
