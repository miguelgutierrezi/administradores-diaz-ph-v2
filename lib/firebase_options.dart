import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const firebaseConfig = FirebaseOptions(
    apiKey: "AIzaSyAR1UfNPeWgH0inDx0qT_W6DzR5e1kfh3s",
    authDomain: "administradores-diaz-ph-sass.firebaseapp.com",
    databaseURL: "https://administradores-diaz-ph-sass.firebaseio.com",
    projectId: "administradores-diaz-ph-sass",
    storageBucket: "administradores-diaz-ph-sass.appspot.com",
    messagingSenderId: "289910440888",
    appId: "1:289910440888:web:9709c00112a0af812d854d",
    measurementId: "G-Q23F5MSKC7");

Future<FirebaseApp> initializeFirebase() async {
  return await Firebase.initializeApp(
    options: kIsWeb ? firebaseConfig : null,
  );
}
