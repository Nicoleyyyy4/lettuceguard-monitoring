import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../providers/sensor_provider.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
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
    if (_firebaseUrlController.text.isEmpty) {
      _firebaseUrlController.text = provider.firebaseUrl;
    }
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
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: LettuceGuardColors.statusError),
            SizedBox(width: 10),
            Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of LettuceGuard?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LettuceGuardColors.statusError,
              foregroundColor: Colors.white,
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
          backgroundColor: LettuceGuardColors.canvas(context),
          body: SingleChildScrollView(
            child: ResponsiveContainer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTwoCol = constraints.maxWidth >= 880;

                  final profileCard = _buildProfileCard(context, currentUser);
                  final appearanceCard = _buildAppearanceCard(
                    context,
                    provider,
                  );
                  final thresholdsCard = _buildReferenceCard(context);
                  final cloudCard = _buildCloudCard(context, provider);
                  final diagnosticsCard = _buildDiagnosticBenchCard(
                    context,
                    provider,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Configuration & Diagnostics',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: LettuceGuardColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage telemetry sources, visual theme, and diagnostic fault testing.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: LettuceGuardColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (isTwoCol)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  profileCard,
                                  const SizedBox(height: 16),
                                  appearanceCard,
                                  const SizedBox(height: 16),
                                  thresholdsCard,
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  cloudCard,
                                  const SizedBox(height: 16),
                                  diagnosticsCard,
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        profileCard,
                        const SizedBox(height: 16),
                        appearanceCard,
                        const SizedBox(height: 16),
                        cloudCard,
                        const SizedBox(height: 16),
                        diagnosticsCard,
                        const SizedBox(height: 16),
                        thresholdsCard,
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: LettuceGuardColors.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LettuceGuardColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: LettuceGuardColors.shadow(context),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
  }) {
    final isDark = LettuceGuardColors.isDark(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: LettuceGuardColors.textPrimary(context),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: LettuceGuardColors.textSecondary(context),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic currentUser) {
    final name = (currentUser?.displayName as String?)?.isNotEmpty == true
        ? currentUser!.displayName as String
        : 'Greenhouse Operator';
    final email = (currentUser?.email as String?)?.isNotEmpty == true
        ? currentUser!.email as String
        : 'operator@lettuceguard.io';

    return _sectionCard(
      context,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LettuceGuardColors.heroGradient(context),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'O',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: LettuceGuardColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: LettuceGuardColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton.outlined(
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
            style: IconButton.styleFrom(
              side: BorderSide(
                color: LettuceGuardColors.statusError.withValues(alpha: 0.35),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.logout_rounded,
              color: LettuceGuardColors.statusError,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context, SensorProvider provider) {
    return _sectionCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context,
            icon: Icons.palette_outlined,
            iconColor: LettuceGuardColors.primary(context),
            title: 'App Appearance',
            subtitle: 'Botanical Light & Dark display themes',
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Dark Mode Theme',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Switch between Light and Dark visual themes.',
              style: TextStyle(
                fontSize: 12,
                color: LettuceGuardColors.textSecondary(context),
              ),
            ),
            value: provider.isDarkMode,
            onChanged: (_) => provider.toggleThemeMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudCard(BuildContext context, SensorProvider provider) {
    return _sectionCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context,
            icon: Icons.cloud_sync_rounded,
            iconColor: LettuceGuardColors.primary(context),
            title: 'Firebase Cloud Layer Settings',
            subtitle: 'Configure live hardware data sources and simulation',
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Hardware Simulation / Demo Mode',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              'Generates live mock sensor streams for testing without ESP32 connected.',
              style: TextStyle(
                fontSize: 12,
                color: LettuceGuardColors.textSecondary(context),
              ),
            ),
            value: provider.isDemoMode,
            onChanged: provider.toggleDemoMode,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<LiveSensorSource>(
            initialValue: provider.liveSource,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Production live sensor source',
              prefixIcon: Icon(Icons.router_outlined),
            ),
            items: const [
              DropdownMenuItem(
                value: LiveSensorSource.firebase,
                child: Text('Firebase current snapshot'),
              ),
              DropdownMenuItem(
                value: LiveSensorSource.esp32,
                child: Text('ESP32 local HTTP'),
              ),
            ],
            onChanged: (source) {
              if (source != null) {
                provider.updateLiveSource(source);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Heat detection requires a fresh sensor timestamp. Missing or repeated timestamps cannot confirm heat or recovery.',
            style: TextStyle(
              fontSize: 11.5,
              color: LettuceGuardColors.textSecondary(context),
            ),
          ),
          if (kDebugMode && provider.isDemoMode) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: LettuceGuardColors.surfaceElevated(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LettuceGuardColors.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer demo temperature scenarios (simulated only)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LettuceGuardColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [24.0, 28.0, 32.0, 36.0]
                        .map(
                          (value) => OutlinedButton(
                            onPressed: () =>
                                provider.setDemoAirTemperature(value),
                            child: Text('${value.toStringAsFixed(0)}\u00b0C'),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Water temperature and pump scenarios',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LettuceGuardColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [20.0, 23.5, 26.0]
                        .map(
                          (value) => OutlinedButton(
                            onPressed: () =>
                                provider.setDemoWaterTemperature(value),
                            child: Text(
                              'Water ${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}°C',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 28),
          TextField(
            controller: _firebaseUrlController,
            decoration: const InputDecoration(
              labelText: 'Firebase Realtime Database URL',
              hintText: 'https://lettuceguard-bd1f4-default-rtdb.firebaseio.com',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                provider.updateFirebaseUrl(_firebaseUrlController.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Firebase connection URL updated!'),
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('SAVE FIREBASE URL'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticBenchCard(
    BuildContext context,
    SensorProvider provider,
  ) {
    return _sectionCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context,
            icon: Icons.bug_report_rounded,
            iconColor: LettuceGuardColors.statusError,
            title: 'Diagnostic Error Flag Test Bench',
            subtitle:
                'Inject mock hardware sensor failures to verify visual dashboard flags and alert popups.',
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate DHT22 Sensor Fault'),
            value: provider.mockService.forceDht22Error,
            activeTrackColor: LettuceGuardColors.statusError,
            onChanged: provider.setDht22Error,
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate DS18B20 Water Temp Disconnect'),
            value: provider.mockService.forceDs18b20Error,
            activeTrackColor: LettuceGuardColors.statusError,
            onChanged: provider.setDs18b20Error,
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate pH Sensor Disconnect / Fault'),
            value: provider.mockService.forcePhError,
            activeTrackColor: LettuceGuardColors.statusError,
            onChanged: provider.setPhError,
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate HC-SR04 Ultrasonic Timeout'),
            value: provider.mockService.forceUltrasonicError,
            activeTrackColor: LettuceGuardColors.statusError,
            onChanged: provider.setUltrasonicError,
          ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate ESP32 ADC Saturation'),
            value: provider.mockService.forceAdcSaturation,
            activeTrackColor: LettuceGuardColors.statusError,
            onChanged: provider.setAdcSaturation,
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(BuildContext context) {
    final rows = [
      (
        Icons.thermostat_rounded,
        LettuceGuardColors.airTempColor,
        'Air Temp',
        '${LettuceGuardConstants.minAirTemp} - ${LettuceGuardConstants.maxAirTemp}°C',
      ),
      (
        Icons.water_drop_rounded,
        LettuceGuardColors.humidityColor,
        'Air Humidity',
        '${LettuceGuardConstants.minAirHumidity} - ${LettuceGuardConstants.maxAirHumidity}%',
      ),
      (
        Icons.device_thermostat_rounded,
        LettuceGuardColors.waterTempColor,
        'Water Temp',
        '${LettuceGuardConstants.minWaterTemp} - ${LettuceGuardConstants.maxWaterTemp}°C',
      ),
      (
        Icons.science_rounded,
        LettuceGuardColors.phColor,
        'pH Range',
        '${LettuceGuardConstants.minPh} - ${LettuceGuardConstants.maxPh} pH',
      ),
      (
        Icons.bolt_rounded,
        LettuceGuardColors.tdsColor,
        'Nutrient TDS',
        '${LettuceGuardConstants.minTds} - ${LettuceGuardConstants.maxTds} ppm',
      ),
      (
        Icons.waves_rounded,
        LettuceGuardColors.waterLevelColor,
        'Reservoir Level',
        '> ${LettuceGuardConstants.minWaterLevelPct}%',
      ),
    ];

    return _sectionCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            context,
            icon: Icons.eco_rounded,
            iconColor: LettuceGuardColors.primary(context),
            title: 'Lettuce Hydroponic Reference Thresholds',
            subtitle: 'Optimal target ranges for Butterhead & Romaine lettuce',
          ),
          const SizedBox(height: 14),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: LettuceGuardColors.surfaceElevated(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(row.$1, size: 17, color: row.$2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        row.$3,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: LettuceGuardColors.textPrimary(context),
                        ),
                      ),
                    ),
                    Text(
                      row.$4,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: row.$2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
