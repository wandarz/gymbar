import 'package:flutter/material.dart';
import '../models/gym_set.dart';
import '../data/exercise_groups.dart';

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

