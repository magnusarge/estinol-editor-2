// lib/screens/editor_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/word_editor.dart';
import '../providers/dictionary_provider.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // Internetiühenduse jälgimiseks
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    
    // 1. Paneme käivitamisel sõnastiku laadima
    // Kasutame Future.microtask, et Provideri väljakutse toimuks pärast esimest renderdust
    Future.microtask(() {
      context.read<DictionaryProvider>().loadDictionary();
    });

    // 2. Paneme käima internetiühenduse jälgija
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        // Kui tulemustes ei ole 'none', on mingisugune ühendus olemas
        _hasInternet = !results.contains(ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DictionaryProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // --- ÜLEMINE RIDA (APPBAR) ---
      appBar: AppBar(
        // Kasutame logo, mille saatsid (kuna see on PNG/SVG, kasutame lihtsuse mõttes PNG ikooni)
        title: Row(
          children: [
            Image.asset('assets/icon.png', height: 32),
            const SizedBox(width: 12),
            const Text('Estiñol Editor 2', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Logi välja',
          ),
          const SizedBox(width: 16),
        ],
      ),

      // --- PÕHISISU (KAKS TULPA) ---
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === 1. TULP ===
                Expanded(
                  flex: 3,
                  child: Container(
                    color: colorScheme.surface,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // NUPUD: Keele vahetus ja Uus sõna
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.swap_horiz),
                              label: Text(provider.currentLang == 'es' ? '🇪🇸 ES' : '🇪🇪 ET'),
                              onPressed: () {
                                provider.switchLanguage(provider.currentLang == 'es' ? 'et' : 'es');
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Uus sõna'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              onPressed: () {
                                provider.startAddingNewWord();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // TÄHESTIKU NUPUD
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: provider.currentAlphabet.map((letter) {
                            final count = provider.getCountByLetter(letter);
                            final isSelected = provider.selectedLetter == letter;
                            final hasWords = count > 0;

                            return InkWell(
                              onTap: () => provider.setSelectedLetter(letter),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? colorScheme.primary 
                                      : (hasWords ? colorScheme.primaryContainer : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  letter.toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected 
                                        ? colorScheme.onPrimary 
                                        : (hasWords ? colorScheme.onPrimaryContainer : Colors.grey.shade500),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),

                        // SÕNADE NIMEKIRI
                        Expanded(
                          child: ListView.builder(
                            itemCount: provider.getWordsByLetter(provider.selectedLetter).length,
                            itemBuilder: (context, index) {
                              final word = provider.getWordsByLetter(provider.selectedLetter)[index];
                              return ListTile(
                                title: Text(word.algvorm, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(word.otsingVorm, style: TextStyle(color: Colors.grey.shade600)),
                                onTap: () => provider.selectWord(word),
                              );
                            },
                          ),
                        ),
                        const Divider(),

                        // STATISTIKA VALITUD TÄHE KOHTA
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Sõnu tähega "${provider.selectedLetter.toUpperCase()}": ${provider.getCountByLetter(provider.selectedLetter)}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const VerticalDivider(width: 1, thickness: 1),

                // === 2. TULP ===
                Expanded(
                  flex: 7,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: provider.selectedWord == null && !provider.isAddingNew
                        ? const Center(child: Text('Vali sõna või lisa uus'))
                        : const WordEditor(),
                  ),
                ),
              ],
            ),

      // --- ALUMINE STAATUSERIBA ---
      bottomNavigationBar: BottomAppBar(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Vasak pool: Keel ja koguarv
            Text(
              'Keel: ${provider.currentLang == 'es' ? 'Hispaania' : 'Eesti'}   |   '
              'Sõnu kokku: ${provider.totalWords}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            
            // Parem pool: Viimane muudatus ja internet
            Row(
              children: [
                // TODO: Siia lisame hiljem viimase muudatuse aja andmebaasist
                const Text('Viimati muudetud: -'),
                const SizedBox(width: 16),
                Icon(
                  _hasInternet ? Icons.wifi : Icons.wifi_off,
                  color: _hasInternet ? Colors.green : Colors.red,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}