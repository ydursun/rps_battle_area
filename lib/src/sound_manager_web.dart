import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

Future<Source> writeDeviceFileSource(String name, Uint8List data) async {
  // On web, we use BytesSource directly (no file system)
  return BytesSource(data);
}
