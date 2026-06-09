class DayCounter {
  final String id;
  String label;
  DateTime targetDate;
  bool countUp;

  DayCounter({
    required this.id,
    this.label = 'Countdown',
    DateTime? targetDate,
    this.countUp = false,
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
    final suffix = d == 1 ? '' : 's';
    if (daysDiff >= 0) {
      return '$d day$suffix left';
    } else {
      return '${d} day$suffix ago';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'targetDate': '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}',
    'countUp': countUp,
  };
}
