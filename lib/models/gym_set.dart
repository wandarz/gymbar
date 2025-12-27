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

