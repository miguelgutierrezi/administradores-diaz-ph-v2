import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Método para recuperar una colección completa
  Future<List<Map<String, dynamic>>> getCollection(
      String collectionPath) async {
    try {
      QuerySnapshot snapshot = await _db.collection(collectionPath).get();
      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  // Método para recuperar un documento específico por ID
  Future<Map<String, dynamic>?> getDocument(
      String collectionPath, String documentId) async {
    try {
      DocumentSnapshot snapshot =
          await _db.collection(collectionPath).doc(documentId).get();
      return snapshot.data() as Map<String, dynamic>?;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<DocumentReference> createDocument(
      String collectionName, Map<String, dynamic> data) async {
    return await _db.collection(collectionName).add(data);
  }

  Future<void> updateDocument(
      String collectionName, String id, Map<String, dynamic> data) async {
    await _db.collection(collectionName).doc(id).update(data);
  }

  Future<void> addData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data);
  }

  Future<void> deleteObject(String collectionPath, String documentId) async {
    try {
      await _db.collection(collectionPath).doc(documentId).delete();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<String> uploadFile(
      String collectionName, String objectId, String filePath) async {
    File file = File(filePath);
    TaskSnapshot taskSnapshot = await _storage
        .ref('$collectionName/$objectId/${file.uri.pathSegments.last}')
        .putFile(file);
    return await taskSnapshot.ref.getDownloadURL();
  }

  Future<DocumentSnapshot> getDocumentSnapshot(
      String collection, String docId) async {
    return await _db.collection(collection).doc(docId).get();
  }

  Future<String> uploadPdf(
      String folder, String fileName, Uint8List pdfBytes) async {
    try {
      final ref = _storage.ref().child('$folder/$fileName');
      final uploadTask = ref.putData(pdfBytes);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading PDF: $e');
      return '';
    }
  }

  Future<List<Map<String, dynamic>>> getBookings(String zoneKey) async {
    try {
      QuerySnapshot snapshot =
          await _db.collection('zonas').doc(zoneKey).collection('events').get();

      return snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error getting bookings: $e');
    }
  }

  Future<void> deleteBooking(String zoneKey, String bookKey) async {
    try {
      await _db
          .collection('zonas')
          .doc(zoneKey)
          .collection('events')
          .doc(bookKey)
          .delete();
    } catch (e) {
      throw Exception('Error deleting booking: $e');
    }
  }
}
