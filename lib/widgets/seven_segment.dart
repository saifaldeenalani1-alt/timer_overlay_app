import 'dart:ui' as ui;
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
    return CustomPaint(
      size: Size(text.length * fontSize * 0.8, fontSize * 1.5),
      painter: _SevenSegPainter(text: text, color: color, fontSize: fontSize),
    );
  }
}

class _SevenSegPainter extends CustomPainter {
  final String text;
  final Color color;
  final double fontSize;

  _SevenSegPainter({required this.text, required this.color, required this.fontSize});

  static const List<List<bool>> _digitPatterns = [
    [true,true,true,true,true,true,false], // 0
    [false,true,true,false,false,false,false], // 1
    [true,true,false,true,true,false,true], // 2
    [true,true,true,true,false,false,true], // 3
    [false,true,true,false,false,true,true], // 4
    [true,false,true,true,false,true,true], // 5
    [true,false,true,true,true,true,true], // 6
    [true,true,true,false,false,false,false], // 7
    [true,true,true,true,true,true,true], // 8
    [true,true,true,true,false,true,true], // 9
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final charW = fontSize * 0.8;
    final charH = fontSize * 1.5;

    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      final ox = i * charW;

      if (ch == ':') {
        _paintColon(canvas, ox, 0, charW, charH);
        continue;
      }

      final d = int.tryParse(ch);
      if (d == null) continue;
      _paintDigit(canvas, ox, 0, charW, charH, _digitPatterns[d]);
    }
  }

  void _paintDigit(Canvas canvas, double ox, double oy, double w, double h, List<bool> segs) {
    final thick = (w * 0.18).clamp(2.0, 8.0);
    final gap = thick * 0.6;
    final r = Radius.circular(thick * 0.45);

    final onPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final offPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Layout: horizontal segments shorter to avoid overlap
    final hLen = w - thick * 2 - gap * 2;
    final vLen = (h - thick * 3 - gap * 4) / 2;

    final cx = ox + w / 2;
    final left = ox + thick + gap;
    final right = ox + w - thick - gap;
    final top = oy + thick / 2 + gap;
    final mid = oy + h / 2;
    final bot = oy + h - thick / 2 - gap;

    // a (top)
    _hSeg(canvas, cx - hLen / 2, top, hLen, thick, r, segs[0] ? onPaint : offPaint);
    // b (upper right)
    _vSeg(canvas, right, top + thick / 2 + gap, vLen, thick, r, segs[1] ? onPaint : offPaint);
    // c (lower right)
    _vSeg(canvas, right, mid + thick / 2 + gap, vLen, thick, r, segs[2] ? onPaint : offPaint);
    // d (bottom)
    _hSeg(canvas, cx - hLen / 2, bot, hLen, thick, r, segs[3] ? onPaint : offPaint);
    // e (lower left)
    _vSeg(canvas, left, mid + thick / 2 + gap, vLen, thick, r, segs[4] ? onPaint : offPaint);
    // f (upper left)
    _vSeg(canvas, left, top + thick / 2 + gap, vLen, thick, r, segs[5] ? onPaint : offPaint);
    // g (middle)
    _hSeg(canvas, cx - hLen / 2, mid, hLen, thick, r, segs[6] ? onPaint : offPaint);
  }

  void _hSeg(Canvas canvas, double x, double y, double len, double thick, Radius r, Paint paint) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y - thick / 2, len, thick), r), paint);
  }

  void _vSeg(Canvas canvas, double x, double y, double len, double thick, Radius r, Paint paint) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - thick / 2, y, thick, len), r), paint);
  }

  void _paintColon(Canvas canvas, double ox, double oy, double w, double h) {
    final r = (w * 0.12).clamp(2.0, 6.0);
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(ox + w / 2, oy + h * 0.33), r, paint);
    canvas.drawCircle(Offset(ox + w / 2, oy + h * 0.67), r, paint);
  }

  @override
  bool shouldRepaint(covariant _SevenSegPainter old) =>
      old.text != text || old.color != color;
}
