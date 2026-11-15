import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Displays provider score data without deriving or filling missing ratings.
final class HomeScoreBadge extends StatelessWidget {
  const HomeScoreBadge({required this.score, this.compact = true, super.key});

  final int? score;
  final bool compact;

  static const starColor = Color(0xffffcf62);

  @override
  Widget build(BuildContext context) {
    if (score == null) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xe60d0d10),
        borderRadius: BorderRadius.circular(compact ? 7 : 10),
        border: Border.all(color: const Color(0x2affffff)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: compact ? 4 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: Size.square(compact ? 14 : 17),
              painter: _ScoreStarPainter(starColor),
            ),
            const SizedBox(width: 3),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                height: 1,
                fontWeight: FontWeight.w600,
                letterSpacing: -.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreStarPainter extends CustomPainter {
  const _ScoreStarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.shortestSide / 2;
    final inner = outer * .46;
    final path = Path();
    for (var point = 0; point < 10; point++) {
      final radius = point.isEven ? outer : inner;
      final angle = -math.pi / 2 + point * math.pi / 5;
      final position = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (point == 0) {
        path.moveTo(position.dx, position.dy);
      } else {
        path.lineTo(position.dx, position.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ScoreStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
