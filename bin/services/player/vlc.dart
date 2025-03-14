import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/mysql.dart' show mySql;
import 'package:shelf/shelf.dart' as shelf;
import 'package:dotenv/dotenv.dart' as dotenv;

import '../../entity/history.dart';
import '../../entity/song.dart';
import '../song/history.dart';
import '../song/song.dart';

class VlcService {
  final HistoryService _historyService = HistoryService();
  final SongService _songService = SongService();
  String currentState = 'stopped';
  late History currentHistory;
  Song? currentSong;
  int elapsedSeconds = 0;
  final Map config = {
    'headers': {
      'Authorization': 'Basic ${base64Encode(utf8.encode("${dotenv.env['VLC_USER'] ?? ''}:${dotenv.env['VLC_PASSWORD']}"))}'
    }
  };

  VlcService() {
    Timer.periodic(Duration(milliseconds: 500), _updateStatus);
  }

  String url = 'http://${dotenv.env['VLC_HOST']}:${dotenv.env['VLC_PORT']}';

  bool randomPlay = false;

  Future<shelf.Response> play(Request req, int id) async {
    if ( await isPlayerRunning()) await _stopVideo();
    try {
      Song? song = await _songService.getSong(id);
      randomPlay = false;
      if (song.duration != null && song.hash != null) {
        currentSong = song;
        if (dotenv.env['HISTORY_ENABLED'] == "true") {
          currentHistory = await _historyService.create(song);
        }
        await _playVideo(song.pfad + song.datei);

        print('player started');
        return Response.ok(jsonEncode({
          'status': 'success',
          'message': 'player started'
        }));
      } else {
        return Response.notFound(jsonEncode(
         {
           'status': 'error',
           'message': 'invalid song data'
         }
        ));
      }
    } catch(e) {
      return Response.ok('not found');
    }
  }
  
  Future<void> _seekVideo(String value) async {
    RegExp regex = RegExp(r"^(?<operator>[+\-])(?<count>\d+)(?<unit>[sm])");
    RegExpMatch? match = regex.firstMatch(value);
    String? operator = match!.namedGroup('operator');
    String? count = match.namedGroup('count');
    String? unit = match.namedGroup('unit');
    int duplicator = 0;

    switch (unit) {
      case 's':
        duplicator = 1;
        break;
      case 'm':
        duplicator = 60;
        break;
    }
    if (dotenv.env['HISTORY_ENABLED'] == "true") {
      int difference = duplicator * int.parse(count!);
      int newDuration = currentHistory.duration;
      switch (operator) {
        case '+':
          newDuration = currentHistory.duration - difference;
          break;
        case '-':
          newDuration = currentHistory.duration + difference;
          break;
      }
      currentHistory = await _historyService.updateDuration(currentHistory, newDuration);
    }

    await http.get(
      Uri.parse('$url/requests/status.xml?command=seek&val=${Uri.encodeFull(value)}'),
      headers: config['headers']
    );
  }
  
  Future<void> seekPlusTenSeconds() async {
    await _seekVideo('+10s');
  }

  Future<void> seekMinusTenSeconds() async {
    await _seekVideo('-10s');
  }

  _updateStatus(Timer timer) async {
    try {
      http.Response res = await http.get(
          Uri.parse('$url/requests/status.xml'),
          headers: config['headers']
      );
      xml.XmlDocument doc = xml.XmlDocument.parse(res.body);
      currentState = doc.children[2].getElement('state')!.innerText.trim();
      if (currentState == 'playing') {
        elapsedSeconds =
            int.parse(doc.children[2].getElement('time')!.innerText.trim());
      }
    } catch(exception) {
      print('error occurred ${exception.toString()}');
    }

  }

  _stopVideo() async {
    http.Response res = await http.get(
        Uri.parse('$url/requests/status.xml?command=pl_stop'),
        headers: config['headers']
    );
    xml.XmlDocument doc = xml.XmlDocument.parse(res.body);

    if (dotenv.env['HISTORY_ENABLED'] == "true") {
      int duration = int.parse(
          doc.children[2].getElement('time')!.innerText.trim());
      await _historyService.updateDuration(currentHistory, duration);
    }
  }

  _playVideo(path) async {
    await http.get(
        Uri.parse('$url/requests/status.xml?command=pl_empty'),
        headers: config['headers']
    );
    await http.get(
        Uri.parse('$url/requests/status.xml?command=in_play&input=file:///${Uri.encodeComponent(path)}'),
        headers: config['headers']
    );
  }
  _pauseVideo() async  {
    await http.get(Uri.parse('$url/requests/status.xml?command=pl_pause'), headers: config['headers']);
  }

  Future<shelf.Response> pause (shelf.Request req) async {
    await _pauseVideo();
    print('player paused');
    return shelf.Response.ok('player paused');
  }

  isPlayerRunning() async {
    http.Response res = await http.get(Uri.parse('$url/requests/status.xml'), headers: config['headers']);

    xml.XmlDocument doc = xml.XmlDocument.parse(res.body);

    String state = doc.children[2].getElement('state')!.innerText;

    if (state == 'playing'){
      return true;
    } else {
      print(state);
      return false;
    }
  }

  Future<shelf.Response> stop(shelf.Request req) async {
    if ( !(await isPlayerRunning())) return shelf.Response.ok('player isn\'t running');

    await _stopVideo();
    print('player stopped');
    return shelf.Response.ok('song stopped!');
  }

  playRandomRequest (req,res) async {
    res.send('');
    randomPlay = true;
    await _playRandom();
  }
  _playRandom() async {
    Results rows = await mySql.query('SELECT * FROM conka.songs order by RAND() LIMIT 1');
    var timeArray = rows.first['duration'].split(':');
    await _playVideo(rows.iterator.current['pfad'] + rows.iterator.current['datei']);
    await Future.delayed(
        Duration(
            hours: int.parse(timeArray[0]),
            seconds: (int.parse(timeArray[2])+5),
            minutes: int.parse(timeArray[1])
        ),
        _playRandom
    );
  }
}