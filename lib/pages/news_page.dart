import 'package:administradores_diaz_ph/modals/add_news.dart';
import 'package:administradores_diaz_ph/models/news.dart';
import 'package:administradores_diaz_ph/models/user_role.dart';
import 'package:administradores_diaz_ph/services/platform_service.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/utils.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();

  List<News> _noticias = [];
  List<News> _filterNews = [];
  String _searchTerm = '';
  UserRole? _role;
  String? _userBuilding;
  List<String>? _adminBuildings;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    UserRole? userRole = await _authService.getCurrentUserRole();
    final prefs = await SharedPreferences.getInstance();
    if (userRole == UserRole.user) {
      _userBuilding = prefs.getString("edificio");
    } else if (userRole == UserRole.admin) {
      _adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
    }
    setState(() {
      _role = userRole;
    });
  }

  Stream<List<News>> _newsStream() {
    Query query = FirebaseFirestore.instance.collection('news');
    if (_role == UserRole.user && _userBuilding != null) {
      query = query.where('edificio', isEqualTo: _userBuilding);
    } else if (_role == UserRole.admin &&
        _adminBuildings != null &&
        _adminBuildings!.isNotEmpty) {
      query = query.where('edificio', whereIn: _adminBuildings);
    }
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return News(
          id: doc.id,
          descripcion: data['descripcion'] ?? '',
          edificio: data['edificio'] ?? '',
          fecha: data['fecha'] ?? '',
          filesLinks: List<String>.from(data['filesLinks'] ?? []),
          filesNames: List<String>.from(data['filesNames'] ?? []),
          noticia: data['noticia'] ?? '',
        );
      }).toList();
    });
  }

  Future<void> _downloadFile(News noticia, int index) async {
    try {
      if (index < noticia.filesLinks.length) {
        final url = noticia.filesLinks[index];
        launchUrl(Uri.parse(url));
      }
    } catch (e) {
      Utils.debugPrint("Error downloading: $e");
    }
  }

  Future<void> _deleteNews(String newsId) async {
    await _firestoreService.deleteObject('news', newsId);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Noticia eliminada'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Se ha eliminado la noticia'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _setFilteredNews(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm.toLowerCase();
      _filterNews = _noticias
          .where(
              (noticia) => noticia.noticia.toLowerCase().contains(_searchTerm))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Filtrar noticias',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  _setFilteredNews(value);
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<News>>(
                stream: _newsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Cargando noticias',
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No hay noticias disponibles.'),
                    );
                  }

                  _noticias = snapshot.data!;
                  _filterNews = _searchTerm.isEmpty
                      ? _noticias
                      : _noticias
                          .where((noticia) => noticia.noticia
                              .toLowerCase()
                              .contains(_searchTerm))
                          .toList();

                  _filterNews.sort((a, b) {
                    if (a.fecha.isEmpty && b.fecha.isEmpty) {
                      return 0;
                    } else if (a.fecha.isEmpty) {
                      return -1;
                    } else if (b.fecha.isEmpty) {
                      return 1;
                    } else {
                      return DateTime.parse(b.fecha)
                          .compareTo(DateTime.parse(a.fecha));
                    }
                  });

                  return ListView.builder(
                    itemCount: _filterNews.length,
                    itemBuilder: (context, index) {
                      final noticia = _filterNews[index];
                      return _role == UserRole.admin ||
                              _role == UserRole.superadmin
                          ? Dismissible(
                              key: Key(noticia.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                _deleteNews(noticia.id);
                                setState(() {
                                  _filterNews.removeAt(index);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Noticia eliminada'),
                                  ),
                                );
                              },
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: _buildNewsCard(noticia),
                            )
                          : _buildNewsCard(noticia);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ((_role == UserRole.admin ||
                  _role == UserRole.superadmin) &&
              PlatformService.isMobile())
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddNewsPage()),
                );
              },
              backgroundColor: Colors.black,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                semanticLabel: 'Agregar noticia',
              ),
            )
          : null,
    );
  }

  Widget _buildNewsCard(News noticia) {
    return SizedBox(
      width: double.infinity, // Ocupa todo el ancho
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                noticia.edificio,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
                semanticsLabel: 'Edificio: ${noticia.edificio}',
              ),
              const SizedBox(height: 8.0),
              Text(
                noticia.noticia,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
                semanticsLabel: 'Noticia: ${noticia.noticia}',
              ),
              const SizedBox(height: 8.0),
              Text(
                noticia.descripcion,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
                semanticsLabel: 'Descripción: ${noticia.descripcion}',
              ),
              const SizedBox(height: 8.0),
              if (noticia.filesNames.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      List.generate(noticia.filesNames.length, (fileIndex) {
                    return Row(
                      children: [
                        const Icon(
                          Icons.attach_file,
                          size: 16.0,
                          semanticLabel: 'Archivo adjunto',
                        ),
                        const SizedBox(width: 4.0),
                        GestureDetector(
                          onTap: () => _downloadFile(noticia, fileIndex),
                          child: Text(
                            noticia.filesNames[fileIndex],
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            semanticsLabel:
                                'Archivo adjunto: ${noticia.filesNames[fileIndex]}',
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              const SizedBox(height: 8.0),
              Text(
                'Fecha: ${noticia.fecha}',
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey,
                ),
                semanticsLabel: 'Fecha de la noticia: ${noticia.fecha}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
