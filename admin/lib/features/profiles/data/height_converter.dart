/// Same logic as `runanubandh/lib/utils/height_converter.dart`.
class HeightConverter {
  static Map<String, int> cmToFeetInches(int cm) {
    final totalInches = (cm / 2.54).round();
    return {'feet': totalInches ~/ 12, 'inches': totalInches % 12};
  }

  static int feetInchesToCm(int feet, int inches) {
    return ((feet * 12 + inches) * 2.54).round();
  }

  static String formatFeetInches(int feet, int inches) {
    if (inches > 0) return "$feet'$inches\"";
    return "$feet'";
  }
}
