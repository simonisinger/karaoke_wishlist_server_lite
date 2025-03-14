import 'song.dart';

class History {
  final int id;
  final Song song;
  final int duration;

  History(this.id, this.song, this.duration);

  static History fromMap(Map data) {
    Song song = data['song'].runtimeType == Song ? data['song'] : Song.fromMap(data['song']);
    return History(data['id'], song, data['duration'] ?? song.duration?.inSeconds);
  }
}