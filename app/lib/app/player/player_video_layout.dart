import 'package:flutter/widgets.dart';

/// Keeps the texture mounted while the toolbar moves between dock and overlay.
final class PlayerVideoLayout extends StatelessWidget {
  const PlayerVideoLayout({
    required this.video,
    required this.controls,
    required this.fullscreen,
    super.key,
  });

  final Widget video;
  final Widget controls;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) => CustomMultiChildLayout(
    delegate: _PlayerVideoLayoutDelegate(fullscreen),
    children: [
      LayoutId(id: _Slot.video, child: video),
      LayoutId(
        id: _Slot.controls,
        child: SingleChildScrollView(primary: false, child: controls),
      ),
    ],
  );
}

enum _Slot { video, controls }

final class _PlayerVideoLayoutDelegate extends MultiChildLayoutDelegate {
  _PlayerVideoLayoutDelegate(this.fullscreen);
  final bool fullscreen;

  @override
  void performLayout(Size size) {
    final Size bar = layoutChild(
      _Slot.controls,
      BoxConstraints.tightFor(width: size.width)
          .copyWith(maxHeight: size.height * .60),
    );
    layoutChild(
      _Slot.video,
      BoxConstraints.tight(
        Size(size.width, fullscreen ? size.height : size.height - bar.height),
      ),
    );
    positionChild(_Slot.video, Offset.zero);
    positionChild(_Slot.controls, Offset(0, size.height - bar.height));
  }

  @override
  bool shouldRelayout(_PlayerVideoLayoutDelegate oldDelegate) =>
      fullscreen != oldDelegate.fullscreen;
}
