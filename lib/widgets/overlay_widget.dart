import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  List<Map<String, dynamic>> _timers = [];
  StreamSubscription? _sub;
  Timer? _localTick;
  double _dragX = 0;
  double _dragY = 0;

  @override
  void initState() {
    super.initState();
    _sub = FlutterOverlayWindow.overlayListener.listen(_onData);
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
    FlutterOverlayWindow.shareData({'action': 'toggle', 'id': id});
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggle(_timers.first['id'] as String),
      onLongPress: () {
        final t = _timers.first;
        FlutterOverlayWindow.shareData({
          'action': 'request_remove',
          'id': t['id'] as String,
          'name': t['name'] as String,
        });
      },
      onPanUpdate: (d) {
        _dragX += d.delta.dx;
        _dragY += d.delta.dy;
        FlutterOverlayWindow.shareData({
          'action': 'drag',
          'x': _dragX.round(),
          'y': _dragY.round(),
        });
      },
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _timers.map((t) {
            final bgColor = Color(t['color'] as int);
            final opacity = (t['opacity'] as num?)?.toDouble() ?? 0.7;
            final idx = _timers.indexOf(t);
            return Padding(
              padding: EdgeInsets.only(bottom: idx < _timers.length - 1 ? 8 : 0),
              child: Container(
                clipBehavior: Clip.none,
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: _TimerContent(data: t, time: _timeFor(t)),
              ),
            );
          }).toList(),
        ),
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
    final fontSize = (data['fontSize'] as num?)?.toDouble() ?? 16.0;

    return Text(
      time,
      style: TextStyle(
        color: fgColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
  }
}
