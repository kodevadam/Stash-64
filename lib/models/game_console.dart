/// Represents a game console/platform (e.g., N64, SNES, Genesis).
class GameConsole {
  final int? id;
  final String name;
  final String abbreviation;
  final int colorValue; // Stored as int for DB, used as Color in UI

  const GameConsole({
    this.id,
    required this.name,
    required this.abbreviation,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'abbreviation': abbreviation,
      'color_value': colorValue,
    };
  }

  factory GameConsole.fromMap(Map<String, dynamic> map) {
    return GameConsole(
      id: map['id'] as int?,
      name: map['name'] as String,
      abbreviation: map['abbreviation'] as String,
      colorValue: map['color_value'] as int,
    );
  }

  GameConsole copyWith({
    int? id,
    String? name,
    String? abbreviation,
    int? colorValue,
  }) {
    return GameConsole(
      id: id ?? this.id,
      name: name ?? this.name,
      abbreviation: abbreviation ?? this.abbreviation,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameConsole &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => abbreviation;
}
