import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pick an image file and copy it to the app's covers directory (native).
/// Returns the local file path, or null if cancelled.
Future<String?> pickAndSaveCoverArt() async {
  final result = await FilePicker.platform.pickFiles(type: FileType.image);
  if (result == null || result.files.isEmpty) return null;

  final sourcePath = result.files.first.path;
  if (sourcePath == null) return null;

  final appDir = await getApplicationDocumentsDirectory();
  final coverDir = Directory(p.join(appDir.path, 'covers'));
  if (!await coverDir.exists()) {
    await coverDir.create(recursive: true);
  }

  final ext = p.extension(sourcePath);
  final destPath = p.join(
      coverDir.path, '${DateTime.now().millisecondsSinceEpoch}$ext');
  await File(sourcePath).copy(destPath);

  return destPath;
}
