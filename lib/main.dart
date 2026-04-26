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
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Proovime Firebase'i käima panna
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Kui õnnestus, käivitame põhiprogrammi
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DictionaryProvider()),
        ],
        child: const EstinolApp(),
      ),
    );
  } catch (e, stackTrace) {
    // KUI MIDAGI LÄHEB VALESTI, ÄRA SULGE AKENT, VAID NÄITA VIGA!
    runApp(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Kriitiline viga käivitamisel')),
          body: Padding(
            padding: const EdgeInsets.all(32.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Programm jooksis käivitamisel kokku järgmise veaga:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    e.toString(),
                    style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Stack trace:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SelectableText(
                    stackTrace.toString(),
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EstinolApp extends StatelessWidget {
  const EstinolApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Sinu logo roosa tooni ligikaudne vaste
    const Color estinolPink = Color(0xFFD874D8); 

    return MaterialApp(
      title: 'Estiñol Editor 2',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: estinolPink,
          // Lisame natuke heledama tausta kogu äpile
          surface: Colors.grey.shade50, 
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const EditorScreen(); 
          }
          return const LoginScreen();
        },
      ),
    );
  }
}