import 'package:flutter/material.dart';
import 'package:flutter_custom_overlay/flutter_custom_overlay.dart';

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  String _time = '00:00:00';
  bool _minimized = false;

  @override
  void initState() {
    super.initState();
    OverlayMessenger.listen();
    OverlayMessenger.onDataReceived.listen((event) {
      if (event is Map<String, dynamic>) {
        final action = event['action'] as String?;
        if (action == 'tick') {
          setState(() => _time = event['time'] as String? ?? _time);
        } else if (action == 'reset') {
          setState(() => _time = '00:00:00');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
      child: GestureDetector(
        onTap: () => setState(() => _minimized = !_minimized),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                _time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              if (!_minimized) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => FlutterCustomOverlay.hideOverlay(),
                  child: const Icon(Icons.close, color: Colors.white54, size: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
