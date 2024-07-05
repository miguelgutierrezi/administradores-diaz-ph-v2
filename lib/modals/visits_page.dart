import 'package:administradores_diaz_ph/modals/add_visit.dart';
import 'package:administradores_diaz_ph/modals/visit_detail.dart';
import 'package:administradores_diaz_ph/services/shared_preferences_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class VisitsListPage extends StatefulWidget {
  const VisitsListPage({super.key});

  @override
  _VisitsListPageState createState() => _VisitsListPageState();
}

class _VisitsListPageState extends State<VisitsListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  final AuthService _authService = AuthService();

  static const int pageSize = 10;
  final PagingController<DocumentSnapshot?, Map<String, dynamic>>
      _pagingController = PagingController(firstPageKey: null);

  String _searchTerm = '';
  UserRole? _userRole;
  String? _userName;
  String? _userId;
  List<String>? _adminBuildings;
  List<Map<String, dynamic>> _allVisits = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userRole = await _authService.getCurrentUserRole();
    _userName = prefs.getString('nombre');
    _userId = prefs.getString('id');
    if (_userRole == UserRole.admin) {
      _adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
      _loadVisits();
    }
    setState(() {});
  }

  Future<void> _loadVisits() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('visits').get();
    List<Map<String, dynamic>> visits = snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      _allVisits = visits;
    });
  }

  Future<void> _fetchPage(DocumentSnapshot? pageKey) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('visits')
          .orderBy('date', descending: true)
          .limit(pageSize);

      if (pageKey != null) {
        query = query.startAfterDocument(pageKey);
      }

      final newSnapshot = await query.get();

      var newItems = newSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (_searchTerm.isNotEmpty) {
        newItems = newItems.where((visit) {
          return visit['edificio']
              .toLowerCase()
              .contains(_searchTerm.toLowerCase());
        }).toList();
      }

      final isLastPage = newItems.length < pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = newSnapshot.docs.last;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  List<Map<String, dynamic>> _filterVisits() {
    List<Map<String, dynamic>> filteredVisits = _allVisits;

    if (_userRole == UserRole.admin && _adminBuildings != null) {
      filteredVisits = filteredVisits.where((visit) {
        return _adminBuildings!.contains(visit['edificio']) &&
            visit['user'] == _userId;
      }).toList();
    }

    filteredVisits.sort((a, b) {
      return (b['date'] as Timestamp).compareTo(a['date'] as Timestamp);
    });

    if (_searchTerm.isNotEmpty) {
      filteredVisits = filteredVisits.where((visit) {
        return visit['edificio']
            .toLowerCase()
            .contains(_searchTerm.toLowerCase());
      }).toList();
    }

    return filteredVisits;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Visitas',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          if (_userRole == UserRole.superadmin)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Filtrar visitas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchTerm = value;
                    _pagingController.refresh();
                  });
                },
              ),
            ),
          Expanded(
            child: _userRole == UserRole.superadmin
                ? PagedListView<DocumentSnapshot?, Map<String, dynamic>>(
                    pagingController: _pagingController,
                    builderDelegate:
                        PagedChildBuilderDelegate<Map<String, dynamic>>(
                      itemBuilder: (context, visit, index) => Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: ListTile(
                          title: Text(visit['edificio']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                  'Fecha: ${DateTime.fromMillisecondsSinceEpoch(visit['date'].seconds * 1000)}'),
                              Text('Autor: ${visit['name']}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VisitDetailPage(
                                  visitId: visit['id'],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filterVisits().length,
                    itemBuilder: (context, index) {
                      var visit = _filterVisits()[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        child: ListTile(
                          title: Text(visit['edificio']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                  'Fecha: ${DateTime.fromMillisecondsSinceEpoch(visit['date'].seconds * 1000)}'),
                              Text(
                                  'Autor: ${_userRole == UserRole.superadmin ? visit['name'] : _userName}'),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VisitDetailPage(
                                  visitId: visit['id'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AddVisitPage()));
        },
      ),
    );
  }
}
