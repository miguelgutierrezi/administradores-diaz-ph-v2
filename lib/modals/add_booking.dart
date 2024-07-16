import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/shared_preferences_service.dart';

class AddBookingPage extends StatefulWidget {
  final DateTime selectedDate;
  final String zoneId;
  final String zoneName;

  const AddBookingPage({
    Key? key,
    required this.selectedDate,
    required this.zoneId,
    required this.zoneName,
  }) : super(key: key);

  @override
  _AddBookingPageState createState() => _AddBookingPageState();
}

class _AddBookingPageState extends State<AddBookingPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final SharedPreferencesService _sharedPreferencesService =
      SharedPreferencesService();
  final _formKey = GlobalKey<FormState>();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _allDay = false;
  bool _wholeDay = false;
  String? _userName;
  String? _userId;
  List<Map<String, dynamic>> _reservas = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchZoneData();
    _fetchEvents();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('nombre');
    _userId = prefs.getString('id');
    setState(() {});
  }

  Future<void> _fetchZoneData() async {
    var zoneDoc = await _firestoreService.getDocument('zonas', widget.zoneId);
    setState(() {
      _wholeDay = zoneDoc?['reservasTodoElDia'] ?? false;
    });
  }

  Future<void> _fetchEvents() async {
    var events =
        await _firestoreService.getCollection('zonas/${widget.zoneId}/events');
    setState(() {
      _reservas = events.map((event) {
        var data = event as Map<String, dynamic>;
        data['fechaInicio'] = (data['fechaInicio'] as Timestamp).toDate();
        data['fechaFin'] = (data['fechaFin'] as Timestamp).toDate();
        return data;
      }).toList();
    });
  }

  Future<void> _saveBooking() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _loading = true;
      });

      var startTime = _allDay ? '00:00' : _startTime!.format(context);
      var endTime = _allDay ? '23:59' : _endTime!.format(context);
      var startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _allDay ? 0 : _startTime!.hour,
        _allDay ? 0 : _startTime!.minute,
      );
      var endDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _allDay ? 23 : _endTime!.hour,
        _allDay ? 59 : _endTime!.minute,
      );

      final newBooking = {
        'fechaInicio': startDateTime,
        'fechaFin': endDateTime,
        'user': _userId,
        'nombre': _userName,
        'dia': _allDay,
      };

      if (_validateBooking(newBooking)) {
        var bookingRef = await _firestoreService.createDocument(
            'zonas/${widget.zoneId}/events', newBooking);
        Navigator.pop(context, 'success');
        setState(() {
          _loading = false;
        });
      } else {
        _showErrorDialog(
            'No es posible realizar la reserva. No hay disponibilidad horaria.');
      }
    }
  }

  bool _validateBooking(Map<String, dynamic> newBooking) {
    DateTime newStart = newBooking['fechaInicio'] as DateTime;
    DateTime newEnd = newBooking['fechaFin'] as DateTime;

    if (newStart.isAfter(newEnd)) {
      return false; // La fecha de inicio es después de la fecha de fin, la reserva no es válida
    }

    for (var booking in _reservas) {
      DateTime existingStart = booking['fechaInicio'] as DateTime;
      DateTime existingEnd = booking['fechaFin'] as DateTime;

      bool overlaps =
          newStart.isBefore(existingEnd) && newEnd.isAfter(existingStart);

      if (overlaps) {
        return false; // Hay solapamiento con una reserva existente
      }
    }

    return true; // No hay solapamiento
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
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
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Reservar ${widget.zoneName}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white,
            semanticLabel: 'Cerrar',
          ),
          onPressed: () {
            Navigator.pop(context, 'cancel');
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            label: 'Hora de inicio',
                            hint: 'Seleccione la hora de inicio',
                            child: ListTile(
                              title: const Text('Hora inicio'),
                              subtitle: Text(_startTime == null
                                  ? 'Seleccione la hora de inicio'
                                  : _startTime!.format(context)),
                              onTap: _allDay
                                  ? null
                                  : () async {
                                      var time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      setState(() {
                                        _startTime = time;
                                      });
                                    },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Semantics(
                            label: 'Hora de fin',
                            hint: 'Seleccione la hora de fin',
                            child: ListTile(
                              title: const Text('Hora fin'),
                              subtitle: Text(_endTime == null
                                  ? 'Seleccione la hora de fin'
                                  : _endTime!.format(context)),
                              onTap: _allDay
                                  ? null
                                  : () async {
                                      var time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                      setState(() {
                                        _endTime = time;
                                      });
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_wholeDay)
                      Semantics(
                        label: 'Reservar todo el día',
                        hint: 'Activar o desactivar reserva todo el día',
                        child: ListTile(
                          title: const Text('Reservar todo el día'),
                          trailing: Switch(
                            value: _allDay,
                            onChanged: (value) {
                              setState(() {
                                _allDay = value;
                              });
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Semantics(
                        label: 'Botón para realizar reserva',
                        hint: 'Presione para realizar la reserva',
                        child: ElevatedButton.icon(
                          onPressed: _saveBooking,
                          icon: const Icon(
                            Icons.check,
                            semanticLabel: 'Realizar reserva',
                          ),
                          label: const Text('Realizar reserva'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            textStyle: const TextStyle(fontSize: 18),
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
