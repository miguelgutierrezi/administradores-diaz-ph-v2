import 'package:administradores_diaz_ph/register_page.dart';
import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/firestore_service.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:administradores_diaz_ph/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _sharedPreferencesService = SharedPreferencesService();

  bool _isButtonEnabled = false;

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su contraseña';
    }
    return null;
  }

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        User? user = await _authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        if (user != null) {
          await _storeUserData(user);
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()));
        }
      } catch (e) {
        Utils.debugPrint(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al iniciar sesión')),
        );
      }
    }
  }

  Future<void> _storeUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('correo', user.email ?? '');
    prefs.setString('id', _authService.getCurrentUserId());

    List<Map<String, dynamic>> users =
        await _firestoreService.getCollection('users');

    for (var userData in users) {
      if (userData['id'] == _authService.getCurrentUserId()) {
        if (userData['rol'] == 'CLIENTE') {
          prefs.setString('edificio', userData['edificio'] ?? '');
        } else {
          _sharedPreferencesService.storeDynamicList(
              'edificio', userData['edificio']);
        }
        prefs.setString('rol', userData['rol'] ?? '');
        prefs.setString('nombre', userData['nombre'] ?? '');
        prefs.setString('numeroApto', userData['numeroApto'] ?? '');
        break;
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final forgotPasswordEmailController = TextEditingController();
        final formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (context, setState) {
            bool isLoading = false;
            String? errorMessage;

            return AlertDialog(
              title: const Text('¿Olvidaste tu contraseña?'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                        'Ingresa tu email para restablecer tu contraseña.'),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: forgotPasswordEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese su email';
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Por favor ingrese un email válido';
                        }
                        return null;
                      },
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        await _authService.sendPasswordResetEmail(
                            forgotPasswordEmailController.text);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Correo de restablecimiento de contraseña enviado')),
                        );
                      } catch (e) {
                        setState(() {
                          errorMessage =
                              'Error al enviar el correo de restablecimiento';
                          isLoading = false;
                        });
                      }
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Iniciar Sesión',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Semantics(
                label: 'Logo de Administradores Diaz',
                child: Center(
                  child: Image.asset(
                    'assets/Logo_Diaz_Administradores.jpeg',
                    height: 100,
                    width: 100,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Encabezado de Iniciar sesión',
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    // Lógica adicional cuando el campo recibe el enfoque
                    Utils.debugPrint('Campo de email enfocado');
                  }
                },
                child: Semantics(
                  label: 'Campo de texto de email',
                  hint: 'Ingrese su email',
                  child: TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      labelText: 'Email',
                      hintText: 'Ingrese su email',
                      border: const OutlineInputBorder(),
                      helperText: 'Por favor ingrese su dirección de email.',
                      errorText: _formKey.currentState?.validate() ?? false
                          ? _emailValidator(_emailController.text)
                          : null,
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Focus(
                onFocusChange: (hasFocus) {
                  if (hasFocus) {
                    // Lógica adicional cuando el campo recibe el enfoque
                    Utils.debugPrint('Campo de contraseña enfocado');
                  }
                },
                child: Semantics(
                  label: 'Campo de texto de contraseña',
                  hint: 'Ingrese su contraseña',
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      labelText: 'Contraseña',
                      hintText: 'Ingrese su contraseña',
                      border: const OutlineInputBorder(),
                      helperText: 'Por favor ingrese su contraseña.',
                      errorText: _formKey.currentState?.validate() ?? false
                          ? _passwordValidator(_passwordController.text)
                          : null,
                    ),
                    obscureText: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.visiblePassword,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Botón de iniciar sesión',
                hint: 'Presione para iniciar sesión',
                child: ElevatedButton.icon(
                  onPressed: _isButtonEnabled ? _signIn : null,
                  icon: const Icon(Icons.login),
                  label: const Text('Entrar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Botón de registro',
                hint: 'Presione para registrarse',
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const RegisterPage()));
                  },
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
              ),
              Semantics(
                label: 'Botón de recuperar contraseña',
                hint: 'Presione para recuperar contraseña',
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: const Text('He olvidado mi contraseña'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
