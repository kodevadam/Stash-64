import 'dart:convert';

import 'package:http/http.dart' as http;

/// Represents a game from the catalog (external database lookup).
class CatalogGame {
  final String title;
  final String? genre;
  final int? releaseYear;
  final String? coverUrl;
  final int? minPlayers;
  final int? maxPlayers;
  final String? description;
  final List<String> platforms;
  final List<String> regions;

  const CatalogGame({
    required this.title,
    this.genre,
    this.releaseYear,
    this.coverUrl,
    this.minPlayers,
    this.maxPlayers,
    this.description,
    this.platforms = const [],
    this.regions = const [],
  });
}

/// Searches for games using free APIs (RAWG, ScreenScraper-compatible)
/// to populate game data automatically when adding to the collection.
class GameCatalog {
  /// Platform name to abbreviation mapping for matching against console list.
  static const _platformMap = {
    // Nintendo
    'nes': 'NES',
    'nintendo entertainment system': 'NES',
    'famicom': 'FC',
    'snes': 'SNES',
    'super nintendo': 'SNES',
    'super famicom': 'SFC',
    'nintendo 64': 'N64',
    'n64': 'N64',
    'gamecube': 'GCN',
    'nintendo gamecube': 'GCN',
    'wii': 'Wii',
    'nintendo wii': 'Wii',
    'game boy': 'GB',
    'game boy color': 'GBC',
    'game boy advance': 'GBA',
    'nintendo ds': 'NDS',
    'virtual boy': 'VB',
    // Sega
    'sega master system': 'SMS',
    'master system': 'SMS',
    'genesis': 'GEN',
    'sega genesis': 'GEN',
    'mega drive': 'MD',
    'sega mega drive': 'MD',
    'sega cd': 'SCD',
    'sega 32x': '32X',
    '32x': '32X',
    'sega saturn': 'SAT',
    'saturn': 'SAT',
    'dreamcast': 'DC',
    'sega dreamcast': 'DC',
    'game gear': 'GG',
    'sega game gear': 'GG',
    // Sony
    'playstation': 'PS1',
    'ps1': 'PS1',
    'psx': 'PS1',
    'playstation 2': 'PS2',
    'ps2': 'PS2',
    'psp': 'PSP',
    'playstation portable': 'PSP',
    // Atari
    'atari 2600': '2600',
    'atari 5200': '5200',
    'atari 7800': '7800',
    'atari jaguar': 'JAG',
    'jaguar': 'JAG',
    'atari lynx': 'LYNX',
    'lynx': 'LYNX',
    // NEC
    'turbografx-16': 'TG16',
    'turbografx 16': 'TG16',
    'pc engine': 'PCE',
    'turbografx-cd': 'TGCD',
    // SNK
    'neo geo': 'AES',
    'neo geo aes': 'AES',
    'neo geo mvs': 'MVS',
    'neo geo pocket': 'NGP',
    'neo geo pocket color': 'NGPC',
    // Other
    'colecovision': 'CV',
    'intellivision': 'INTV',
    'vectrex': 'VEC',
    '3do': '3DO',
    'xbox': 'XBOX',
    'wonderswan': 'WS',
    'wonderswan color': 'WSC',
  };

  /// RAWG platform IDs for filtering searches by console.
  static const _rawgPlatformIds = {
    'NES': 49,
    'FC': 49,
    'SNES': 79,
    'SFC': 79,
    'N64': 83,
    'GCN': 105,
    'Wii': 11,
    'GB': 26,
    'GBC': 43,
    'GBA': 24,
    'NDS': 9,
    'GEN': 167,
    'MD': 167,
    'DC': 106,
    'SAT': 107,
    'SMS': 74,
    'GG': 77,
    'PS1': 27,
    'PS2': 15,
    'PSP': 17,
    '2600': 31,
    '7800': 46,
    'JAG': 112,
    'LYNX': 28,
    'TG16': 111,
    'PCE': 111,
    'AES': 12,
    'MVS': 12,
    'NGPC': 25,
    '3DO': 55,
    'XBOX': 80,
  };

