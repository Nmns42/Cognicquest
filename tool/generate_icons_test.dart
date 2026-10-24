@Tags(['tool'])
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cognicquest/core/theme/logo_palette.dart';
import 'package:cognicquest/core/ui/cq_logo.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Génère toutes les icônes de l'app depuis [CqLogoPainter], source unique
/// du logo :
///
/// ```
/// flutter test --no-pub --tags tool tool/generate_icons_test.dart
/// ```
///
/// Exclu de la suite normale (tag `tool`, cf. `dart_test.yaml`).
void main() {
  /// Fond : carré arrondi clair ([radius] relatif), plein cadre, ou aucun.
  Future<Uint8List> render(
    int px, {
    required LogoPalette palette,
    Color? background,
    double radius = 0,
    double inset = 0.08,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size.square(px.toDouble());
    if (background != null) {
      final paint = Paint()..color = background;
      if (radius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Offset.zero & size, Radius.circular(px * radius)),
          paint,
        );
      } else {
        canvas.drawRect(Offset.zero & size, paint);
      }
    }
    CqLogoPainter(palette, inset: inset).paint(canvas, size);
    final image = await recorder.endRecording().toImage(px, px);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  Future<void> write(String path, Uint8List bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  /// Icône claire « any » : carré arrondi parchemin.
  Future<Uint8List> light(int px, {double radius = 0.22, double inset = 0.1}) =>
      render(px,
          palette: LogoPalette.onLight,
          background: LogoPalette.lightBackground,
          radius: radius,
          inset: inset);

  /// Icône maskable : fond forêt plein cadre, logo clair dans la zone sûre
  /// (cercle de 80 %).
  Future<Uint8List> maskable(int px) => render(px,
      palette: LogoPalette.onForest,
      background: LogoPalette.forestBackground,
      inset: 0.16);

  /// ICO à entrées PNG (Windows Vista et suivants).
  Uint8List ico(List<(int, Uint8List)> images) {
    final header = BytesBuilder()
      ..add(_u16(0))
      ..add(_u16(1))
      ..add(_u16(images.length));
    var offset = 6 + 16 * images.length;
    final entries = BytesBuilder();
    for (final (px, png) in images) {
      entries
        ..addByte(px >= 256 ? 0 : px)
        ..addByte(px >= 256 ? 0 : px)
        ..addByte(0)
        ..addByte(0)
        ..add(_u16(1))
        ..add(_u16(32))
        ..add(_u32(png.length))
        ..add(_u32(offset));
      offset += png.length;
    }
    return (BytesBuilder()
          ..add(header.toBytes())
          ..add(entries.toBytes())
          ..add([for (final (_, png) in images) ...png]))
        .toBytes();
  }

  testWidgets('génère les icônes', (tester) async {
    await tester.runAsync(() async {
      // ── Web ─────────────────────────────────────────────────────────────
      await write('web/favicon.png', await light(32, radius: 0.2, inset: 0.04));
      await write('web/icons/Icon-192.png', await light(192));
      await write('web/icons/Icon-512.png', await light(512));
      await write('web/icons/Icon-maskable-192.png', await maskable(192));
      await write('web/icons/Icon-maskable-512.png', await maskable(512));
      // iOS arrondit lui-même : plein cadre, opaque.
      await write('web/icons/apple-touch-icon.png',
          await light(180, radius: 0, inset: 0.1));

      // ── Android (icônes classiques) ─────────────────────────────────────
      const android = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final MapEntry(key: density, value: px) in android.entries) {
        await write('android/app/src/main/res/mipmap-$density/ic_launcher.png',
            await light(px, radius: 0.2));
      }

      // ── iOS : opaque, plein cadre (l'App Store refuse la transparence) ──
      const ios = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
      };
      for (final MapEntry(key: name, value: px) in ios.entries) {
        await write('ios/Runner/Assets.xcassets/AppIcon.appiconset/$name',
            await light(px, radius: 0, inset: 0.1));
      }

      // ── Windows ─────────────────────────────────────────────────────────
      await write('windows/runner/resources/app_icon.ico', ico([
        for (final px in [16, 24, 32, 48, 64, 256])
          (px, await light(px, radius: 0.2, inset: px < 32 ? 0.02 : 0.08)),
      ]));

      // ── Logo seul, transparent (documents, aperçus) ─────────────────────
      await write('assets/logo/cognicquest-logo-512.png',
          await render(512, palette: LogoPalette.onLight, inset: 0));
      await write('assets/logo/cognicquest-logo-on-forest-512.png',
          await maskable(512));
    });
  });
}

List<int> _u16(int v) => [v & 0xFF, (v >> 8) & 0xFF];
List<int> _u32(int v) =>
    [v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF];
