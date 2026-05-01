// lib/widgets/word_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/dictionary_provider.dart';
import '../utils/string_utils.dart';

enum _MarkdownAction { bold, italic }

class _MarkdownIntent extends Intent {
  const _MarkdownIntent(this.action);
  const _MarkdownIntent.bold() : action = _MarkdownAction.bold;
  const _MarkdownIntent.italic() : action = _MarkdownAction.italic;

  final _MarkdownAction action;
}

class WordEditor extends StatefulWidget {
  const WordEditor({super.key});

  @override
  State<WordEditor> createState() => _WordEditorState();
}

class _WordEditorState extends State<WordEditor> {
  final _algvormController = TextEditingController();
  final _otsingVController = TextEditingController();
  final _sisuController = TextEditingController();
  int _raskusaste = 0;
  String _currentId = '';

  bool _isDuplicate = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _algvormController.addListener(_checkChangesAndDuplicates);
    _sisuController.addListener(_checkChangesAndDuplicates);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<DictionaryProvider>();
    final word = provider.selectedWord;
    
    if (word != null && word.id != _currentId) {
      _isLoadingData = true; // ALUSTAME LAADIMIST
      
      _currentId = word.id;
      _algvormController.text = word.algvorm;
      _otsingVController.text = word.otsingVorm;
      _sisuController.text = word.sisuMd;
      _raskusaste = word.raskusaste;
      _isDuplicate = false;

      // Kasutame lühikest viivitust, et kuulajad jõuaksid "vaikida"
      Future.microtask(() {
        _isLoadingData = false;
        // Pärast laadimist kinnitame, et andmed on puhtad
        context.read<DictionaryProvider>().setUnsavedChanges(false);
      });
      
    } else if (word == null && !provider.isAddingNew) {
      _currentId = '';
    } else if (word == null && provider.isAddingNew && _currentId != 'NEW') {
      _isLoadingData = true;
      _currentId = 'NEW';
      _algvormController.clear();
      _otsingVController.clear();
      _sisuController.clear();
      _raskusaste = 0;
      _isDuplicate = false;
      
      Future.microtask(() {
        _isLoadingData = false;
        context.read<DictionaryProvider>().setUnsavedChanges(false);
      });
    }
  }

  @override
  void dispose() {
    _algvormController.dispose();
    _otsingVController.dispose();
    _sisuController.dispose();
    super.dispose();
  }

  // --- KONTROLLID (Duplikaadid ja Salvestamata muudatused) ---
  void _checkChangesAndDuplicates() {
    // KUI LAADIMINE KÄIB, SIIS ME EI KONTROLLI MUUDATUSI
    if (_isLoadingData) return; 

    final provider = context.read<DictionaryProvider>();
    final word = provider.selectedWord;

    // 1. Duplikaadi kontroll
    if (provider.isAddingNew) {
      final input = _algvormController.text.trim().toLowerCase();
      final duplicateExists = provider.words.any((w) => w.algvorm.toLowerCase() == input);
      if (_isDuplicate != duplicateExists) {
        setState(() => _isDuplicate = duplicateExists);
      }
    }

    // 2. Salvestamata muudatuste kontroll
    bool isDirty = false;
    if (provider.isAddingNew) {
      isDirty = _algvormController.text.isNotEmpty || _sisuController.text.isNotEmpty;
    } else if (word != null) {
      isDirty = _algvormController.text != word.algvorm ||
                _sisuController.text != word.sisuMd ||
                _raskusaste != word.raskusaste;
    }
    
    provider.setUnsavedChanges(isDirty);
    setState(() {});
  }

  // --- NUPPUDE TEGEVUSED ---
  void _saveForm() {
    final provider = context.read<DictionaryProvider>();
    final isNew = provider.isAddingNew;

    final word = Word(
      id: isNew ? 'word_${DateTime.now().millisecondsSinceEpoch}' : _currentId,
      algvorm: _algvormController.text.trim(),
      otsingVorm: _otsingVController.text.trim(),
      sisuMd: _sisuController.text.trim(),
      raskusaste: _raskusaste,
      viimatiMuudetud: DateTime.now(),
    );

    provider.addOrUpdateWord(word);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sõna edukalt salvestatud!'), backgroundColor: Colors.green),
    );
  }

  void _cancelEditing() {
    final provider = context.read<DictionaryProvider>();
    // Tühistame muudatused laadides eelmise sõna uuesti või tühjendades uue sõna vormi
    if (provider.isAddingNew) {
      provider.startAddingNewWord(); 
    } else {
      provider.selectWord(provider.selectedWord); 
      // Sunnime lahtrid uuesti väärtusi võtma
      setState(() { _currentId = ''; }); 
    }
  }

  Future<void> _deleteWord() async {
    final provider = context.read<DictionaryProvider>();
    final word = provider.selectedWord;
    if (word == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kustuta sõna'),
        content: Text('Kas oled kindel, et soovid sõna "${word.algvorm}" kustutada? Seda tegevust ei saa tagasi võtta.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tühista')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Kustuta'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteWord(word);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sõna kustutatud.')),
        );
      }
    }
  }

  // ... [siia vahele jääb _applyMarkdown funktsioon täpselt samana nagu enne] ...
  void _applyMarkdown(String prefix, String suffix) {
    final text = _sisuController.text;
    final selection = _sisuController.selection;
    if (selection.isCollapsed) return;

    final selectedText = selection.textInside(text);
    final newText = text.replaceRange(selection.start, selection.end, '$prefix$selectedText$suffix');
    
    _sisuController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + prefix.length + selectedText.length + suffix.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DictionaryProvider>();
    final isNew = provider.isAddingNew;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyB, control: true): _MarkdownIntent.bold(),
        SingleActivator(LogicalKeyboardKey.keyI, control: true): _MarkdownIntent.italic(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _MarkdownIntent: CallbackAction<_MarkdownIntent>(
            onInvoke: (intent) {
              switch (intent.action) {
                case _MarkdownAction.bold:
                  _applyMarkdown('**', '**');
                  break;
                case _MarkdownAction.italic:
                  _applyMarkdown('*', '*');
                  break;
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
        // --- HOIATUS DUPLIKAADI KORRAL ---
        if (_isDuplicate)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.red.shade100,
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('See sõna on juba sõnastikus olemas!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

        // Sisestusväljad
        Row(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _algvormController,
                      enabled: isNew,
                      decoration: const InputDecoration(labelText: 'Algvorm'),
                      onChanged: (val) {
                        if (isNew) {
                          _otsingVController.text = StringUtils.normalize(val);
                        }
                      },
                    ),
                  ),
                  if (!isNew)
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Kopeeri algvorm',
                      onPressed: _algvormController.text.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: _algvormController.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Algvorm kopeeritud')),
                              );
                            },
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _otsingVController,
                enabled: false,
                decoration: const InputDecoration(labelText: 'Otsinguvorm'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Raskusaste
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Määramata')),
            ButtonSegment(value: 1, label: Text('Kerge')),
            ButtonSegment(value: 2, label: Text('Keskmine')),
            ButtonSegment(value: 3, label: Text('Raske')),
          ],
          selected: {_raskusaste},
          onSelectionChanged: (val) {
            setState(() => _raskusaste = val.first);
            _checkChangesAndDuplicates();
          },
        ),
        const SizedBox(height: 16),

        // Markdown tööriistariba
        Row(
          children: [
            IconButton(onPressed: () => _applyMarkdown('**', '**'), icon: const Icon(Icons.format_bold)),
            IconButton(onPressed: () => _applyMarkdown('*', '*'), icon: const Icon(Icons.format_italic)),
            const Spacer(),
            TextButton.icon(
              onPressed: provider.togglePreview,
              icon: Icon(provider.showPreview ? Icons.visibility_off : Icons.visibility),
              label: Text(provider.showPreview ? 'Peida eelvaade' : 'Näita eelvaadet'),
            ),
          ],
        ),

        // Redaktor ja Eelvaade
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  controller: _sisuController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Kirjuta Markdown tekst siia...',
                  ),
                ),
              ),
              if (provider.showPreview) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: MarkdownBody(data: _sisuController.text),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // --- ALUMINE NUPPUDE RIDA ---
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Kustuta nupp (nähtav ainult olemasoleva sõna muutmisel)
              if (!isNew)
                TextButton.icon(
                  onPressed: _deleteWord,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Kustuta', style: TextStyle(color: Colors.red)),
                ),
              const Spacer(),
              // Katkesta nupp
              if (provider.hasUnsavedChanges)
                TextButton(
                  onPressed: _cancelEditing,
                  child: const Text('Katkesta'),
                ),
              const SizedBox(width: 16),
              // Salvesta nupp
              ElevatedButton.icon(
                // Nupp on inaktiivne, kui on duplikaat või algvorm on tühi
                onPressed: _isDuplicate || _algvormController.text.trim().isEmpty ? null : _saveForm,
                icon: const Icon(Icons.save),
                label: const Text('Salvesta muudatused'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
            ],
          ),
        ),
      ),
    );
  }
}
