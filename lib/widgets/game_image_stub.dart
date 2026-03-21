import 'package:flutter/material.dart';

/// Stub — should never be reached. One of io/web will always match.
Widget buildPlatformImage({
  required String path,
  required BoxFit fit,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  throw UnsupportedError('Cannot create image on this platform');
}
