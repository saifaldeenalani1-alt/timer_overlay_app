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

  @override
  void initState() {
    super.initState();
    _sub = FlutterOverlayWindow.overlayListener.listen(_onData);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onData(dynamic event) {
    if (event is Map<String, dynamic> && event['action'] == 'state') {
      final list = event['timers'] as List<dynamic>?;
      if (list != null) {
        setState(() => _timers = list.cast<Map<String, dynamic>>());
      }
    }
  }

  void _toggle() {
    if (_timers.isEmpty) return;
    FlutterOverlayWindow.shareData({'action': 'toggle', 'id': _timers.first['id'] as String});
  }

  void _requestRemove() {
    if (_timers.isEmpty) return;
    final t = _timers.first;
    FlutterOverlayWindow.shareData({
      'action': 'request_remove',
      'id': t['id'] as String,
      'name': t['name'] as String,
    });
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
      color: Colors.transparent,
      child: Listener(
        onPointerDown: (e) {
          FlutterOverlayWindow.shareData({
            'action': 'drag_start',
            'dx': e.position.dx,
            'dy': e.position.dy,
          });
        },
        onPointerMove: (e) {
          FlutterOverlayWindow.shareData({
            'action': 'drag',
            'dx': e.delta.dx,
            'dy': e.delta.dy,
          });
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          onLongPress: _requestRemove,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black87.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _timers.map((t) {
                final idx = _timers.indexOf(t);
                return Padding(
                  padding: EdgeInsets.only(left: idx > 0 ? 8 : 0),
                  child: _TimerContent(data: t, time: _timeFor(t)),
                );
              }).toList(),
            ),
          ),
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