import '../models/game.dart';
import '../models/game_console.dart';
import 'database_helper.dart';

/// Seeds the database with sample consoles and games for first launch.
class SampleData {
  static Future<void> seed(DatabaseHelper db) async {
    final existingCount = await db.getGameCount();
    if (existingCount > 0) return; // Already seeded

    // Insert consoles
    final consoles = <String, int>{};
    for (final c in _sampleConsoles) {
      final id = await db.insertConsole(c);
      consoles[c.abbreviation] = id;
    }

    // Insert games
    for (final g in _sampleGames(consoles)) {
      await db.insertGame(g);
    }
  }

  static const _sampleConsoles = [
    GameConsole(
      name: 'Nintendo 64',
      abbreviation: 'N64',
      colorValue: 0xFF1A237E, // Deep blue
    ),
    GameConsole(
      name: 'Super Nintendo',
      abbreviation: 'SNES',
      colorValue: 0xFF6A1B9A, // Purple
    ),
    GameConsole(
      name: 'Sega Genesis',
      abbreviation: 'GEN',
      colorValue: 0xFFB71C1C, // Red
    ),
    GameConsole(
      name: 'Nintendo Entertainment System',
      abbreviation: 'NES',
      colorValue: 0xFFC62828, // Bright red
    ),
    GameConsole(
      name: 'PlayStation',
      abbreviation: 'PS1',
      colorValue: 0xFF0D47A1, // Blue
    ),
    GameConsole(
      name: 'Game Boy',
      abbreviation: 'GB',
      colorValue: 0xFF2E7D32, // Green
    ),
    GameConsole(
      name: 'Sega Dreamcast',
      abbreviation: 'DC',
      colorValue: 0xFFE65100, // Orange
    ),
    GameConsole(
      name: 'Atari 2600',
      abbreviation: '2600',
      colorValue: 0xFF4E342E, // Brown
    ),
  ];

  static List<Game> _sampleGames(Map<String, int> consoles) {
    return [
      // N64
      Game(
        title: 'Super Mario 64',
        consoleId: consoles['N64']!,
        genre: 'Platformer',
        minPlayers: 1,
        maxPlayers: 1,
        storageLocation: 'Drawer 1',
        releaseYear: 1996,
        isFavorite: true,
      ),
      Game(
        title: 'GoldenEye 007',
        consoleId: consoles['N64']!,
        genre: 'Shooter',
        minPlayers: 1,
        maxPlayers: 4,
        storageLocation: 'Drawer 1',
        releaseYear: 1997,
        isFavorite: true,
      ),
      Game(
        title: 'The Legend of Zelda: Ocarina of Time',
        consoleId: consoles['N64']!,
        genre: 'Action-Adventure',
        minPlayers: 1,
        maxPlayers: 1,
        storageLocation: 'Drawer 1',
        releaseYear: 1998,
        isFavorite: true,
      ),
      Game(
        title: 'Mario Kart 64',
        consoleId: consoles['N64']!,
        genre: 'Racing',
        minPlayers: 1,
        maxPlayers: 4,
        storageLocation: 'Drawer 1',
        releaseYear: 1996,
      ),
      Game(
        title: 'Super Smash Bros.',
        consoleId: consoles['N64']!,
        genre: 'Fighting',
        minPlayers: 1,
        maxPlayers: 4,
        storageLocation: 'Drawer 2',
        releaseYear: 1999,
      ),
      Game(
        title: 'Star Fox 64',
        consoleId: consoles['N64']!,
        genre: 'Shooter',
        minPlayers: 1,
        maxPlayers: 4,
        storageLocation: 'Drawer 2',
        releaseYear: 1997,
      ),

      // SNES
      Game(
        title: 'Super Mario World',
        consoleId: consoles['SNES']!,
        genre: 'Platformer',
        minPlayers: 1,
        maxPlayers: 2,
        storageLocation: 'Drawer 2',
        releaseYear: 1990,
        isFavorite: true,
      ),
      Game(
        title: 'The Legend of Zelda: A Link to the Past',
        consoleId: consoles['SNES']!,
        genre: 'Action-Adventure',
        minPlayers: 1,
        maxPlayers: 1,
        storageLocation: 'Drawer 2',
        releaseYear: 1991,
      ),
      Game(
        title: 'Super Metroid',
        consoleId: consoles['SNES']!,
        genre: 'Action-Adventure',
        minPlayers: 1,
        maxPlayers: 1,
        storageLocation: 'Drawer 3',
        releaseYear: 1994,
      ),
      Game(
        title: 'Street Fighter II Turbo',
        consoleId: consoles['SNES']!,
        genre: 'Fighting',
        minPlayers: 1,
        maxPlayers: 2,
        storageLocation: 'Drawer 3',
        releaseYear: 1993,
      ),

      // Genesis
      Game(
        title: 'Sonic the Hedgehog 2',
        consoleId: consoles['GEN']!,
        genre: 'Platformer',
        minPlayers: 1,
        maxPlayers: 2,
        storageLocation: 'Drawer 3',
        releaseYear: 1992,
      ),
      Game(
        title: 'Streets of Rage 2',
        consoleId: consoles['GEN']!,
        genre: 'Beat \'em Up',
        minPlayers: 1,
        maxPlayers: 2,
        storageLocation: 'Drawer 3',
        releaseYear: 1992,
      ),

      // NES
      Game(
        title: 'Super Mario Bros. 3',
        consoleId: consoles['NES']!,
        genre: 'Platformer',
        minPlayers: 1,
        maxPlayers: 2,
        storageLocation: 'Shelf A',
        releaseYear: 1988,
      ),
      Game(
        title: 'Mega Man 2',
        consoleId: consoles['NES']!,
        genre: 'Platformer',
        minPlayers: 1,
        maxPlayers: 1,
        storageLocation: 'Shelf A',
        releaseYear: 1988,
      ),

      // PS1
      Game(
        title: 'Final Fantasy VII',
        consoleId: consoles['PS1']!,
        genre: 'RPG',
        minPlayers: 1,
        maxPlayers: 1,
        storageLocation: 'Shelf B',
        releaseYear: 1997,
        isFavorite: true,
      ),
      Game(
        title: 'Crash Bandicoot',
        consoleId: consoles['PS1']!,
        genre: 'Platformer',
        minPlayers: 1,
        maxPlayers: 1,
        storageLocation: 'Shelf B',
        releaseYear: 1996,
      ),

      // Game Boy
      Game(
        title: 'Pokemon Red',
        consoleId: consoles['GB']!,
        genre: 'RPG',
        minPlayers: 1,
        maxPlayers: 2,
        storageLocation: 'Box 1',
        releaseYear: 1996,
      ),
      Game(
        title: 'Tetris',
        consoleId: consoles['GB']!,
        genre: 'Puzzle',
        minPlayers: 1,
        maxPlayers: 2,
        storageLocation: 'Box 1',
        releaseYear: 1989,
      ),

      // Dreamcast
      Game(
        title: 'Sonic Adventure',
        consoleId: consoles['DC']!,
        genre: 'Platformer',
        minPlayers: 1,
        maxPlayers: 1,
        storageLocation: 'Shelf C',
        releaseYear: 1998,
      ),
      Game(
        title: 'Soul Calibur',
        consoleId: consoles['DC']!,
        genre: 'Fighting',
        minPlayers: 1,
        maxPlayers: 2,
        storageLocation: 'Shelf C',
        releaseYear: 1999,
      ),
    ];
  }
}
