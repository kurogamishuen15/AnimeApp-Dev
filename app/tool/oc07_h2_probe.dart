import 'dart:io';

import 'package:anime_app/data/player/providers/miruro/miruro_http2_client.dart';

Future<void> main(List<String> args) async {
  final MiruroHttp2Client client = MiruroHttp2Client();
  final Map<String, String> headers = <String, String>{
    'user-agent': 'Kongroo/0.1 (public anime catalog client)',
    'accept': 'application/json',
    'accept-language': 'en-US,en;q=0.5',
    'referer': 'https://www.miruro.cx/',
    'origin': 'https://www.miruro.cx',
    'sec-fetch-site': 'same-origin',
    'sec-fetch-mode': 'cors',
    'sec-fetch-dest': 'empty',
  };
  for (final String path in <String>[
    '/health',
    '/api/config',
    '/api/v1/anime?q=Tokyo%20Ghoul%3Are&limit=15&sort=-popularity',
  ]) {
    try {
      final MiruroHttp2Response r = await client.get(
        Uri.parse('https://www.miruro.cx$path'),
        headers: headers,
        timeout: const Duration(seconds: 20),
        maxBytes: 8 * 1024 * 1024,
      );
      stdout.writeln(
        'H2 $path -> ${r.statusCode} ${r.headers['content-type']} '
        '${r.body.length}B',
      );
      if (r.body.isNotEmpty) {
        stdout.writeln('   ${String.fromCharCodes(r.body.take(60))}');
      }
    } on Object catch (error) {
      stdout.writeln('H2 $path -> ERROR ${error.runtimeType}: $error');
    }
  }
  await client.close();
  exit(0);
}
