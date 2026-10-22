import 'package:flutter/widgets.dart';

/// Outline tab icons drawn on a 24 x 24 grid, coloured by the [IconTheme].
class TabIcon extends StatelessWidget {
  const TabIcon(this.path, {super.key});

  final Path Function() path;

  static Path home() => Path()
    ..moveTo(3, 11)
    ..lineTo(12, 3)
    ..lineTo(21, 11)
    ..lineTo(21, 20)
    ..arcToPoint(const Offset(20, 21), radius: const Radius.circular(1))
    ..lineTo(15, 21)
    ..lineTo(15, 15)
    ..lineTo(9, 15)
    ..lineTo(9, 21)
    ..lineTo(4, 21)
    ..arcToPoint(const Offset(3, 20), radius: const Radius.circular(1))
    ..close();

  static Path links() {
    const r = Radius.circular(5);
    return Path()
      ..moveTo(10, 14)
      ..arcToPoint(const Offset(17, 14), radius: r, clockwise: false)
      ..lineTo(20, 11)
      ..arcToPoint(const Offset(13, 4), radius: r, clockwise: false)
      ..lineTo(12, 5)
      ..moveTo(14, 10)
      ..arcToPoint(const Offset(7, 10), radius: r, clockwise: false)
      ..lineTo(4, 13)
      ..arcToPoint(const Offset(11, 20), radius: r, clockwise: false)
      ..lineTo(12, 19);
  }

  static Path events() => Path()
    ..moveTo(4, 19)
    ..lineTo(4, 9)
    ..moveTo(10, 19)
    ..lineTo(10, 5)
    ..moveTo(16, 19)
    ..lineTo(16, 12)
    ..moveTo(22, 19)
    ..lineTo(2, 19);

  static Path inApp() => Path()
    ..moveTo(4, 5)
    ..lineTo(20, 5)
    ..lineTo(20, 16)
    ..lineTo(8, 16)
    ..lineTo(4, 20)
    ..close();

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;
    return CustomPaint(
      size: Size.square(size),
      painter: _StrokePainter(path(), theme.color ?? const Color(0xFF000000)),
    );
  }
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter(this.path, this.color);

  final Path path;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StrokePainter old) => old.color != color;
}
