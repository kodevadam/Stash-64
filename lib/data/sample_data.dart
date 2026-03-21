import '../models/game_console.dart';
import 'database_helper.dart';

/// Seeds the database with default consoles on first launch.
/// No sample games are added — the user adds their own collection.
class SampleData {
  static Future<void> seed(DatabaseHelper db) async {
    final existingConsoles = await db.getConsoles();
    if (existingConsoles.isNotEmpty) return; // Already seeded

    // Insert all default consoles
    for (final c in _defaultConsoles) {
      await db.insertConsole(c);
    }
  }

  static const _defaultConsoles = [
    // --- Nintendo Home Consoles ---
    GameConsole(
      name: 'Nintendo Entertainment System',
      abbreviation: 'NES',
      colorValue: 0xFFC62828, // Red
    ),
    GameConsole(
      name: 'Famicom',
      abbreviation: 'FC',
      colorValue: 0xFFD32F2F, // Lighter red
    ),
    GameConsole(
      name: 'Super Nintendo',
      abbreviation: 'SNES',
      colorValue: 0xFF6A1B9A, // Purple
    ),
    GameConsole(
      name: 'Super Famicom',
      abbreviation: 'SFC',
      colorValue: 0xFF7B1FA2, // Lighter purple
    ),
    GameConsole(
      name: 'Nintendo 64',
      abbreviation: 'N64',
      colorValue: 0xFF1A237E, // Deep blue
    ),
    GameConsole(
      name: 'Nintendo GameCube',
      abbreviation: 'GCN',
      colorValue: 0xFF4A148C, // Deep purple
    ),
    GameConsole(
      name: 'Nintendo Wii',
      abbreviation: 'Wii',
      colorValue: 0xFF00ACC1, // Cyan
    ),

    // --- Nintendo Handhelds ---
    GameConsole(
      name: 'Game Boy',
      abbreviation: 'GB',
      colorValue: 0xFF2E7D32, // Green
    ),
    GameConsole(
      name: 'Game Boy Color',
      abbreviation: 'GBC',
      colorValue: 0xFF388E3C, // Medium green
    ),
    GameConsole(
      name: 'Game Boy Advance',
      abbreviation: 'GBA',
      colorValue: 0xFF1B5E20, // Dark green
    ),
    GameConsole(
      name: 'Nintendo DS',
      abbreviation: 'NDS',
      colorValue: 0xFF546E7A, // Blue grey
    ),
    GameConsole(
      name: 'Nintendo Virtual Boy',
      abbreviation: 'VB',
      colorValue: 0xFFB71C1C, // Dark red
    ),

    // --- Sega Home Consoles ---
    GameConsole(
      name: 'Sega Master System',
      abbreviation: 'SMS',
      colorValue: 0xFF0277BD, // Blue
    ),
    GameConsole(
      name: 'Sega Genesis',
      abbreviation: 'GEN',
      colorValue: 0xFFB71C1C, // Red
    ),
    GameConsole(
      name: 'Sega Mega Drive',
      abbreviation: 'MD',
      colorValue: 0xFFC62828, // Red variant
    ),
    GameConsole(
      name: 'Sega CD',
      abbreviation: 'SCD',
      colorValue: 0xFF880E4F, // Deep pink
    ),
    GameConsole(
      name: 'Sega 32X',
      abbreviation: '32X',
      colorValue: 0xFF4A148C, // Purple
    ),
    GameConsole(
      name: 'Sega Saturn',
      abbreviation: 'SAT',
      colorValue: 0xFF37474F, // Dark grey
    ),
    GameConsole(
      name: 'Sega Dreamcast',
      abbreviation: 'DC',
      colorValue: 0xFFE65100, // Orange
    ),

    // --- Sega Handhelds ---
    GameConsole(
      name: 'Sega Game Gear',
      abbreviation: 'GG',
      colorValue: 0xFF0D47A1, // Blue
    ),

    // --- Sony ---
    GameConsole(
      name: 'PlayStation',
      abbreviation: 'PS1',
      colorValue: 0xFF1565C0, // Blue
    ),
    GameConsole(
      name: 'PlayStation 2',
      abbreviation: 'PS2',
      colorValue: 0xFF0D47A1, // Darker blue
    ),
    GameConsole(
      name: 'PlayStation Portable',
      abbreviation: 'PSP',
      colorValue: 0xFF263238, // Dark blue grey
    ),

    // --- Atari ---
    GameConsole(
      name: 'Atari 2600',
      abbreviation: '2600',
      colorValue: 0xFF4E342E, // Brown
    ),
    GameConsole(
      name: 'Atari 5200',
      abbreviation: '5200',
      colorValue: 0xFF5D4037, // Medium brown
    ),
    GameConsole(
      name: 'Atari 7800',
      abbreviation: '7800',
      colorValue: 0xFF6D4C41, // Light brown
    ),
    GameConsole(
      name: 'Atari Jaguar',
      abbreviation: 'JAG',
      colorValue: 0xFF3E2723, // Dark brown
    ),
    GameConsole(
      name: 'Atari Lynx',
      abbreviation: 'LYNX',
      colorValue: 0xFF795548, // Tan brown
    ),

    // --- NEC ---
    GameConsole(
      name: 'TurboGrafx-16',
      abbreviation: 'TG16',
      colorValue: 0xFFFF6F00, // Amber
    ),
    GameConsole(
      name: 'PC Engine',
      abbreviation: 'PCE',
      colorValue: 0xFFFF8F00, // Light amber
    ),
    GameConsole(
      name: 'TurboGrafx-CD',
      abbreviation: 'TGCD',
      colorValue: 0xFFE65100, // Deep orange
    ),

    // --- SNK ---
    GameConsole(
      name: 'Neo Geo AES',
      abbreviation: 'AES',
      colorValue: 0xFFBF360C, // Deep orange
    ),
    GameConsole(
      name: 'Neo Geo MVS',
      abbreviation: 'MVS',
      colorValue: 0xFFD84315, // Orange red
    ),
    GameConsole(
      name: 'Neo Geo Pocket',
      abbreviation: 'NGP',
      colorValue: 0xFFE64A19, // Deep orange
    ),
    GameConsole(
      name: 'Neo Geo Pocket Color',
      abbreviation: 'NGPC',
      colorValue: 0xFFFF5722, // Orange
    ),

    // --- Other ---
    GameConsole(
      name: 'ColecoVision',
      abbreviation: 'CV',
      colorValue: 0xFF455A64, // Blue grey
    ),
    GameConsole(
      name: 'Intellivision',
      abbreviation: 'INTV',
      colorValue: 0xFF1B5E20, // Dark green
    ),
    GameConsole(
      name: 'Vectrex',
      abbreviation: 'VEC',
      colorValue: 0xFF212121, // Near black
    ),
    GameConsole(
      name: '3DO',
      abbreviation: '3DO',
      colorValue: 0xFFAD1457, // Pink
    ),
    GameConsole(
      name: 'Philips CD-i',
      abbreviation: 'CDi',
      colorValue: 0xFF00695C, // Teal
    ),
    GameConsole(
      name: 'WonderSwan',
      abbreviation: 'WS',
      colorValue: 0xFF558B2F, // Lime green
    ),
    GameConsole(
      name: 'WonderSwan Color',
      abbreviation: 'WSC',
      colorValue: 0xFF689F38, // Light lime
    ),

    // --- Microsoft ---
    GameConsole(
      name: 'Xbox',
      abbreviation: 'XBOX',
      colorValue: 0xFF2E7D32, // Green
    ),
  ];
}
