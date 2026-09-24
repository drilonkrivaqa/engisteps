// Run with: flutter test tool/generate_icons.dart
// Vector-drawn brand mark: three steps and a circuit connection.
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Generate platform icons from the EngiSteps vector mark', () async {
    Future<void> write(String path, int pixels) async {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder)..scale(pixels / 1024);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1024, 1024),
        Paint()
          ..shader = Gradient.linear(
            const Offset(0, 0),
            const Offset(1024, 1024),
            [const Color(0xFF123A46), const Color(0xFF146B70)],
          ),
      );
      final pen = Paint()
        ..color = const Color(0xFFA3E7D6)
        ..strokeWidth = 64
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        Path()
          ..moveTo(272, 696)
          ..lineTo(272, 560)
          ..lineTo(432, 560)
          ..lineTo(432, 416)
          ..lineTo(592, 416)
          ..lineTo(592, 272)
          ..lineTo(752, 272),
        pen,
      );
      canvas.drawCircle(
        const Offset(752, 272),
        44,
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawLine(
        const Offset(272, 752),
        const Offset(752, 752),
        Paint()
          ..color = const Color(0xFFFFFFFF)
          ..strokeWidth = 24
          ..strokeCap = StrokeCap.round,
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(pixels, pixels);
      final bytes = await image.toByteData(format: ImageByteFormat.png);
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    }

    for (final size in [192, 512]) {
      await write('web/icons/Icon-$size.png', size);
      await write('web/icons/Icon-maskable-$size.png', size);
    }
    await write('web/favicon.png', 32);
    await write('docs/store-icon.png', 512);
    for (final entry in {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    }.entries) {
      await write(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        entry.value,
      );
    }
    for (final folder in [
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
      'macos/Runner/Assets.xcassets/AppIcon.appiconset',
    ]) {
      final manifest =
          jsonDecode(await File('$folder/Contents.json').readAsString())
              as Map<String, dynamic>;
      for (final icon in manifest['images'] as List) {
        final size = double.parse((icon['size'] as String).split('x').first);
        final scale = double.parse(
          (icon['scale'] as String).replaceAll('x', ''),
        );
        await write('$folder/${icon['filename']}', (size * scale).round());
      }
    }
  });
}
