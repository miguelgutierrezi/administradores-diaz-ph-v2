import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AddClientPage extends StatefulWidget {
  const AddClientPage({super.key});

  @override
  _AddClientPageState createState() => _AddClientPageState();
}

class _AddClientPageState extends State<AddClientPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();

  List<String> _buildings = [];
  List<String> _adminBuildings = [];
  String _selectedBuilding = '';
  bool _isButtonDisabled = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    UserRole? userRole = await _authService.getCurrentUserRole();

    if (userRole == UserRole.admin) {
      _adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
      setState(() {
        _buildings = _adminBuildings;
      });
    } else {
      List<Map<String, dynamic>> buildingsData =
          await _firestoreService.getCollection('buildings');
      setState(() {
        _buildings =
            buildingsData.map((data) => data['nombre'].toString()).toList();
      });
    }
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
            'edificio': _selectedBuilding,
            'rol': 'CLIENTE',
            'email': _emailController.text,
            'numeroApto': _apartmentController.text,
          };
          await _firestoreService.addData(user.uid, userData);
          Navigator.pop(context); // Close loader
          _showAlert(context, 'Cliente agregado',
              'Se ha añadido al cliente ${_emailController.text}');
        }
      } catch (e) {
        Navigator.of(context).pop();
        setState(() {
          _errorMessage = e.toString();
        });
        showErrorDialog(context, 'Error', _errorMessage);
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
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
          'Crear cliente',
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
          onChanged: _validateForm,
          child: ListView(
            children: <Widget>[
              Semantics(
                label: 'Campo de texto para correo electrónico',
                hint: 'Ingrese su correo electrónico',
                child: TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    icon: Icon(
                      Icons.email,
                      semanticLabel: 'Correo electrónico',
                    ),
                  ),
                  validator: _emailValidator,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              Semantics(
                label: 'Campo de texto para contraseña',
                hint: 'Ingrese su contraseña',
                child: TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    icon: Icon(
                      Icons.lock,
                      semanticLabel: 'Contraseña',
                    ),
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
                label: 'Campo de texto para nombres y apellidos',
                hint: 'Ingrese sus nombres y apellidos',
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombres y apellidos',
                    icon: Icon(
                      Icons.person,
                      semanticLabel: 'Nombres y apellidos',
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
              Semantics(
                label: 'Selector de edificio',
                hint: 'Seleccione el edificio',
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Edificio',
                    icon: Icon(
                      Icons.location_city,
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
              Semantics(
                label: 'Campo de texto para número de apartamento',
                hint: 'Ingrese su número de apartamento',
                child: TextFormField(
                  controller: _apartmentController,
                  decoration: const InputDecoration(
                    labelText: 'Número apartamento',
                    icon: Icon(
                      Icons.home,
                      semanticLabel: 'Número de apartamento',
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
              const SizedBox(height: 20),
              Semantics(
                label: 'Botón para registrar cliente',
                hint: 'Presione para registrar el cliente',
                child: ElevatedButton.icon(
                  onPressed: _isButtonDisabled ? null : _register,
                  icon: const Icon(
                    Icons.login,
                    semanticLabel: 'Registrar cliente',
                  ),
                  label: const Text('Registrar cliente'),
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
