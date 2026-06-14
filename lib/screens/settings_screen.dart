import 'package:flutter/material.dart';
import 'package:lobmindergo/services/notification_service.dart';
import 'package:lobmindergo/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final notificationService = NotificationService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00F5D4)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Notificaciones'),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: 'Vibración',
            subtitle: 'Vibrar al recibir notificación',
            value: notificationService.vibrationEnabled,
            onChanged: (value) {
              notificationService.setVibrationEnabled(value);
              setState(() {});
            },
          ),
          _buildSwitchTile(
            icon: Icons.volume_up,
            title: 'Sonido',
            subtitle: 'Reproducir sonido de alerta',
            value: notificationService.soundEnabled,
            onChanged: (value) {
              notificationService.setSoundEnabled(value);
              setState(() {});
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Prueba'),
          _buildActionTile(
            icon: Icons.notifications_active,
            title: 'Probar notificación',
            subtitle: 'Enviar notificación de prueba',
            onTap: _onTestNotification,
          ),
          _buildActionTile(
            icon: Icons.phone_android,
            title: 'Probar alarma',
            subtitle: 'Vibración y flash de pantalla',
            onTap: _onTestAlarm,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00F5D4),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF2196F3)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00F5D4),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2196F3)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF00F5D4)),
        onTap: onTap,
      ),
    );
  }

  void _onTestNotification() {
    notificationService.testNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificación de prueba enviada'),
        backgroundColor: Color(0xFF2196F3),
      ),
    );
  }

  void _onTestAlarm() async {
    final cron = ApiService.instance.currentCron;
    if (cron != null && cron.tasks.isNotEmpty) {
      final task = cron.tasks.first;
      await notificationService.showTestNotification(task);
    }
  }
}
