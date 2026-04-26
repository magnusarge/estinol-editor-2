// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/word.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Laeb alla kogu sõnastiku mällu (kõik tähed/dokumendid)
  Future<List<Word>> fetchAllWords(String lang) async {
    List<Word> allWords = [];
    
    // Loeme kõik dokumendid (iga dokument on üks täht) kollektsioonist
    var snapshot = await _db.collection('words_$lang').get();
    
    for (var doc in snapshot.docs) {
      Map<String, dynamic> wordsMap = doc.data();
      wordsMap.forEach((wordId, wordData) {
        allWords.add(Word.fromMap(wordId, wordData));
      });
    }
    
    return allWords;
  }

  Future<void> saveWord(String lang, Word word) async {
    // Faili nimi (dokument) on algvormi esimene täht
    String letter = word.algvorm.toLowerCase()[0];
    
    await _db.collection('words_$lang').doc(letter).set(
      {word.id: word.toMap()},
      SetOptions(merge: true),
    );

    // Muudatuste logi
    await _db.collection('data').doc('changes').set(
      {'${lang}_$letter': DateTime.now().millisecondsSinceEpoch},
      SetOptions(merge: true),
    );
  }

  Future<void> deleteWord(String lang, Word word) async {
    String letter = word.algvorm.toLowerCase()[0];
    
    await _db.collection('words_$lang').doc(letter).update({
      word.id: FieldValue.delete(),
    });
  }
}