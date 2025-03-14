import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../services/player/vlc.dart';

class PlayerController {
  VlcService vlcService = VlcService();

  Future<Response> playSong(Request request, String id) async => await vlcService.play(request, int.parse(id));
  Future<Response> pause(Request request) async => await vlcService.pause(request);
  Future<Response> stop(Request request) async => await vlcService.stop(request);
  Future<Response> seekPlusTenSeconds(Request request) async {
    await vlcService.seekPlusTenSeconds();
    return Response.ok(jsonEncode({
      'status': 'success'
    }));
  }
  Future<Response> seekMinusTenSeconds(Request request) async {
    await vlcService.seekMinusTenSeconds();
    return Response.ok(jsonEncode({
      'status': 'success'
    }));
  }

  Response getStatus(Request request) => Response.ok(
      jsonEncode({
        'state': vlcService.currentState,
        'songName': vlcService.currentSong?.datei ?? '',
        'totalTime': vlcService.currentSong?.duration?.inSeconds ?? 0,
        'elapsedTime': vlcService.elapsedSeconds
      })
  );
}