import 'dart:io';

import 'package:anime_app/app/anime_app.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AnimeApp());

  // F0.6 opt-in marker: engine rasterization is not proof that the compositor
  // presented a visible window. Keep normal launches side-effect free.
  final markerPath = Platform.environment['ANIMEAPP_FIRST_FRAME_MARKER'];
  if (markerPath != null && markerPath.isNotEmpty) {
    WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) {
      File(
        markerPath,
      ).writeAsStringSync('${DateTime.now().toUtc().microsecondsSinceEpoch}');
    });
  }
}
