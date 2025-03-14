import 'dart:async';

import '../cache/import.dart';
import '../services/song/song.dart';

SongService _songService = SongService();
int songsToCheckCount = 0;
int songsToCheckIndex = 0;

initAutoSongImport() {
  runImport(null);
  Timer.periodic(Duration(minutes: 10), runImport);
}

runImport(Timer? timer) async {
  print('trying to run import');
  if (importQueue.where((element) => element['command'] == 'import').isEmpty) {
    print('no import is currently running');
    _songService.importSongs();
  } else {
    print('another import is already running: skipping');
  }
}