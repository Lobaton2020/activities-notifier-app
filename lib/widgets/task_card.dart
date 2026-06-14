import 'package:flutter/material.dart';
import 'package:lobmindergo/models/task_model.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final Function(bool) onStateChanged;
  final Function()? onDelete;
  final Function()? onEdit;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStateChanged,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _isLoading = false;

  Future<void> _toggleComplete() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final newState = !widget.task.state;
    await widget.onStateChanged(newState);
    if (mounted) setState(() => _isLoading = false);
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Eliminar Tarea',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Eliminar "${widget.task.description}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onDelete?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(bool isCompleted) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? const Color(0xFF00F5D4) : Colors.transparent,
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF00F5D4)
              : const Color(0xFF2196F3),
          width: 2,
        ),
      ),
      child: isCompleted
          ? const Icon(Icons.check, size: 16, color: Color(0xFF1A1A2E))
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.task.state;
    final isPast = widget.task.isPast && !isCompleted;

    Widget cardContent = Opacity(
      opacity: _isLoading ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF00F5D4).withValues(alpha: 0.3)
                : const Color(0xFF2196F3).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _toggleComplete,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildCheckbox(isCompleted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.description,
                          style: TextStyle(
                            color: isCompleted
                                ? Colors.grey[500]
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.task.formattedTime,
                          style: TextStyle(
                            color: isPast
                                ? Colors.red[400]
                                : const Color(0xFF2196F3),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  if (widget.task.project != null && !_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.task.project!.name,
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.onEdit != null || widget.onDelete != null) {
      return Dismissible(
        key: Key(widget.task.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            widget.onEdit!();
          } else if (direction == DismissDirection.endToStart) {
            _showDeleteDialog();
          }
          return false;
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 20),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        secondaryBackground: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: cardContent,
      );
    }
    return cardContent;
  }
}
