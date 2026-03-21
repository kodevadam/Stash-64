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

/// Searches for games using free APIs and LibRetro thumbnails (same source
/// as EmuDeck) to populate game data automatically when adding to the collection.
class GameCatalog {
  /// Console abbreviation to LibRetro system name mapping.
  static const _libRetroSystemMap = {
    'NES': 'Nintendo - Nintendo Entertainment System',
    'FC': 'Nintendo - Nintendo Entertainment System',
    'SNES': 'Nintendo - Super Nintendo Entertainment System',
    'SFC': 'Nintendo - Super Nintendo Entertainment System',
    'N64': 'Nintendo - Nintendo 64',
    'GCN': 'Nintendo - GameCube',
    'Wii': 'Nintendo - Wii',
    'GB': 'Nintendo - Game Boy',
    'GBC': 'Nintendo - Game Boy Color',
    'GBA': 'Nintendo - Game Boy Advance',
    'NDS': 'Nintendo - Nintendo DS',
    'VB': 'Nintendo - Virtual Boy',
    'SMS': 'Sega - Master System - Mark III',
    'GEN': 'Sega - Mega Drive - Genesis',
    'MD': 'Sega - Mega Drive - Genesis',
    'SCD': 'Sega - Mega-CD - Sega CD',
    '32X': 'Sega - 32X',
    'SAT': 'Sega - Saturn',
    'DC': 'Sega - Dreamcast',
    'GG': 'Sega - Game Gear',
    'PS1': 'Sony - PlayStation',
    'PS2': 'Sony - PlayStation 2',
    'PSP': 'Sony - PlayStation Portable',
    '2600': 'Atari - 2600',
    '5200': 'Atari - 5200',
    '7800': 'Atari - 7800',
    'JAG': 'Atari - Jaguar',
    'LYNX': 'Atari - Lynx',
    'TG16': 'NEC - PC Engine - TurboGrafx 16',
    'PCE': 'NEC - PC Engine - TurboGrafx 16',
    'TGCD': 'NEC - PC Engine CD - TurboGrafx-CD',
    'AES': 'SNK - Neo Geo',
    'MVS': 'SNK - Neo Geo',
    'NGP': 'SNK - Neo Geo Pocket',
    'NGPC': 'SNK - Neo Geo Pocket Color',
    'CV': 'Coleco - ColecoVision',
    'INTV': 'Mattel - Intellivision',
    'VEC': 'GCE - Vectrex',
    '3DO': 'The 3DO Company - 3DO',
    'WS': 'Bandai - WonderSwan',
    'WSC': 'Bandai - WonderSwan Color',
    'XBOX': 'Microsoft - Xbox',
  };

  /// Platform name to abbreviation mapping for matching against console list.
  static const _platformMap = {
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
    'playstation': 'PS1',
    'ps1': 'PS1',
    'psx': 'PS1',
    'playstation 2': 'PS2',
    'ps2': 'PS2',
    'psp': 'PSP',
    'playstation portable': 'PSP',
    'atari 2600': '2600',
    'atari 5200': '5200',
    'atari 7800': '7800',
    'atari jaguar': 'JAG',
    'jaguar': 'JAG',
    'atari lynx': 'LYNX',
    'lynx': 'LYNX',
    'turbografx-16': 'TG16',
    'turbografx 16': 'TG16',
    'pc engine': 'PCE',
    'turbografx-cd': 'TGCD',
    'neo geo': 'AES',
    'neo geo aes': 'AES',
    'neo geo mvs': 'MVS',
    'neo geo pocket': 'NGP',
    'neo geo pocket color': 'NGPC',
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
    'NES': 49, 'FC': 49, 'SNES': 79, 'SFC': 79, 'N64': 83,
    'GCN': 105, 'Wii': 11, 'GB': 26, 'GBC': 43, 'GBA': 24,
    'NDS': 9, 'GEN': 167, 'MD': 167, 'DC': 106, 'SAT': 107,
    'SMS': 74, 'GG': 77, 'PS1': 27, 'PS2': 15, 'PSP': 17,
    '2600': 31, '7800': 46, 'JAG': 112, 'LYNX': 28,
    'TG16': 111, 'PCE': 111, 'AES': 12, 'MVS': 12, 'NGPC': 25,
    '3DO': 55, 'XBOX': 80,
  };

  /// Get LibRetro system name for a console abbreviation.
  static String? getLibRetroSystem(String consoleAbbr) {
    return _libRetroSystemMap[consoleAbbr];
  }

  /// Build a LibRetro thumbnail URL for a game title and console.
  static String? getLibRetroBoxartUrl(String title, String consoleAbbr) {
    final system = _libRetroSystemMap[consoleAbbr];
    if (system == null) return null;
    // LibRetro uses exact filenames - replace illegal path chars with _
    final safeName = title.replaceAll(RegExp(r'[<>:"/\\|?*&]'), '_');
    return 'https://thumbnails.libretro.com/'
        '${Uri.encodeComponent(system)}/Named_Boxarts/'
        '${Uri.encodeComponent(safeName)}.png';
  }

