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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        margin: const EdgeInsets.all(4),
        padding: _timers.isEmpty ? EdgeInsets.zero : const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Colors.black87.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _timers.isEmpty
            ? const Center(child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('No timers', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _timers.map((t) => _TimerRow(
                    data: t,
                    time: _timeFor(t),
                    onTap: () => _toggle(t['id'] as String),
                    onLongPress: () => _confirmRemove(t['id'] as String, t['name'] as String),
                  )).toList(),
                ),
              ),
      ),
    );
  }
}

class _TimerRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String time;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TimerRow({
    required this.data,
    required this.time,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(data['color'] as int).withValues(alpha: (data['opacity'] as num?)?.toDouble() ?? 0.7);
    final fgColor = Color(data['textColor'] as int);
    final running = data['running'] as bool? ?? false;
    final finished = data['finished'] as bool? ?? false;
    final fontSize = (data['fontSize'] as num?)?.toDouble() ?? 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: finished ? Colors.amber.withValues(alpha: 0.9) : bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                finished ? Icons.notifications_active : (running ? Icons.pause : Icons.play_arrow),
                color: fgColor, size: fontSize * 0.9,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  time,
                  style: TextStyle(
                    color: finished ? Colors.black : fgColor,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
