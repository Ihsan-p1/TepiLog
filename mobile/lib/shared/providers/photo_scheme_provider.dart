import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tepilog/shared/widgets/tepi_image.dart';

/// "Warna dari Foto": the colours a photo lends to the UI around it.
///
/// Uses Flutter's own content-colour extraction. The fidelity variant keeps
/// the photo's hue and chroma, and fixes the tone per theme (40 light, 80
/// dark), so a dark or hazy photo still gives an accent that reads.
/// ponytail: a photo with no usable colour (pure grey fog) falls back to the
/// library's default blue; a neutral fallback needs our own scoring.
Future<ColorScheme?> schemeFromPhoto(ImageProvider photo, Brightness brightness) async {
  try {
    return await ColorScheme.fromImageProvider(
      provider: photo,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
  } catch (_) {
    return null; // Callers keep the theme's neutral colours.
  }
}

/// Cached per photo URL and theme brightness.
final photoSchemeProvider =
    FutureProvider.family<ColorScheme?, (String, Brightness)>(
  (ref, key) => schemeFromPhoto(tepiImageProvider(key.$1), key.$2),
);
