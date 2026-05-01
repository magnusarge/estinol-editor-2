// lib/screens/editor_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/word_editor.dart';
import '../providers/dictionary_provider.dart';

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = (distance + dashLength).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength ||
        oldDelegate.radius != radius;
  }
}

enum _WordListMove { previous, next }

class _MoveWordSelectionIntent extends Intent {
  const _MoveWordSelectionIntent(this.move);
  const _MoveWordSelectionIntent.previous() : move = _WordListMove.previous;
  const _MoveWordSelectionIntent.next() : move = _WordListMove.next;

  final _WordListMove move;
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // Internetiühenduse jälgimiseks
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternet = true;

  final FocusNode _wordListFocusNode = FocusNode(debugLabel: 'word_list');
  final ScrollController _wordListScrollController = ScrollController();
  static const double _wordListItemExtent = 72.0;

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
    _wordListFocusNode.dispose();
    _wordListScrollController.dispose();
    super.dispose();
  }

  Future<void> _moveWordSelection(_WordListMove move) async {
    final provider = context.read<DictionaryProvider>();
    final words = provider.getWordsByLetter(provider.selectedLetter);
    if (words.isEmpty) return;

    final selectedId = provider.selectedWord?.id;
    int currentIndex = selectedId == null ? -1 : words.indexWhere((w) => w.id == selectedId);
    if (currentIndex < 0) currentIndex = 0;

    final int nextIndex = switch (move) {
      _WordListMove.previous => (currentIndex - 1).clamp(0, words.length - 1),
      _WordListMove.next => (currentIndex + 1).clamp(0, words.length - 1),
    };

    if (nextIndex == currentIndex) return;

    if (!await _canProceed()) return;

    provider.selectWord(words[nextIndex]);

    final targetOffset = nextIndex * _wordListItemExtent;
    if (!_wordListScrollController.hasClients) return;

    final viewport = _wordListScrollController.position.viewportDimension;
    final currentOffset = _wordListScrollController.offset;
    final minVisible = currentOffset;
    final maxVisible = currentOffset + viewport - _wordListItemExtent;

    if (targetOffset < minVisible) {
      await _wordListScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    } else if (targetOffset > maxVisible) {
      await _wordListScrollController.animateTo(
        (targetOffset - viewport + _wordListItemExtent).clamp(
          _wordListScrollController.position.minScrollExtent,
          _wordListScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  // --- SALVESTAMATA MUUDATUSTE KAITSE ---
  Future<bool> _canProceed() async {
    final provider = context.read<DictionaryProvider>();
    if (!provider.hasUnsavedChanges) return true; // Kui muudatusi pole, luba minna

    // Kui on muudatusi, küsime kasutajalt kinnitust
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Salvestamata muudatused'),
        content: const Text('Sul on salvestamata muudatusi. Kas soovid jätkata ja muudatused kaotada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Ei jätka
            child: const Text('Tagasi toimetama'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true), // Jätka ja kaota muudatused
            child: const Text('Jätka ja kaota muudatused'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      provider.setUnsavedChanges(false); // Nullime lipu
      return true;
    }
    return false;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    final hr = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d.$m.$y $hr:$min';
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
            onPressed: () async {
              if (await _canProceed()) FirebaseAuth.instance.signOut();
            },
            tooltip: 'Logi välja',
          ),
          const SizedBox(width: 16),
        ],
      ),

      // --- PÕHISISU (KAKS TULPA) ---
      body: provider.errorMessage.isNotEmpty
          // KUI ON VIGA, NÄITAME SEDA PUNASELT EES:
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  provider.errorMessage, 
                  style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : provider.isLoading
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
                              onPressed: () async {
                                if (await _canProceed()) {
                                  provider.switchLanguage(provider.currentLang == 'es' ? 'et' : 'es');
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Uus sõna'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              onPressed: () async {
                                if (await _canProceed()) {
                                  provider.startAddingNewWord();
                                }
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
                              onTap: () async {
                                if (await _canProceed()) {
                                  provider.setSelectedLetter(letter);
                                }
                              },
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
                          child: Shortcuts(
                            shortcuts: const <ShortcutActivator, Intent>{
                              SingleActivator(LogicalKeyboardKey.arrowUp): _MoveWordSelectionIntent.previous(),
                              SingleActivator(LogicalKeyboardKey.arrowDown): _MoveWordSelectionIntent.next(),
                            },
                            child: Actions(
                              actions: <Type, Action<Intent>>{
                                _MoveWordSelectionIntent: CallbackAction<_MoveWordSelectionIntent>(
                                  onInvoke: (intent) {
                                    _moveWordSelection(intent.move);
                                    return null;
                                  },
                                ),
                              },
                              child: Focus(
                                focusNode: _wordListFocusNode,
                                child: Builder(
                                  builder: (context) {
                                    final words = provider.getWordsByLetter(provider.selectedLetter);
                                    return ListView.builder(
                                      controller: _wordListScrollController,
                                      itemExtent: _wordListItemExtent,
                                      itemCount: words.length,
                                      itemBuilder: (context, index) {
                                        final word = words[index];
                                        final isSelected = provider.selectedWord?.id == word.id;

                                        final tile = ListTile(
                                          selected: isSelected,
                                          title: Text(word.algvorm, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text(word.otsingVorm, style: TextStyle(color: Colors.grey.shade600)),
                                          onTap: () async {
                                            _wordListFocusNode.requestFocus();
                                            if (await _canProceed()) {
                                              provider.selectWord(word);
                                            }
                                          },
                                        );

                                        if (!isSelected) return tile;

                                        return CustomPaint(
                                          foregroundPainter: _DashedRectPainter(
                                            color: Colors.grey.shade400,
                                            strokeWidth: 1,
                                            dashLength: 3,
                                            gapLength: 3,
                                            radius: 6,
                                          ),
                                          child: tile,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
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
                Text('Viimati muudetud: ${_formatDate(provider.lastModifiedLang)}'),
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