class KaraokeException implements Exception {
  final String message;

  KaraokeException(this.message);

  @override
  String toString() => message;
}