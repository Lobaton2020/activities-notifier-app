import 'package:flutter/material.dart';
import 'package:activities_notifier_app/models/cron.dart';
import 'package:activities_notifier_app/services/api_service.dart';
import 'package:activities_notifier_app/screens/settings_screen.dart';
import 'package:intl/intl.dart';

class SideDrawer extends StatelessWidget {
  final Function(Cron) onCronSelected;

  const SideDrawer({super.key, required this.onCronSelected});

  @override
  Widget build(BuildContext context) {
    final crons = ApiService.instance.cronList;

    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const Divider(color: Color(0xFF7B2CBF), height: 1),
            Expanded(
              child: crons.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: crons.length,
                      itemBuilder: (context, index) =>
                          _buildCronTile(crons[index], context),
                    ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7B2CBF), Color(0xFF00F5D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.checklist_rtl,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cronogramas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Últimos 10 registros',
                  style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCronTile(Cron cron, BuildContext context) {
    final isSelected = cron.id == ApiService.instance.currentCron?.id;
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
    final parsedDate = DateTime.tryParse(cron.date) ?? DateTime.now();
    final formattedDate = dateFormat.format(parsedDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF7B2CBF).withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF7B2CBF) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: () => onCronSelected(cron),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00F5D4)
                : const Color(0xFF7B2CBF).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            cron.progress == 1.0 ? Icons.check_circle : Icons.calendar_today,
            color: isSelected
                ? const Color(0xFF0D0D0D)
                : const Color(0xFF00F5D4),
            size: 20,
          ),
        ),
        title: Text(
          cron.name,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00F5D4) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          formattedDate,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${cron.completedCount}/${cron.totalTasks}',
              style: TextStyle(
                color: cron.progress == 1.0
                    ? const Color(0xFF00F5D4)
                    : Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Color(0xFF7B2CBF)),
          SizedBox(height: 16),
          Text(
            'No hay cronogramas',
            style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, color: Color(0xFF7B2CBF), size: 20),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: const Text(
              'Configuración',
              style: TextStyle(color: Color(0xFF00F5D4)),
            ),
          ),
        ],
      ),
    );
  }
}
