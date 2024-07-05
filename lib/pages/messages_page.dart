import 'package:administradores_diaz_ph/modals/send_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../modals/message_detail.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final AuthService _authService = AuthService();
  UserRole? _userRole;
  String? _userId;
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _filteredMessages = [];
  String _searchTerm = '';
  bool _childNoLeidos = true;
  bool _childLeidos = true;
  bool _childEnviados = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    UserRole? role = await _authService.getCurrentUserRole();
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      _userRole = role;
      _userId = userId;
    });
  }

  Stream<Map<String, dynamic>> _messagesStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .snapshots()
        .map((snapshot) {
      var data = snapshot.data() as Map<String, dynamic>;
      return data;
    });
  }

  void _updateReadStatusAndNavigate(BuildContext context,
      Map<String, dynamic> mensaje, int index, bool isSent) async {
    // Realiza la navegación primero
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageDetailPage(
          mensaje: mensaje,
          isSent: isSent,
        ),
      ),
    );

    // Luego, actualiza el estado de lectura en Firestore
    if (!isSent) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final snapshot = await userDoc.get();
      final List recibidos = snapshot.data()?['recibidos'] ?? [];

      recibidos[index]['read'] = true;

      try {
        await userDoc.update({
          'recibidos': recibidos,
        });
      } catch (e) {
        // Maneja el error de actualización si es necesario
        print('Error actualizando el estado de lectura: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Filtrar mensajes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var data = snapshot.data ?? {};
                List<Map<String, dynamic>> receivedMessages = [];
                List<Map<String, dynamic>> sentMessages = [];
                receivedMessages =
                    List<Map<String, dynamic>>.from(data['recibidos'] ?? []);
                if (_userRole == UserRole.admin ||
                    _userRole == UserRole.superadmin) {
                  sentMessages =
                      List<Map<String, dynamic>>.from(data['enviados'] ?? []);
                }

                receivedMessages = receivedMessages
                    .where((message) =>
                        message['asunto']
                            .toLowerCase()
                            .contains(_searchTerm.toLowerCase()) ||
                        message['from']
                            .toLowerCase()
                            .contains(_searchTerm.toLowerCase()))
                    .toList();

                sentMessages = sentMessages
                    .where((message) =>
                        message['asunto']
                            .toLowerCase()
                            .contains(_searchTerm.toLowerCase()) ||
                        message['to']
                            .toLowerCase()
                            .contains(_searchTerm.toLowerCase()))
                    .toList();

                return ListView(
                  children: [
                    ExpansionTile(
                      title: const Text(
                        'Mensajes no leídos',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      initiallyExpanded: _childNoLeidos,
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          _childNoLeidos = expanded;
                        });
                      },
                      children: receivedMessages
                          .where((message) => !message['read'])
                          .map((message) {
                        int index = receivedMessages.indexOf(message);
                        return ListTile(
                          title: Text(
                            message['asunto'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('De: ${message['from']}'),
                          leading: const CircleAvatar(
                            backgroundImage:
                                AssetImage('assets/avatar-icon.png'),
                          ),
                          trailing: Wrap(
                            spacing: 12,
                            children: <Widget>[
                              if (message['imageUrl'] != null &&
                                  message['imageUrl'] != '')
                                const Icon(Icons.attach_file),
                              const Icon(Icons.add_alert, color: Colors.red),
                            ],
                          ),
                          onTap: () {
                            _updateReadStatusAndNavigate(
                                context, message, index, false);
                          },
                        );
                      }).toList(),
                    ),
                    if (receivedMessages
                        .where((message) => !message['read'])
                        .isEmpty)
                      const Center(child: Text('No tienes mensajes no leídos')),
                    ExpansionTile(
                      title: const Text(
                        'Mensajes leídos',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      initiallyExpanded: _childLeidos,
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          _childLeidos = expanded;
                        });
                      },
                      children: receivedMessages
                          .where((message) => message['read'])
                          .map((message) {
                        int index = receivedMessages.indexOf(message);
                        return ListTile(
                          title: Text(
                            message['asunto'],
                            style:
                                const TextStyle(fontWeight: FontWeight.normal),
                          ),
                          subtitle: Text('De: ${message['from']}'),
                          leading: const CircleAvatar(
                            backgroundImage:
                                AssetImage('assets/avatar-icon.png'),
                          ),
                          trailing: Wrap(
                            spacing: 12,
                            children: <Widget>[
                              if (message['imageUrl'] != null &&
                                  message['imageUrl'] != '')
                                const Icon(Icons.attach_file),
                            ],
                          ),
                          onTap: () {
                            _updateReadStatusAndNavigate(
                                context, message, index, false);
                          },
                        );
                      }).toList(),
                    ),
                    if (receivedMessages
                        .where((message) => message['read'])
                        .isEmpty)
                      const Center(child: Text('No tienes mensajes leídos')),
                    if (_userRole != UserRole.user)
                      ExpansionTile(
                        title: const Text(
                          'Mensajes enviados',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        initiallyExpanded: _childEnviados,
                        onExpansionChanged: (bool expanded) {
                          setState(() {
                            _childEnviados = expanded;
                          });
                        },
                        children: sentMessages.map((message) {
                          int index = sentMessages.indexOf(message);
                          return ListTile(
                            title: Text(
                              message['asunto'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal),
                            ),
                            subtitle: Text('Para: ${message['to']}'),
                            leading: const CircleAvatar(
                              backgroundImage:
                                  AssetImage('assets/avatar-icon.png'),
                            ),
                            trailing: Wrap(
                              spacing: 12,
                              children: <Widget>[
                                if (message['imageUrl'] != null &&
                                    message['imageUrl'] != '')
                                  const Icon(Icons.attach_file),
                              ],
                            ),
                            onTap: () {
                              _updateReadStatusAndNavigate(
                                  context, message, index, true);
                            },
                          );
                        }).toList(),
                      ),
                    if (_userRole != UserRole.user && sentMessages.isEmpty)
                      const Center(child: Text('No tienes mensajes enviados')),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _userRole != UserRole.user
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SendMessagePage()),
                );
              },
              backgroundColor: Colors.black,
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
