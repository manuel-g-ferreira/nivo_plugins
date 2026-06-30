class DexcomException implements Exception {
  DexcomException(this.message);
  final String message;
  @override
  String toString() => message;
}
