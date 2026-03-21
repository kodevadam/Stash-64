// Conditional import: picks the right implementation based on platform.
export 'game_image_stub.dart'
    if (dart.library.io) 'game_image_io.dart'
    if (dart.library.html) 'game_image_web.dart';
