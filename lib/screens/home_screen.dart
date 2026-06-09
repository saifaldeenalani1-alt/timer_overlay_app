import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screen_overlay/flutter_screen_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _countUp = true;
  int _hours = 0;
  int _minutes = 1;
  int _seconds = 0;
  int _elapsed = 0;
  Timer? _timer;
  bool _running = false;
  bool _overlayVisible = false;

  @override
  void initState() {
    super.initState();
    _requestOverlayPermission();
  }

  Future<void> _requestOverlayPermission() async {
    if (!await FlutterScreenOverlay.isPermissionGranted()) {
      await FlutterScreenOverlay.requestPermission();
    }
  }

  int get _total => _hours * 3600 + _minutes * 60 + _seconds;

  int get _display => _countUp
      ? _elapsed
      : (_total - _elapsed).clamp(0, _total);

  String _fmt(int sec) {
    final h = (sec ~/ 3600).toString().padLeft(2, '0');
    final m = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _send(Map<String, dynamic> msg) {
    FlutterScreenOverlay.shareData(jsonEncode(msg));
  }

  void _showOverlay() async {
    await FlutterScreenOverlay.showOverlay(
      height: 60,
      width: 210,
      enableDrag: true,
      overlayTitle: 'Timer',
      flag: OverlayFlag.defaultFlag,
    );
    setState(() => _overlayVisible = true);
  }

  void _hideOverlay() async {
    await FlutterScreenOverlay.closeOverlay();
    setState(() {
      _overlayVisible = false;
      _running = false;
      _timer?.cancel();
    });
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      _send({'action': 'stop'});
    } else {
      if (!_overlayVisible) _showOverlay();
      _send({
        'action': 'start',
        'mode': _countUp ? 'up' : 'down',
        'total': _total,
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed++;
          if (!_countUp && _elapsed >= _total) {
            _timer?.cancel();
            _running = false;
          }
        });
        _send({'action': 'tick', 'time': _fmt(_display)});
      });
    }
    setState(() => _running = !_running);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _elapsed = 0;
      _running = false;
    });
    _send({'action': 'reset'});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floating Timer'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Count Up')),
                ButtonSegment(value: false, label: Text('Count Down')),
              ],
              selected: {_countUp},
              onSelectionChanged: _running ? (_) {} : (v) => setState(() => _countUp = v.first),
            ),
            if (!_countUp) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DurationPicker(label: 'HH', value: _hours, max: 99, onChange: (v) => _hours = v),
                  const Text(' : ', style: TextStyle(fontSize: 28)),
                  _DurationPicker(label: 'MM', value: _minutes, max: 59, onChange: (v) => _minutes = v),
                  const Text(' : ', style: TextStyle(fontSize: 28)),
                  _DurationPicker(label: 'SS', value: _seconds, max: 59, onChange: (v) => _seconds = v),
                ],
              ),
            ],
            const Spacer(),
            Text(_fmt(_display), style: theme.textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _toggle,
                  icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  label: Text(_running ? 'Pause' : 'Start'),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _running || _elapsed > 0 ? _reset : null,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _overlayVisible ? _hideOverlay : _showOverlay,
              icon: Icon(_overlayVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              label: Text(_overlayVisible ? 'Hide Overlay' : 'Show Overlay'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DurationPicker extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChange;

  const _DurationPicker({
    required this.label,
    required this.value,
    required this.max,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        SizedBox(
          width: 64,
          child: TextField(
            controller: TextEditingController(text: value.toString().padLeft(2, '0')),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (s) {
              final v = int.tryParse(s) ?? 0;
              onChange(v.clamp(0, max));
            },
          ),
        ),
      ],
    );
  }
}
