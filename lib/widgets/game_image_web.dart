import 'package:flutter/material.dart';

/// Web implementation — all image paths are treated as URLs.
Widget buildPlatformImage({
  required String path,
  required BoxFit fit,
  double? width,
  double? height,
  int? cacheWidth,
  int? cacheHeight,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return Image.network(
    path,
    fit: fit,
    width: width,
    height: height,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    errorBuilder: errorBuilder,
  );
}
