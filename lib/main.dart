
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';

void main() {
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Logger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MainMenuScreen(),
    );
  }
}

// =====================================================
// Model: GymSet with JSON serialization + date formatter
// =====================================================
class GymSet {
  final String exercise;
  final double weightKg;
  final int reps;
  final DateTime dateTime;
  final String? notes;

  GymSet({
    required this.exercise,
    required this.weightKg,
    required this.reps,
    required this.dateTime,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'exercise': exercise,
    'weightKg': weightKg,
    'reps': reps,
    'dateTime': dateTime.toIso8601String(),
    'notes': notes,
  };

  factory GymSet.fromJson(Map<String, dynamic> json) => GymSet(
    exercise: json['exercise'] as String,
    weightKg: (json['weightKg'] as num).toDouble(),
    reps: json['reps'] as int,
    dateTime: DateTime.parse(json['dateTime'] as String),
    notes: (json['notes'] as String?)?.trim(),
  );

  static String formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final yyyy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$mi';
  }

  static String formatDate(DateTime dt) {
    final local = dt.toLocal();
    final yyyy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  static String formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$hh:$mi';
  }

  @override
  String toString() => '$exercise — ${weightKg} kg × $reps';
}

// ======================================
// Built-in Exercise groups (headers -> exercises)
// ======================================
const Map<String, List<String>> kExerciseGroups = {
  'Pecs': ['Bench Press', 'Incline Bench Press', 'Dumbbell Fly', 'Cable Crossover'],
  'Back': ['Deadlift', 'Barbell Row', 'Pull-up', 'Lat Pulldown'],
  'Shoulders': ['Overhead Press', 'Dumbbell Shoulder Press', 'Lateral Raise', 'Rear Delt Fly'],
  'Legs': ['Squat', 'Front Squat', 'Romanian Deadlift', 'Leg Press', 'Lunge'],
  'Arms': ['Bicep Curl', 'Hammer Curl', 'Triceps Pushdown', 'Skull Crushers'],
  'Abs': ['Crunches', 'Plank', 'Hanging Leg Raise', 'Cable Crunch'],
  'Glutes': ['Hip Thrust', 'Glute Bridge'],
  'Calves': ['Standing Calf Raise', 'Seated Calf Raise'],
};

