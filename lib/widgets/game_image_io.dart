import 'dart:io';

import 'package:flutter/material.dart';

/// Native (desktop/mobile) implementation — uses Image.file for local paths,
/// Image.network for URLs.
///
/// [cacheWidth] / [cacheHeight] downscale the decoded bitmap at load time,
/// so a 2000x3000 cover doesn't hog GPU memory when we're only showing it
/// as a 400px grid thumbnail. Especially important on Chromecast hardware
/// where the GPU budget is tight.
Widget buildPlatformImage({
  required String path,
  required BoxFit fit,
  double? width,
  double? height,
  int? cacheWidth,
  int? cacheHeight,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
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

  return Image.file(
    File(path),
    fit: fit,
    width: width,
    height: height,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    errorBuilder: errorBuilder,
  );
}
