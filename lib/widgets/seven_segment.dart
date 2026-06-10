import 'dart:math';
import 'package:flutter/material.dart';

class SevenSegmentDisplay extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const SevenSegmentDisplay({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((char) {
        if (char == ':') {
          return SizedBox(
            width: fontSize * 0.3,
            height: fontSize * 1.2,
            child: CustomPaint(
              painter: _ColonPainter(color: color, fontSize: fontSize),
            ),
          );
        }
        final digit = int.tryParse(char);
        if (digit == null) {
          return SizedBox(
            width: fontSize * 0.6,
            height: fontSize * 1.2,
          );
        }
        return SizedBox(
          width: fontSize * 0.6,
          height: fontSize * 1.2,
          child: CustomPaint(
            painter: _SegmentPainter(digit: digit, color: color, fontSize: fontSize),
          ),
        );
      }).toList(),
    );
  }
}

class _SegmentPainter extends CustomPainter {
  final int digit;
  final Color color;
  final double fontSize;

  _SegmentPainter({required this.digit, required this.color, required this.fontSize});

  static const Map<int, List<bool>> _segments = {
    0: [true, true, true, true, true, true, false],
    1: [false, true, true, false, false, false, false],
    2: [true, true, false, true, true, false, true],
    3: [true, true, true, true, false, false, true],
    4: [false, true, true, false, false, true, true],
    5: [true, false, true, true, false, true, true],
    6: [true, false, true, true, true, true, true],
    7: [true, true, true, false, false, false, false],
    8: [true, true, true, true, true, true, true],
    9: [true, true, true, true, false, true, true],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(2.0, fontSize * 0.08);

    final segs = _segments[digit] ?? _segments[0]!;
    final w = size.width;
    final h = size.height;
    final t = fontSize * 0.06;
    final len = w * 0.65;
    final segH = h * 0.25;

    final offColor = color.withValues(alpha: 0.15);

    // a - top horizontal
    _drawH(canvas, w / 2 - len / 2, t, len, segs[0] ? color : offColor, paint);
    // b - top right vertical
    _drawV(canvas, w - t - segH, t, h / 2 - t * 1.5, segs[1] ? color : offColor, paint);
    // c - bottom right vertical
    _drawV(canvas, w - t - segH, h / 2 + t * 0.5, h / 2 - t * 1.5, segs[2] ? color : offColor, paint);
    // d - bottom horizontal
    _drawH(canvas, w / 2 - len / 2, h - t - segH * 0.6, len, segs[3] ? color : offColor, paint);
    // e - bottom left vertical
    _drawV(canvas, t, h / 2 + t * 0.5, h / 2 - t * 1.5, segs[4] ? color : offColor, paint);
    // f - top left vertical
    _drawV(canvas, t, t, h / 2 - t * 1.5, segs[5] ? color : offColor, paint);
    // g - middle horizontal
    _drawH(canvas, w / 2 - len / 2, h / 2 - segH * 0.3, len, segs[6] ? color : offColor, paint);
  }

  void _drawH(Canvas canvas, double x, double y, double len, Color c, Paint p) {
    p.color = c;
    canvas.drawLine(Offset(x, y), Offset(x + len, y), p);
  }

  void _drawV(Canvas canvas, double x, double y, double len, Color c, Paint p) {
    p.color = c;
    canvas.drawLine(Offset(x, y), Offset(x, y + len), p);
  }

  @override
  bool shouldRepaint(covariant _SegmentPainter old) =>
      old.digit != digit || old.color != color;
}

class _ColonPainter extends CustomPainter {
  final Color color;
  final double fontSize;

  _ColonPainter({required this.color, required this.fontSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final r = max(2.0, fontSize * 0.06);
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.3), r, paint);
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.7), r, paint);
  }

  @override
  bool shouldRepaint(covariant _ColonPainter old) => old.color != color;
}
