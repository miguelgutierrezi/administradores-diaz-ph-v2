import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Método para recuperar una colección completa
  Future<List<Map<String, dynamic>>> getCollection(String collectionPath) async {
    try {
      QuerySnapshot snapshot = await _db.collection(collectionPath).get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  // Método para recuperar un documento específico por ID
  Future<Map<String, dynamic>?> getDocument(String collectionPath, String documentId) async {
    try {
      DocumentSnapshot snapshot = await _db.collection(collectionPath).doc(documentId).get();
      return snapshot.data() as Map<String, dynamic>?;
    } catch (e) {
      print(e);
      return null;
    }
  }
}