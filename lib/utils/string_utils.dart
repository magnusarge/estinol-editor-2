// lib/utils/string_utils.dart
class StringUtils {
  static String normalize(String text) {
    var str = text.toLowerCase();
    var withDia = 'áéíóúüñäöõšž';
    var withoutDia = 'aeiouunaoosz';
    
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  /// Produces a stable sort key for "human" alphabetical order.
  ///
  /// - For Spanish (`lang == 'es'`), accents are ignored (á -> a) but `ñ` is kept
  ///   as a distinct letter that sorts after `n` and before `o`.
  /// - For other languages, we fall back to accent-insensitive comparison.
  static String sortKey(String text, {required String lang}) {
    var str = text.toLowerCase().trim();

    if (lang == 'es') {
      // Keep ñ distinct (after n) by mapping it to a sequence that compares
      // after any "na..nz" but before "o..".
      str = str.replaceAll('ñ', 'n{');

      // Strip accents for vowels/ü only (do not touch the '{' we introduced).
      const withDia = 'áéíóúü';
      const withoutDia = 'aeiouu';
      for (int i = 0; i < withDia.length; i++) {
        str = str.replaceAll(withDia[i], withoutDia[i]);
      }
      return str;
    }

    return normalize(str);
  }
}