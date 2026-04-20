import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database_helper.dart';
import '../models/backdrop.dart';

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

/// Common ROM file extensions for console cartridges we're likely to see.
const _romExtensions = [
  'z64', 'n64', 'v64', 'rom',  // N64
  'nes', 'fds',                 // NES / Famicom Disk
  'sfc', 'smc',                 // SNES
  'gb', 'gbc', 'gba',           // Game Boy family
  'md', 'gen', 'smd', 'bin',    // Sega Genesis
  'gg', 'sms',                  // Game Gear / Master System
  'nds', '3ds',                 // Nintendo DS / 3DS
  'iso', 'cue', 'chd',          // Disc-based
];

/// Pick a ROM file and copy it into the library directory. If the picked
/// file already lives inside [libraryDir], we just return its existing
/// path — no duplicate copy. Returns null if cancelled.
Future<String?> pickAndSaveRom({String? libraryDir}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: _romExtensions,
  );
  if (result == null || result.files.isEmpty) return null;

  final sourcePath = result.files.first.path;
  if (sourcePath == null) return null;

  final dir = libraryDir?.isNotEmpty == true
      ? Directory(libraryDir!)
      : Directory(p.join(
          (await getApplicationDocumentsDirectory()).path, 'roms'));
  if (!await dir.exists()) await dir.create(recursive: true);

  // If the picked file already sits inside the library, don't re-copy.
  if (p.isWithin(dir.path, sourcePath) || p.equals(dir.path, p.dirname(sourcePath))) {
    return sourcePath;
  }

  final destPath = p.join(dir.path, p.basename(sourcePath));
  await File(sourcePath).copy(destPath);
  return destPath;
}

/// Let the user point us at a different ROM library root. Used from the
/// settings screen so collections can live on an external drive.
Future<String?> pickRomLibraryDir() async {
  return FilePicker.platform.getDirectoryPath(
    dialogTitle: 'Pick ROM library directory',
  );
}

/// Let the user manually point us at the sc64deployer binary. Used when
/// auto-detection via PATH fails.
Future<String?> pickSc64BinaryPath() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    dialogTitle: 'Pick the sc64deployer binary',
  );
  return result?.files.firstOrNull?.path;
}

/// Pick one or more backdrop media files (images / gifs / videos) and
/// insert them into the DB. Files are copied under
/// `<appdocs>/backdrops/<gameId>/`.
Future<int> pickAndSaveBackdrops(int gameId) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowMultiple: true,
    allowedExtensions: const [
      'jpg', 'jpeg', 'png', 'webp', 'bmp',
      'gif',
      'mp4', 'webm', 'mov', 'm4v', 'mkv',
    ],
  );
  if (result == null || result.files.isEmpty) return 0;

  final appDir = await getApplicationDocumentsDirectory();
  final backdropDir =
      Directory(p.join(appDir.path, 'backdrops', '$gameId'));
  if (!await backdropDir.exists()) {
    await backdropDir.create(recursive: true);
  }

  var imported = 0;
  for (final file in result.files) {
    if (file.path == null) continue;
    final ext = p.extension(file.path!);
    final newName = '${DateTime.now().millisecondsSinceEpoch}_$imported$ext';
    final destPath = p.join(backdropDir.path, newName);
    await File(file.path!).copy(destPath);
    await DatabaseHelper.instance.insertBackdrop(Backdrop(
      gameId: gameId,
      filePath: destPath,
      mediaType: Backdrop.inferMediaType(destPath),
    ));
    imported++;
  }
  return imported;
}

Future<List<Backdrop>> loadBackdrops(int gameId) async {
  return DatabaseHelper.instance.getBackdrops(gameId);
}

Future<void> deleteBackdropById(int backdropId, String filePath) async {
  await DatabaseHelper.instance.deleteBackdrop(backdropId);
  // Best-effort file cleanup — ignore failures in case the file is gone.
  try {
    final f = File(filePath);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
