import 'package:administradores_diaz_ph/pages/dashboard_page.dart';
import 'package:administradores_diaz_ph/pages/messages_page.dart';
import 'package:administradores_diaz_ph/pages/news_page.dart';
import 'package:administradores_diaz_ph/pages/settings_page.dart';
import 'package:administradores_diaz_ph/pages/zones_page.dart';
import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/welcome_page.dart';
import 'package:flutter/material.dart';

import 'models/user_role.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  late List<Widget> _children;
  late List<BottomNavigationBarItem> _items;
  UserRole? _userRole;
  int _unreadMessagesCount = 1;

  @override
  void initState() {
    super.initState();
    _initializeRoleAndTabs();
  }

  Future<void> _initializeRoleAndTabs() async {
    UserRole? role = await _authService.getCurrentUserRole();
    setState(() {
      _userRole = role;
      _initializeTabs();
    });
  }

  void _initializeTabs() {
    _children = [
      const NewsPage(),
      const DashboardPage(),
      const ZonesPage(),
      const MessagesPage(),
      SettingsPage(title: _userRole == UserRole.user ? 'Más opciones' : 'Admon')
    ];
    _items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.article),
        label: 'Noticias',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.view_agenda),
        label: 'Cartelera',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map),
        label: 'Zonas',
      ),
      BottomNavigationBarItem(
        icon: _buildMessagesIcon(),
        label: 'Mensajes',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.admin_panel_settings),
        label: _userRole == 'admin' || _userRole == 'superadmin'
            ? 'Admon'
            : 'Más opciones',
      ),
    ];
  }

  Widget _buildMessagesIcon() {
    return Stack(
      children: <Widget>[
        const Icon(Icons.message),
        if (_unreadMessagesCount > 0)
          Positioned(
            right: 0,
            child: Container(
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(
                minWidth: 12,
                minHeight: 12,
              ),
              child: Text(
                '$_unreadMessagesCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
      ],
    );
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Home',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              onPressed: () async {
                await _authService.signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const WelcomePage()));
              },
            ),
          ],
        ),
        body: _userRole == null
            ? const Center(child: CircularProgressIndicator())
            : _children[_currentIndex],
        bottomNavigationBar: _userRole == null
            ? null
            : BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                onTap: onTabTapped,
                currentIndex: _currentIndex,
                items: _items,
              ),
      ),
    );
  }
}
