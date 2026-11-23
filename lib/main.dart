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
import 'widgets/temperature_alert_host.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirebaseStartupGate());
}

class FirebaseStartupGate extends StatefulWidget {
  const FirebaseStartupGate({super.key});

  @override
  State<FirebaseStartupGate> createState() => _FirebaseStartupGateState();
}

class _FirebaseStartupGateState extends State<FirebaseStartupGate> {
  bool _isInitializing = true;
  bool _isReady = false;
  Object? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _isReady = true;
        _isInitializing = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _initializationError = error;
        _isInitializing = false;
      });
    }
  }

  void _retryFirebaseInitialization() {
    setState(() {
      _initializationError = null;
      _isInitializing = true;
    });
    _initializeFirebase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return const LettuceGuardApp();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _isInitializing
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Starting LettuceGuard…'),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'LettuceGuard could not start Firebase. Check the '
                        'phone\'s internet connection and app configuration.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        _initializationError.toString(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _retryFirebaseInitialization,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class LettuceGuardApp extends StatefulWidget {
  const LettuceGuardApp({super.key});

  @override
  State<LettuceGuardApp> createState() => _LettuceGuardAppState();
}

class _LettuceGuardAppState extends State<LettuceGuardApp> {
  late final SensorProvider _sensorProvider;
  final _navigatorKey = GlobalKey<NavigatorState>();

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
            navigatorKey: _navigatorKey,
            builder: (context, child) => TemperatureAlertHost(
              provider: _sensorProvider,
              navigatorKey: _navigatorKey,
              child: child!,
            ),
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