  /// Search the RAWG API for games matching a query and optional console.
  static Future<List<CatalogGame>> search(
    String query, {
    String? consoleAbbreviation,
  }) async {
    final results = <CatalogGame>[];

    // Build RAWG API URL
    final params = <String, String>{
      'search': query,
      'page_size': '20',
      'search_precise': 'true',
    };

    // Add platform filter if we know the RAWG ID
    if (consoleAbbreviation != null) {
      final platformId = _rawgPlatformIds[consoleAbbreviation];
      if (platformId != null) {
        params['platforms'] = platformId.toString();
      }
    }

    final uri = Uri.https('api.rawg.io', '/api/games', {
      ...params,
      'key': '', // RAWG allows keyless queries with rate limiting
    });

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 12),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final gamesData = data['results'] as List<dynamic>? ?? [];

        for (final game in gamesData) {
          final platforms = <String>[];
          final platformsList =
              game['platforms'] as List<dynamic>? ?? [];
          for (final p in platformsList) {
            final platName = (p['platform']?['name'] as String? ?? '')
                .toLowerCase();
            final slug =
                (p['platform']?['slug'] as String? ?? '').toLowerCase();
            // Try to match to our console list
            final abbr = _platformMap[platName] ?? _platformMap[slug];
            if (abbr != null && !platforms.contains(abbr)) {
              platforms.add(abbr);
            }
          }

          // Parse genres
          final genres = <String>[];
          final genresList = game['genres'] as List<dynamic>? ?? [];
          for (final g in genresList) {
            genres.add(g['name'] as String? ?? '');
          }

          // Parse year from release date
          int? releaseYear;
          final released = game['released'] as String?;
          if (released != null && released.length >= 4) {
            releaseYear = int.tryParse(released.substring(0, 4));
          }

          results.add(CatalogGame(
            title: game['name'] as String? ?? 'Unknown',
            genre: genres.isNotEmpty ? _mapGenre(genres.first) : null,
            releaseYear: releaseYear,
            coverUrl: game['background_image'] as String?,
            description: game['description_raw'] as String?,
            platforms: platforms,
            regions: _inferRegions(platforms),
          ));
        }
      }
    } catch (_) {
      // API unavailable — return empty
    }

    return results;
  }

  /// Infer likely regional variants based on platforms.
  static List<String> _inferRegions(List<String> platforms) {
    final regions = <String>{};
    for (final p in platforms) {
      // Japanese consoles / variants
      if (['FC', 'SFC', 'PCE', 'MD', 'SAT', 'DC'].contains(p)) {
        regions.add('NTSC-J');
      }
      // Western consoles
      if (['NES', 'SNES', 'GEN', 'TG16'].contains(p)) {
        regions.add('NTSC-U');
        regions.add('PAL');
      }
      // Multi-region consoles
      if (['N64', 'GCN', 'Wii', 'PS1', 'PS2', 'GB', 'GBC', 'GBA',
           'NDS', 'PSP', 'XBOX'].contains(p)) {
        regions.addAll(['NTSC-U', 'NTSC-J', 'PAL']);
      }
    }
    if (regions.isEmpty) {
      regions.addAll(['NTSC-U', 'NTSC-J', 'PAL']);
    }
    return regions.toList();
  }

  /// Map RAWG genre names to our simpler genre list.
  static String _mapGenre(String rawgGenre) {
    final lower = rawgGenre.toLowerCase();
    if (lower.contains('rpg') || lower.contains('role-playing')) return 'RPG';
    if (lower.contains('platformer')) return 'Platformer';
    if (lower.contains('shooter')) return 'Shooter';
    if (lower.contains('fighting')) return 'Fighting';
    if (lower.contains('racing')) return 'Racing';
    if (lower.contains('puzzle')) return 'Puzzle';
    if (lower.contains('strategy')) return 'Strategy';
    if (lower.contains('simulation')) return 'Simulation';
    if (lower.contains('sports')) return 'Sports';
    if (lower.contains('adventure')) return 'Action-Adventure';
    if (lower.contains('action')) return 'Action';
    return rawgGenre;
  }
}
