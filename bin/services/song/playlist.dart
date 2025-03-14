import 'package:mysql1/mysql1.dart';

import '../../core/exception.dart';
import '../../entity/playlist.dart';
import '../../entity/playlist_item.dart';
import '../../entity/song.dart';
import '../../core/mysql.dart';
import 'song.dart';

class PlaylistService {
  SongService songService = SongService();

  Future<Playlist> createPlaylist(String name, List<Song> songs,
      {String creator = 'System', String ip = '127.0.0.1'}) async {
    Results queryResult =
        await mySql.query('INSERT INTO playlist (name) VALUE (?)', [name]);
    int? id = queryResult.insertId;

    if (id == null) {
      throw KaraokeException('playlist entry couldnt be created');
    }

    String entryString = List.filled(songs.length, '(?,?,?,?)').join(', ');
    List valuesList = [];
    for (Song song in songs) {
      valuesList.add(song.id);
      valuesList.add(id);
      valuesList.add(creator);
      valuesList.add(ip);
    }
    await mySql.query(
        'INSERT INTO playlist_song (song_id, playlist_id, added_by, ip) VALUES $entryString',
        valuesList
    );

    return await getPlaylist(id);
  }

  Future<void> addSongToPlaylist(Playlist playlist, Song song, {String creator = 'System', String ip = '127.0.0.1'}) async {
    if (playlist.items.where((element) => element.id == song.id).isEmpty) {
      Results playlistItemResults = await mySql.query(
          'INSERT INTO playlist_song (song_id, playlist_id, added_by, ip) VALUE (?,?,?,?)',
          [song.id, playlist.id, creator, ip]
      );

      playlist.items.add(
          PlaylistItem(playlistItemResults.insertId!, song, creator, ip, false)
      );
    } else {
      throw KaraokeException('Lied bereits in der Playlist');
    }
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    await mySql.query("DELETE FROM playlist_song WHERE playlist_id = ?", [playlist.id]);
    await mySql.query("DELETE FROM playlist WHERE id = ?", [playlist.id]);
  }

  Future<Playlist> getPlaylist(int id) async {
    Results playlistRaw =
        await mySql.query("SELECT * FROM playlist WHERE id = ?", [id]);
    Results playlistItemsRaw = await mySql
        .query("SELECT * FROM playlist_song WHERE playlist_id = ?", [id]);
    List<PlaylistItem> items = [];
    for (ResultRow playlistItemRaw in playlistItemsRaw) {
      Song? song = await songService.getSong(playlistItemRaw['song_id']);
      if (song.duration != null && song.hash != null) {
        items.add(
            PlaylistItem(
                playlistItemRaw['id'],
                song,
                playlistItemRaw['added_by'],
                playlistItemRaw['ip'],
                playlistItemRaw['file_warning'] == 1 ? true : false
            )
        );
      }
    }
    return Playlist(id, playlistRaw.first['name'], items);
  }

  Future<PlaylistItem> getPlaylistItem(int id) async {
    Map playlistItemResults = (await mySql.query('SELECT * FROM playlist_song WHERE id = ?', [id])).first.fields;
    playlistItemResults['song'] = (await mySql.query("SELECT * FROM songs WHERE id = ?", [playlistItemResults['song_id']])).first.fields;
    return PlaylistItem.fromMap(playlistItemResults);
  }

  Future<List<Playlist>> getPlaylists() async {
    Results playlistRaw =
        await mySql.query("SELECT * FROM playlist");

    List<Playlist> playlists = [];
    for (ResultRow playlistRawRow in playlistRaw) {
      List<PlaylistItem> items = [];
      Results playlistItemsRaw = await mySql.query(
          "SELECT * FROM playlist_song WHERE playlist_id = ?",
          [playlistRawRow['id']]
      );
      for (ResultRow playlistItemRaw in playlistItemsRaw) {
        Song? song = await songService.getSong(playlistItemRaw['song_id']);
        if (song.duration != null && song.hash != null) {
          items.add(
              PlaylistItem(
                  playlistItemRaw['id'],
                  song,
                  playlistItemRaw['added_by'],
                  playlistItemRaw['ip'],
                  playlistItemRaw['file_warning'] == 1 ? true : false,
              )
          );
        }
      }
      playlists.add(Playlist(playlistRawRow['id'], playlistRawRow['name'], items));
    }

    return playlists;
  }
}
