import 'dart:io';
import 'package:path/path.dart' as p;

String? scanVideo(File file) {
  String path = p.dirname(file.path) +
      p.separator +
      p.basenameWithoutExtension(file.path) +
      p.extension(file.path);
  try {
    ProcessResult ffmpegInfo = Process.runSync(
      'ffmpeg',
      [
        "-i",
        '$path'
      ],
    );
    String output = ffmpegInfo.stderr;
    List<String> outputLines = output.split('\n');
    String? duration;
    for(int i = 0; i < outputLines.length; i++){
      List<String> lineList = outputLines[i].trim().split(':');
      if(lineList[0] == 'Duration'){
        lineList.removeAt(0);
        duration = lineList.join(':').split(',').first.trim();
        break;
      }
    }
    return duration;
  } catch (exception) {
    throw Exception('invalid video file');
  }
}