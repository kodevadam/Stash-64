import '../models/backdrop.dart';

/// Pick cover art (web — not yet supported).
/// TODO: Implement image upload via API when server supports it.
Future<String?> pickAndSaveCoverArt() async {
  // On web, cover art comes from RAWG/LibRetro URLs during game search.
  // Manual upload requires server-side storage — pending implementation.
  return null;
}

/// ROM picker — no-op on web; sc64deployer is desktop-only.
Future<String?> pickAndSaveRom({String? libraryDir}) async => null;

Future<String?> pickRomLibraryDir() async => null;

Future<String?> pickSc64BinaryPath() async => null;

/// Backdrop picker — no-op on web. Could be wired up later once the web
/// backend supports media uploads.
Future<int> pickAndSaveBackdrops(int gameId) async => 0;

Future<List<Backdrop>> loadBackdrops(int gameId) async => const [];

Future<void> deleteBackdropById(int backdropId, String filePath) async {}
