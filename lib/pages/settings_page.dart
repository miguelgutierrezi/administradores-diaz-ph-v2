import 'package:administradores_diaz_ph/modals/add_admin.dart';
import 'package:administradores_diaz_ph/modals/add_bill.dart';
import 'package:administradores_diaz_ph/modals/add_building.dart';
import 'package:administradores_diaz_ph/modals/add_client.dart';
import 'package:administradores_diaz_ph/modals/add_complaint.dart';
import 'package:administradores_diaz_ph/modals/add_zone.dart';
import 'package:administradores_diaz_ph/modals/admins_page.dart';
import 'package:administradores_diaz_ph/modals/bills_page.dart';
import 'package:administradores_diaz_ph/modals/buildings_page.dart';
import 'package:administradores_diaz_ph/modals/clients_page.dart';
import 'package:administradores_diaz_ph/modals/complaints_page.dart';
import 'package:administradores_diaz_ph/modals/profile_page.dart';
import 'package:administradores_diaz_ph/modals/visits_page.dart';
import 'package:administradores_diaz_ph/modals/votings_page.dart';
import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  final String title;

  const SettingsPage({required this.title});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    UserRole? role = await _authService.getCurrentUserRole();
    setState(() {
      _userRole = role;
    });
  }

  bool isSuperAdmin() {
    var superAdmin = _userRole == UserRole.superadmin;
    return superAdmin;
  }

  bool isNotClient() {
    return _userRole != UserRole.user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline,
                semanticLabel: 'Icono de perfil'),
            title: const Text('Mi perfil',
                semanticsLabel: 'Opción de menú: Mi perfil'),
            trailing: const Icon(Icons.arrow_forward,
                semanticLabel: 'Ir a Mi perfil'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          const Divider(),
          if (isNotClient()) ...[
            ListTile(
              leading: const Icon(Icons.person_outline,
                  semanticLabel: 'Icono de agregar cliente'),
              title: const Text('Agregar cliente',
                  semanticsLabel: 'Opción de menú: Agregar cliente'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Agregar cliente'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddClientPage()),
                );
              },
            ),
            const Divider(),
          ],
          if (isSuperAdmin()) ...[
            ListTile(
              leading: const Icon(Icons.person_outline,
                  semanticLabel: 'Icono de agregar administrador'),
              title: const Text('Agregar administrador',
                  semanticsLabel: 'Opción de menú: Agregar administrador'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Agregar administrador'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAdminPage()),
                );
              },
            ),
            const Divider(),
          ],
          if (isSuperAdmin()) ...[
            ListTile(
              leading: const Icon(Icons.business_outlined,
                  semanticLabel: 'Icono de agregar edificio'),
              title: const Text('Agregar edificio',
                  semanticsLabel: 'Opción de menú: Agregar edificio'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Agregar edificio'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddBuildingPage()),
                );
              },
            ),
            const Divider(),
          ],
          if (isNotClient()) ...[
            ListTile(
              leading: const Icon(Icons.navigation_outlined,
                  semanticLabel: 'Icono de agregar zona común'),
              title: const Text('Agregar zona común',
                  semanticsLabel: 'Opción de menú: Agregar zona común'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Agregar zona común'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddZonePage()),
                );
              },
            ),
            const Divider(),
          ],
          if (isNotClient()) ...[
            ListTile(
              leading: const Icon(Icons.add_alert_outlined,
                  semanticLabel: 'Icono de ver quejas y reclamos'),
              title: const Text('Ver quejas y reclamos',
                  semanticsLabel: 'Opción de menú: Ver quejas y reclamos'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Ver quejas y reclamos'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ComplaintsListPage()),
                );
              },
            ),
            const Divider(),
          ],
          if (!isNotClient()) ...[
            ListTile(
              leading: const Icon(Icons.add_alert_outlined,
                  semanticLabel: 'Icono de enviar queja o reclamo'),
              title: const Text('Enviar queja o reclamo',
                  semanticsLabel: 'Opción de menú: Enviar queja o reclamo'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Enviar queja o reclamo'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddComplaintPage()),
                );
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.archive_outlined,
                semanticLabel: 'Icono de ver votaciones'),
            title: const Text('Ver votaciones',
                semanticsLabel: 'Opción de menú: Ver votaciones'),
            trailing: const Icon(Icons.arrow_forward,
                semanticLabel: 'Ir a Ver votaciones'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const VotingsListPage()),
              );
            },
          ),
          const Divider(),
          if (isNotClient()) ...[
            ListTile(
              leading: isSuperAdmin()
                  ? const Icon(Icons.people_outlined,
                      semanticLabel: 'Icono de ver visitas')
                  : const Icon(Icons.groups_outlined,
                      semanticLabel: 'Icono de mis visitas'),
              title: isSuperAdmin()
                  ? const Text('Ver visitas',
                      semanticsLabel: 'Opción de menú: Ver visitas')
                  : const Text('Mis visitas',
                      semanticsLabel: 'Opción de menú: Mis visitas'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Ver visitas'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VisitsListPage()),
                );
              },
            ),
            const Divider(),
          ],
          if (isSuperAdmin()) ...[
            ListTile(
              leading: const Icon(Icons.business_outlined,
                  semanticLabel: 'Icono de mis edificios'),
              title: const Text('Mis edificios',
                  semanticsLabel: 'Opción de menú: Mis edificios'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Mis edificios'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BuildingsListPage()),
                );
              },
            ),
            const Divider(),
          ],
          if (isSuperAdmin()) ...[
            ListTile(
              leading: const Icon(Icons.people_outlined,
                  semanticLabel: 'Icono de ver administradores'),
              title: const Text('Ver administradores',
                  semanticsLabel: 'Opción de menú: Ver administradores'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Ver administradores'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminsListPage()),
                );
              },
            ),
            const Divider(),
          ],
          if (isNotClient()) ...[
            ListTile(
              leading: const Icon(Icons.people_outlined,
                  semanticLabel: 'Icono de ver clientes'),
              title: const Text('Ver clientes',
                  semanticsLabel: 'Opción de menú: Ver clientes'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Ver clientes'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ClientsListPage()),
                );
              },
            ),
            const Divider(),
          ],
          if (isNotClient()) ...[
            ListTile(
              leading: const Icon(Icons.wallet_outlined,
                  semanticLabel: 'Icono de ingresar factura'),
              title: const Text('Ingresar factura',
                  semanticsLabel: 'Opción de menú: Ingresar factura'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Ingresar factura'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddBillPage()),
                );
              },
            ),
            const Divider(),
          ],
          if (!isNotClient()) ...[
            ListTile(
              leading: const Icon(Icons.wallet_outlined,
                  semanticLabel: 'Icono de consultar factura'),
              title: const Text('Consultar factura',
                  semanticsLabel: 'Opción de menú: Consultar factura'),
              trailing: const Icon(Icons.arrow_forward,
                  semanticLabel: 'Ir a Consultar factura'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BillsListPage()),
                );
              },
            ),
            const Divider(),
          ],
        ],
      ),
    );
  }
}
