/// Download cover art (web — returns the URL directly for use as network image).
Future<String?> downloadCoverArt(String url) async {
  // On web, we store the URL as the cover path.
  // The GameImage/buildPlatformImage widget will render it via Image.network.
  return url;
}

/// Download and save screenshots (web — no-op for now).
/// TODO: Upload to server via API when image upload endpoint is implemented.
Future<void> downloadAndSaveScreenshots(
    int gameId, List<String> urls) async {
  // Web screenshot storage requires server-side upload — pending.
}