// ======================================
// Main Menu: Add Set + History + Settings
// ======================================
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final List<GymSet> _history = [];
  List<String> _customExercises = [];
  static const _historyKey = 'history';
  static const _customExercisesKey = 'custom_exercises';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadCustomExercises();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString == null) return;

    try {
      final decoded = json.decode(jsonString) as List<dynamic>;
      final loaded = decoded.map((e) => GymSet.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _history..clear()..addAll(loaded);
      });
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _history.map((s) => s.toJson()).toList();
    final jsonString = json.encode(data);
    await prefs.setString(_historyKey, jsonString);
  }

  Future<void> _loadCustomExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_customExercisesKey);
    if (jsonString == null) return;
    try {
      final decoded = json.decode(jsonString) as List<dynamic>;
      final loaded = decoded.map((e) => e.toString()).toList();
      setState(() {
        _customExercises = loaded;
      });
    } catch (e) {
      debugPrint('Failed to load custom exercises: $e');
    }
  }

  Future<void> _saveCustomExercises(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customExercisesKey, json.encode(list));
  }

  Future<void> _openAddSet() async {
    final result = await Navigator.push<List<GymSet>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddSetScreen(customExercises: _customExercises),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _history.addAll(result));
      await _saveHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${result.length} set${result.length > 1 ? 's' : ''}')),
        );
      }
    }
  }

  Future<void> _deleteSet(GymSet target) async {
    final idx = _history.indexWhere((s) =>
    s.exercise == target.exercise &&
        s.weightKg == target.weightKg &&
        s.reps == target.reps &&
        s.dateTime.isAtSameMomentAs(target.dateTime) &&
        (s.notes ?? '') == (target.notes ?? '')
    );
    if (idx != -1) {
      setState(() => _history.removeAt(idx));
      await _saveHistory();
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(history: _history, onDelete: _deleteSet),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          customExercises: _customExercises,
          onSave: (list) async {
            setState(() => _customExercises = list);
            await _saveCustomExercises(list);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom exercises saved')),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = Colors.blueGrey.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('gymbar'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120, height: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _openAddSet,
                child: const Text('Add Set', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 120, height: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _openHistory,
                child: const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================
// Settings Screen: manage custom exercise names
// - Add new custom exercise
// - Delete existing custom exercise
// - Persist via onSave callback
// ======================================
class SettingsScreen extends StatefulWidget {
  final List<String> customExercises;
  final Future<void> Function(List<String>) onSave;

  const SettingsScreen({
    super.key,
    required this.customExercises,
    required this.onSave,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late List<String> _items;
  final TextEditingController _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = widget.customExercises.toList();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  bool _containsCaseInsensitive(String value) {
    final v = value.trim().toLowerCase();
    return _items.any((e) => e.trim().toLowerCase() == v) ||
        // Also avoid duplicating built-ins
        kExerciseGroups.values.expand((x) => x).any((e) => e.trim().toLowerCase() == v);
  }

  void _addItem() {
    final v = _addController.text.trim();
    if (v.isEmpty) return;
    if (_containsCaseInsensitive(v)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise already exists')),
      );
      return;
    }
    setState(() {
      _items.add(v);
    });
    _addController.clear();
  }

  void _deleteItem(String value) {
    setState(() {
      _items.removeWhere((e) => e == value);
    });
  }

  Future<void> _save() async {
    await widget.onSave(_items);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Manage Custom Exercises',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addController,
                  decoration: const InputDecoration(
                    labelText: 'New exercise name',
                    hintText: 'e.g. Bulgarian Split Squat',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                onPressed: _addItem,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_items.isEmpty)
            const Text('No custom exercises yet', style: TextStyle(color: Colors.grey))
          else
            ..._items.map((e) => Card(
              child: ListTile(
                title: Text(e),
                trailing: IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteItem(e),
                ),
              ),
            )),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Built-in Exercise Groups (read-only)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...kExerciseGroups.entries.map(
                (group) => ExpansionTile(
              title: Text(group.key, style: const TextStyle(color: Colors.grey)),
              children: group.value
                  .map((name) => ListTile(
                dense: true,
                leading: const Icon(Icons.chevron_right, size: 18),
                title: Text(name),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================
// Add Set Screen: grouped exercise picker + notes + multiple sets
// ======================================
class AddSetScreen extends StatefulWidget {
  final List<String> customExercises;

  const AddSetScreen({super.key, required this.customExercises});

  @override
  State<AddSetScreen> createState() => _AddSetScreenState();
}

class _AddSetScreenState extends State<AddSetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _exerciseController = TextEditingController(); // read-only field
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _notesController = TextEditingController();
  final _setsController = TextEditingController(); // multiple sets

  bool _showNotes = false;
  bool _showSets = false;
  String? _selectedExercise;

  @override
  void dispose() {
    _exerciseController.dispose();
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    _setsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final exercise = _selectedExercise!.trim();
    final weight = double.parse(_weightController.text.trim());
    final reps = int.parse(_repsController.text.trim());
    final noteText = _showNotes ? _notesController.text.trim() : '';
    final note = noteText.isEmpty ? null : noteText;

    final setsCount = _showSets
        ? (int.tryParse(_setsController.text.trim()) ?? 1)
        : 1;

    final base = DateTime.now();
    final result = <GymSet>[];
    for (int i = 0; i < setsCount; i++) {
      result.add(GymSet(
        exercise: exercise,
        weightKg: weight,
        reps: reps,
        dateTime: base.add(Duration(seconds: i)), // unique timestamps
        notes: note,
      ));
    }

    Navigator.pop(context, result);
  }

  Future<void> _openExercisePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const Text('Select Exercise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                // Custom group first (if any)
                if (widget.customExercises.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 6),
                    child: Text('Custom',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      children: [
                        for (final ex in widget.customExercises)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.chevron_right, size: 20),
                            title: Text(ex),
                            onTap: () => Navigator.pop(context, ex),
                          ),
                      ],
                    ),
                  ),
                ],

                // Built-in groups
                for (final entry in kExerciseGroups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 6),
                    child: Text(entry.key,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      children: [
                        for (final ex in entry.value)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.chevron_right, size: 20),
                            title: Text(ex),
                            onTap: () => Navigator.pop(context, ex),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _selectedExercise = selected;
        _exerciseController.text = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Set')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Exercise (read-only field opens grouped picker)
                          TextFormField(
                            controller: _exerciseController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Exercise',
                              hintText: 'Tap to choose',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            onTap: _openExercisePicker,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Select an exercise' : null,
                          ),
                          const SizedBox(height: 16),

                          // Weight & Reps row with smaller widths
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 140,
                                child: TextFormField(
                                  controller: _weightController,
                                  decoration: const InputDecoration(
                                    labelText: 'Weight (kg)',
                                    hintText: 'e.g. 100',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textInputAction: TextInputAction.next,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final n = double.tryParse(v.trim());
                                    if (n == null || n < 0) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 120,
                                child: TextFormField(
                                  controller: _repsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Reps',
                                    hintText: 'e.g. 5',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final n = int.tryParse(v.trim());
                                    if (n == null || n <= 0 || n > 100) return '1–100';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Optional Notes (revealed by small "Add note" button)
                          if (_showNotes) ...[
                            TextFormField(
                              controller: _notesController,
                              minLines: 2,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Notes (optional)',
                                hintText: 'Anything you want to remember',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Optional Sets (revealed by small "Multiple sets" button)
                          if (_showSets) ...[
                            TextFormField(
                              controller: _setsController,
                              decoration: const InputDecoration(
                                labelText: 'Sets',
                                hintText: 'e.g. 3',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (!_showSets) return null;
                                if (v == null || v.trim().isEmpty) return 'Required';
                                final n = int.tryParse(v.trim());
                                if (n == null || n <= 0 || n > 100) return '1–100';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _save,
                                  child: const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Small buttons row: Add note + Multiple sets
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.note_add_outlined, size: 18),
                                label: Text(
                                  _showNotes ? 'Add note (added)' : 'Add note',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                onPressed: _showNotes ? null : () => setState(() => _showNotes = true),
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                icon: const Icon(Icons.format_list_numbered, size: 18),
                                label: Text(
                                  _showSets ? 'Multiple sets (added)' : 'Multiple sets',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                onPressed: _showSets ? null : () => setState(() => _showSets = true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =====================
// History List Screen
// - Sorted newest first
// - Tap to view details + delete
// - Export CSV: first save, then suggest share
// =====================
class HistoryScreen extends StatefulWidget {
  final List<GymSet> history;
  final Future<void> Function(GymSet) onDelete; // async callback
  const HistoryScreen({
    super.key,
    required this.history,
    required this.onDelete,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late List<GymSet> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.history.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // newest first
  }

  String _csvEscape(String? s) {
    final v = (s ?? '');
    final needsQuote = v.contains('"') || v.contains(',') || v.contains('\n') || v.contains('\r');
    if (!needsQuote) return v;
    return '"${v.replaceAll('"', '""')}"';
  }

  Future<void> _exportCsvSaveThenSuggestShare() async {
    // 1) Build CSV content
    final rows = <List<String>>[
      ['date', 'time', 'exercise', 'weight', 'reps', 'note'],
      for (final s in widget.history)
        [
          GymSet.formatDate(s.dateTime),
          GymSet.formatTime(s.dateTime),
          s.exercise,
          s.weightKg.toString(),
          s.reps.toString(),
          s.notes ?? '',
        ],
    ];
    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(row.map(_csvEscape).join(','));
    }
    final csv = buffer.toString();
    final bytes = utf8.encode(csv);

    // 2) Timestamped file name
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'gym_history_$stamp';

    // 3) Save to device (Downloads on Android / Files on iOS)
    String? savedPath;
    try {
      savedPath = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.other, // text/csv
      );
    } catch (e) {
      // Fallback: app documents
      final dir = await getApplicationDocumentsDirectory();
      final fallback = File('${dir.path}/$fileName.csv');
      await fallback.writeAsBytes(bytes);
      savedPath = fallback.path;
    }

    // 4) Inform + suggest share
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported to: ${savedPath ?? "file"}'),
        action: SnackBarAction(
          label: 'SHARE',
          onPressed: () async {
            try {
              if (savedPath != null) {
                await Share.shareXFiles([XFile(savedPath)],
                    text: 'Gym history (CSV export)', subject: 'Gym history export');
              } else {
                await Share.share(csv, subject: 'Gym history export');
              }
            } catch (_) {}
          },
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _showDetails(GymSet set) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(set.exercise, style: const TextStyle(fontSize: 18)),
                subtitle: Text(GymSet.formatDateTime(set.dateTime)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text('Weight', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 6),
                            Text('${set.weightKg} kg',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text('Reps', style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 6),
                            Text('${set.reps}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Notes only in details sheet
              if ((set.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(set.notes!, style: const TextStyle(fontSize: 15))),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    setState(() {
                      _items.removeWhere((s) =>
                      s.exercise == set.exercise &&
                          s.weightKg == set.weightKg &&
                          s.reps == set.reps &&
                          s.dateTime.isAtSameMomentAs(set.dateTime) &&
                          (s.notes ?? '') == (set.notes ?? '')
                      );
                    });
                    await widget.onDelete(set);
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Deleted')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.file_download),
            onPressed: _exportCsvSaveThenSuggestShare,
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text('No sets yet'))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final set = items[i];
          return ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text('${set.exercise} — ${set.weightKg} kg × ${set.reps}'),
            subtitle: Text('Logged at ${GymSet.formatDateTime(set.dateTime)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showDetails(set),
          );
        },
      ),
    );
  }
}
