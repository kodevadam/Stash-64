import 'package:flutter/material.dart';

/// Web implementation — all image paths are treated as URLs.
Widget buildPlatformImage({
  required String path,
  required BoxFit fit,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return Image.network(
    path,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}
