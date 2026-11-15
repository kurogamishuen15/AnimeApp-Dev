import 'package:material_ui/material_ui.dart';

import 'home_appearance.dart';

final class HomeArtwork extends StatelessWidget {
  const HomeArtwork({
    required this.asset,
    required this.width,
    this.url,
    this.height,
    this.alignment = Alignment.center,
    super.key,
  });

  final String? asset;
  final double width;
  final double? height;
  final String? url;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(color: HomeAppearance.of(context).surface);
    final path = asset;
    final imageUrl = url;
    if (imageUrl != null && Uri.tryParse(imageUrl)?.scheme == 'https') {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: alignment,
        cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
            .ceil()
            .clamp(1, 1600),
        filterQuality: FilterQuality.low,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (path == null) return fallback;
    return Image.asset(
      'assets/home/$path.webp',
      fit: BoxFit.cover,
      alignment: alignment,
      excludeFromSemantics: true,
      cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(
        1,
        path == 'hero' ? 1440 : 560,
      ),
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
