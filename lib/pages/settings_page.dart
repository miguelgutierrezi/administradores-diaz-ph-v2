import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  final String title;

  const SettingsPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$title Page'),
    );
  }
}
