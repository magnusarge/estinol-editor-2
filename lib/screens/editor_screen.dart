// lib/screens/editor_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estiñol Editor 2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Logi välja',
          ),
        ],
      ),
      body: const Center(
        child: Text('Siia tuleb peagi kahe tulbaga redaktor.'),
      ),
    );
  }
}