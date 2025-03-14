import 'dart:isolate';

import 'package:dotenv/dotenv.dart';

import '../../core/mysql.dart';
import 'services/import.dart';

main(args, message) async {
  load();
  await initMysql();
  ImportService importService = ImportService();
  print(message);
  switch (message['command']) {
    case 'import':
      await importService.importSongs();
      break;
    case 'check':
      await importService.checkSongs();
      break;
    case 'checkSingle':
      await importService.checkSong(message['songId']);
      break;
  }
  Isolate.current.kill(priority: Isolate.immediate);
}