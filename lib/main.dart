import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/sensor_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/colors.dart';
import 'utils/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LettuceGuardApp());
}

class LettuceGuardApp extends StatefulWidget {
  const LettuceGuardApp({super.key});

  @override
  State<LettuceGuardApp> createState() => _LettuceGuardAppState();
}

class _LettuceGuardAppState extends State<LettuceGuardApp> {
  late final SensorProvider _sensorProvider;

  @override
  void initState() {
    super.initState();
    _sensorProvider = SensorProvider();
  }

  @override
  void dispose() {
    _sensorProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SensorProviderScope(
      provider: _sensorProvider,
      child: ListenableBuilder(
        listenable: _sensorProvider,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LettuceGuard',
            themeMode: _sensorProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: LettuceGuardColors.primaryGreen,
                brightness: Brightness.light,
                surface: LettuceGuardColors.background,
              ),
              scaffoldBackgroundColor: LettuceGuardColors.background,
              appBarTheme: const AppBarTheme(
                backgroundColor: LettuceGuardColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: LettuceGuardColors.primaryGreen,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF121B14),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1B2A1E),
                foregroundColor: Colors.white,
              ),
            ),
            initialRoute: LettuceGuardRoutes.splash,
            routes: {
              LettuceGuardRoutes.splash: (_) => const SplashScreen(),
              LettuceGuardRoutes.login: (_) => const LoginScreen(),
              LettuceGuardRoutes.register: (_) => const RegisterScreen(),
              LettuceGuardRoutes.dashboard: (_) => const DashboardScreen(),
              LettuceGuardRoutes.history: (_) => const HistoryScreen(),
              LettuceGuardRoutes.alerts: (_) => const AlertsScreen(),
              LettuceGuardRoutes.settings: (_) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
