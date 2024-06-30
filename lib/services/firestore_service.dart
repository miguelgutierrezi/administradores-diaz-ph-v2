import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
}
