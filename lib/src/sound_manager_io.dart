import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

String? _soundDirPath;

Future<DeviceFileSource> writeDeviceFileSource(
    String name, Uint8List data) async {
  if (_soundDirPath == null) {
    final dir = await getApplicationSupportDirectory();
    final soundDir = Directory('${dir.path}/sounds');
    if (!soundDir.existsSync()) {
      soundDir.createSync(recursive: true);
    }
    _soundDirPath = soundDir.path;
  }
  final file = File('$_soundDirPath/$name');
  await file.writeAsBytes(data);
  return DeviceFileSource(file.path);
}
