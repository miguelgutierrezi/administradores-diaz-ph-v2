import 'package:administradores_diaz_ph/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageDetailPage extends StatelessWidget {
  final Map<String, dynamic> mensaje;
  final bool isSent;

  const MessageDetailPage({
    Key? key,
    required this.mensaje,
    required this.isSent,
  }) : super(key: key);

  Future<void> _downloadFile(String url) async {
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            semanticLabel: 'Regresar',
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Semantics(
                label: 'Avatar del remitente',
                child: const CircleAvatar(
                  backgroundImage: AssetImage('assets/avatar-icon.png'),
                ),
              ),
              title: Text(
                mensaje['asunto'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Remitente: ${mensaje['from']}'),
                  Text('Para: ${mensaje['to']}'),
                  if (mensaje['imageUrl'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: () => _downloadFile(mensaje['imageUrl']),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file,
                              semanticLabel: 'Archivo adjunto',
                            ),
                            const SizedBox(width: 8.0),
                            Text(mensaje['imageName']),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              mensaje['message'],
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 32.0),
            Container(
              alignment: Alignment.center,
              color: Colors.black,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Image.asset(
                    'assets/Logo_Diaz_Administradores.jpeg',
                    width: 150,
                    semanticLabel: 'Logo Diaz Administradores',
                  ),
                  Text(
                    '${Globals.mainName}\n${Globals.mainSlogan}\n${Globals.phoneNumber} | ${Globals.mainEmail}\n${Globals.mainAddress}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
