import 'package:flutter/material.dart';
import '../models/sensor_model.dart';
import '../providers/sensor_provider.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../utils/routes.dart';
import '../widgets/sensor_card.dart';
import '../widgets/water_level_card.dart';
import '../widgets/status_card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/temperature_alert_banner.dart';
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

  static const _pageTitles = [
    'Live Overview',
    'Trend Analytics',
    'Diagnostics & Alerts',
    'System Settings',
  ];

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

  void _showModeSnackBar(BuildContext context, SensorProvider provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.isDemoMode
              ? 'Running in Demo / Hardware Simulation Mode'
              : 'Production mode. Firebase history URL: ${provider.firebaseUrl}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = SensorProviderScope.of(context);
    final sizeClass = LettuceGuardResponsive.of(context);

    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final List<Widget> pages = [
          _buildLiveDashboardView(context, provider),
          const HistoryScreen(),
          const AlertsScreen(),
          const SettingsScreen(),
        ];

        final content = IndexedStack(index: _currentNavIndex, children: pages);

        if (sizeClass == ScreenSizeClass.expanded) {
          return Scaffold(
            backgroundColor: LettuceGuardColors.canvas(context),
            body: Row(
              children: [
                LettuceGuardBottomNav(
                  mode: NavigationLayoutMode.sidebar,
                  currentIndex: _currentNavIndex,
                  alertBadgeCount: provider.unresolvedAlertsCount,
                  onTap: (index) => setState(() => _currentNavIndex = index),
                  sidebarHeader: _buildSidebarBrandHeader(context),
                  sidebarFooter: _buildSidebarFooter(context, provider),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopTopBar(context, provider),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (sizeClass == ScreenSizeClass.medium) {
          return Scaffold(
            backgroundColor: LettuceGuardColors.canvas(context),
            appBar: _buildMobileAppBar(context, provider),
            body: Row(
              children: [
                LettuceGuardBottomNav(
                  mode: NavigationLayoutMode.rail,
                  currentIndex: _currentNavIndex,
                  alertBadgeCount: provider.unresolvedAlertsCount,
                  onTap: (index) => setState(() => _currentNavIndex = index),
                ),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: LettuceGuardColors.canvas(context),
          appBar: _buildMobileAppBar(context, provider),
          body: content,
          bottomNavigationBar: LettuceGuardBottomNav(
            mode: NavigationLayoutMode.bottomBar,
            currentIndex: _currentNavIndex,
            alertBadgeCount: provider.unresolvedAlertsCount,
            onTap: (index) => setState(() => _currentNavIndex = index),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    BuildContext context,
    SensorProvider provider,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: provider.isDarkMode
          ? LettuceGuardColors.darkSidebar
          : LettuceGuardColors.primaryGreenDark,
      foregroundColor: Colors.white,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LettuceGuard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                Text(
                  'Hydroponic IoT Monitor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            provider.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: Colors.white,
            size: 21,
          ),
          tooltip: provider.isDarkMode
              ? 'Switch to Light Theme'
              : 'Switch to Dark Theme',
          onPressed: provider.toggleThemeMode,
        ),
        IconButton(
          icon: Icon(
            provider.isDemoMode
                ? Icons.science_rounded
                : Icons.cloud_done_rounded,
            color: Colors.white,
            size: 21,
          ),
          tooltip: provider.isDemoMode
              ? 'Demo / Simulation Mode'
              : 'Production sensor readings',
          onPressed: () => _showModeSnackBar(context, provider),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 21),
          tooltip: 'Sign Out',
          onPressed: () => _handleLogout(context),
        ),
      ],
    );
  }

  Widget _buildSidebarBrandHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LettuceGuardColors.heroGradient(context),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: LettuceGuardColors.primaryGreen.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LettuceGuard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: LettuceGuardColors.textPrimary(context),
                ),
              ),
              Text(
                'Hydroponic IoT Monitor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: LettuceGuardColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarFooter(BuildContext context, SensorProvider provider) {
    final isDark = LettuceGuardColors.isDark(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => _showModeSnackBar(context, provider),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: LettuceGuardColors.surfaceElevated(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LettuceGuardColors.border(context)),
            ),
            child: Row(
              children: [
                Icon(
                  provider.isDemoMode
                      ? Icons.science_rounded
                      : Icons.cloud_done_rounded,
                  size: 18,
                  color: provider.isDemoMode
                      ? LettuceGuardColors.tdsColor
                      : LettuceGuardColors.statusOk,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.isDemoMode ? 'Demo Mode' : 'Live Production',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: LettuceGuardColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        provider.isConnected
                            ? 'Telemetry Active'
                            : 'Disconnected',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: LettuceGuardColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: provider.isConnected
                        ? LettuceGuardColors.statusOk
                        : LettuceGuardColors.statusError,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: provider.toggleThemeMode,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 16,
                ),
                label: Text(
                  isDark ? 'Light' : 'Dark',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Sign Out',
              onPressed: () => _handleLogout(context),
              style: IconButton.styleFrom(
                side: BorderSide(color: LettuceGuardColors.border(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: LettuceGuardColors.statusError,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopTopBar(BuildContext context, SensorProvider provider) {
    final currentUser = _authService.currentUser;
    final userName = currentUser?.displayName.isNotEmpty == true
        ? currentUser!.displayName
        : (currentUser?.email.contains('@') == true
              ? currentUser!.email.split('@')[0]
              : 'Operator');

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: LettuceGuardColors.surface(context),
        border: Border(
          bottom: BorderSide(color: LettuceGuardColors.border(context)),
        ),
      ),
      child: Row(
        children: [
          Text(
            _pageTitles[_currentNavIndex],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: LettuceGuardColors.textPrimary(context),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: LettuceGuardColors.surfaceElevated(context),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: LettuceGuardColors.border(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: LettuceGuardColors.primaryGreen,
                  foregroundColor: Colors.white,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'O',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: LettuceGuardColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveDashboardView(
    BuildContext context,
    SensorProvider provider,
  ) {
    final data = provider.currentData;
    if (!provider.isDemoMode && !data.hasValidTimestamp) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TemperatureAlertBanner(),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: LettuceGuardColors.surface(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: LettuceGuardColors.border(context),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: LettuceGuardColors.primary(
                              context,
                            ).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.sensors_rounded,
                            size: 36,
                            color: LettuceGuardColors.primary(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Waiting for live ESP32 readings. Check the device connection.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: LettuceGuardColors.textPrimary(context),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final currentUser = _authService.currentUser;
    final userName = currentUser?.displayName.isNotEmpty == true
        ? currentUser!.displayName
        : (currentUser?.email.contains('@') == true
              ? currentUser!.email.split('@')[0]
              : 'Operator');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ResponsiveContainer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isWide = availableWidth >= 820;
            final gridColumns = LettuceGuardResponsive.sensorGridColumns(
              availableWidth,
            );
            final gridAspect = LettuceGuardResponsive.sensorGridAspectRatio(
              availableWidth,
              gridColumns,
            );

            final welcomeCard = _buildWelcomeCard(context, userName, provider);
            final statusCard = StatusCard(
              status: data.calculatedStatus,
              errorCount: provider.unresolvedAlertsCount,
              isConnected: provider.isConnected,
              lastUpdated: data.timestamp,
              onAlertTap: () => setState(() => _currentNavIndex = 2),
            );

            final waterLevelCard = WaterLevelCard(
              percentage: data.waterLevelPct,
              distanceCm: data.waterLevelCm,
              reservoirDepthCm: data.reservoirDepthCm,
              isError:
                  data.ultrasonicError ||
                  !data.waterLevelPct.isFinite ||
                  !data.waterLevelCm.isFinite,
              isLow: data.isWaterLevelLow,
            );

            final pumpSnapshotCard = _buildPumpClimateCard(
              context,
              data,
              provider,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TemperatureAlertBanner(),

                // Top Summary Row (Side-by-side on wide screens, stacked on compact)
                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: welcomeCard),
                        const SizedBox(width: 16),
                        Expanded(flex: 7, child: statusCard),
                      ],
                    ),
                  )
                else ...[
                  welcomeCard,
                  const SizedBox(height: 14),
                  statusCard,
                ],

                const SizedBox(height: 16),

                // Active Hardware Error Strip
                if (data.hasSensorError) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: LettuceGuardColors.statusError.withValues(
                        alpha: LettuceGuardColors.isDark(context) ? 0.16 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: LettuceGuardColors.statusError.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: LettuceGuardColors.statusError.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: LettuceGuardColors.statusError,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HARDWARE SENSOR ERROR',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: LettuceGuardColors.statusError,
                                  fontSize: 12,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getPrimaryErrorMessage(data),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: LettuceGuardColors.textPrimary(
                                    context,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _currentNavIndex = 2),
                          child: const Text(
                            'VIEW',
                            style: TextStyle(
                              color: LettuceGuardColors.statusError,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Live Environmental Metrics',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: LettuceGuardColors.textPrimary(context),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setState(() => _currentNavIndex = 1),
                      icon: const Icon(Icons.show_chart_rounded, size: 16),
                      label: const Text('Trends'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Responsive Sensor Cards Grid
                GridView.count(
                  crossAxisCount: gridColumns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: gridAspect,
                  children: [
                    SensorCard(
                      title: 'Air Temperature',
                      value: data.hasValidAirTemperature
                          ? data.airTemperature.toStringAsFixed(1)
                          : 'N/A',
                      unit: '°C',
                      icon: Icons.thermostat_rounded,
                      themeColor: LettuceGuardColors.airTempColor,
                      isError: !data.hasValidAirTemperature,
                      isWarning: data.isAirTempOutOfRange,
                      targetRange: '18 - 26°C',
                      normalizedProgress: _normalize(
                        data.airTemperature,
                        10,
                        40,
                      ),
                      alertMessage: 'DHT22 SENSOR ERROR',
                      onTap: () => setState(() => _currentNavIndex = 1),
                    ),
                    SensorCard(
                      title: 'Air Humidity',
                      value: data.airHumidity.isFinite
                          ? data.airHumidity.toStringAsFixed(1)
                          : 'N/A',
                      unit: '%',
                      icon: Icons.water_drop_rounded,
                      themeColor: LettuceGuardColors.humidityColor,
                      isError: data.dht22Error,
                      isWarning: data.isAirHumidityOutOfRange,
                      targetRange: '50 - 70%',
                      normalizedProgress: _normalize(data.airHumidity, 0, 100),
                      alertMessage: 'DHT22 SENSOR ERROR',
                      onTap: () => setState(() => _currentNavIndex = 1),
                    ),
                    SensorCard(
                      title: 'Water Temp',
                      value: data.waterTemperature.isFinite
                          ? data.waterTemperature.toStringAsFixed(1)
                          : 'N/A',
                      unit: '°C',
                      icon: Icons.device_thermostat_rounded,
                      themeColor: LettuceGuardColors.waterTempColor,
                      isError: data.ds18b20Error,
                      isWarning: data.isWaterTempOutOfRange,
                      targetRange: '18 - 22°C',
                      normalizedProgress: _normalize(
                        data.waterTemperature,
                        10,
                        35,
                      ),
                      alertMessage: 'DS18B20 SENSOR ERROR',
                      onTap: () => setState(() => _currentNavIndex = 1),
                    ),
                    SensorCard(
                      title: 'pH Level',
                      value: data.ph.isFinite ? data.ph.toStringAsFixed(2) : 'N/A',
                      unit: 'pH',
                      icon: Icons.science_rounded,
                      themeColor: LettuceGuardColors.phColor,
                      isError: data.phError || data.adcSaturation,
                      isWarning: data.isPhOutOfRange || data.phUncalibrated,
                      targetRange: '5.5 - 6.5',
                      normalizedProgress: _normalize(data.ph, 3.5, 9.0),
                      alertMessage: data.adcSaturation
                          ? 'ADC SATURATION'
                          : 'pH SENSOR ERROR',
                      onTap: () => setState(() => _currentNavIndex = 1),
                    ),
                    SensorCard(
                      title: 'TDS (Nutrient)',
                      value: data.hasValidTds
                          ? data.tds.toStringAsFixed(0)
                          : 'N/A',
                      unit: 'ppm',
                      icon: Icons.bolt_rounded,
                      themeColor: LettuceGuardColors.tdsColor,
                      isError: !data.hasValidTds,
                      isWarning: data.isTdsOutOfRange,
                      targetRange:
                          '${LettuceGuardConstants.minTds.toStringAsFixed(0)} - ${LettuceGuardConstants.maxTds.toStringAsFixed(0)} ppm',
                      normalizedProgress: _normalize(data.tds, 200, 1200),
                      alertMessage: 'TDS SENSOR ERROR',
                      onTap: () => setState(() => _currentNavIndex = 1),
                    ),
                    SensorCard(
                      title: 'Water Distance',
                      value: data.waterLevelCm.isFinite
                          ? data.waterLevelCm.toStringAsFixed(1)
                          : 'N/A',
                      unit: 'cm',
                      icon: Icons.height_rounded,
                      themeColor: LettuceGuardColors.waterLevelColor,
                      isError: data.ultrasonicError,
                      isWarning: false,
                      targetRange: '0 - 30 cm',
                      normalizedProgress: _normalize(
                        data.reservoirDepthCm - data.waterLevelCm,
                        0,
                        data.reservoirDepthCm,
                      ),
                      alertMessage: 'HC-SR04 ERROR',
                      onTap: () => setState(() => _currentNavIndex = 1),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Reservoir + Circulation Pump Row
                if (isWide)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 7, child: waterLevelCard),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: pumpSnapshotCard),
                      ],
                    ),
                  )
                else ...[
                  waterLevelCard,
                  const SizedBox(height: 14),
                  pumpSnapshotCard,
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    BuildContext context,
    String userName,
    SensorProvider provider,
  ) {
    final isDark = LettuceGuardColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LettuceGuardColors.heroGradient(context),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'O',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, $userName!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: LettuceGuardColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Greenhouse Hydroponic System Online',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: LettuceGuardColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MiniTag(
                      label: provider.isDemoMode ? 'DEMO STREAM' : 'LIVE NODE',
                      color: provider.isDemoMode
                          ? LettuceGuardColors.tdsColor
                          : LettuceGuardColors.primary(context),
                      isDark: isDark,
                    ),
                    _MiniTag(
                      label: LettuceGuardConstants.defaultDeviceId,
                      color: LettuceGuardColors.secondaryTeal,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPumpClimateCard(
    BuildContext context,
    SensorData data,
    SensorProvider provider,
  ) {
    final pumpActive = data.waterPumpActive;
    final pumpStatus = pumpActive
        ? 'Circulating Actively'
        : data.waterPumpReason == 'low_or_unavailable_water_level'
        ? 'Paused · Low Water'
        : 'Standby Ready';
    final accent = pumpActive
        ? LettuceGuardColors.accentLightGreen
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LettuceGuardColors.heroGradient(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: LettuceGuardColors.primaryGreenDark.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  pumpActive ? Icons.sync_rounded : Icons.water_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Circulation & Thermal Guard',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      'Auto pump control · 23°C ON / 22°C OFF',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PUMP STATE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pumpStatus,
                        style: TextStyle(
                          color: accent,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE ALERTS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.unresolvedAlertsCount} Open',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _currentNavIndex = 2),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              icon: const Icon(Icons.health_and_safety_outlined, size: 16),
              label: const Text(
                'Open Diagnostics',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double? _normalize(double value, double min, double max) {
    if (!value.isFinite || max <= min) return null;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  String _getPrimaryErrorMessage(SensorData data) {
    if (data.dht22Error) return 'DHT22 sensor error or disconnected.';
    if (data.ds18b20Error) return 'DS18B20 water temp sensor error.';
    if (data.phError) return 'pH sensor reading failed or disconnected.';
    if (data.ultrasonicError) return 'HC-SR04 ultrasonic sensor timeout.';
    if (!data.hasValidTds) return 'TDS reading unavailable or sensor error.';
    if (data.adcSaturation) return 'ESP32 ADC saturation detected.';
    return 'Hardware diagnostic required.';
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _MiniTag({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
