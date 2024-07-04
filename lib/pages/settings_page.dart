import 'package:administradores_diaz_ph/modals/add_admin.dart';
import 'package:administradores_diaz_ph/modals/add_bill.dart';
import 'package:administradores_diaz_ph/modals/add_client.dart';
import 'package:administradores_diaz_ph/modals/add_complaint.dart';
import 'package:administradores_diaz_ph/modals/add_zone.dart';
import 'package:administradores_diaz_ph/modals/bills_page.dart';
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
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi perfil'),
            trailing: const Icon(Icons.arrow_forward),
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
              leading: const Icon(Icons.person_outline),
              title: const Text('Agregar cliente'),
              trailing: const Icon(Icons.arrow_forward),
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
              leading: const Icon(Icons.person_outline),
              title: const Text('Agregar administrador'),
              trailing: const Icon(Icons.arrow_forward),
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
              leading: const Icon(Icons.business_outlined),
              title: const Text('Agregar edificio'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.pushNamed(context, '/buildings/add-building');
              },
            ),
            const Divider(),
          ],
          if (isNotClient()) ...[
            ListTile(
              leading: const Icon(Icons.navigation_outlined),
              title: const Text('Agregar zona común'),
              trailing: const Icon(Icons.arrow_forward),
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
              leading: const Icon(Icons.add_alert_outlined),
              title: const Text('Ver quejas y reclamos'),
              trailing: const Icon(Icons.arrow_forward),
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
              leading: const Icon(Icons.add_alert_outlined),
              title: const Text('Enviar queja o reclamo'),
              trailing: const Icon(Icons.arrow_forward),
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
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Ver votaciones'),
            trailing: const Icon(Icons.arrow_forward),
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
                  ? const Icon(Icons.people_outlined)
                  : const Icon(Icons.groups_outlined),
              title: isSuperAdmin()
                  ? const Text('Ver visitas')
                  : const Text('Mis visitas'),
              trailing: const Icon(Icons.arrow_forward),
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
              leading: const Icon(Icons.business_outlined),
              title: const Text('Mis edificios'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.pushNamed(context, '/buildings');
              },
            ),
            const Divider(),
          ],
          if (isSuperAdmin()) ...[
            ListTile(
              leading: const Icon(Icons.people_outlined),
              title: const Text('Ver administradores'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.pushNamed(context, '/users/admins');
              },
            ),
            const Divider(),
          ],
          if (isNotClient()) ...[
            ListTile(
              leading: const Icon(Icons.people_outlined),
              title: const Text('Ver clientes'),
              trailing: const Icon(Icons.arrow_forward),
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
              leading: const Icon(Icons.wallet_outlined),
              title: const Text('Ingresar factura'),
              trailing: const Icon(Icons.arrow_forward),
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
              leading: const Icon(Icons.wallet_outlined),
              title: const Text('Consultar factura'),
              trailing: const Icon(Icons.arrow_forward),
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
