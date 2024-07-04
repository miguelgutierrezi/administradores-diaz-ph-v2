import 'package:administradores_diaz_ph/home_page.dart';
import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddAdminPage extends StatefulWidget {
  const AddAdminPage({super.key});

  @override
  _AddAdminPageState createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final List<String> _edificios = [];
  final List<String> _selectedEdificios = [];
  String _selectedEdificio = '';
  bool _isButtonDisabled = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    List<Map<String, dynamic>> buildingsData =
        await _firestoreService.getCollection('buildings');
    setState(() {
      _edificios.addAll(buildingsData.map((data) => data['nombre'].toString()));
    });
  }

  void _validateForm() {
    setState(() {
      _isButtonDisabled = !_formKey.currentState!.validate();
    });
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor ingrese un email válido';
    }
    return null;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _showLoader(context);
      try {
        User? user = await _authService.registerWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        if (user != null) {
          Map<String, dynamic> userData = {
            'nombre': _nameController.text,
            'edificio': _selectedEdificios,
            'rol': 'ADMINISTRADOR',
            'email': _emailController.text,
          };
          await _firestoreService.addData(user.uid, userData);
          Navigator.pop(context); // Close loader
          _showAlert(context, 'Administrador agregado',
              'Se ha añadido al administrador ${_emailController.text}');
        }
      } catch (e) {
        Navigator.pop(context); // Close loader in case of an error
        setState(() {
          _errorMessage = e.toString();
        });
        _showErrorDialog(context, 'Error', _errorMessage);
      }
    }
  }

  Future<void> _showAlert(
      BuildContext context, String title, String message) async {
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showErrorDialog(
      BuildContext context, String title, String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
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

  Future<void> _showLoader(BuildContext context) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Cargando..."),
              ],
            ),
          ),
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
          'Crear administrador',
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
          onChanged: _validateForm,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  icon: Icon(Icons.email),
                ),
                validator: _emailValidator,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  icon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombres y apellidos',
                  icon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Edificio',
                  icon: Icon(Icons.location_city),
                ),
                items: _edificios.map((building) {
                  return DropdownMenuItem<String>(
                    value: building,
                    child: Text(building),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEdificio = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo requerido';
                  }
                  return null;
                },
              ),
              Wrap(
                spacing: 8.0,
                children: _selectedEdificios.map((edificio) {
                  return Chip(
                    label: Text(edificio),
                    onDeleted: () {
                      setState(() {
                        _selectedEdificios.remove(edificio);
                      });
                    },
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_selectedEdificio.isNotEmpty &&
                      !_selectedEdificios.contains(_selectedEdificio)) {
                    setState(() {
                      _selectedEdificios.add(_selectedEdificio);
                    });
                  }
                },
                child: const Text('Añadir edificio'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isButtonDisabled ? null : _register,
                icon: const Icon(Icons.login),
                label: const Text('Registrar administrador'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
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
