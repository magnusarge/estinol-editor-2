// lib/widgets/word_editor.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/word.dart';
import '../providers/dictionary_provider.dart';
import '../utils/string_utils.dart';

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

  // --- LISATUD: Uuendab reaalajas eelvaadet ---
  @override
  void initState() {
    super.initState();
    _sisuController.addListener(() {
      setState(() {}); 
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final word = context.watch<DictionaryProvider>().selectedWord;
    if (word != null && word.id != _currentId) {
      _currentId = word.id;
      _algvormController.text = word.algvorm;
      _otsingVController.text = word.otsingVorm;
      _sisuController.text = word.sisuMd;
      _raskusaste = word.raskusaste;
    } else if (word == null) {
      _currentId = '';
      _algvormController.clear();
      _otsingVController.clear();
      _sisuController.clear();
      _raskusaste = 0;
    }
  }

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
    final isNew = provider.selectedWord == null;

    return Column(
      children: [
        // Sisestusväljad
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _algvormController,
                enabled: isNew,
                decoration: const InputDecoration(labelText: 'Algvorm'),
                onChanged: (val) {
                  if (isNew) _otsingVController.text = StringUtils.normalize(val);
                },
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
          onSelectionChanged: (val) => setState(() => _raskusaste = val.first),
        ),
        const SizedBox(height: 16),

        // Markdown tööriistariba
        Row(
          children: [
            IconButton(onPressed: () => _applyMarkdown('**', '**'), icon: const Icon(Icons.format_bold)),
            IconButton(onPressed: () => _applyMarkdown('_', '_'), icon: const Icon(Icons.format_italic)),
            IconButton(onPressed: () => _applyMarkdown('~~', '~~'), icon: const Icon(Icons.format_strikethrough)),
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
                    child: Markdown(data: _sisuController.text),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Salvestamise nupp
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ElevatedButton(
            onPressed: () {
              // TODO: Salvestamise loogika
            },
            child: const Text('Salvesta muudatused'),
          ),
        ),
      ],
    );
  }
}