  /// Search for games using the RAWG API (free tier, no key required for
  /// basic queries with rate limiting).
  static Future<List<CatalogGame>> search(
    String query, {
    String? consoleAbbreviation,
  }) async {
    final results = <CatalogGame>[];

    // Try RAWG first
    final rawgResults = await _searchRawg(query, consoleAbbreviation);
    results.addAll(rawgResults);

    // If RAWG returned nothing and we have a console, try LibRetro listing
    if (results.isEmpty && consoleAbbreviation != null) {
      final lrResults =
          await _searchLibRetroListing(query, consoleAbbreviation);
      results.addAll(lrResults);
    }

    return results;
  }

  static Future<List<CatalogGame>> _searchRawg(
      String query, String? consoleAbbr) async {
    final results = <CatalogGame>[];

    final params = <String, String>{
      'key': '', // RAWG requires key param; empty string for rate-limited access
      'search': query,
      'page_size': '20',
      'search_precise': 'true',
    };

    if (consoleAbbr != null) {
      final platformId = _rawgPlatformIds[consoleAbbr];
      if (platformId != null) {
        params['platforms'] = platformId.toString();
      }
    }

    final uri = Uri.https('api.rawg.io', '/api/games', params);

    try {
      final response = await http.get(uri).timeout(
        const Duration(seconds: 12),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final gamesData = data['results'] as List<dynamic>? ?? [];

        for (final game in gamesData) {
          final platforms = <String>[];
          final platformsList = game['platforms'] as List<dynamic>? ?? [];
          for (final p in platformsList) {
            final platName =
                (p['platform']?['name'] as String? ?? '').toLowerCase();
            final slug =
                (p['platform']?['slug'] as String? ?? '').toLowerCase();
            final abbr = _platformMap[platName] ?? _platformMap[slug];
            if (abbr != null && !platforms.contains(abbr)) {
              platforms.add(abbr);
            }
          }

          final genres = <String>[];
          final genresList = game['genres'] as List<dynamic>? ?? [];
          for (final g in genresList) {
            genres.add(g['name'] as String? ?? '');
          }

          int? releaseYear;
          final released = game['released'] as String?;
          if (released != null && released.length >= 4) {
            releaseYear = int.tryParse(released.substring(0, 4));
          }

          // Use LibRetro boxart as cover if we know the console,
          // otherwise fall back to RAWG background_image
          String? coverUrl = game['background_image'] as String?;
          if (consoleAbbr != null) {
            final lrUrl = getLibRetroBoxartUrl(
                game['name'] as String? ?? '', consoleAbbr);
            if (lrUrl != null) coverUrl = lrUrl;
          }

          results.add(CatalogGame(
            title: game['name'] as String? ?? 'Unknown',
            genre: genres.isNotEmpty ? _mapGenre(genres.first) : null,
            releaseYear: releaseYear,
            coverUrl: coverUrl,
            description: game['description_raw'] as String?,
            platforms: platforms,
            regions: _inferRegions(platforms),
          ));
        }
      }
    } catch (_) {
      // API unavailable
    }

    return results;
  }

  /// Search LibRetro thumbnail listings on GitHub for matching game names.
  /// This uses the GitHub API to list files in the Named_Boxarts directory
  /// and filter by the search query. Works like EmuDeck's art scraping.
  static Future<List<CatalogGame>> _searchLibRetroListing(
      String query, String consoleAbbr) async {
    final results = <CatalogGame>[];
    final system = _libRetroSystemMap[consoleAbbr];
    if (system == null) return results;

    // Use GitHub API to search for matching filenames
    final repoName = system.replaceAll(' ', '_').replaceAll('-', '_');
    // LibRetro thumbnail repos use the system name with spaces as repo names
    // but GitHub search works across the org
    final searchQuery = Uri.encodeComponent(
        '$query extension:png repo:libretro-thumbnails/${system.replaceAll(' ', '_')}');

    try {
      // Use GitHub search to find matching thumbnails
      final uri = Uri.parse(
          'https://api.github.com/search/code?q=$searchQuery&per_page=15');
      final response = await http.get(uri, headers: {
        'Accept': 'application/vnd.github.v3+json',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          final path = item['path'] as String? ?? '';
          if (!path.contains('Named_Boxarts')) continue;

          // Extract game title from filename
          final fileName = path.split('/').last;
          final title =
              fileName.replaceAll('.png', '').replaceAll('_', ' ');

          final coverUrl =
              'https://thumbnails.libretro.com/${Uri.encodeComponent(system)}/Named_Boxarts/${Uri.encodeComponent(fileName)}';

          results.add(CatalogGame(
            title: title,
            coverUrl: coverUrl,
            platforms: [consoleAbbr],
            regions: _inferRegions([consoleAbbr]),
          ));
        }
      }
    } catch (_) {
      // GitHub API unavailable or rate limited
    }

    return results;
  }

  /// Infer likely regional variants based on platforms.
  static List<String> _inferRegions(List<String> platforms) {
    final regions = <String>{};
    for (final p in platforms) {
      if (['FC', 'SFC', 'PCE', 'MD', 'SAT', 'DC'].contains(p)) {
        regions.add('NTSC-J');
      }
      if (['NES', 'SNES', 'GEN', 'TG16'].contains(p)) {
        regions.add('NTSC-U');
        regions.add('PAL');
      }
      if ([
        'N64', 'GCN', 'Wii', 'PS1', 'PS2', 'GB', 'GBC', 'GBA',
        'NDS', 'PSP', 'XBOX'
      ].contains(p)) {
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
