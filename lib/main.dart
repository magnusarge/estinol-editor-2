// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'providers/dictionary_provider.dart';
import 'screens/login_screen.dart';
import 'screens/editor_screen.dart'; // Loome selle hiljem

void main() async {
  // Vajalik, kuna initsialiseerime Firebase'i enne runApp() käivitamist
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DictionaryProvider()),
      ],
      child: const EstinolApp(),
    ),
  );
}

class EstinolApp extends StatelessWidget {
  const EstinolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Estiñol Editor 2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // StreamBuilder jälgib reaalajas, kas kasutaja on sisse logitud või mitte
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Kui Firebase alles kontrollib staatust
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Kui kasutaja on olemas, suuname pealehele, muidu sisselogimisse
          if (snapshot.hasData) {
            return const EditorScreen(); 
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}