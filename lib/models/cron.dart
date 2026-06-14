import 'package:lobmindergo/models/task_model.dart';

class Cron {
  final String id;
  final String name;
  final String date;
  final List<TaskModel> tasks;

  Cron({
    required this.id,
    required this.name,
    required this.date,
    required this.tasks,
  });

  factory Cron.fromJson(Map<String, dynamic> json) {
    final tasksJson = json['tasks'] as List? ?? [];
    final cronDate = json['date'] ?? '';
    return Cron(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      date: cronDate,
      tasks:
          tasksJson.map((task) {
            final taskModel = TaskModel.fromJson(task);
            return TaskModel(
              id: taskModel.id,
              description: taskModel.description,
              state: taskModel.state,
              hour: taskModel.hour,
              minute: taskModel.minute,
              project: taskModel.project,
              cronDate: cronDate,
            );
          }).toList()..sort((a, b) {
            final aTime = a.hour * 60 + a.minute;
            final bTime = b.hour * 60 + b.minute;
            return aTime.compareTo(bTime);
          }),
    );
  }

  List<TaskModel> get pendingTasks =>
      tasks.where((task) => !task.state).toList();
  List<TaskModel> get completedTasks =>
      tasks.where((task) => task.state).toList();
  int get totalTasks => tasks.length;
  int get completedCount => completedTasks.length;
  double get progress => totalTasks > 0 ? completedCount / totalTasks : 0.0;
}
