// lib/models/word.dart
class Word {
  final String id;
  final String algvorm;
  final String otsingVorm;
  final String sisuMd;
  final int raskusaste; // 0=Määramata, 1=Kerge, 2=Keskmine, 3=Raske
  final DateTime viimatiMuudetud;

  Word({
    required this.id,
    required this.algvorm,
    required this.otsingVorm,
    required this.sisuMd,
    required this.raskusaste,
    required this.viimatiMuudetud,
  });

  factory Word.fromMap(String id, dynamic rawData) {
    // Kaitseme end ootamatute andmete eest (kui Firebase'i rida polegi Map)
    if (rawData == null || rawData is! Map) {
      return Word(
        id: id, algvorm: '', otsingVorm: '', sisuMd: '', 
        raskusaste: 0, viimatiMuudetud: DateTime.now()
      );
    }
    
    final data = rawData as Map<dynamic, dynamic>;
    
    return Word(
      id: id,
      // .toString() garanteerib, et isegi kui baasis on kogemata number, tehakse see tekstiks
      algvorm: data['algvorm']?.toString() ?? '',
      otsingVorm: data['otsing_vorm']?.toString() ?? '',
      sisuMd: data['sisu_md']?.toString() ?? '',
      raskusaste: data['raskusaste'] is int ? data['raskusaste'] : 0,
      viimatiMuudetud: data['viimati_muudetud'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['viimati_muudetud'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'algvorm': algvorm,
      'otsing_vorm': otsingVorm,
      'sisu_md': sisuMd,
      'raskusaste': raskusaste,
      'viimati_muudetud': viimatiMuudetud.millisecondsSinceEpoch,
    };
  }
}