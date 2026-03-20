/// Represents a game in the collection.
class Game {
  final int? id;
  final String title;
  final int consoleId;
  final String genre;
  final int minPlayers;
  final int maxPlayers;
  final String? coverArtPath; // Local file path to cover art image
  final String storageLocation; // e.g., "Drawer 1", "Shelf A"
  final int? releaseYear;
  final String? notes;
  final bool isFavorite;

  // Joined field — populated from query, not stored directly
  final String? consoleName;
  final String? consoleAbbreviation;

  const Game({
    this.id,
    required this.title,
    required this.consoleId,
    required this.genre,
    this.minPlayers = 1,
    this.maxPlayers = 1,
    this.coverArtPath,
    required this.storageLocation,
    this.releaseYear,
    this.notes,
    this.isFavorite = false,
    this.consoleName,
    this.consoleAbbreviation,
  });

  String get playerRange {
    if (minPlayers == maxPlayers) return '$minPlayers player';
    return '$minPlayers-$maxPlayers players';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'console_id': consoleId,
      'genre': genre,
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'cover_art_path': coverArtPath,
      'storage_location': storageLocation,
      'release_year': releaseYear,
      'notes': notes,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'] as int?,
      title: map['title'] as String,
      consoleId: map['console_id'] as int,
      genre: map['genre'] as String,
      minPlayers: map['min_players'] as int? ?? 1,
      maxPlayers: map['max_players'] as int? ?? 1,
      coverArtPath: map['cover_art_path'] as String?,
      storageLocation: map['storage_location'] as String? ?? '',
      releaseYear: map['release_year'] as int?,
      notes: map['notes'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      consoleName: map['console_name'] as String?,
      consoleAbbreviation: map['console_abbreviation'] as String?,
    );
  }

  Game copyWith({
    int? id,
    String? title,
    int? consoleId,
    String? genre,
    int? minPlayers,
    int? maxPlayers,
    String? coverArtPath,
    String? storageLocation,
    int? releaseYear,
    String? notes,
    bool? isFavorite,
    String? consoleName,
    String? consoleAbbreviation,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      consoleId: consoleId ?? this.consoleId,
      genre: genre ?? this.genre,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      coverArtPath: coverArtPath ?? this.coverArtPath,
      storageLocation: storageLocation ?? this.storageLocation,
      releaseYear: releaseYear ?? this.releaseYear,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      consoleName: consoleName ?? this.consoleName,
      consoleAbbreviation: consoleAbbreviation ?? this.consoleAbbreviation,
    );
  }
}
