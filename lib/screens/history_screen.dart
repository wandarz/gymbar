import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import '../models/gym_set.dart';

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

