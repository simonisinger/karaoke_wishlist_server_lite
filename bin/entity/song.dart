class Song {
  final int id;
  final String pfad;
  final String datei;
  final Duration? duration;
  final String? hash;

  Song(this.id, this.pfad, this.datei, this.duration, this.hash);

  static Song fromMap(Map data) {
    Duration? duration;
    if (data['duration'] != null) {
      List<String> durationItems = data['duration'].split(RegExp(r'([.:])'));
      if (durationItems.length > 2) {
        duration = Duration(
            seconds: int.parse(durationItems[2]),
            minutes: int.parse(durationItems[1])
        );
      }
    }
    return Song(
        data['id'],
        data['pfad'],
        data['datei'],
        duration,
        data['hash']
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'pfad': pfad,
    'datei': datei,
    'duration': duration.toString(),
    'hash': hash
  };
}