import 'song.dart';

class PlaylistItem {
  final int id;
  final Song song;
  final String addedBy;
  final String ip;
  final bool fileWarning;

  PlaylistItem(this.id, this.song, this.addedBy, this.ip, this.fileWarning);

  static PlaylistItem fromMap(Map data) => PlaylistItem(
      data['id'],
      data['song'].runtimeType == Song ? data['song'] : Song.fromMap(data['song']),
      data['added_by'],
      data['ip'],
      data['file_warning'] == 1 ? true : false
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'song': song.toMap(),
    'addedBy': addedBy,
    'ip': ip,
    'fileWarning': fileWarning
  };
}