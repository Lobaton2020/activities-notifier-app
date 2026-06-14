class Project {
  final String id;
  final String name;

  Project({required this.id, required this.name});

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(id: json['id'] ?? '', name: json['name'] ?? '');
  }
}

class TaskModel {
  final String id;
  final String description;
  final bool state;
  final int hour;
  final int minute;
  final Project? project;
  final String cronDate;

  TaskModel({
    required this.id,
    required this.description,
    required this.state,
    required this.hour,
    required this.minute,
    this.project,
    this.cronDate = '',
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final stateValue = json['state'];
    final isCompleted =
        stateValue == true || stateValue == 'completed' || stateValue == 'true';
    return TaskModel(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      state: isCompleted,
      hour: json['hour'] ?? 0,
      minute: json['minute'] ?? 0,
      project: json['project'] != null
          ? Project.fromJson(json['project'])
          : null,
    );
  }

  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime get scheduledDateTime {
    if (cronDate.isNotEmpty) {
      final parsed = DateTime.tryParse(cronDate);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day, hour, minute);
      }
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  bool get isPast => scheduledDateTime.isBefore(DateTime.now());
}
