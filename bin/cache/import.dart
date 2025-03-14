import 'dart:async';
import 'dart:isolate';

List<Map<String, dynamic>> importQueue = [];
bool importActive = false;

void _checkForNewImportJob(Timer timer) async {
  if (!importActive) {
    print('trying to start conversion');
    await _createNewIsolate();
  } else {
    print('conversion active: skipping');
  }
}

void initImportTimer() {
  Timer.periodic(Duration(seconds: 10), _checkForNewImportJob);
}

Future<void> _createNewIsolate() async {
  if (importQueue.isNotEmpty) {
    print('new object in queue found');
    importActive = true;
    ReceivePort receivePort = ReceivePort();
    receivePort.first.then((value) async {
      print('isolate completed');
      importQueue.remove(importQueue.first);
      await _createNewIsolate();
      print('new import isolate created');
    });
    print('create new import isolate');
    await Isolate.spawnUri(
        Uri.parse('sub_isolate/autoimport/autoimport.dart'),
        [],
        importQueue.first,
        onExit: receivePort.sendPort,
        errorsAreFatal: false
    );
  } else {
    print('no object in the queue anymore');
    importActive = false;
  }
}