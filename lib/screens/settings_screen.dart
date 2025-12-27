import 'package:flutter/material.dart';
import '../data/exercise_groups.dart';

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

