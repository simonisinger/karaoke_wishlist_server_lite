import 'playlist.dart';

class Application {
  final int id;
  final String username;
  final Playlist playlist;

  Application(this.id, this.username, this.playlist);

  static Application fromMap(Map data) => Application(
      data['id'],
      data['username'],
      Playlist.fromMap(data['playlist'])
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'username': username,
    'playlist': playlist.toMap(),
  };
}