import 'package:mysql1/mysql1.dart';

import '../../cache/import.dart';
import '../../core/exception.dart';
import '../../core/mysql.dart';
import '../../entity/setting.dart';
import '../../entity/song.dart';
import '../setting/setting.dart';

class SongService {
  final SettingService _settingService = SettingService();
  Future<List<Song>> searchSong(String searchQuery) async {
    List<String> searchWords = searchQuery.split(' ').map((e) => '%$e%').toList();
    String searchString = List.filled(searchWords.length, "datei LIKE ?").join(' AND ');
    Results songsRaw = await mySql.query('SELECT * FROM songs WHERE $searchString', searchWords);
    return _removeInvalidSongs(songsRaw.map((e) => Song.fromMap(e.fields)).toList());
  }

  Future<void> wishSong(Song song, String addedBy, String ip) async {
    Results wishlistOpenRaw = await mySql.query("SELECT value FROM settings WHERE name = 'wishlist'");
    if (wishlistOpenRaw.isEmpty) {
      throw KaraokeException('Wunschlistenkonfiguration fehlt. Bitte wende dich an den Administrator');
    }

    Results ipCheckRaw = await mySql.query("SELECT * FROM allowed_ips WHERE ip = ?", [ip]);

    if (wishlistOpenRaw.first['value'] != '1' && (ipCheckRaw.isEmpty || ipCheckRaw.first['bypass'] != 'all')) {
      throw KaraokeException('Die Wunschliste wurde deaktiviert. Bitte wende dich an die Karaokehelfer');
    }

    Setting songCountSetting = await _settingService.getSetting('max-user-song-counts');
    Results songCount = await mySql.query('SELECT COUNT(*) AS count FROM playlist_song WHERE playlist_id = 1 AND ip = ?', [ip]);
    if (songCount.first['count'] >= int.parse(songCountSetting.value) && (ipCheckRaw.isEmpty || ipCheckRaw.first.fields['bypass'] != 'all' && ipCheckRaw.first.fields['bypass'] != 'wishlist')) {
      throw KaraokeException('Du hast dir bereits ${songCount.first['count']} Lieder in der Warteschleife. Warte bitte bis deine Songs gespielt wurden bevor du dir was neues wünscht');
    }

    bool songExists = (await mySql.query("SELECT id FROM playlist_song WHERE playlist_id = 1 AND song_id = ?", [song.id])).isNotEmpty;
    if (songExists) {
      throw KaraokeException('Lied bereits in der Wunschliste');
    }

    await mySql.query(
        "INSERT INTO playlist_song (song_id, playlist_id, added_by, ip) VALUE (?,1,?,?)",
        [song.id, addedBy, ip]
    );
  }

  void importSongs() {
    importQueue.add({
      'command': 'import'
    });
  }

  void checkSongs() {
    importQueue.add({
      'command': 'check'
    });
  }

  List<Song> _removeInvalidSongs(List<Song> nullableSongs) => List.from(
      nullableSongs.where(
              (song) => song.duration != null && song.hash != null
      ).toList()
  );


  Future<void> removeSongFromWishlist(int itemId) async {
    await mySql.query("DELETE FROM playlist_song WHERE id = ?", [itemId]);
  }

  Future<String> generateAbsolutePath(Map songMap) async {
    Setting baseFolderSetting = await _settingService.getSetting('karaoke-base-folder');
    String baseFolder = baseFolderSetting.value;
    if (baseFolder.endsWith('/')) {
      baseFolder = baseFolder.substring(0, baseFolder.length-1);
    }

    return baseFolder + songMap['pfad'];
  }

  Future<Song> getSong(int id) async {
    Results song = await mySql.query("SELECT * FROM songs WHERE id = ?", [id]);
    if (song.isEmpty) {
      throw KaraokeException('Song by id not found');
    }
    Map songMap = song.first.fields;
    songMap['pfad'] = await generateAbsolutePath(songMap);

    return Song.fromMap(Map.from(songMap));
  }

  Future<List<Song>> getAllSongs({bool removeDefective=true}) async {
    Results results = await mySql.query("SELECT * FROM songs");
    List<Song> songList = [];

    for (ResultRow songRow in results) {
      Map songMap = songRow.fields;
      songMap['pfad'] = await generateAbsolutePath(songMap);
      songList.add(Song.fromMap(songMap));
    }
    return removeDefective ? _removeInvalidSongs(songList) : songList;
  }
}