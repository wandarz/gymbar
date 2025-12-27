import 'package:flutter/material.dart';
import '../models/gym_set.dart';
import '../services/storage_service.dart';
import 'add_set_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final List<GymSet> _history = [];
  List<String> _customExercises = [];
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadCustomExercises();
  }

  Future<void> _loadHistory() async {
    final loaded = await _storageService.loadHistory();
    setState(() {
      _history..clear()..addAll(loaded);
    });
  }

  Future<void> _saveHistory() async {
    await _storageService.saveHistory(_history);
  }

  Future<void> _loadCustomExercises() async {
    final loaded = await _storageService.loadCustomExercises();
    setState(() {
      _customExercises = loaded;
    });
  }

  Future<void> _saveCustomExercises(List<String> list) async {
    await _storageService.saveCustomExercises(list);
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

