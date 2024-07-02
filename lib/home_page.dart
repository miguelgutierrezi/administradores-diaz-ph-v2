import 'package:administradores_diaz_ph/pages/dashboard_page.dart';
import 'package:administradores_diaz_ph/pages/messages_page.dart';
import 'package:administradores_diaz_ph/pages/news_page.dart';
import 'package:administradores_diaz_ph/pages/settings_page.dart';
import 'package:administradores_diaz_ph/pages/zones_page.dart';
import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/platform_service.dart';
import 'package:administradores_diaz_ph/welcome_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int _unreadMessagesCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeRoleAndTabs();
    if (PlatformService.isMobile()) {
      _setupPushNotifications();
    }
  }

  Future<void> _initializeRoleAndTabs() async {
    UserRole? role = await _authService.getCurrentUserRole();
    setState(() {
      _userRole = role;
      _initializeTabs();
    });
  }

  void _setupPushNotifications() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    final prefs = await SharedPreferences.getInstance();
    UserRole? _role = await _authService.getCurrentUserRole();

    if (_role == UserRole.user) {
      String? building = prefs.getString('edificio');
      if (building != null) {
        String topic = 'news_${building.replaceAll(' ', '_').toLowerCase()}';
        await fcm.subscribeToTopic(topic);
        print('Subscribed to $topic');
      }
    } else if (_role == UserRole.admin) {
      List<String>? buildings = prefs.getStringList('edificio');
      if (buildings != null) {
        for (String building in buildings) {
          String topic = 'news_${building.replaceAll(' ', '_').toLowerCase()}';
          await fcm.subscribeToTopic(topic);
          print('Subscribed to $topic');
        }
      }
    } else if (_role == UserRole.superadmin) {
      await fcm.subscribeToTopic('news');
      print('Subscribed to news');
    }
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
        label: _userRole == UserRole.admin || _userRole == UserRole.superadmin
            ? 'Admon'
            : 'Más opciones',
      ),
    ];
  }

  Stream<int> _unreadMessagesCountStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_authService.getCurrentUserId())
        .snapshots()
        .map((snapshot) {
      var data = snapshot.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> receivedMessages =
          List<Map<String, dynamic>>.from(data['recibidos'] ?? []);
      int unreadCount =
          receivedMessages.where((message) => !message['read']).length;
      return unreadCount;
    });
  }

  Widget _buildMessagesIcon() {
    return StreamBuilder<int>(
      stream: _unreadMessagesCountStream(),
      builder: (context, snapshot) {
        _unreadMessagesCount = snapshot.data ?? 0;
        return Stack(
          children: <Widget>[
            const Icon(Icons.message),
            if (_unreadMessagesCount > 0)
              Positioned(
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(1),
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
      },
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
            'Administradores Diaz PH',
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
