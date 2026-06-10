import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_custom_overlay/flutter_custom_overlay.dart';

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  List<Map<String, dynamic>> _timers = [];
  StreamSubscription? _sub;
  Timer? _localTick;

  @override
  void initState() {
    super.initState();
    OverlayMessenger.listen();
    _sub = OverlayMessenger.onDataReceived.listen(_onData);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _localTick?.cancel();
    super.dispose();
  }

  void _onData(dynamic event) {
    if (event is Map<String, dynamic> && event['action'] == 'state') {
      final list = event['timers'] as List<dynamic>?;
      if (list != null) {
        setState(() {
          _timers = list.cast<Map<String, dynamic>>();
          _manageTick();
        });
      }
    }
  }

  void _manageTick() {
    final running = _timers.any((t) => t['running'] as bool? ?? false);
    if (running && _localTick == null) {
      _localTick = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else if (!running && _localTick != null) {
      _localTick?.cancel();
      _localTick = null;
    }
  }

  void _tick() {
    setState(() {
      for (final t in _timers) {
        if (t['running'] as bool? ?? false) {
          final e = (t['elapsed'] as num?)?.toInt() ?? 0;
          t['elapsed'] = e + 1;
        }
      }
    });
  }

  void _toggle(String id) {
    OverlayMessenger.sendToMainApp({'action': 'toggle', 'id': id});
  }

  void _confirmRemove(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Timer'),
        content: Text('Remove "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              OverlayMessenger.sendToMainApp({'action': 'remove', 'id': id});
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static String _fmt(int d) {
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

  @override
  Widget build(BuildContext context) {
    if (_timers.isEmpty) return const SizedBox.shrink();
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _timers.map((t) {
          final fs = (t['fontSize'] as num?)?.toDouble() ?? 16.0;
          final bgColor = Color(t['color'] as int);
          final opacity = (t['opacity'] as num?)?.toDouble() ?? 0.7;
          final h = (fs * 1.5 + 20).round().clamp(48, 120);
          final idx = _timers.indexOf(t);
          return Padding(
            padding: EdgeInsets.only(top: idx > 0 ? 4 : 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggle(t['id'] as String),
              onLongPress: () => _confirmRemove(t['id'] as String, t['name'] as String),
              child: Container(
                height: h.toDouble(),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                alignment: Alignment.centerLeft,
                child: _TimerContent(data: t, time: _timeFor(t)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          finished ? Icons.notifications_active : (running ? Icons.pause : Icons.play_arrow),
          color: fgColor, size: fontSize * 0.9,
        ),
        const SizedBox(width: 6),
        Text(
          time,
          style: TextStyle(
            color: fgColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
