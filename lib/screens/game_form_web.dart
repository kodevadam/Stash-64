/// Pick cover art (web — not yet supported).
/// TODO: Implement image upload via API when server supports it.
Future<String?> pickAndSaveCoverArt() async {
  // On web, cover art comes from RAWG/LibRetro URLs during game search.
  // Manual upload requires server-side storage — pending implementation.
  return null;
}
