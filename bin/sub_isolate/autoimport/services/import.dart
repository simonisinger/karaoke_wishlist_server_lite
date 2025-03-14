import 'dart:io';

import 'package:file_hasher/file_hasher.dart';
import 'package:mysql1/mysql1.dart';

import '../../../core/mysql.dart';
import '../../../entity/setting.dart';
import '../../../entity/song.dart';
import '../../../services/setting/setting.dart';
import '../../../services/song/song.dart';
import '../../../shared_helpers/video.dart';
import 'package:path/path.dart' as p;

class ImportService {
  final SettingService _settingService = SettingService();
  final SongService _songService = SongService();

  Future<void> importSongs() async {
    if ((await _settingService.getSetting('song-autoimport')).value != '1') {
      print('song import is currently deactivated');
      return;
    }
    print('starting import');

    List<String> files = await getFolderFiles();
    if (files.isEmpty) {
      print('skipping: base folder is empty or does not exist');
      return;
    }
    List<Song> songs = await _songService.getAllSongs(removeDefective: false);
    print('found ${songs.length} songs in database');

    List<Song> songsToRemove = _getSongsToRemove(songs, files);

    List<String> songsToAdd = List.from(files);
    songsToAdd.removeWhere((element) => songs.where(
            (song) => song.pfad + song.datei == element).isNotEmpty
        || !['.mp4','.mkv','.avi'].contains(p.extension(element).toLowerCase())
    );

    print('removing ${songsToRemove.length} songs');
    for (Song song in songsToRemove) {
      await deleteSong(song);
    }

    print('adding ${songsToAdd.length} songs');
    for (String pfad in songsToAdd) {
      await create(pfad);
    }
  }

  List<Song> _getSongsToRemove(List<Song> songs, List<String> files) {
    List<Song> songsToRemove = List.from(songs);
    songsToRemove.removeWhere((element) => files.contains(element.pfad+element.datei));
    return songsToRemove;
  }

  Future<void> checkSongs() async {
    List<String> files = await getFolderFiles();
    List<Song> songs = await _songService.getAllSongs();

    List<Song> songsToRemove = _getSongsToRemove(songs, files);

    List<Song> songsToCheck = List.from(songs);
    songsToCheck.removeWhere((element) => songsToRemove.contains(element));

    for (Song song in songsToCheck) {
      await checkSong(song.id);
    }
  }

  Future<void> deleteSong(Song song) async {
    await mySql.query("DELETE FROM songs WHERE id = ?", [ song.id ]);
  }

  Future<bool> checkSong(int songId) async {
    Song song = await _songService.getSong(songId);
    File file = File(song.pfad + song.datei);
    String hash = FileHasher.hashSync(file).toString();
    if(song.hash == null || hash != song.hash!){
      String? duration;
      try {
        duration = scanVideo(file);
      } catch (exception){
        return false;
      }

      await mySql.query(
          "UPDATE songs SET hash = ?, duration = ? WHERE id = ?",
          [hash, duration, song.id]
      );
    }
    return true;
  }

  Future<Song?> create(String pfad) async {
    Setting basePath = await _settingService.getSetting('karaoke-base-folder');
    pfad = pfad.replaceAll(basePath.value, '');
    if (!pfad.startsWith('/')) {
      pfad = '/$pfad';
    }
    String finalPath = p.dirname(pfad);
    if (pfad.isNotEmpty) {
      finalPath += (Platform.isWindows ? '\\' : '/');
    }
    Results results = await mySql.query(
        "INSERT INTO songs (pfad,datei) VALUES (?,?)",
        [finalPath, p.basename(pfad)]
    );
    Song? song = await _songService.getSong(results.insertId!);
    await checkSong(results.insertId!);
    return song;
  }

  Future<List<String>> getFolderFiles() async {
    Setting baseFolderSetting = await _settingService.getSetting('karaoke-base-folder');
    List<FileSystemEntity> files;
    try {
      Directory baseDirectory = Directory(baseFolderSetting.value);
      files = baseDirectory.listSync(recursive: true);
      print('reading files from: ${baseFolderSetting.value}');
    } catch (exception) {
      return [];
    }


    List<String> pathList = files.map((e) => e.path).toList();
    pathList.removeWhere((element) => !['.mkv', '.mp4', '.avi'].contains(p.extension(element).toLowerCase()));
    print('found ${pathList.length} video files');
    return pathList;
  }
}