import 'package:administradores_diaz_ph/modals/add_booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/shared_preferences_service.dart';
// import 'add_booking_component.dart';

class CalendarUiPage extends StatefulWidget {
  final String zoneId;

  const CalendarUiPage({required this.zoneId, super.key});

  @override
  _CalendarUiPageState createState() => _CalendarUiPageState();
}

class _CalendarUiPageState extends State<CalendarUiPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  final AuthService _authService = AuthService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  UserRole? _userRole;
  String? _userName;
  String? _userId;
  List<String>? _adminBuildings;
  Map<String, dynamic>? _zone;
  List<dynamic> _selectedDateBookings = [];
  List<String> _selectedDateIds = [];
  bool _validDay = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getZone();
    _getEvents();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userRole = await _authService.getCurrentUserRole();
    _userName = prefs.getString('nombre');
    _userId = prefs.getString('id');
    if (_userRole == UserRole.admin) {
      _adminBuildings =
          await _sharedPreferencesService.getDynamicList('edificio');
    }
    setState(() {});
  }

  Future<void> _getZone() async {
    List<Map<String, dynamic>> zones =
        await _firestoreService.getCollection('zonas');
    setState(() {
      _zone = zones.firstWhere((zone) => zone['id'] == widget.zoneId);
    });
  }

  Future<void> _getEvents() async {
    if (_zone == null) return;
    setState(() {
      _selectedDateBookings = [];
      _selectedDateIds = [];
    });

    List<Map<String, dynamic>> bookings =
        await _firestoreService.getBookings(widget.zoneId);
    for (var booking in bookings) {
      DateTime fechaInicio = (booking['fechaInicio'] as Timestamp).toDate();
      DateTime fechaFin = (booking['fechaFin'] as Timestamp).toDate();
      if (compareDates(fechaInicio, _selectedDate)) {
        setState(() {
          _selectedDateBookings.add(booking);
          _selectedDateIds.add(booking['id']);
        });
      }
    }

    setState(() {
      _validDay = _selectedDateBookings.isEmpty ? true : validateDay();
    });
  }

  bool compareDates(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  bool validateDay() {
    DateTime initialDate = _selectedDateBookings.first['fechaInicio'].toDate();
    bool result = !(_selectedDateBookings.length == 1 && initialDate.hour == 0);
    return result;
  }

  void _onAddBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBookingPage(
          selectedDate: _selectedDate,
          zoneId: widget.zoneId,
          zoneName: _zone?['nombre'],
        ),
      ),
    ).then((result) {
      if (result == 'confirm') {
        _getEvents();
      }
    });
  }

  void _onDeleteEvent(String bookingId) async {
    await _firestoreService.deleteBooking(widget.zoneId, bookingId);
    await _getEvents();
  }

  bool _availableDelete(String bookingUserId) {
    String userId = _userId!;
    return _userRole == UserRole.superadmin || bookingUserId == userId;
  }

  bool _isOwner(String bookingUserId) {
    String userId = _userId!;
    return bookingUserId == userId;
  }

  bool _isNotOwner(String bookingUserId) {
    String userId = _userId!;
    return bookingUserId != userId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Reservas de ${_zone?['nombre'] ?? ''}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                      _getEvents();
                    });
                  },
                ),
                if (_selectedDateBookings.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${_selectedDate.day} - ${_selectedDate.month} - ${_selectedDate.year}',
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedDateBookings.isEmpty)
                          const Center(
                              child: Text(
                                  'No hay reservas para la fecha seleccionada')),
                        ..._selectedDateBookings.map((booking) {
                          int index = _selectedDateBookings.indexOf(booking);
                          return ListTile(
                            leading: const Icon(Icons.today),
                            title: Text(
                              _isOwner(booking['user'])
                                  ? 'Espacio reservado por ti'
                                  : _isNotOwner(booking['user'])
                                      ? 'Horario reservado'
                                      : booking['nombre'],
                            ),
                            subtitle: Text(
                              '${DateFormat('h:mm a').format((booking['fechaInicio'] as Timestamp).toDate())} - ${DateFormat('h:mm a').format((booking['fechaFin'] as Timestamp).toDate())}',
                            ),
                            trailing: _availableDelete(booking['user'])
                                ? IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _onDeleteEvent(_selectedDateIds[index]),
                                  )
                                : null,
                          );
                        }),
                      ],
                    ),
                  ),
                if (_validDay &&
                    _userRole == UserRole.user &&
                    _selectedDate.isAfter(DateTime.now()))
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: _onAddBooking,
                      icon: const Icon(Icons.check),
                      label: const Text('Añadir reserva'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (!_validDay || !_selectedDate.isAfter(DateTime.now()))
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No hay horarios disponibles para reservar',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
