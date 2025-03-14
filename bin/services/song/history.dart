import 'package:mysql1/mysql1.dart';

import '../../core/mysql.dart';
import '../../entity/history.dart';
import '../../entity/song.dart';
import 'song.dart';

class HistoryService {
  final SongService _songService = SongService();
  Future<History> create(Song song) async {
    Results results = await mySql.query('INSERT INTO history (song_id, duration) VALUES (${song.id},${song.duration?.inSeconds})');
    return getHistory(results.insertId!);
  }

  Future<History> getHistory(int id) async {
    Results results = await mySql.query("SELECT * FROM history WHERE id = ${id.toString()}");
    Map<String, dynamic> data = results.first.fields;
    data['song'] = await _songService.getSong(data['song_id']);
    return History.fromMap(data);
  }

  Future<History> updateDuration(History history, int newDuration) async {
    await mySql.query('UPDATE history SET duration = $newDuration WHERE id = ${history.id}');
    return History(history.id, history.song, newDuration);
  }

  void clearHistory() async {
    await mySql.query('TRUNCATE history');
  }
}