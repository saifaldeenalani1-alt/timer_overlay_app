import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_custom_overlay/flutter_custom_overlay.dart';
import '../models/timer_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<TimerItem> _timers = [];
  int _nextId = 1;
  bool _overlayActive = false;
  Timer? _updateTimer;
  StreamSubscription? _overlaySub;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _overlaySub = FlutterCustomOverlay.overlayStream.listen(_onOverlayMessage);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _overlaySub?.cancel();
    for (final t in _timers) {
      t.dispose();
    }
    super.dispose();
  }

  void _onOverlayMessage(dynamic event) {
    if (event is Map<String, dynamic>) {
      final action = event['action'] as String?;
      final id = event['id'] as String?;
      if (action == 'toggle' && id != null) {
        final timer = _timers.cast<TimerItem?>().firstWhere((t) => t?.id == id, orElse: () => null);
        if (timer != null) {
          timer.cancelTimer();
          setState(() {});
          _syncOverlay();
        }
      } else if (action == 'remove' && id != null) {
        final idx = _timers.indexWhere((t) => t.id == id);
        if (idx >= 0) {
          _timers[idx].dispose();
          setState(() => _timers.removeAt(idx));
          _syncOverlay();
        }
      }
    }
  }

  Future<void> _checkPermission() async {
    if (!await FlutterCustomOverlay.hasOverlayPermission()) {
      await FlutterCustomOverlay.requestOverlayPermission();
    }
  }

  void _syncOverlay() {
    final visible = _timers.where((t) => t.showInOverlay).toList();
    FlutterCustomOverlay.shareData({
      'action': 'state',
      'timers': visible.map((t) => t.toMap()).toList(),
    });

    if (_timers.any((t) => t.running)) {
      _updateTimer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } else {
      _updateTimer?.cancel();
      _updateTimer = null;
    }
  }

  void _tick() {
    if (!mounted) return;
    for (final t in _timers) {
      if (t.running) {
        t.elapsed++;
        if (t.isFinished) {
          t.cancelTimer();
          if (t.alertOnEnd) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${t.name} finished!'), duration: const Duration(seconds: 3)),
            );
          }
        }
      }
    }
    setState(() {});
    _syncOverlay();
    if (!_timers.any((t) => t.running)) {
      _updateTimer?.cancel();
      _updateTimer = null;
    }
  }

  void _toggleTimer(TimerItem t) {
    if (t.running) {
      t.cancelTimer();
    } else {
      t.running = true;
      if (t.isFinished) t.elapsed = 0;
    }
    setState(() {});
    _syncOverlay();
  }

  void _removeTimer(TimerItem t) {
    t.dispose();
    setState(() => _timers.remove(t));
    _syncOverlay();
  }

  void _resetTimer(TimerItem t) {
    t.elapsed = 0;
    t.cancelTimer();
    setState(() {});
    _syncOverlay();
  }

  Future<void> _showOverlay() async {
    final visible = _timers.where((t) => t.showInOverlay).toList();
    final ok = await FlutterCustomOverlay.showOverlay(
      config: OverlayConfig(
        width: 260,
        height: 300,
        isDraggable: true,
        alignment: OverlayAlignment.topCenter,
      ),
      data: {
        'action': 'state',
        'timers': visible.map((t) => t.toMap()).toList(),
      },
    );
    if (ok) {
      setState(() => _overlayActive = true);
      _syncOverlay();
    }
  }

  void _hideOverlay() async {
    await FlutterCustomOverlay.closeOverlay();
    _updateTimer?.cancel();
    _updateTimer = null;
    setState(() => _overlayActive = false);
  }

  void _addTimer() => _showTimerDialog();

  void _showTimerDialog({TimerItem? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var countUp = existing?.countUp ?? true;
    var hours = existing?.hours ?? 0;
    var minutes = existing?.minutes ?? 1;
    var seconds = existing?.seconds ?? 0;
    var color = existing?.color ?? Colors.indigo;
    var textColor = existing?.textColor ?? Colors.white;
    var opacity = existing?.opacity ?? 0.7;
    var sizeScale = existing?.sizeScale ?? 1.0;
    var alertOnEnd = existing?.alertOnEnd ?? false;
    var showInOverlay = existing?.showInOverlay ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Timer' : 'New Timer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Up')),
                    ButtonSegment(value: false, label: Text('Down')),
                  ],
                  selected: {countUp},
                  onSelectionChanged: (v) => setDialogState(() => countUp = v.first),
                ),
                if (!countUp) ...[
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _DurField('HH', hours, 99, (v) => hours = v),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(':', style: TextStyle(fontSize: 20))),
                    _DurField('MM', minutes, 59, (v) => minutes = v),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text(':', style: TextStyle(fontSize: 20))),
                    _DurField('SS', seconds, 59, (v) => seconds = v),
                  ]),
                ],
                const SizedBox(height: 12),
                const Text('Bubble Color', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                _ColorPicker(selected: color, onChanged: (c) => setDialogState(() => color = c)),
                const SizedBox(height: 8),
                const Text('Text Color', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                _ColorPicker(selected: textColor, onChanged: (c) => setDialogState(() => textColor = c)),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('Opacity', style: TextStyle(fontSize: 12)),
                  Expanded(child: Slider(value: opacity, min: 0.1, max: 1.0, onChanged: (v) => setDialogState(() => opacity = v))),
                  Text('${(opacity * 100).toInt()}%', style: const TextStyle(fontSize: 11)),
                ]),
                Row(children: [
                  const Text('Size', style: TextStyle(fontSize: 12)),
                  Expanded(child: Slider(value: sizeScale, min: 0.5, max: 2.0, onChanged: (v) => setDialogState(() => sizeScale = v))),
                  Text('${(sizeScale * 100).toInt()}%', style: const TextStyle(fontSize: 11)),
                ]),
                SwitchListTile(
                  title: const Text('Alert on End', style: TextStyle(fontSize: 12)),
                  value: alertOnEnd,
                  onChanged: (v) => setDialogState(() => alertOnEnd = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                SwitchListTile(
                  title: const Text('Show in Overlay', style: TextStyle(fontSize: 12)),
                  value: showInOverlay,
                  onChanged: (v) => setDialogState(() => showInOverlay = v),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (isEdit) {
                  existing!.name = nameCtrl.text;
                  existing.countUp = countUp;
                  existing.hours = hours;
                  existing.minutes = minutes;
                  existing.seconds = seconds;
                  existing.color = color;
                  existing.textColor = textColor;
                  existing.opacity = opacity;
                  existing.sizeScale = sizeScale;
                  existing.alertOnEnd = alertOnEnd;
                  existing.showInOverlay = showInOverlay;
                } else {
                  _timers.add(TimerItem(
                    id: 't${_nextId++}',
                    name: nameCtrl.text,
                    countUp: countUp,
                    hours: hours,
                    minutes: minutes,
                    seconds: seconds,
                    color: color,
                    textColor: textColor,
                    opacity: opacity,
                    sizeScale: sizeScale,
                    alertOnEnd: alertOnEnd,
                    showInOverlay: showInOverlay,
                  ));
                }
                Navigator.pop(ctx);
                setState(() {});
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floating Timer'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addTimer),
        ],
      ),
      body: _timers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_off, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No timers yet', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(onPressed: _addTimer, icon: const Icon(Icons.add), label: const Text('Add Timer')),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _timers.length,
                    itemBuilder: (ctx, i) => _TimerTile(
                      timer: _timers[i],
                      onToggle: () => _toggleTimer(_timers[i]),
                      onReset: () => _resetTimer(_timers[i]),
                      onEdit: () => _showTimerDialog(existing: _timers[i]),
                      onRemove: () => _removeTimer(_timers[i]),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _overlayActive ? _hideOverlay : _showOverlay,
                          icon: Icon(_overlayActive ? Icons.visibility_off : Icons.visibility),
                          label: Text(_overlayActive ? 'Hide Overlay' : 'Show Overlay'),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TimerTile extends StatelessWidget {
  final TimerItem timer;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _TimerTile({
    required this.timer,
    required this.onToggle,
    required this.onReset,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: timer.color.withValues(alpha: timer.opacity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (timer.showInOverlay) ...[
                    const Icon(Icons.visibility, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                  ],
                  Text(timer.name, style: TextStyle(color: timer.textColor, fontSize: 12)),
                ]),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove),
            ]),
            const SizedBox(height: 8),
            Center(
              child: Text(
                timer.formattedTime,
                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              FilledButton.icon(
                onPressed: onToggle,
                icon: Icon(timer.running ? Icons.pause : Icons.play_arrow, size: 18),
                label: Text(timer.running ? 'Pause' : 'Start'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: timer.elapsed > 0 ? onReset : null,
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('Reset'),
              ),
            ]),
            const SizedBox(height: 4),
            Center(
              child: Text(
                timer.countUp ? 'Count Up' : 'Count Down',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurField extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChange;

  const _DurField(this.label, this.value, this.max, this.onChange);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: TextField(
        controller: TextEditingController(text: value.toString().padLeft(2, '0')),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          label: Text(label, style: const TextStyle(fontSize: 10)),
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (s) {
          final v = int.tryParse(s) ?? 0;
          onChange(v.clamp(0, max));
        },
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;

  static const _colors = [
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.lime,
    Colors.cyan,
    Colors.deepPurple,
  ];

  const _ColorPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: _colors.map((c) => GestureDetector(
        onTap: () => onChanged(c),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: c == selected ? Border.all(color: Colors.white, width: 3) : null,
          ),
        ),
      )).toList(),
    );
  }
}
