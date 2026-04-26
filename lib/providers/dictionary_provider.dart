// lib/providers/dictionary_provider.dart
import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/database_service.dart';

class DictionaryProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<Word> _words = [];
  String _currentLang = 'es'; // Vaikimisi hispaania
  bool _isLoading = false;

  List<Word> get words => _words;
  String get currentLang => _currentLang;
  bool get isLoading => _isLoading;

  // Filtreeritud sõnad vastavalt valitud tähele
  List<Word> getWordsByLetter(String letter) {
    return _words
        .where((w) => w.algvorm.toLowerCase().startsWith(letter.toLowerCase()))
        .toList()
      ..sort((a, b) => a.algvorm.compareTo(b.algvorm));
  }

  // Statistika: Sõnu keeles kokku
  int get totalWords => _words.length;

  // Statistika: Sõnu konkreetse tähega
  int getCountByLetter(String letter) {
    return _words.where((w) => w.algvorm.toLowerCase().startsWith(letter.toLowerCase())).length;
  }

  // Keele vahetamine ja uute andmete laadimine
  Future<void> switchLanguage(String lang) async {
    _currentLang = lang;
    await loadDictionary();
  }

  Future<void> loadDictionary() async {
    _isLoading = true;
    notifyListeners();
    
    _words = await _dbService.fetchAllWords(_currentLang);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addOrUpdateWord(Word word) async {
    await _dbService.saveWord(_currentLang, word);
    
    // Uuendame mälus olevat nimekirja ilma uuesti serverist tõmbamata
    int index = _words.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      _words[index] = word;
    } else {
      _words.add(word);
    }
    notifyListeners();
  }
}