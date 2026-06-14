class NightscoutException implements Exception {
  NightscoutException(this.message);
  final String message;
  @override
  String toString() => message;
}
