import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import 'cache/import.dart';
import 'controller/player_controller.dart';
import 'controller/settings_controller.dart';
import 'controller/song_controller.dart';
import 'controller/user_controller.dart';
import 'core/auth_middleware.dart';
import 'core/mysql.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

import 'cron/song_import.dart';


PlayerController playerController = PlayerController();
SongController songController = SongController();
AuthMiddleware authMiddleware = AuthMiddleware();
UserController userController = UserController();
SettingsController settingsController = SettingsController();
// Configure routes.
final _router = Router()
  ..get('/player/status', playerController.getStatus)
  ..get('/playlist/<id>', songController.getPlaylist)
  ..get('/playlist', songController.getPlaylists)
  ..get('/users', userController.getUsers)
  ..get('/setting', settingsController.getSettings)
  ..get('/song/import', songController.importSongs)
  ..get('/song/check', songController.checkSongs)
  ..post('/login', userController.login)
  ..post('/song/search', songController.search)
  ..post('/player/play/<id>', playerController.playSong)
  ..post('/player/pause', playerController.pause)
  ..post('/player/seek/forward/10', playerController.seekPlusTenSeconds)
  ..post('/player/seek/backward/10', playerController.seekMinusTenSeconds)
  ..post('/player/stop', playerController.stop)
  ..post('/song/search', songController.search)
  ..post('/song/wish', songController.wishSong)
  ..post('/song/wish/remove', songController.removeFromWishlist)
  ..put('/user/create', userController.createUser)
  ..put('/setting', settingsController.setSetting)
  ..delete('/user/delete', userController.deleteUser)
;

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;
  dotenv.load();
  await initMysql();
  final overrideHeaders = {
    'access-control-allow-headers': 'accept,accept-encoding,authorization,content-type,dnt,origin,user-agent,x-api-key'
  };
  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(corsHeaders(headers: overrideHeaders))
      .addMiddleware(authMiddleware.checkAuth())
      .addMiddleware(logRequests())
      .addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
  initAutoSongImport();
  initImportTimer();
}
