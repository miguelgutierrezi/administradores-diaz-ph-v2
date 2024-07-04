import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';

class VisitDetailPage extends StatefulWidget {
  final String visitId;

  const VisitDetailPage({required this.visitId, super.key});

  @override
  _VisitDetailPageState createState() => _VisitDetailPageState();
}

class _VisitDetailPageState extends State<VisitDetailPage> {
  late Future<DocumentSnapshot> _visitFuture;

  @override
  void initState() {
    super.initState();
    _visitFuture = _fetchVisit(widget.visitId);
  }

  Future<DocumentSnapshot> _fetchVisit(String visitId) {
    return FirebaseFirestore.instance.collection('visits').doc(visitId).get();
  }

  void _displayImage(String url) {
    launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Detalle de Visita',
            style: TextStyle(color: Colors.white)),
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
      body: FutureBuilder<DocumentSnapshot>(
        future: _visitFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar la visita'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró la visita'));
          } else {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            List<dynamic> zones = data['zones'] ?? [];
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: <Widget>[
                  ListTile(
                    title: Text('Edificio: ${data['edificio']}'),
                    subtitle:
                        Text('Fecha: ${(data['date'] as Timestamp).toDate()}'),
                  ),
                  ListTile(
                    title: Text('Autor: ${data['name']}'),
                  ),
                  const SizedBox(height: 16),
                  Text('Zonas:',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  ...zones.map((zone) {
                    List<dynamic> filesLinks = zone['filesLinks'] ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Zona: ${zone['nombre']}'),
                        const SizedBox(height: 8),
                        if (filesLinks.isNotEmpty)
                          CarouselSlider(
                            options: CarouselOptions(
                              height: 400.0,
                              autoPlay: true,
                              enlargeCenterPage: true,
                              aspectRatio: 16 / 9,
                              enableInfiniteScroll: true,
                              autoPlayInterval: const Duration(seconds: 3),
                            ),
                            items: filesLinks.map((fileLink) {
                              return Builder(
                                builder: (BuildContext context) {
                                  return GestureDetector(
                                    onTap: () =>
                                        _displayImage(fileLink.toString()),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 5.0),
                                      decoration: const BoxDecoration(
                                        color: Colors.black12,
                                      ),
                                      child: Image.network(
                                        fileLink.toString(),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 8),
                        Text('Observaciones: ${zone['observacion'] ?? ''}'),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
