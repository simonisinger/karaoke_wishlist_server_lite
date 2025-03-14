

import 'playlist_item.dart';

class Playlist {
  final int id;
  final String name;
  final List<PlaylistItem> items;

  Playlist(this.id, this.name, this.items);

  static Playlist fromMap(Map data) => Playlist(
      data['id'],
      data['name'],
      data['items'].map((e) => PlaylistItem.fromMap(e))
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'items': items.map((e) => e.toMap()).toList()
  };
}