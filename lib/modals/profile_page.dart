import 'package:administradores_diaz_ph/models/user_role.dart';
import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:administradores_diaz_ph/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();

  String? _correo;
  String? _id;
  String? _rol;
  String? _nombre;
  String? _numeroApto;
  List<String>? _edificios;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    List<String>? edificios;
    UserRole? userRole = await _authService.getCurrentUserRole();
    final prefs = await SharedPreferences.getInstance();
    if (userRole == UserRole.user) {
      edificios = [prefs.getString('edificio') ?? ''];
    } else {
      edificios = await _sharedPreferencesService.getDynamicList('edificio');
    }
    setState(() {
      _correo = prefs.getString('correo');
      _id = prefs.getString('id');
      _rol = prefs.getString('rol');
      _nombre = prefs.getString('nombre');
      _numeroApto = prefs.getString('numeroApto');
      _edificios = edificios;
    });
  }

  void _logout() async {
    await _authService.signOut();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
    );
  }

  Future<void> _deleteAccount() async {
    await _authService.deleteAccount();
  }

  void _showDeleteConfirmationDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar cuenta'),
          content: const Text(
              '¿Estás seguro de que deseas eliminar tu cuenta? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                _showLoaderAndDeleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLoaderAndDeleteAccount() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await _deleteAccount();
      Navigator.of(context).pop(); // Cierra el loader
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta eliminada exitosamente')),
      );
      // Navegar a la pantalla de bienvenida o login después de eliminar la cuenta
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    } catch (e) {
      print('Error al eliminar la cuenta: $e');
      Navigator.of(context).pop(); // Cierra el loader
      // Muestra un mensaje de error en caso de que ocurra un problema
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la cuenta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Perfil',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: _logout,
          )
        ],
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
        child: ListView(
          children: [
            Center(
              child: ClipOval(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: AssetImage('assets/avatar-icon.png'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Correo electrónico'),
              subtitle: Text(_correo ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Nombre'),
              subtitle: Text(_nombre ?? ''),
            ),
            if (_rol == 'CLIENTE')
              ListTile(
                leading: const Icon(Icons.apartment),
                title: const Text('Número de Apartamento'),
                subtitle: Text(_numeroApto ?? ''),
              ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Rol'),
              subtitle: Text(_rol ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('Edificio(s)'),
              subtitle: Text(_edificios?.join(', ') ?? ''),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showDeleteConfirmationDialog,
              icon: const Icon(Icons.delete),
              label: const Text('Eliminar cuenta'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
