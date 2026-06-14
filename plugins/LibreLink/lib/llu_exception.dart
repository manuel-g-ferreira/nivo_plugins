class LluException implements Exception {
  LluException(this.message);
  final String message;
  @override
  String toString() => message;
}
