/// A media file shown behind a game's detail page.
///
/// Can be an image, animated GIF, or looping video. Games can have zero,
/// one, or many backdrops; when more than one is set the detail page
/// either shuffles (pick random on entry) or cycles through them
/// depending on the `backdrop_playback` setting.
class Backdrop {
  final int? id;
  final int gameId;
  final String filePath;
  final BackdropMediaType mediaType;
  final int sortOrder;

  const Backdrop({
    this.id,
    required this.gameId,
    required this.filePath,
    required this.mediaType,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'game_id': gameId,
      'file_path': filePath,
      'media_type': mediaType.name,
      'sort_order': sortOrder,
    };
  }

  factory Backdrop.fromMap(Map<String, dynamic> map) {
    return Backdrop(
      id: map['id'] as int?,
      gameId: map['game_id'] as int,
      filePath: map['file_path'] as String,
      mediaType: BackdropMediaType.fromName(map['media_type'] as String),
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  /// Infer the media type from a file path's extension. Falls back to image.
  static BackdropMediaType inferMediaType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'gif':
        return BackdropMediaType.gif;
      case 'mp4':
      case 'webm':
      case 'mov':
      case 'mkv':
      case 'm4v':
        return BackdropMediaType.video;
      default:
        return BackdropMediaType.image;
    }
  }
}

enum BackdropMediaType {
  image,
  gif,
  video;

  static BackdropMediaType fromName(String name) {
    return BackdropMediaType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => BackdropMediaType.image,
    );
  }
}
