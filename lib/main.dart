import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lobmindergo/screens/home_screen.dart';
import 'package:lobmindergo/services/notification_service.dart';
import 'package:lobmindergo/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D0D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await NotificationService.instance.initialize();
  await ApiService.instance.initialize();

  runApp(const ActivitiesNotifierApp());
}

class ActivitiesNotifierApp extends StatelessWidget {
  const ActivitiesNotifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activities Notifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2196F3),
          secondary: Color(0xFF00F5D4),
          surface: Color(0xFF1A1A2E),
          error: Color(0xFFFF6B6B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0D0D),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF00F5D4)),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF1A1A2E)),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A2E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF00F5D4);
            }
            return const Color(0xFF2196F3);
          }),
          checkColor: WidgetStateProperty.all(const Color(0xFF0D0D0D)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Color(0xFFB0B0B0)),
          bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
