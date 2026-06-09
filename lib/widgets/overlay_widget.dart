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
  bool _minimized = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    OverlayMessenger.listen();
    _sub = OverlayMessenger.onDataReceived.listen(_onData);
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

  @override
  Widget build(BuildContext context) {
    if (_timers.isEmpty) {
      return const SizedBox.shrink();
    }

    final baseScale = _timers.fold(1.0, (max, t) => (t['sizeScale'] as num?)?.toDouble() ?? 1.0 > max ? (t['sizeScale'] as num).toDouble() : max);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () => setState(() => _minimized = !_minimized),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16 * baseScale),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _timers.map((t) => _TimerRow(
              data: t,
              minimized: _minimized,
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
  final bool minimized;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TimerRow({
    required this.data,
    required this.minimized,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scale = (data['sizeScale'] as num?)?.toDouble() ?? 1.0;
    final bgColor = Color(data['color'] as int).withValues(alpha: (data['opacity'] as num?)?.toDouble() ?? 0.7);
    final fgColor = Color(data['textColor'] as int);
    final running = data['running'] as bool? ?? false;
    final finished = data['finished'] as bool? ?? false;
    final fontSize = (16 * scale).clamp(12.0, 32.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2 * scale),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
          decoration: BoxDecoration(
            color: finished ? Colors.amber.withValues(alpha: 0.9) : bgColor,
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                finished ? Icons.notifications_active : (running ? Icons.pause : Icons.play_arrow),
                color: fgColor, size: 14 * scale,
              ),
              SizedBox(width: 4 * scale),
              if (!minimized) ...[
                Text(
                  data['name'] as String? ?? '',
                  style: TextStyle(color: fgColor, fontSize: fontSize * 0.7),
                ),
                SizedBox(width: 6 * scale),
              ],
              Text(
                data['time'] as String? ?? '00:00:00',
                style: TextStyle(
                  color: finished ? Colors.black : fgColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
