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

  bool _hasUnsavedChanges = false;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  // --- UUD VÄLJAD VIIMASE MUUDATUSE JAOKS ---
  Map<String, dynamic> _latestChangesData = {};
  DateTime? _lastModifiedLang;
  DateTime? get lastModifiedLang => _lastModifiedLang;

  // Konstruktor käivitab andmebaasi kuulamise kohe
  DictionaryProvider() {
    _initChangesListener();
  }

  void _initChangesListener() {
    _dbService.getChangesStream().listen((data) {
      _latestChangesData = data;
      _calculateLastModified();
    });
  }

  void _calculateLastModified() {
    int maxTime = 0;
    // Otsime praeguse keele kõige värskemat templit
    _latestChangesData.forEach((key, value) {
      if (key.startsWith('${_currentLang}_') && value is int) {
        if (value > maxTime) maxTime = value;
      }
    });

    if (maxTime > 0) {
      _lastModifiedLang = DateTime.fromMillisecondsSinceEpoch(maxTime);
    } else {
      _lastModifiedLang = null;
    }
    notifyListeners();
  }

  void setUnsavedChanges(bool value) {
    if (_hasUnsavedChanges != value) {
      _hasUnsavedChanges = value;
      // Kasutame microtaski, et vältida build-faasi ajal uuendamise viga
      Future.microtask(() => notifyListeners());
    }
  }

  void togglePreview() {
    _showPreview = !_showPreview;
    notifyListeners();
  }

  void selectWord(Word? word) {
    _selectedWord = word;
    _isAddingNew = false;
    _hasUnsavedChanges = false; // Nullime staatuse
    notifyListeners();
  }

  // --- LISATUD: funktsioon uue sõna alustamiseks ---
  void startAddingNewWord() {
    _selectedWord = null;
    _isAddingNew = true;
    _hasUnsavedChanges = false; // Nullime staatuse
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
    _selectedLetter = 'a';
    
    // --- LISATUD PARANDUS ---
    _selectedWord = null;      // Eemaldame valitud sõna fookusest
    _isAddingNew = false;      // Igaks juhuks tühistame ka uue sõna lisamise
    _hasUnsavedChanges = false; // Nullime muudatuste staatuse
    
    _calculateLastModified();
    await loadDictionary();
    notifyListeners(); // Teavitame UI-d, et pilt puhtaks löödaks
  }

  Future<void> loadDictionary() async {
    _isLoading = true;
    notifyListeners();
    
    _words = await _dbService.fetchAllWords(_currentLang);
    
    _isLoading = false;
    notifyListeners();
  }

  // Sõna salvestamine (uue või olemasoleva)
  Future<void> addOrUpdateWord(Word word) async {
    await _dbService.saveWord(_currentLang, word);
    
    int index = _words.indexWhere((w) => w.id == word.id);
    if (index != -1) {
      _words[index] = word;
    } else {
      _words.add(word);
    }
    
    // --- LISATUD: Muudame vasaku tulba aktiivse tähe vastavaks ---
    if (word.algvorm.isNotEmpty) {
      String firstLetter = word.algvorm[0].toLowerCase();
      // Kontrollime igaks juhuks, kas see täht on antud keele tähestikus olemas
      if (currentAlphabet.contains(firstLetter)) {
        _selectedLetter = firstLetter;
      }
    }

    _hasUnsavedChanges = false;
    _selectedWord = word; // Pärast salvestamist jääb sõna valituks
    _isAddingNew = false;
    notifyListeners();
  }

  Future<void> deleteWord(Word word) async {
    await _dbService.deleteWord(_currentLang, word);
    _words.removeWhere((w) => w.id == word.id);
    _selectedWord = null;
    _hasUnsavedChanges = false;
    notifyListeners();
  }
}