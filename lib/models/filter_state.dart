/// Holds the current filter/sort state for browsing games.
class FilterState {
  final int? consoleId;
  final String? genre;
  final int? playerCount; // Filter to games supporting this many players
  final String? storageLocation;
  final bool? favoritesOnly;
  final String searchQuery;
  final SortField sortField;
  final bool sortAscending;

  const FilterState({
    this.consoleId,
    this.genre,
    this.playerCount,
    this.storageLocation,
    this.favoritesOnly,
    this.searchQuery = '',
    this.sortField = SortField.title,
    this.sortAscending = true,
  });

  bool get hasActiveFilters =>
      consoleId != null ||
      genre != null ||
      playerCount != null ||
      storageLocation != null ||
      favoritesOnly == true ||
      searchQuery.isNotEmpty;

  FilterState copyWith({
    int? consoleId,
    String? genre,
    int? playerCount,
    String? storageLocation,
    bool? favoritesOnly,
    String? searchQuery,
    SortField? sortField,
    bool? sortAscending,
    bool clearConsole = false,
    bool clearGenre = false,
    bool clearPlayerCount = false,
    bool clearStorageLocation = false,
    bool clearFavorites = false,
  }) {
    return FilterState(
      consoleId: clearConsole ? null : (consoleId ?? this.consoleId),
      genre: clearGenre ? null : (genre ?? this.genre),
      playerCount:
          clearPlayerCount ? null : (playerCount ?? this.playerCount),
      storageLocation: clearStorageLocation
          ? null
          : (storageLocation ?? this.storageLocation),
      favoritesOnly:
          clearFavorites ? null : (favoritesOnly ?? this.favoritesOnly),
      searchQuery: searchQuery ?? this.searchQuery,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  FilterState clearAll() {
    return const FilterState();
  }
}

enum SortField {
  title,
  console,
  genre,
  releaseYear,
  storageLocation,
}
