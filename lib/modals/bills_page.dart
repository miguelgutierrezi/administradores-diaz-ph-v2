import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firestore_service.dart';

class BillsListPage extends StatefulWidget {
  const BillsListPage({super.key});

  @override
  _BillsListPageState createState() => _BillsListPageState();
}

class _BillsListPageState extends State<BillsListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  final List<String> _monthsList = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];

  final int _currentYear = DateTime.now().year;
  List<int> _yearsList = [];
  String? _selectedMonth;
  int? _selectedYear;
  Map<String, dynamic>? _building;
  Map<String, dynamic>? _bill;
  List<Map<String, dynamic>> _bills = [];

  @override
  void initState() {
    super.initState();
    _yearsList = [_currentYear - 1, _currentYear, _currentYear + 1];
    _selectedYear = _currentYear;
    _selectedMonth = _monthsList[0];
    _loadBills();
  }

  Future<void> _loadBills() async {
    final prefs = await SharedPreferences.getInstance();
    final String? edificio = prefs.getString('edificio');
    final List<Map<String, dynamic>> buildings =
        await _firestoreService.getCollection('buildings');

    setState(() {
      _building =
          buildings.firstWhere((building) => building['nombre'] == edificio);
    });

    final List<Map<String, dynamic>> bills =
        await _firestoreService.getCollection('bills');
    setState(() {
      _bills = bills
          .where((bill) => bill['buildingId'] == _building!['id'])
          .toList();
    });
  }

  void _getBill() async {
    final prefs = await SharedPreferences.getInstance();
    final numeroApto = prefs.getString('numeroApto');
    setState(() {
      _bill = _bills.firstWhere(
        (bill) =>
            bill['mes'] == _selectedMonth &&
            bill['anho'] == _selectedYear &&
            bill['numeroApto'] == numeroApto,
        orElse: () => {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Consultar factura',
          style: TextStyle(color: Colors.white),
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        icon: Icon(Icons.calendar_today),
                      ),
                      items: _yearsList.map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                      value: _selectedYear,
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un año';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                        icon: Icon(Icons.calendar_today),
                      ),
                      items: _monthsList.map((month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      },
                      value: _selectedMonth,
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un mes';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _getBill();
                    }
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Consultar factura'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _bill == null || _bill!.isEmpty
                  ? const Center(child: Text('No se ha encontrado factura'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_bill!['fileUrl'] != null &&
                            _bill!['fileUrl']!.isNotEmpty)
                          Text('Ver factura: ${_bill!['fileName']}'),
                        if (_bill!['statusUrl'] != null &&
                            _bill!['statusUrl']!.isNotEmpty)
                          Text(
                              'Ver estado de cuenta: ${_bill!['accountStatusName']}'),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
