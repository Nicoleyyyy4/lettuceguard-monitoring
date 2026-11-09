import 'package:flutter/material.dart';
import '../models/sensor_model.dart';
import '../providers/sensor_provider.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../utils/routes.dart';
import '../widgets/sensor_card.dart';
import '../widgets/water_level_card.dart';
import '../widgets/status_card.dart';
import '../widgets/bottom_nav.dart';
import 'history_screen.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;
  final AuthService _authService = AuthService();

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: LettuceGuardColors.statusError),
            SizedBox(width: 10),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to log out of LettuceGuard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: LettuceGuardColors.statusError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          LettuceGuardRoutes.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = SensorProviderScope.of(context);

    final List<Widget> pages = [
      _buildLiveDashboardView(context, provider),
      const HistoryScreen(),
      const AlertsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: provider.isDarkMode ? const Color(0xFF121B14) : LettuceGuardColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: provider.isDarkMode ? const Color(0xFF1B2A1E) : LettuceGuardColors.primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.eco_rounded, size: 28),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LettuceGuard',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Hydroponic IoT Monitor',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Theme Light / Dark Mode Toggle
          IconButton(
            icon: Icon(
              provider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: Colors.white,
            ),
            tooltip: provider.isDarkMode ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () {
              provider.toggleThemeMode();
            },
          ),

          // Simulation / Live Indicator
          IconButton(
            icon: Icon(
              provider.isDemoMode ? Icons.science_rounded : Icons.cloud_done_rounded,
              color: Colors.white,
            ),
            tooltip: provider.isDemoMode ? 'Demo / Simulation Mode' : 'Firebase Live Mode',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    provider.isDemoMode
                        ? 'Running in Demo / Hardware Simulation Mode'
                        : 'Connected to Firebase Realtime Database: ${provider.firebaseUrl}',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          // Logout Action
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),

      body: IndexedStack(
        index: _currentNavIndex,
        children: pages,
      ),

      bottomNavigationBar: LettuceGuardBottomNav(
        currentIndex: _currentNavIndex,
        alertBadgeCount: provider.unresolvedAlertsCount,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildLiveDashboardView(BuildContext context, SensorProvider provider) {
    final data = provider.currentData;
    final currentUser = _authService.currentUser;
    final userName = currentUser?.displayName.isNotEmpty == true
        ? currentUser!.displayName
        : (currentUser?.email.contains('@') == true
            ? currentUser!.email.split('@')[0]
            : 'Operator');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. User Greeting Greeting Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: provider.isDarkMode
                  ? const Color(0xFF1B2A1E)
                  : LettuceGuardColors.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: provider.isDarkMode
                    ? Colors.white10
                    : LettuceGuardColors.primaryGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: LettuceGuardColors.primaryGreen,
                  foregroundColor: Colors.white,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'O',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $userName! 👋',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: provider.isDarkMode ? Colors.white : LettuceGuardColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Greenhouse Hydroponic System Online',
                        style: TextStyle(
                          fontSize: 11,
                          color: LettuceGuardColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Status Overview Banner
          StatusCard(
            status: data.calculatedStatus,
            errorCount: provider.unresolvedAlertsCount,
            isConnected: provider.isConnected,
            lastUpdated: data.timestamp,
            onAlertTap: () {
              setState(() {
                _currentNavIndex = 2; // Jump to Alerts tab
              });
            },
          ),

          const SizedBox(height: 16),

          // 3. Active Error Alert Warning Strip (if any)
          if (data.hasSensorError) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LettuceGuardColors.statusError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LettuceGuardColors.statusError),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: LettuceGuardColors.statusError, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HARDWARE SENSOR ERROR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: LettuceGuardColors.statusError,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _getPrimaryErrorMessage(data),
                          style: TextStyle(
                            fontSize: 11,
                            color: provider.isDarkMode ? Colors.white70 : LettuceGuardColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentNavIndex = 2; // Go to Alerts
                      });
                    },
                    child: const Text('VIEW',
                        style: TextStyle(
                            color: LettuceGuardColors.statusError,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            'Live Environmental Metrics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: provider.isDarkMode ? Colors.white : LettuceGuardColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          // 4. Grid of Sensor Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              // Air Temperature (DHT22)
              SensorCard(
                title: 'Air Temperature',
                value: data.airTemperature.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat,
                themeColor: LettuceGuardColors.airTempColor,
                isError: data.dht22Error,
                isWarning: data.isAirTempOutOfRange,
                targetRange: '18 - 26°C',
                alertMessage: 'DHT22 SENSOR ERROR',
              ),

              // Air Humidity (DHT22)
              SensorCard(
                title: 'Air Humidity',
                value: data.airHumidity.toStringAsFixed(1),
                unit: '%',
                icon: Icons.water_drop,
                themeColor: LettuceGuardColors.humidityColor,
                isError: data.dht22Error,
                isWarning: data.isAirHumidityOutOfRange,
                targetRange: '50 - 70%',
                alertMessage: 'DHT22 SENSOR ERROR',
              ),

              // Water Temperature (DS18B20)
              SensorCard(
                title: 'Water Temp',
                value: data.waterTemperature.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.device_thermostat,
                themeColor: LettuceGuardColors.waterTempColor,
                isError: data.ds18b20Error,
                isWarning: data.isWaterTempOutOfRange,
                targetRange: '18 - 22°C',
                alertMessage: 'DS18B20 SENSOR ERROR',
              ),

              // pH Level (Analog pH Meter)
              SensorCard(
                title: 'pH Level',
                value: data.ph.toStringAsFixed(2),
                unit: 'pH',
                icon: Icons.science,
                themeColor: LettuceGuardColors.phColor,
                isError: data.phError || data.adcSaturation,
                isWarning: data.isPhOutOfRange || data.phUncalibrated,
                targetRange: '5.5 - 6.5',
                alertMessage: data.adcSaturation
                    ? 'ADC SATURATION'
                    : 'pH SENSOR ERROR',
              ),

              // Total Dissolved Solids / EC
              SensorCard(
                title: 'TDS (Nutrient)',
                value: data.tds.toStringAsFixed(0),
                unit: 'ppm',
                icon: Icons.bolt,
                themeColor: LettuceGuardColors.tdsColor,
                isError: data.tdsError,
                isWarning: data.isTdsOutOfRange,
                targetRange: '560 - 840 ppm',
                alertMessage: 'TDS SENSOR ERROR',
              ),

              // Reservoir Distance (HC-SR04)
              SensorCard(
                title: 'Water Distance',
                value: data.waterLevelCm.toStringAsFixed(1),
                unit: 'cm',
                icon: Icons.height,
                themeColor: LettuceGuardColors.waterLevelColor,
                isError: data.ultrasonicError,
                isWarning: false,
                targetRange: '0 - 30 cm',
                alertMessage: 'HC-SR04 ERROR',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 5. Reservoir Water Level Visual Gauge Card
          WaterLevelCard(
            percentage: data.waterLevelPct,
            distanceCm: data.waterLevelCm,
            reservoirDepthCm: data.reservoirDepthCm,
            isError: data.ultrasonicError,
            isLow: data.isWaterLevelLow,
          ),
        ],
      ),
    );
  }

  String _getPrimaryErrorMessage(SensorData data) {
    if (data.dht22Error) return 'DHT22 sensor error or disconnected.';
    if (data.ds18b20Error) return 'DS18B20 water temp sensor error.';
    if (data.phError) return 'pH sensor reading failed or disconnected.';
    if (data.ultrasonicError) return 'HC-SR04 ultrasonic sensor timeout.';
    if (data.adcSaturation) return 'ESP32 ADC saturation detected.';
    return 'Hardware diagnostic required.';
  }
}
