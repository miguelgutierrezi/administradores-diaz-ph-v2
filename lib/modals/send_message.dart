import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home_page.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

class SendMessagePage extends StatefulWidget {
  @override
  _SendMessagePageState createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage> {
  final _formKey = GlobalKey<FormState>();
  final _asuntoController = TextEditingController();
  final _messageController = TextEditingController();
  final _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  UserRole? _role;
  List<Map<String, String>> _recipients = [];
  Map<String, String> _selectedRecipient = {};
  PlatformFile? _pickedFile;
  String? _userId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _asuntoController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    List<Map<String, dynamic>> usersData =
        await _firestoreService.getCollection('users');
    usersData.sort(
        (a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()));
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    setState(() {
      _recipients = usersData
          .where((data) => data['id'] != currentUserId)
          .map((data) =>
              {'id': data['id'] as String, 'nombre': data['nombre'] as String})
          .toList();
    });
  }

  Future<void> _loadUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UserRole? userRole = await _authService.getCurrentUserRole();
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    String? userName = prefs.getString('nombre');
    setState(() {
      _role = userRole;
      _userId = userId;
      _userName = userName;
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
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
          'asunto': _asuntoController.text,
          'message': _messageController.text,
          'to': _selectedRecipient['nombre'],
          'from': _userName,
          'read': false,
          'imageName': _pickedFile?.name,
          'imageUrl': _pickedFile != null
              ? await _firestoreService.uploadFile(
                  'messages', _userId!, _pickedFile!.path!)
              : null,
        };

        // Actualizar el usuario remitente
        DocumentSnapshot currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();
        List sentMessages = currentUserDoc['enviados'] ?? [];
        sentMessages.add(data);

        await _firestoreService
            .updateDocument('users', _userId!, {'enviados': sentMessages});

        // Actualizar el usuario receptor
        DocumentSnapshot receiverUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_selectedRecipient['id'])
            .get();
        List receivedMessages = receiverUserDoc['recibidos'] ?? [];
        receivedMessages.add(data);

        await _firestoreService.updateDocument('users',
            _selectedRecipient['id']!, {'recibidos': receivedMessages});

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        _showAlert(context, 'Mensaje enviado',
            'El mensaje ha sido enviado exitosamente');
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
          'Enviar mensaje',
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
              DropdownButtonFormField<Map<String, String>>(
                decoration: const InputDecoration(
                  labelText: 'Para',
                  icon: Icon(Icons.person_outline),
                ),
                items: _recipients.map((recipient) {
                  return DropdownMenuItem<Map<String, String>>(
                    value: recipient,
                    child: Text(recipient['nombre']!,
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRecipient = value!;
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
                controller: _asuntoController,
                decoration: const InputDecoration(
                  labelText: 'Asunto',
                  icon: Icon(Icons.send),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el asunto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  icon: Icon(Icons.message),
                ),
                maxLines: 5, // Aumenta el número de líneas visibles
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el mensaje';
                  }
                  return null;
                },
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
                  Icons.send,
                  color: Colors.white,
                ),
                label: const Text('Enviar mensaje'),
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
