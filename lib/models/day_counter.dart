import 'package:flutter/material.dart';

class DayCounter {
  final String id;
  String label;
  DateTime targetDate;
  bool countUp;
  Color bgColor;
  Color textColor;
  double opacity;

  DayCounter({
    required this.id,
    this.label = '\u0627\u0644\u0639\u062F',
    DateTime? targetDate,
    this.countUp = false,
    this.bgColor = const Color(0xFF1C1C1E),
    this.textColor = Colors.white,
    this.opacity = 1.0,
  }) : targetDate = targetDate ?? DateTime.now().add(const Duration(days: 30));

  DateTime get normalizedDate => DateTime(targetDate.year, targetDate.month, targetDate.day);

  int get daysDiff {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = normalizedDate;
    return end.difference(start).inDays;
  }

  String get displayText {
    final d = daysDiff.abs();
    if (daysDiff >= 0) {
      return '\u0645\u062A\u0628\u0642\u064A $d \u064A\u0648\u0645';
    } else {
      return '\u0645\u0646\u0630 $d \u064A\u0648\u0645';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'targetDate': '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}',
    'countUp': countUp,
    'bgColor': bgColor.toARGB32(),
    'textColor': textColor.toARGB32(),
    'opacity': opacity,
  };
}
