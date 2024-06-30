import 'package:administradores_diaz_ph/models/user_role.dart';
import 'package:administradores_diaz_ph/services/auth_service.dart';
import 'package:administradores_diaz_ph/services/platform_service.dart';
import 'package:administradores_diaz_ph/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  Future<void> _checkAuthentication() async {
    try {
      User? user = _authService.getCurrentUser();
      if (user != null) {
        if (PlatformService.isMobile()) {
          await _subscribeToNotifications();
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    } catch (e) {
      print('Error checking authentication: $e');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    }
  }

  Future<void> _subscribeToNotifications() async {
    FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    final prefs = await SharedPreferences.getInstance();
    UserRole? _role = await _authService.getCurrentUserRole();

    if (_role == UserRole.user) {
      String? building = prefs.getString('edificio');
      if (building != null) {
        String topic = 'news_${building.replaceAll(' ', '_').toLowerCase()}';
        await _firebaseMessaging.subscribeToTopic(topic);
        print('Subscribed to $topic');
      }
    } else if (_role == UserRole.admin) {
      List<String>? buildings = prefs.getStringList('edificio');
      if (buildings != null) {
        for (String building in buildings) {
          String topic = 'news_${building.replaceAll(' ', '_').toLowerCase()}';
          await _firebaseMessaging.subscribeToTopic(topic);
          print('Subscribed to $topic');
        }
      }
    } else if (_role == UserRole.superadmin) {
      await _firebaseMessaging.subscribeToTopic('news');
      print('Subscribed to news');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
