import 'package:flutter/material.dart';
import 'package:activities_notifier_app/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Function(bool) onStateChanged;

  const TaskCard({super.key, required this.task, required this.onStateChanged});

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.state;
    final isPast = task.isPast && !isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF00F5D4).withValues(alpha: 0.3)
              : const Color(0xFF7B2CBF).withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isCompleted
                        ? const Color(0xFF00F5D4)
                        : const Color(0xFF7B2CBF))
                    .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onStateChanged(!task.state),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildCheckbox(isCompleted),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.description,
                        style: TextStyle(
                          color: isCompleted ? Colors.grey[500] : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (task.project != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7B2CBF,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.project!.name,
                                style: const TextStyle(
                                  color: Color(0xFF9D4EDD),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (isPast)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ATRASADA',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildTime(isCompleted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool isCompleted) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF00F5D4) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF00F5D4)
              : const Color(0xFF7B2CBF),
          width: 2,
        ),
      ),
      child: isCompleted
          ? const Icon(Icons.check, color: Color(0xFF0D0D0D), size: 18)
          : null,
    );
  }

  Widget _buildTime(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFF00F5D4).withValues(alpha: 0.1)
            : const Color(0xFF7B2CBF).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        task.formattedTime,
        style: TextStyle(
          color: isCompleted ? const Color(0xFF00F5D4) : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
