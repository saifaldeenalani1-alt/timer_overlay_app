import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

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
    FlutterOverlayWindow.overlayListener.listen(_onMessage);
  }

  void _onMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final action = data['action'] as String?;
      if (action == 'tick') {
        setState(() => _time = data['time'] as String? ?? _time);
      } else if (action == 'reset') {
        setState(() => _time = '00:00:00');
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onTap: () => setState(() => _minimized = !_minimized),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
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
                    onTap: () => FlutterOverlayWindow.closeOverlay(),
                    child: const Icon(Icons.close, color: Colors.white54, size: 16),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
