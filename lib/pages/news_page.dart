import 'package:administradores_diaz_ph/models/news.dart';
import 'package:administradores_diaz_ph/models/user_role.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';

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
  String? _searchTerm;
  UserRole? _role;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    _role = await _authService.getCurrentUserRole();
    _getNews();
  }

  Future<void> _getNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> newsData =
          await _firestoreService.getCollection('news');
      List<News> noticias = newsData
          .map((data) => News(
                id: data['id'],
                descripcion: data['descripcion'] ?? '',
                edificio: data['edificio'] ?? '',
                fecha: data['fecha'] ?? '',
                filesLinks: List<String>.from(data['filesLinks'] ?? []),
                filesNames: List<String>.from(data['filesNames'] ?? []),
                noticia: data['noticia'] ?? '',
              ))
          .toList();

      if (_role == UserRole.user) {
        String? edificioLocal = prefs.getString("edificio");
        setState(() {
          _noticias = noticias
              .where((noticia) => noticia.edificio == edificioLocal)
              .toList();
          _filterNews = _noticias;
        });
      } else if (_role == UserRole.admin) {
        List<String> edificioLocal =
            await _sharedPreferencesService.getDynamicList('edificio');
        setState(() {
          _noticias = noticias
              .where((noticia) => edificioLocal.contains(noticia.edificio))
              .toList();
          _filterNews = _noticias;
        });
      } else {
        setState(() {
          _noticias = noticias;
          _filterNews = noticias;
        });
      }
    } catch (e) {
      print('Error fetching news: $e');
    }
  }

  Future<void> _downloadFile(News noticia, int index) async {
    try {
      if (index < noticia.filesLinks.length) {
        final url = noticia.filesLinks[index];
        launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print("Error downloading: $e");
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
                _getNews();
              },
            ),
          ],
        );
      },
    );
  }

  void _setFilteredNews(String searchTerm) {
    setState(() {
      _filterNews = _noticias
          .where((noticia) =>
              noticia.noticia.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  setState(() {
                    _searchTerm = value;
                    _setFilteredNews(value);
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filterNews.length,
                itemBuilder: (context, index) {
                  final noticia = _filterNews[index];
                  return _role == UserRole.admin || _role == UserRole.superadmin
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
                                  content: Text('Noticia eliminada')),
                            );
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: _buildNewsCard(noticia),
                        )
                      : _buildNewsCard(noticia);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Lógica para agregar una nueva noticia
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
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
              ),
              const SizedBox(height: 8.0),
              Text(
                noticia.noticia,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                noticia.descripcion,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 8.0),
              if (noticia.filesNames.isNotEmpty)
                Column(
                  children:
                      List.generate(noticia.filesNames.length, (fileIndex) {
                    return Row(
                      children: [
                        const Icon(Icons.attach_file, size: 16.0),
                        const SizedBox(width: 4.0),
                        GestureDetector(
                          onTap: () => _downloadFile(noticia, fileIndex),
                          child: Text(
                            noticia.filesNames[fileIndex],
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
