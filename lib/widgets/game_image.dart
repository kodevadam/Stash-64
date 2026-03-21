import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'game_image_builder.dart';

/// Platform-safe image widget that handles both local file paths (native)
/// and URLs (web). On native, uses Image.file; on web, uses Image.network.
class GameImage extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? placeholderText;

  const GameImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholderText,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _placeholder();
    }

    return buildPlatformImage(
      path: imagePath!,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.surfaceDark,
      child: Center(
        child: placeholderText != null
            ? Text(
                placeholderText!,
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
              )
            : Icon(
                Icons.image_not_supported_outlined,
                size: 24,
                color: AppTheme.textSecondary.withOpacity(0.3),
              ),
      ),
    );
  }
}
