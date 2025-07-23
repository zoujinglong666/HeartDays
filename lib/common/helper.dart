
final class Helper {
  Helper._();
  static bool isEmpty(dynamic input) {
    if (input == null) return true;
    if (input is String || input is List || input is Map) {
      return input.isEmpty;
    }
    return false;
  }
  static bool isNotEmpty(dynamic input) {
    if (input == null) return false;
    if (input is String || input is List || input is Map) {
      return input.isNotEmpty;
    }
    return true;
  }
}