import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<String> _buildings = [];
  String _selectedBuilding = '';
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
      _buildings =
          buildingsData.map((data) => data['nombre'].toString()).toList();
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
    // Validación simple de correo electrónico
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor ingrese un email valido';
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
            'edificio': _selectedBuilding,
            'rol': 'CLIENTE',
            'email': _emailController.text,
            'numeroApto': _apartmentController.text,
          };
          await _firestoreService.addData(user.uid, userData);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('correo', _emailController.text);
          prefs.setString('id', user.uid);
          prefs.setString('edificio', _selectedBuilding);
          prefs.setString('rol', 'CLIENTE');
          prefs.setString('nombre', _nameController.text);
          prefs.setString('numeroApto', _apartmentController.text);
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const HomePage()));
        } // Dismiss the loader
      } catch (e) {
        Navigator.of(context).pop(); // Dismiss the loader in case of an error
        setState(() {
          _errorMessage = e.toString();
        });
        showErrorDialog(context, 'Error', _errorMessage);
      }
    }
  }

  Future<void> showErrorDialog(
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
          'Registrarse',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            semanticLabel: 'Volver',
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
              Semantics(
                label: 'Campo de texto de email',
                hint: 'Ingrese su email',
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    icon:
                        Icon(Icons.email, semanticLabel: 'Correo electrónico'),
                  ),
                  validator: _emailValidator,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              Semantics(
                label: 'Campo de texto de contraseña',
                hint: 'Ingrese su contraseña',
                child: TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    icon: Icon(Icons.lock, semanticLabel: 'Contraseña'),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.visiblePassword,
                ),
              ),
              Semantics(
                label: 'Campo de texto de nombres y apellidos',
                hint: 'Ingrese sus nombres y apellidos',
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombres y apellidos',
                    icon: Icon(Icons.person, semanticLabel: 'Nombre completo'),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
              ),
              Semantics(
                label: 'Selector de edificio',
                hint: 'Seleccione su edificio',
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Edificio',
                    icon: Icon(Icons.location_city, semanticLabel: 'Edificio'),
                  ),
                  items: _buildings
                      .map((building) => DropdownMenuItem(
                            value: building,
                            child: Text(building),
                          ))
                      .toList(),
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
              Semantics(
                label: 'Campo de texto de número de apartamento',
                hint: 'Ingrese su número de apartamento',
                child: TextFormField(
                  controller: _apartmentController,
                  decoration: const InputDecoration(
                    labelText: 'Número apartamento',
                    icon: Icon(Icons.home,
                        semanticLabel: 'Número de apartamento'),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Botón de registro',
                hint: 'Presione para registrar al cliente',
                child: ElevatedButton.icon(
                  onPressed: _isButtonDisabled ? null : _register,
                  icon: const Icon(Icons.login, semanticLabel: 'Registrar'),
                  label: const Text('Registrar cliente'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
