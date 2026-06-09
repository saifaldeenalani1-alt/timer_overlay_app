import 'dart:async';
import 'package:flutter/material.dart';

class TimerItem {
  final String id;
  Timer? _timer;

  String name;
  bool countUp;
  int hours;
  int minutes;
  int seconds;
  int elapsed;
  bool running;
  Color color;
  Color textColor;
  double opacity;
  double fontSize;
  bool alertOnEnd;
  bool showInOverlay;

  TimerItem({
    required this.id,
    this.name = 'Timer',
    this.countUp = true,
    this.hours = 0,
    this.minutes = 1,
    this.seconds = 0,
    this.elapsed = 0,
    this.running = false,
    this.color = Colors.indigo,
    this.textColor = Colors.white,
    this.opacity = 0.7,
    this.fontSize = 16.0,
    this.alertOnEnd = false,
    this.showInOverlay = true,
  });

  int get total => hours * 3600 + minutes * 60 + seconds;
  int get display => countUp ? elapsed : (total - elapsed).clamp(0, total);

  String get formattedTime {
    final d = display;
    return '${(d ~/ 3600).toString().padLeft(2, '0')}:${((d % 3600) ~/ 60).toString().padLeft(2, '0')}:${(d % 60).toString().padLeft(2, '0')}';
  }

  bool get isFinished => !countUp && elapsed >= total;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'time': formattedTime,
    'elapsed': elapsed,
    'total': total,
    'countUp': countUp,
    'running': running,
    'finished': isFinished,
    'color': color.toARGB32(),
    'textColor': textColor.toARGB32(),
    'opacity': opacity,
    'fontSize': fontSize,
  };

  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    running = false;
  }

  void dispose() {
    _timer?.cancel();
  }
}
