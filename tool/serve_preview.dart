import 'dart:io';

// Local release preview: dart tool/serve_preview.dart
Future<void> main() async {
  final root = Directory('build/web').absolute;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8787);
  stdout.writeln('EngiSteps preview: http://127.0.0.1:8787');
  await for (final request in server) {
    try {
      final parts = request.uri.pathSegments;
      if (parts.any(
        (part) =>
            part == '..' ||
            part.contains('\\') ||
            part.contains('/') ||
            part.contains(':'),
      )) {
        request.response.statusCode = HttpStatus.forbidden;
      } else {
        final relative = parts.isEmpty || parts.last.isEmpty
            ? 'index.html'
            : parts.join('/');
        final file = File('${root.path}/$relative');
        if (await file.exists()) {
          final ext = relative.split('.').last;
          final type = {
            'html': 'text/html',
            'js': 'application/javascript',
            'json': 'application/json',
            'png': 'image/png',
            'wasm': 'application/wasm',
            'css': 'text/css',
            'svg': 'image/svg+xml',
            'ttf': 'font/ttf',
          }[ext];
          if (type != null) {
            request.response.headers.contentType = ContentType.parse(type);
          }
          request.response.headers.set(
            HttpHeaders.cacheControlHeader,
            'no-store',
          );
          await request.response.addStream(file.openRead());
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
      }
    } catch (_) {
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await request.response.close();
    }
  }
}
