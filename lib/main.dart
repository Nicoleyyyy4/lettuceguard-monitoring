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
import 'utils/app_theme.dart';
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
      title: 'LettuceGuard',
      theme: LettuceGuardTheme.light,
      home: Scaffold(
        backgroundColor: LettuceGuardColors.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _isInitializing
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                LettuceGuardColors.primaryGreenDark,
                                LettuceGuardColors.primaryGreen,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: LettuceGuardColors.primaryGreen
                                    .withValues(alpha: 0.24),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: LettuceGuardColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Starting LettuceGuard…',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: LettuceGuardColors.textDark,
                          ),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: LettuceGuardColors.borderLight,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: LettuceGuardColors.statusError.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_off_rounded,
                              size: 36,
                              color: LettuceGuardColors.statusError,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Connection Issue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: LettuceGuardColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'LettuceGuard could not start Firebase. Check the '
                            'device\'s internet connection and app configuration.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: LettuceGuardColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            _initializationError.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: LettuceGuardColors.statusError,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _retryFirebaseInitialization,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Retry'),
                            ),
                          ),
                        ],
                      ),
                    ),
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
            theme: LettuceGuardTheme.light,
            darkTheme: LettuceGuardTheme.dark,
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
