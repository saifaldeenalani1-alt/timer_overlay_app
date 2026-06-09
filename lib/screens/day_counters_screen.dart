import 'dart:async';
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Counter' : 'New Counter'),
          content: Column(
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
                  color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(children: [
                  Text(labelCtrl.text.isEmpty ? 'Countdown' : labelCtrl.text,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_previewDays(targetDate, countUp),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                ]),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (isEdit) {
                  existing!.label = labelCtrl.text;
                  existing.targetDate = targetDate;
                  existing.countUp = countUp;
                } else {
                  _counters.add(DayCounter(
                    id: 'c${_nextId++}',
                    label: labelCtrl.text,
                    targetDate: targetDate,
                    countUp: countUp,
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
      final data = _counters.map((c) => c.toMap()).toList();
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
