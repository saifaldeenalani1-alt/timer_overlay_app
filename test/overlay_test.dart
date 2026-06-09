import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Time formatting', () {
    test('formats seconds correctly', () {
      expect(_fmt(0), '00:00:00');
      expect(_fmt(59), '00:00:59');
      expect(_fmt(60), '00:01:00');
      expect(_fmt(3661), '01:01:01');
      expect(_fmt(86399), '23:59:59');
    });

    test('countUp display', () {
      expect(_timeFor({'countUp': true, 'elapsed': 0, 'total': 3600}), '00:00:00');
      expect(_timeFor({'countUp': true, 'elapsed': 3661, 'total': 3600}), '01:01:01');
    });

    test('countDown display', () {
      expect(_timeFor({'countUp': false, 'elapsed': 0, 'total': 3600}), '01:00:00');
      expect(_timeFor({'countUp': false, 'elapsed': 1800, 'total': 3600}), '00:30:00');
      expect(_timeFor({'countUp': false, 'elapsed': 3600, 'total': 3600}), '00:00:00');
      expect(_timeFor({'countUp': false, 'elapsed': 4000, 'total': 3600}), '00:00:00');
    });
  });

  group('TimerContent rendering', () {
    testWidgets('shows play icon when not running', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _TimerContent(
          data: {
            'id': 't1',
            'name': 'Test',
            'textColor': Colors.white.toARGB32(),
            'running': false,
            'finished': false,
            'fontSize': 16.0,
          },
          time: '00:00:00',
        ),
      ));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('00:00:00'), findsOneWidget);
    });

    testWidgets('shows pause icon when running', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _TimerContent(
          data: {
            'id': 't1',
            'name': 'Test',
            'textColor': Colors.white.toARGB32(),
            'running': true,
            'finished': false,
            'fontSize': 16.0,
          },
          time: '00:05:30',
        ),
      ));
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.text('00:05:30'), findsOneWidget);
    });

    testWidgets('shows notification icon when finished', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: _TimerContent(
          data: {
            'id': 't1',
            'name': 'Test',
            'textColor': Colors.white.toARGB32(),
            'running': false,
            'finished': true,
            'fontSize': 16.0,
          },
          time: '00:00:00',
        ),
      ));
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });
  });
}

String _fmt(int d) {
  final h = d ~/ 3600;
  final m = (d % 3600) ~/ 60;
  final s = d % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String _timeFor(Map<String, dynamic> data) {
  final up = data['countUp'] as bool? ?? true;
  final e = (data['elapsed'] as num?)?.toInt() ?? 0;
  final t = (data['total'] as num?)?.toInt() ?? 0;
  return _fmt(up ? e : (t - e).clamp(0, t));
}

class _TimerContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final String time;
  const _TimerContent({required this.data, required this.time});

  @override
  Widget build(BuildContext context) {
    final fgColor = Color(data['textColor'] as int);
    final running = data['running'] as bool? ?? false;
    final finished = data['finished'] as bool? ?? false;
    final fontSize = (data['fontSize'] as num?)?.toDouble() ?? 16.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            finished ? Icons.notifications_active : (running ? Icons.pause : Icons.play_arrow),
            color: fgColor, size: fontSize * 0.9,
          ),
          const SizedBox(width: 6),
          Text(time, style: TextStyle(color: fgColor, fontSize: fontSize)),
        ],
      ),
    );
  }
}
