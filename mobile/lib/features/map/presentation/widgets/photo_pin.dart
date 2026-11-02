import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tepilog/app/theme.dart';
import 'package:tepilog/shared/providers/photo_scheme_provider.dart';
import 'package:tepilog/shared/widgets/tepi_image.dart';

/// Logical size of a pin bitmap: the photo, a 3 px ring in the photo's colour,
/// a count chip under it, and 6 px around everything for the shadow.
enum PhotoPinSize {
  normal(48),
  selected(60);

  const PhotoPinSize(this.photo);

  static const _margin = 6.0;
  static const _ring = 3.0;
  static const _chipDrop = 12.0; // how far the chip hangs below the frame

  final double photo;
  double get frame => photo + 2 * _ring;
  double get width => frame + 2 * _margin;
  double get height => frame + _chipDrop + 2 * _margin;

  /// Marker anchor at the centre of the photo, so the photo sits on the spot.
  Offset get anchor => Offset(0.5, (_margin + frame / 2) / height);
}

/// Draws a place's map pin as PNG bytes at device resolution.
Future<Uint8List> paintPhotoPin({
  required ImageProvider photo,
  required int count,
  required Color ring,
  required Color onRing,
  required bool selected,
  required double devicePixelRatio,
  Color halo = Colors.white,
}) async {
  final size = selected ? PhotoPinSize.selected : PhotoPinSize.normal;
  const m = PhotoPinSize._margin;
  final image = await _load(
    ResizeImage(photo, width: 256, height: 256, policy: ResizeImagePolicy.fit),
  );

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(devicePixelRatio);

  final frame = RRect.fromRectAndRadius(
    Rect.fromLTWH(m, m, size.frame, size.frame),
    Radius.circular(size.frame * 0.28),
  );
  canvas.drawRRect(
    frame.shift(const Offset(0, 3)),
    Paint()
      ..color = const Color(0x40000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawRRect(frame, Paint()..color = ring);

  final inner = frame.deflate(PhotoPinSize._ring);
  if (image != null) {
    canvas.save();
    canvas.clipRRect(inner);
    paintImage(
      canvas: canvas,
      rect: inner.outerRect,
      image: image,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );
    canvas.restore();
  } else {
    canvas.drawRRect(inner, Paint()..color = const Color(0xFF9C9EA4));
  }

  final label = TextPainter(
    text: TextSpan(
      text: '$count',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: onRing,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final chip = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: Offset(size.width / 2, m + size.frame + 2),
      width: math.max(label.width + 14, 22),
      height: 20,
    ),
    const Radius.circular(10),
  );
  canvas.drawRRect(chip.inflate(1.5), Paint()..color = halo);
  canvas.drawRRect(chip, Paint()..color = ring);
  label.paint(canvas, chip.center - Offset(label.width / 2, label.height / 2));

  final bitmap = await recorder.endRecording().toImage(
        (size.width * devicePixelRatio).round(),
        (size.height * devicePixelRatio).round(),
      );
  final png = await bitmap.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

/// Null when the photo cannot be loaded; the pin then shows a grey tile.
Future<ui.Image?> _load(ImageProvider provider) {
  final done = Completer<ui.Image?>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  void finish(ui.Image? image) {
    if (!done.isCompleted) done.complete(image);
    stream.removeListener(listener);
  }

  listener = ImageStreamListener(
    (info, _) => finish(info.image),
    onError: (_, _) => finish(null),
  );
  stream.addListener(listener);
  return done.future.timeout(const Duration(seconds: 10), onTimeout: () => null);
}

typedef PhotoPinKey = ({
  String url,
  int count,
  bool selected,
  Brightness brightness,
  double devicePixelRatio,
});

/// Pin bitmaps, cached per photo, count, selection and theme.
final photoPinProvider =
    FutureProvider.family<BitmapDescriptor, PhotoPinKey>((ref, key) async {
  final app = key.brightness == Brightness.light ? AppTheme.lightScheme : AppTheme.darkScheme;
  final photo = await ref.watch(photoSchemeProvider((key.url, key.brightness)).future);
  final png = await paintPhotoPin(
    photo: tepiImageProvider(key.url),
    count: key.count,
    ring: photo?.primary ?? app.primary,
    onRing: photo?.onPrimary ?? app.onPrimary,
    halo: app.surface,
    selected: key.selected,
    devicePixelRatio: key.devicePixelRatio,
  );
  return BitmapDescriptor.bytes(png, imagePixelRatio: key.devicePixelRatio);
});
