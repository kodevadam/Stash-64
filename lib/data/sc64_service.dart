import 'dart:async';
import 'dart:io';

/// Thin wrapper around the `sc64deployer` CLI for the SummerCart64
/// flashcart. Handles device detection, lock-state detection, and ROM
/// uploads. Desktop-only — sc64deployer doesn't exist on Android.
///
/// The binary's exact CLI surface is stable across recent releases:
///
///   sc64deployer info          — prints device info (exits 0 if connected,
///                                 non-zero if no device or driver error)
///   sc64deployer upload <rom>  — flashes a ROM file to the cart's SDRAM
///
/// We look for textual markers in stdout/stderr to classify the three
/// states we care about: notConnected, lockedByConsole, ready.
class Sc64Service {
  /// Full path to the sc64deployer binary. If null, we try a plain
  /// `sc64deployer` which relies on PATH.
  final String? binaryPath;

  const Sc64Service({this.binaryPath});

  String get _exe => binaryPath?.isNotEmpty == true ? binaryPath! : 'sc64deployer';

  /// Auto-probe for the binary using `which`. Returns its absolute path
  /// or null if not found. Desktop only — on other platforms returns null.
  static Future<String?> autoDetectBinary() async {
    if (!_desktop) return null;
    try {
      final result = await Process.run(
        Platform.isWindows ? 'where' : 'which',
        ['sc64deployer'],
      );
      if (result.exitCode == 0) {
        final line = (result.stdout as String).trim().split('\n').first.trim();
        if (line.isNotEmpty) return line;
      }
    } catch (_) {/* binary not available — swallow */}
    return null;
  }

  static bool get _desktop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  /// Check the current device state. Cheap enough to poll on a 2s timer
  /// from the game detail page.
  Future<Sc64Status> checkStatus() async {
    if (!_desktop) {
      return const Sc64Status(
        state: Sc64DeviceState.notSupported,
        message: 'sc64deployer is desktop-only',
      );
    }
    try {
      final result = await Process.run(_exe, ['info'])
          .timeout(const Duration(seconds: 5));
      final out = '${result.stdout}\n${result.stderr}'.toLowerCase();

      if (result.exitCode != 0) {
        // sc64deployer prints helpful stderr: "no device found",
        // "permission denied", "locked", etc. Classify what we can.
        if (out.contains('no device') ||
            out.contains('not found') ||
            out.contains('no sc64')) {
          return const Sc64Status(
            state: Sc64DeviceState.notConnected,
            message: 'SummerCart64 not connected',
          );
        }
        if (out.contains('lock')) {
          return const Sc64Status(
            state: Sc64DeviceState.lockedByConsole,
            message: 'Power off the N64 to upload',
          );
        }
        if (out.contains('permission')) {
          return Sc64Status(
            state: Sc64DeviceState.error,
            message: 'USB permission denied — add a udev rule or run with access',
          );
        }
        return Sc64Status(
          state: Sc64DeviceState.error,
          message: _shortError(result.stderr as String, result.stdout as String),
        );
      }

      // Exit 0 + "lock" in output means N64 is powered on and holding
      // the cart. Otherwise we're good to write.
      if (out.contains('locked') || out.contains('console active')) {
        return const Sc64Status(
          state: Sc64DeviceState.lockedByConsole,
          message: 'Power off the N64 to upload',
        );
      }
      return const Sc64Status(
        state: Sc64DeviceState.ready,
        message: 'SummerCart64 ready',
      );
    } on ProcessException {
      return const Sc64Status(
        state: Sc64DeviceState.binaryMissing,
        message: 'sc64deployer not found on PATH',
      );
    } on TimeoutException {
      return const Sc64Status(
        state: Sc64DeviceState.error,
        message: 'sc64deployer timed out',
      );
    } catch (e) {
      return Sc64Status(
        state: Sc64DeviceState.error,
        message: e.toString(),
      );
    }
  }

  /// Upload a ROM. Returns a short user-facing message and whether the
  /// upload succeeded. sc64deployer prints progress but we currently
  /// don't parse it — the upload is fast enough that a spinner is fine.
  Future<Sc64UploadResult> upload(String romPath) async {
    if (!_desktop) {
      return const Sc64UploadResult(
        success: false,
        message: 'sc64deployer is desktop-only',
      );
    }
    if (!await File(romPath).exists()) {
      return Sc64UploadResult(
        success: false,
        message: 'ROM file not found: $romPath',
      );
    }
    try {
      final result = await Process.run(_exe, ['upload', romPath])
          .timeout(const Duration(minutes: 2));
      if (result.exitCode == 0) {
        return const Sc64UploadResult(
          success: true,
          message: 'ROM uploaded',
        );
      }
      return Sc64UploadResult(
        success: false,
        message: _shortError(result.stderr as String, result.stdout as String),
      );
    } on ProcessException {
      return const Sc64UploadResult(
        success: false,
        message: 'sc64deployer not found on PATH',
      );
    } on TimeoutException {
      return const Sc64UploadResult(
        success: false,
        message: 'upload timed out after 2 min',
      );
    } catch (e) {
      return Sc64UploadResult(success: false, message: e.toString());
    }
  }

  /// Take the first non-empty line of stderr (falling back to stdout) —
  /// sc64deployer's most useful error message is almost always on line 1.
  String _shortError(String stderr, String stdout) {
    for (final src in [stderr, stdout]) {
      for (final line in src.split('\n')) {
        final t = line.trim();
        if (t.isNotEmpty) return t;
      }
    }
    return 'sc64deployer failed';
  }
}

enum Sc64DeviceState {
  /// Fresh state / not yet checked.
  unknown,

  /// Running on Android/iOS/web — sc64deployer cannot be invoked.
  notSupported,

  /// Binary not found on PATH or at the configured path.
  binaryMissing,

  /// Binary ran but no cart was plugged in.
  notConnected,

  /// Cart present but N64 is powered on and holds the cart bus.
  lockedByConsole,

  /// Cart present and writable.
  ready,

  /// Anything else — see `message` for details.
  error,
}

class Sc64Status {
  final Sc64DeviceState state;
  final String message;

  const Sc64Status({required this.state, required this.message});

  static const unknown =
      Sc64Status(state: Sc64DeviceState.unknown, message: '');

  bool get canUpload => state == Sc64DeviceState.ready;
}

class Sc64UploadResult {
  final bool success;
  final String message;

  const Sc64UploadResult({required this.success, required this.message});
}
