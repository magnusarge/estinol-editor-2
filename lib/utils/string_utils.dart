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
}