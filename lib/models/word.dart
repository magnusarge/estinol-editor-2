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

  factory Word.fromMap(String id, Map<String, dynamic> data) {
    return Word(
      id: id,
      algvorm: data['algvorm'] ?? '',
      otsingVorm: data['otsing_vorm'] ?? '',
      sisuMd: data['sisu_md'] ?? '',
      raskusaste: data['raskusaste'] ?? 0,
      viimatiMuudetud: data['viimati_muudetud'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['viimati_muudetud'])
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