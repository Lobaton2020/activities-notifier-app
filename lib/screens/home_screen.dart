import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lobmindergo/models/cron.dart';
import 'package:lobmindergo/models/task_model.dart';
import 'package:lobmindergo/services/api_service.dart';
import 'package:lobmindergo/services/notification_service.dart';
import 'package:lobmindergo/widgets/task_card.dart';
import 'package:lobmindergo/widgets/side_drawer.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _logMessage = 'Iniciando...';
  String? _errorMessage;
  bool _isCreatingTask = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _loadData();
    _fadeController.forward();

    _startHourlyCheck();
  }

  void _startHourlyCheck() {
    Future.delayed(const Duration(hours: 1), () {
      if (mounted) {
        _checkTodayTasks();
        _startHourlyCheck();
      }
    });
  }

  Future<void> _checkTodayTasks() async {
    print('=== Hourly check: Looking for today tasks ===');
    await ApiService.instance.fetchCrons(limit: 20);
    final today = DateTime.now();
    final cronList = ApiService.instance.cronList;
    print('Today: $today');
    print('Available crons: ${cronList.length}');

    Cron? todayCron;
    for (final cron in cronList) {
      final cronDate = DateTime.tryParse(cron.date);
      print('Checking cron: ${cron.name} - date: ${cron.date}');
      if (cronDate != null &&
          cronDate.year == today.year &&
          cronDate.month == today.month &&
          cronDate.day == today.day) {
        todayCron = cron;
        print('Found today cron: ${cron.name}');
        break;
      }
    }

    if (todayCron != null) {
      await ApiService.instance.fetchCronById(todayCron.id);
      _scheduleNotifications();
    } else {
      print('No cron found for today');
    }
    print('==========================================');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _logMessage = message;
    });
    debugPrint('[HomeScreen] $message');
    if (message == 'Listo') {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _logMessage = '';
          });
        }
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _errorMessage = null;
    });
    try {
      _log('Cargando...');
      await ApiService.instance.fetchCrons(limit: 10);
      final cron = ApiService.instance.currentCron;
      if (cron != null) {
        _log(cron.name);
        _fadeController.forward();
        await ApiService.instance.fetchCronById(cron.id);
        _scheduleNotifications();
        _log(
          '${ApiService.instance.currentCron?.tasks.length ?? 0} actividades',
        );
      } else {
        _log('Sin cronogramas');
      }
    } catch (e) {
      final msg = e.toString();
      _log(msg.contains('GraphQL') ? msg : 'Error de conexión');
      setState(() {
        _errorMessage = msg;
      });
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _logMessage = '');
        }
      });
    }
  }

  void _scheduleNotifications() {
    final cron = ApiService.instance.currentCron;
    if (cron != null) {
      final now = DateTime.now();
      print('=== Scheduling notifications for ${cron.name} ===');
      print('Current time: $now');
      int count = 0;
      for (final task in cron.tasks) {
        if (!task.state && task.scheduledDateTime.isAfter(now)) {
          print(
            'Scheduling: ${task.description} at ${task.formattedTime} (${task.scheduledDateTime}) - Project: ${task.project?.name ?? "Sin proyecto"}',
          );
          NotificationService.instance.scheduleTaskNotification(task);
          count++;
        } else if (task.state) {
          print('Skipping (completed): ${task.description}');
        } else if (!task.scheduledDateTime.isAfter(now)) {
          print(
            'Skipping (past): ${task.description} at ${task.formattedTime}',
          );
        }
      }
      print('Total scheduled: $count notifications');
      print('==========================================');
      if (count > 0) {
        final tasksInfo = cron.tasks
            .where((t) => !t.state && t.scheduledDateTime.isAfter(now))
            .map(
              (t) =>
                  '${t.formattedTime} - ${t.project?.name ?? "Sin proyecto"}',
            )
            .join(', ');
        _log('$count notificaciones: $tasksInfo');
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SideDrawer(
        isLoading: _isLoading,
        onCronSelected: (cron) async {
          Navigator.pop(context);
          _log(cron.name);
          _fadeController.forward();
          await Future.delayed(const Duration(milliseconds: 400));
          await ApiService.instance.fetchCronById(cron.id);
          _scheduleNotifications();
          setState(() {});
          _fadeController.forward();
        },
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF00F5D4)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00F5D4)),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _logMessage.isNotEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: const Color(0xFF2196F3),
                    child: Row(
                      children: [
                        Icon(
                          _errorMessage != null
                              ? Icons.error
                              : Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _logMessage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: FadeTransition(opacity: _fadeAnimation, child: _buildBody()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          semanticLabel: 'Añadir tarea',
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    _isCreatingTask = false;
    final descController = TextEditingController();
    final hourController = TextEditingController();
    final minuteController = TextEditingController();
    final defaultProject = ApiService.instance.projects.firstWhere(
      (p) => p['name'] == 'Default',
      orElse: () => ApiService.instance.projects.isNotEmpty
          ? ApiService.instance.projects.first
          : {},
    );
    Map<String, dynamic>? selectedProject = defaultProject.isNotEmpty
        ? defaultProject
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              'Nueva Tarea',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hourController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: minuteController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minuto',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButton<Map<String, dynamic>>(
                  value: selectedProject,
                  dropdownColor: const Color(0xFF1A1A2E),
                  hint: const Text(
                    'Seleccionar Proyecto',
                    style: TextStyle(color: Colors.grey),
                  ),
                  isExpanded: true,
                  items: ApiService.instance.projects.map((project) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: project,
                      child: Text(
                        project['name'] ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProject = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (descController.text.isEmpty || selectedProject == null) {
                    return;
                  }
                  setDialogState(() => _isCreatingTask = true);
                  final hour = int.tryParse(hourController.text) ?? 0;
                  final minute = int.tryParse(minuteController.text) ?? 0;
                  try {
                    final success = await ApiService.instance.createTask(
                      ApiService.instance.currentCron!.id,
                      descController.text,
                      hour,
                      minute,
                      selectedProject!,
                    );
                    if (success) {
                      Navigator.pop(dialogContext);
                      await ApiService.instance.fetchCronById(
                        ApiService.instance.currentCron!.id,
                      );
                      setState(() {});
                      _fadeController.reset();
                      _fadeController.forward();
                      final newTask = ApiService.instance.currentCron?.tasks
                          .where((t) => t.description == descController.text)
                          .firstOrNull;
                      if (newTask != null) {
                        await NotificationService.instance
                            .scheduleTaskNotification(newTask);
                      }
                      _log('Tarea creada: ${descController.text}');
                    } else {
                      _log('Error al crear tarea');
                      setDialogState(() => _isCreatingTask = false);
                    }
                  } catch (e) {
                    _log('Error: $e');
                    setDialogState(() => _isCreatingTask = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
                child: _isCreatingTask
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Enviar',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTaskDialog(TaskModel task) {
    final descController = TextEditingController(text: task.description);
    final hourController = TextEditingController(
      text: task.hour.toString().padLeft(2, '0'),
    );
    final minuteController = TextEditingController(
      text: task.minute.toString().padLeft(2, '0'),
    );
    Map<String, dynamic>? selectedProject;
    if (task.project != null) {
      for (var p in ApiService.instance.projects) {
        if (p['id'] == task.project!.id) {
          selectedProject = p;
          break;
        }
      }
    }
    bool isEditing = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              'Editar Tarea',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: hourController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: minuteController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minuto',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButton<Map<String, dynamic>>(
                  value: selectedProject,
                  dropdownColor: const Color(0xFF1A1A2E),
                  hint: const Text(
                    'Seleccionar Proyecto',
                    style: TextStyle(color: Colors.grey),
                  ),
                  isExpanded: true,
                  items: ApiService.instance.projects.map((project) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: project,
                      child: Text(
                        project['name'] ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProject = value;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: isEditing
                    ? null
                    : () async {
                        if (descController.text.isEmpty ||
                            selectedProject == null)
                          return;
                        setDialogState(() => isEditing = true);
                        final hour = int.tryParse(hourController.text) ?? 0;
                        final minute = int.tryParse(minuteController.text) ?? 0;
                        try {
                          final success = await ApiService.instance.editTask(
                            task.id,
                            descController.text,
                            hour,
                            minute,
                            selectedProject!,
                          );
                          if (success) {
                            Navigator.pop(dialogContext);
                            await ApiService.instance.fetchCronById(
                              ApiService.instance.currentCron!.id,
                            );
                            await NotificationService.instance
                                .cancelTaskNotification(task.id);
                            _scheduleNotifications();
                            setState(() {});
                            _fadeController.reset();
                            _fadeController.forward();
                            _log('Tarea actualizada');
                          } else {
                            _log('Error al actualizar');
                            setDialogState(() => isEditing = false);
                          }
                        } catch (e) {
                          _log('Error: $e');
                          setDialogState(() => isEditing = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
                child: isEditing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final cron = ApiService.instance.currentCron;
    if (cron == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No hay cronogramas',
              style: TextStyle(color: Colors.grey[500], fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF2196F3),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(cron)),
          if (cron.tasks.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2196F3)),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final task = cron.tasks[index];
                  return TaskCard(
                    task: task,
                    onStateChanged: (newState) async {
                      await ApiService.instance.updateTaskState(
                        task.id,
                        newState,
                      );
                      await ApiService.instance.fetchCronById(cron.id);
                      await NotificationService.instance.cancelTaskNotification(
                        task.id,
                      );
                      _scheduleNotifications();
                      setState(() {});
                    },
                    onDelete: () async {
                      await NotificationService.instance.cancelTaskNotification(
                        task.id,
                      );
                      await ApiService.instance.deleteTask(task.id);
                      await ApiService.instance.fetchCronById(cron.id);
                      _scheduleNotifications();
                      setState(() {});
                      _fadeController.reset();
                      _fadeController.forward();
                    },
                    onEdit: () => _showEditTaskDialog(task),
                  );
                }, childCount: cron.tasks.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(Cron cron) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');
    final parsedDate = DateTime.tryParse(cron.date) ?? DateTime.now();
    final formattedDate = dateFormat.format(parsedDate);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF9D4EDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cron.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip(
                icon: Icons.check_circle_outline,
                label: '${cron.completedCount}/${cron.totalTasks}',
                isCompleted: true,
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.pending_actions,
                label: '${cron.pendingTasks.length} pendientes',
                isCompleted: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: cron.progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00F5D4),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isCompleted ? const Color(0xFF00F5D4) : Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
