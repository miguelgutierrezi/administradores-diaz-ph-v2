import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/utils.dart';

class PdfService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateAndUploadPdf(
      String visitId, Map<String, dynamic> visitData) async {
    try {
      final pdf = pw.Document();

      // Load logo from assets
      final ByteData logoData =
          await rootBundle.load('assets/Logo_Diaz_Administradores.jpeg');
      final Uint8List logoBytes = logoData.buffer.asUint8List();

      // Create PDF content
      List<pw.Widget> zonesWidgets =
          await _buildZones(visitData['zones'] ?? []);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return <pw.Widget>[
              _buildHeader(logoBytes),
              _buildTitle('Reporte de Visita'),
              _buildVisitDetails(visitData),
              ...zonesWidgets,
            ];
          },
        ),
      );

      // Save PDF to temporary directory
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/reporte_visita_$visitId.pdf');
      await file.writeAsBytes(await pdf.save());

      // Upload PDF to Firebase Storage
      String pdfUrl = await _uploadFile(file, visitId);

      // Update Firestore with PDF URL
      await _updateVisitWithPdfUrl(
          visitId, pdfUrl, 'reporte_visita_$visitId.pdf');
    } catch (e) {
      Utils.debugPrint('Error generating or uploading PDF: $e');
      rethrow;
    }
  }

  pw.Widget _buildHeader(Uint8List logoBytes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(pw.MemoryImage(logoBytes), width: 150),
        pw.Text('Administradores Diaz PH SAS',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text('Administración de Propiedad Horizontal',
            style: pw.TextStyle(fontSize: 12)),
        pw.Text('2568677 | diazmartinezadmon@gmail.com',
            style: pw.TextStyle(fontSize: 12)),
        pw.Text('Cra 53#103B-42 Oficina 609',
            style: pw.TextStyle(fontSize: 12)),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildTitle(String title) {
    return pw.Center(
      child: pw.Text(title,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
    );
  }

  pw.Widget _buildVisitDetails(Map<String, dynamic> visitData) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Edificio: ${visitData['edificio']}',
              style: const pw.TextStyle(fontSize: 16)),
          pw.Text('Fecha: ${(visitData['date'] as Timestamp).toDate()}',
              style: const pw.TextStyle(fontSize: 16)),
          pw.Text('Usuario: ${visitData['name']}',
              style: const pw.TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Future<List<pw.Widget>> _buildZones(List<dynamic> zones) async {
    List<pw.Widget> zoneWidgetsList = [];
    for (var zone in zones) {
      List<pw.Widget> zoneWidgets = [
        pw.Text('Zona: ${zone['nombre']}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Text('Novedad: ${zone['novedad']}'),
        pw.Text('Observaciones: ${zone['observacion'] ?? ''}'),
      ];

      List<dynamic> filesLinks = zone['filesLinks'] ?? [];
      for (var fileLink in filesLinks) {
        try {
          final imageBytes = await _downloadFile(fileLink);
          zoneWidgets.add(pw.Container(
            height: 200,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Center(
              child: pw.Image(pw.MemoryImage(imageBytes)),
            ),
          ));
        } catch (e) {
          Utils.debugPrint('Error downloading file: $e');
          zoneWidgets.add(pw.Container(
            height: 200,
            margin: const pw.EdgeInsets.only(top: 8),
            child: pw.Center(
              child: pw.Text('Error loading image'),
            ),
          ));
        }
      }

      zoneWidgets.add(pw.Divider());

      zoneWidgetsList.add(pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: zoneWidgets,
      ));
    }
    return zoneWidgetsList;
  }

  Future<Uint8List> _downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download file');
      }
    } catch (e) {
      Utils.debugPrint('Error downloading file: $e');
      rethrow;
    }
  }

  Future<String> _uploadFile(File file, String visitId) async {
    try {
      Reference storageRef = _storage.ref().child('visits/$visitId.pdf');
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      Utils.debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> _updateVisitWithPdfUrl(
      String visitId, String pdfUrl, String pdfName) async {
    try {
      await _firestore.collection('visits').doc(visitId).update({
        'pdfUrl': pdfUrl,
        'pdfName': pdfName,
      });
    } catch (e) {
      Utils.debugPrint('Error updating Firestore: $e');
      rethrow;
    }
  }
}
