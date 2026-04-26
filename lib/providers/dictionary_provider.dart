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

  // --- UUD VÄLJAD TÄHESTIKU JAOKS ---
  String _selectedLetter = 'a'; // Vaikimisi valitud täht
  String get selectedLetter => _selectedLetter;

  // Eeldefineeritud tähestikud, et saaksime tühje tähti hallina näidata
  final List<String> esAlphabet = [
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
    'n', 'ñ', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  ];
  final List<String> etAlphabet = [
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 
    'n', 'o', 'p', 'q', 'r', 's', 'š', 'z', 'ž', 't', 'u', 'v', 'w', 
    'õ', 'ä', 'ö', 'ü', 'x', 'y'
  ];

  List<String> get currentAlphabet => _currentLang == 'es' ? esAlphabet : etAlphabet;

  bool _showPreview = true;
  bool get showPreview => _showPreview;

  Word? _selectedWord;
  Word? get selectedWord => _selectedWord;

  bool _isAddingNew = false;
  bool get isAddingNew => _isAddingNew;

  void togglePreview() {
    _showPreview = !_showPreview;
    notifyListeners();
  }

  void selectWord(Word? word) {
    _selectedWord = word;
    _isAddingNew = false; // Kui valime nimekirjast sõna, siis me ei lisa uut
    notifyListeners();
  }

  // --- LISATUD: funktsioon uue sõna alustamiseks ---
  void startAddingNewWord() {
    _selectedWord = null;
    _isAddingNew = true;
    notifyListeners();
  }

  void setSelectedLetter(String letter) {
    _selectedLetter = letter;
    notifyListeners();
  }

  // Filtreeritud sõnad vastavalt valitud tähele
  List<Word> getWordsByLetter(String letter) {
    return _words.where((w) {
      // Topeltkaitse: teeme kindlaks, et algvorm eksisteerib ja on kindlasti string
      final wordForm = w.algvorm.toString().toLowerCase();
      final targetLetter = letter.toLowerCase();
      // Kui algvorm on tühi (näiteks vigane andmebaasi rida), siis see tähtede alla ei ilmu
      return wordForm.isNotEmpty && wordForm.startsWith(targetLetter);
    }).toList()
      ..sort((a, b) => a.algvorm.toString().compareTo(b.algvorm.toString()));
  }

  // Statistika: Sõnu keeles kokku
  int get totalWords => _words.length;

  // Statistika: Sõnu konkreetse tähega
  int getCountByLetter(String letter) {
    return _words.where((w) {
      final wordForm = w.algvorm.toString().toLowerCase();
      final targetLetter = letter.toLowerCase();
      return wordForm.isNotEmpty && wordForm.startsWith(targetLetter);
    }).length;
  }

  // Keele vahetamine ja uute andmete laadimine
  Future<void> switchLanguage(String lang) async {
    _currentLang = lang;
    _selectedLetter = 'a'; // Resetib tähe
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