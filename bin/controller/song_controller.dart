import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import '../entity/song.dart';
import '../services/song/playlist.dart';
import '../services/song/song.dart';

class SongController {
  SongService songService = SongService();
  PlaylistService playlistService = PlaylistService();

  Future<Response> search(Request request) async {
    Map json = jsonDecode((await request.readAsString()));
    List<Song> songs = await songService.searchSong(json['searchQuery']);
    return Response.ok(
        jsonEncode(
            songs.map((Song e) => e.toMap()).toList()
        )
    );
  }

  Future<Response> wishSong(Request request) async {
    try {
      HttpConnectionInfo httpConnection = request.context['shelf.io.connection_info']! as HttpConnectionInfo;
      Map json = jsonDecode((await request.readAsString()));
      Song song;
      try {
        song = await songService.getSong(int.parse(json['songId']));
      } catch (exception) {
        return Response.ok(
            jsonEncode({
              'status': 'error',
              'message': 'Dein Liedwunsch enthält ungültige Daten. Bitte wende dich an die Karaoke Helfer'
            })
        );
      }
      await songService.wishSong(song, json['name'], httpConnection.remoteAddress.address);
      return Response.ok(
          jsonEncode({
            'status': 'success',
            'message': 'Lied wurde in Wunschliste aufgenommen'
          })
      );
    } catch (exception) {
      return Response.ok(
          jsonEncode({
            'status': 'error',
            'message': exception.toString()
          })
      );
    }
  }

  Future<Response> removeFromWishlist(Request request) async {
    Map json = jsonDecode((await request.readAsString()));
    await songService.removeSongFromWishlist(json['itemId']);
    return Response.ok(jsonEncode(
      {'status': 'success'}
    ));
  }

  Response checkSongs(Request request) {
    songService.checkSongs();
    return Response.ok(jsonEncode(
        {'status': 'success'}
    ));
  }

  Response importSongs(Request request) {
    songService.importSongs();
    return Response.ok(jsonEncode(
        {'status': 'success'}
    ));
  }

  Future<Response> getPlaylist(Request request, String id) async
    => Response.ok(jsonEncode((await playlistService.getPlaylist(int.parse(id))).toMap()));

  Future<Response> getPlaylists(Request request) async
    => Response.ok(jsonEncode((await playlistService.getPlaylists()).map((e) => e.toMap()).toList()));
}