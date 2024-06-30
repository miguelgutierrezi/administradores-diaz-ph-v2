import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const firebaseConfig = FirebaseOptions(
    apiKey: "AIzaSyAR1UfNPeWgH0inDx0qT_W6DzR5e1kfh3s",
    authDomain: "administradores-diaz-ph-sass.firebaseapp.com",
    databaseURL: "https://administradores-diaz-ph-sass.firebaseio.com",
    projectId: "administradores-diaz-ph-sass",
    storageBucket: "administradores-diaz-ph-sass.appspot.com",
    messagingSenderId: "289910440888",
    appId: "1:289910440888:web:9709c00112a0af812d854d",
    measurementId: "G-Q23F5MSKC7");

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    name: 'administradores-diaz-ph-sass',
    options: firebaseConfig,
  );
  print("Handling a background message: ${message.messageId}");
}

Future<FirebaseApp> initializeFirebase() async {
  FirebaseApp app = await Firebase.initializeApp(
    options: firebaseConfig,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  return app;
}
