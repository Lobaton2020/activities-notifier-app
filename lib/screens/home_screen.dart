import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:activities_notifier_app/models/cron.dart';
import 'package:activities_notifier_app/services/api_service.dart';
import 'package:activities_notifier_app/services/notification_service.dart';
import 'package:activities_notifier_app/widgets/task_card.dart';
import 'package:activities_notifier_app/widgets/side_drawer.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String _logMessage = 'Iniciando...';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _log(String message) {
    setState(() {
      _logMessage = message;
    });
    debugPrint('[HomeScreen] $message');
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _log('Cargando actividades...');
      await ApiService.instance.fetchCrons(limit: 10);
      final cron = ApiService.instance.currentCron;
      if (cron != null) {
        _log('${cron.tasks.length} actividades cargadas');
      } else {
        _log('No hay actividades disponibles');
      }
      _scheduleNotifications();
      _log('Listo');
    } catch (e) {
      _log('Error de conexión');
      setState(() {
        _errorMessage = 'Error al cargar: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scheduleNotifications() {
    final cron = ApiService.instance.currentCron;
    if (cron != null) {
      for (final task in cron.tasks) {
        NotificationService.instance.scheduleTaskNotification(task);
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
        onCronSelected: (cron) async {
          Navigator.pop(context);
          await ApiService.instance.fetchCronById(cron.id);
          _scheduleNotifications();
          setState(() {});
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
          IconButton(
            icon: const Icon(
              Icons.notifications_active,
              color: Color(0xFF00F5D4),
            ),
            onPressed: () => NotificationService.instance.testNotification(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF7B2CBF),
            child: Row(
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(
                    _errorMessage != null ? Icons.error : Icons.check_circle,
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
          ),
          Expanded(child: _buildBody()),
        ],
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
                backgroundColor: const Color(0xFF7B2CBF),
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
                backgroundColor: const Color(0xFF7B2CBF),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF7B2CBF),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(cron)),
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
                    setState(() {});
                  },
                );
              }, childCount: cron.tasks.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Cron cron) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es_ES');
    final parsedDate = DateTime.tryParse(cron.date) ?? DateTime.now();
    final formattedDate = dateFormat.format(parsedDate);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2CBF).withValues(alpha: 0.3),
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
