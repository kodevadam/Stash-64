/// Represents a game in the collection.
class Game {
  final int? id;
  final String title;
  final int consoleId;
  final String genre;
  final int minPlayers;
  final int maxPlayers;
  final String? coverArtPath; // Local file path to cover art image
  final String? romPath; // Local ROM file path (N64 SummerCart64 uploads, etc.)
  final String? room; // e.g., "Living Room", "Bedroom", "Game Room"
  final String storageLocation; // e.g., "Drawer 1", "Shelf A", "Box 3"
  final String region; // e.g., "NTSC-U", "NTSC-J", "PAL", "NTSC-U/C"
  final int? releaseYear;
  final String? notes;
  final bool isFavorite;
  final double? pricechartingPrice;
  final String? pricechartingUrl;

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
    this.romPath,
    this.room,
    required this.storageLocation,
    this.region = '',
    this.releaseYear,
    this.notes,
    this.isFavorite = false,
    this.pricechartingPrice,
    this.pricechartingUrl,
    this.consoleName,
    this.consoleAbbreviation,
  });

  String get playerRange {
    if (minPlayers == maxPlayers) return '$minPlayers player';
    return '$minPlayers-$maxPlayers players';
  }

  /// Returns a display string combining room and storage location.
  String get fullLocation {
    final parts = <String>[];
    if (room != null && room!.isNotEmpty) parts.add(room!);
    if (storageLocation.isNotEmpty) parts.add(storageLocation);
    return parts.join(' — ');
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
      'rom_path': romPath,
      'room': room,
      'storage_location': storageLocation,
      'region': region,
      'release_year': releaseYear,
      'notes': notes,
      'is_favorite': isFavorite ? 1 : 0,
      'pricecharting_price': pricechartingPrice,
      'pricecharting_url': pricechartingUrl,
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
      romPath: map['rom_path'] as String?,
      room: map['room'] as String?,
      storageLocation: map['storage_location'] as String? ?? '',
      region: map['region'] as String? ?? '',
      releaseYear: map['release_year'] as int?,
      notes: map['notes'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      pricechartingPrice: (map['pricecharting_price'] as num?)?.toDouble(),
      pricechartingUrl: map['pricecharting_url'] as String?,
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
    String? romPath,
    String? room,
    String? storageLocation,
    String? region,
    int? releaseYear,
    String? notes,
    bool? isFavorite,
    double? pricechartingPrice,
    String? pricechartingUrl,
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
      romPath: romPath ?? this.romPath,
      room: room ?? this.room,
      storageLocation: storageLocation ?? this.storageLocation,
      region: region ?? this.region,
      releaseYear: releaseYear ?? this.releaseYear,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      pricechartingPrice: pricechartingPrice ?? this.pricechartingPrice,
      pricechartingUrl: pricechartingUrl ?? this.pricechartingUrl,
      consoleName: consoleName ?? this.consoleName,
      consoleAbbreviation: consoleAbbreviation ?? this.consoleAbbreviation,
    );
  }
}
