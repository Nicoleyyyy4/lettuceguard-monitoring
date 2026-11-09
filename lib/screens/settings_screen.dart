import 'package:flutter/material.dart';
import '../providers/sensor_provider.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _firebaseUrlController;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _firebaseUrlController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = SensorProviderScope.of(context);
    _firebaseUrlController.text = provider.firebaseUrl;
  }

  @override
  void dispose() {
    _firebaseUrlController.dispose();
    super.dispose();
  }

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
    final currentUser = _authService.currentUser;

    return ListenableBuilder(
      listenable: provider,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: provider.isDarkMode ? const Color(0xFF121B14) : LettuceGuardColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Configuration & Diagnostics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: provider.isDarkMode ? Colors.white : LettuceGuardColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),

                // User Profile & Sign Out Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: LettuceGuardColors.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: LettuceGuardColors.primaryGreen,
                          foregroundColor: Colors.white,
                          child: Text(
                            (currentUser?.displayName.isNotEmpty == true)
                                ? currentUser!.displayName[0].toUpperCase()
                                : 'O',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser?.displayName ?? 'Greenhouse Operator',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                currentUser?.email ?? 'operator@lettuceguard.io',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: LettuceGuardColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: LettuceGuardColors.statusError),
                          tooltip: 'Logout',
                          onPressed: () => _handleLogout(context),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Appearance & Theme Mode Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: LettuceGuardColors.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.palette_outlined, color: LettuceGuardColors.primaryGreen),
                            SizedBox(width: 8),
                            Text(
                              'App Appearance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Dark Mode Theme'),
                          subtitle: const Text('Switch between Light and Dark visual themes.'),
                          value: provider.isDarkMode,
                          activeColor: LettuceGuardColors.primaryGreen,
                          onChanged: (val) {
                            provider.toggleThemeMode();
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Firebase Config Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: LettuceGuardColors.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cloud_sync, color: LettuceGuardColors.primaryGreen),
                            SizedBox(width: 8),
                            Text(
                              'Firebase Cloud Layer Settings',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Hardware Simulation / Demo Mode'),
                          subtitle: const Text(
                              'Generates live mock sensor streams for testing without ESP32 connected.'),
                          value: provider.isDemoMode,
                          activeColor: LettuceGuardColors.primaryGreen,
                          onChanged: (val) {
                            provider.toggleDemoMode(val);
                          },
                        ),

                        const Divider(height: 20),

                        TextField(
                          controller: _firebaseUrlController,
                          decoration: InputDecoration(
                            labelText: 'Firebase Realtime Database URL',
                            hintText: 'https://lettuceguard-app-default-rtdb.firebaseio.com',
                            prefixIcon: const Icon(Icons.link),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LettuceGuardColors.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              provider.updateFirebaseUrl(_firebaseUrlController.text.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Firebase connection URL updated!'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('SAVE FIREBASE URL'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Hardware Fault Injector (Diagnostic Suite)
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: LettuceGuardColors.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bug_report, color: LettuceGuardColors.statusError),
                            SizedBox(width: 8),
                            Text(
                              'Diagnostic Error Flag Test Bench',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Inject mock hardware sensor failures to verify visual dashboard flags and alert popups.',
                          style: TextStyle(fontSize: 11, color: LettuceGuardColors.textMuted),
                        ),
                        const SizedBox(height: 12),

                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Simulate DHT22 Sensor Fault'),
                          value: provider.mockService.forceDht22Error,
                          activeColor: LettuceGuardColors.statusError,
                          onChanged: (val) => provider.setDht22Error(val),
                        ),

                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Simulate DS18B20 Water Temp Disconnect'),
                          value: provider.mockService.forceDs18b20Error,
                          activeColor: LettuceGuardColors.statusError,
                          onChanged: (val) => provider.setDs18b20Error(val),
                        ),

                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Simulate pH Sensor Disconnect / Fault'),
                          value: provider.mockService.forcePhError,
                          activeColor: LettuceGuardColors.statusError,
                          onChanged: (val) => provider.setPhError(val),
                        ),

                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Simulate HC-SR04 Ultrasonic Timeout'),
                          value: provider.mockService.forceUltrasonicError,
                          activeColor: LettuceGuardColors.statusError,
                          onChanged: (val) => provider.setUltrasonicError(val),
                        ),

                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Simulate ESP32 ADC Saturation'),
                          value: provider.mockService.forceAdcSaturation,
                          activeColor: LettuceGuardColors.statusError,
                          onChanged: (val) => provider.setAdcSaturation(val),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Hydroponic Reference Standard
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: LettuceGuardColors.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lettuce Hydroponic Reference Thresholds',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text('• Air Temp: ${LettuceGuardConstants.minAirTemp} - ${LettuceGuardConstants.maxAirTemp}°C'),
                        Text('• Air Humidity: ${LettuceGuardConstants.minAirHumidity} - ${LettuceGuardConstants.maxAirHumidity}%'),
                        Text('• Water Temp: ${LettuceGuardConstants.minWaterTemp} - ${LettuceGuardConstants.maxWaterTemp}°C'),
                        Text('• pH Range: ${LettuceGuardConstants.minPh} - ${LettuceGuardConstants.maxPh} pH'),
                        Text('• Nutrient TDS: ${LettuceGuardConstants.minTds} - ${LettuceGuardConstants.maxTds} ppm'),
                        Text('• Reservoir Level: > ${LettuceGuardConstants.minWaterLevelPct}%'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
