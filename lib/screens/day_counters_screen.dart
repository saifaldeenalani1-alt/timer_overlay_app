import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/day_counter.dart';

const _widgetChannel = MethodChannel('com.timer.timer_overlay_app/widget');

class DayCountersScreen extends StatefulWidget {
  const DayCountersScreen({super.key});

  @override
  State<DayCountersScreen> createState() => _DayCountersScreenState();
}

class _DayCountersScreenState extends State<DayCountersScreen> {
  final List<DayCounter> _counters = [];
  int _nextId = 1;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _add() => _showDialog();

  void _edit(DayCounter c) => _showDialog(existing: c);

  void _remove(DayCounter c) {
    setState(() => _counters.remove(c));
    _updateWidget();
  }

  void _showDialog({DayCounter? existing}) {
    final isEdit = existing != null;
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    var targetDate = existing?.targetDate ?? DateTime.now().add(const Duration(days: 30));
    var countUp = existing?.countUp ?? false;
    var bgColor = existing?.bgColor ?? const Color(0xFF1C1C1E);
    var textColor = existing?.textColor ?? Colors.white;
    var opacity = existing?.opacity ?? 1.0;
    var fontSize = existing?.fontSize ?? 28.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Counter' : 'New Counter'),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Text('Target Date: '),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: targetDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => targetDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Count Down')),
                  ButtonSegment(value: true, label: Text('Count Up')),
                ],
                selected: {countUp},
                onSelectionChanged: (v) => setDialogState(() => countUp = v.first),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: [
                  Text(labelCtrl.text.isEmpty ? 'Countdown' : labelCtrl.text,
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(_previewDays(targetDate, countUp),
                      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900, fontFamily: 'monospace', color: textColor)),
                ]),
              ),
              const SizedBox(height: 12),
              const Text('\u0627\u0644\u0644\u0648\u0646 \u0627\u0644\u062E\u0644\u0641\u064A', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              _DayColorPicker(selected: bgColor, onChanged: (c) => setDialogState(() => bgColor = c)),
              const SizedBox(height: 8),
              const Text('\u0644\u0648\u0646 \u0627\u0644\u0646\u0635', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              _DayColorPicker(selected: textColor, onChanged: (c) => setDialogState(() => textColor = c)),
              const SizedBox(height: 8),
              Row(children: [
                const Text('\u0627\u0644\u0634\u0641\u0627\u0641\u064A\u0629', style: TextStyle(fontSize: 12)),
                Expanded(child: Slider(value: opacity, min: 0.1, max: 1.0, onChanged: (v) => setDialogState(() => opacity = v))),
                Text('${(opacity * 100).toInt()}%', style: const TextStyle(fontSize: 11)),
              ]),
              Row(children: [
                const Text('\u062D\u062C\u0645 \u0627\u0644\u062E\u0637', style: TextStyle(fontSize: 12)),
                Expanded(child: Slider(value: fontSize, min: 12, max: 72, onChanged: (v) => setDialogState(() => fontSize = v))),
                Text('${fontSize.toInt()}', style: const TextStyle(fontSize: 11)),
              ]),
            ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (isEdit) {
                  existing!.label = labelCtrl.text;
                  existing.targetDate = targetDate;
                  existing.countUp = countUp;
                  existing.bgColor = bgColor;
                  existing.textColor = textColor;
                  existing.opacity = opacity;
                  existing.fontSize = fontSize;
                } else {
                  _counters.add(DayCounter(
                    id: 'c${_nextId++}',
                    label: labelCtrl.text,
                    targetDate: targetDate,
                    countUp: countUp,
                    bgColor: bgColor,
                    textColor: textColor,
                    opacity: opacity,
                    fontSize: fontSize,
                  ));
                }
                Navigator.pop(ctx);
                setState(() {});
                _updateWidget();
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _previewDays(DateTime date, bool up) {
    final d = DayCounter(id: '', targetDate: date, countUp: up);
    return d.displayText;
  }

  Future<void> _updateWidget() async {
    try {
      final data = jsonEncode(_counters.map((c) => c.toMap()).toList());
      await _widgetChannel.invokeMethod('updateDayCounterWidget', {'counters': data});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day Counters'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _add),
        ],
      ),
      body: _counters.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_note, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('No day counters yet', style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  )),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add Counter')),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'After adding a counter, add the widget to your home screen:\n'
                      'Long-press home screen → Widgets → Day Counter Widget',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _counters.length,
              itemBuilder: (ctx, i) {
                final c = _counters[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(c.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c.targetDate.toString().split(' ')[0]),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(c.displayText, style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'monospace',
                      )),
                      IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _remove(c)),
                    ]),
                    onTap: () => _edit(c),
                  ),
                );
              },
            ),
    );
  }
}

class _DayColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;

  static const _colors = [
    Color(0xFF1C1C1E),
    Colors.white,
    Colors.black,
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

  const _DayColorPicker({required this.selected, required this.onChanged});

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
            border: c == selected
                ? Border.all(color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white, width: 3)
                : (c.computeLuminance() > 0.5 ? Border.all(color: Colors.grey.shade400, width: 1) : null),
          ),
        ),
      )).toList(),
    );
  }
}
