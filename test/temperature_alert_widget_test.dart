import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lettuceguard/models/sensor_model.dart';
import 'package:lettuceguard/models/temperature_level.dart';
import 'package:lettuceguard/providers/sensor_provider.dart';
import 'package:lettuceguard/screens/alerts_screen.dart';
import 'package:lettuceguard/screens/dashboard_screen.dart';
import 'package:lettuceguard/screens/history_screen.dart';
import 'package:lettuceguard/widgets/temperature_alert_banner.dart';
import 'package:lettuceguard/widgets/temperature_alert_host.dart';
import 'package:lettuceguard/widgets/bottom_nav.dart';
import 'history_test_helpers.dart';
import 'temperature_firebase_fixture.dart';

class TemperatureRig {
  TemperatureRig({
    bool demo = true,
    TemperatureFirebaseFixture? firebase,
    bool useFirebasePolling = false,
  }) {
    provider = SensorProvider(
      initialDemoMode: demo,
      initialEsp32Url: '',
      initialLiveSource: useFirebasePolling
          ? LiveSensorSource.firebase
          : LiveSensorSource.esp32,
      firebaseService: firebase?.service(),
      clock: () => now,
      sensorStreamOverride: useFirebasePolling ? null : samples.stream,
    );
  }
  final navigator = GlobalKey<NavigatorState>();
  final samples = StreamController<SensorData>.broadcast(sync: true);
  late final SensorProvider provider;
  DateTime now = DateTime.utc(2026, 11, 23, 1);
  void read(double value, {bool error = false}) {
    now = now.add(const Duration(seconds: 3));
    samples.add(
      SensorData.fromJson({
        ...readingJson(time: now),
        'airTemperature': value,
        'sensorErrors': {'dht22Error': error},
      }),
    );
  }

  void confirm(double value) {
    for (var i = 0; i < 3; i++) {
      read(value);
    }
  }

  Widget host({Widget? home}) => _RigOwner(
    rig: this,
    child: SensorProviderScope(
      provider: provider,
      child: MaterialApp(
        navigatorKey: navigator,
        builder: (_, child) => TemperatureAlertHost(
          provider: provider,
          navigatorKey: navigator,
          child: child!,
        ),
        routes: {'/alerts': (_) => const AlertsScreen()},
        home:
            home ??
            const Scaffold(
              body: Column(
                children: [
                  TemperatureAlertBanner(),
                  Expanded(child: AlertsScreen()),
                ],
              ),
            ),
      ),
    ),
  );
}

class _RigOwner extends StatefulWidget {
  const _RigOwner({required this.rig, required this.child});
  final TemperatureRig rig;
  final Widget child;
  @override
  State<_RigOwner> createState() => _RigOwnerState();
}

class _RigOwnerState extends State<_RigOwner> {
  @override
  void dispose() {
    widget.rig.provider.dispose();
    widget.rig.samples.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets(
    'Firebase current polling supplies real timestamped samples to the detector',
    (tester) async {
      final firebase = TemperatureFirebaseFixture();
      final rig = TemperatureRig(
        demo: false,
        firebase: firebase,
        useFirebasePolling: true,
      );
      await tester.pumpWidget(rig.host());
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        rig.now = rig.now.add(const Duration(seconds: 3));
        firebase.nodes['/devices/lettuceguard_node_01/current'] = {
          ...readingJson(time: rig.now),
          'airTemperature': 32,
        };
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      }
      expect(rig.provider.liveSource, LiveSensorSource.firebase);
      expect(rig.provider.temperatureLevel, TemperatureLevel.critical);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(firebase.events, hasLength(1));
      expect(
        firebase.requests
            .where((r) => r.url.path.endsWith('/current.json'))
            .length,
        greaterThanOrEqualTo(3),
      );
    },
  );

  testWidgets(
    'popup waits for foreground resume and does not repeat after acknowledgment',
    (tester) async {
      final rig = TemperatureRig();
      await tester.pumpWidget(rig.host());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      rig.confirm(32);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Acknowledge'));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'high banner confirms without a popup and stays synchronized with Alerts',
    (tester) async {
      final rig = TemperatureRig();
      await tester.pumpWidget(rig.host());
      rig.read(28);
      await tester.pumpAndSettle();
      expect(find.textContaining('Confirming consecutive'), findsOneWidget);
      expect(rig.provider.alerts.where((a) => a.isTemperatureAlert), isEmpty);
      rig.read(28);
      rig.read(28);
      await tester.pumpAndSettle();
      expect(find.text('DEMO • HIGH AIR TEMPERATURE'), findsNWidgets(2));
      expect(find.byType(AlertDialog), findsNothing);
      expect(rig.provider.activeTemperatureAlert!.isResolved, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'critical popup acknowledges without resolution and never repeats on rebuild',
    (tester) async {
      final rig = TemperatureRig();
      await tester.pumpWidget(rig.host());
      rig.confirm(32);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final id = rig.provider.activeTemperatureAlert!.id;
      await tester.tap(find.widgetWithText(FilledButton, 'Acknowledge'));
      await tester.pumpAndSettle();
      expect(rig.provider.activeTemperatureAlert!.isAcknowledged, isTrue);
      expect(rig.provider.activeTemperatureAlert!.id, id);
      rig.confirm(32);
      rig.provider.toggleThemeMode();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('Condition remains active'), findsOneWidget);
    },
  );
  testWidgets('critical to extreme updates the same visible dialog', (
    tester,
  ) async {
    final rig = TemperatureRig();
    await tester.pumpWidget(rig.host());
    rig.confirm(32);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    final id = rig.provider.activeTemperatureAlert!.id;
    rig.read(36);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('DEMO • EXTREME HEAT DETECTED'),
      ),
      findsOneWidget,
    );
    expect(rig.provider.activeTemperatureAlert!.id, id);
    expect(
      rig.provider.alerts.where((a) => a.isTemperatureAlert),
      hasLength(1),
    );
  });
  testWidgets(
    'popup works while History is visible and View Alerts opens the alert screen',
    (tester) async {
      final rig = TemperatureRig();
      await tester.pumpWidget(rig.host(home: const HistoryScreen()));
      rig.confirm(32);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'View Alerts'));
      await tester.pumpAndSettle();
      expect(
        find.text('System Diagnostics & Alerts').hitTestable(),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(rig.provider.activeTemperatureAlert!.isResolved, isFalse);
      rig.read(32);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
  testWidgets(
    'sensor errors and stale data leave critical conditions active until valid recovery',
    (tester) async {
      final rig = TemperatureRig();
      await tester.pumpWidget(rig.host());
      rig.confirm(32);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Acknowledge'));
      await tester.pumpAndSettle();
      rig.read(0, error: true);
      await tester.pumpAndSettle();
      expect(rig.provider.activeTemperatureAlert, isNotNull);
      expect(
        find.textContaining('Current Air Temperature: Unavailable'),
        findsOneWidget,
      );
      rig.now = rig.now.add(const Duration(seconds: 40));
      await tester.pump(const Duration(seconds: 1));
      expect(rig.provider.activeTemperatureAlert!.isResolved, isFalse);
      rig.confirm(24);
      await tester.pumpAndSettle();
      expect(rig.provider.activeTemperatureAlert, isNull);
      expect(
        find.text('DEMO • TEMPERATURE RETURNED TO NORMAL'),
        findsNWidgets(2),
      );
      expect(
        rig.provider.alerts
            .where((a) => a.isTemperatureAlert)
            .single
            .isResolved,
        isTrue,
      );
    },
  );
  testWidgets(
    'demo incidents never send production requests and switching sources clears them',
    (tester) async {
      final firebase = TemperatureFirebaseFixture();
      final rig = TemperatureRig(firebase: firebase);
      await tester.pumpWidget(rig.host());
      rig.read(36);
      await tester.pumpAndSettle();
      expect(firebase.requests, isEmpty);
      rig.provider.toggleDemoMode(false);
      await tester.pumpAndSettle();
      expect(rig.provider.alerts.where((a) => a.isDemo), isEmpty);
      expect(rig.provider.activeTemperatureAlert, isNull);
      expect(firebase.events, isEmpty);
      expect(() => rig.provider.setDemoAirTemperature(36), throwsStateError);
    },
  );
  testWidgets(
    'unsynchronized production events warn locally then persist on retry',
    (tester) async {
      final firebase = TemperatureFirebaseFixture()..offline = true;
      final rig = TemperatureRig(demo: false, firebase: firebase);
      await tester.pumpWidget(rig.host());
      rig.read(36);
      await tester.pumpAndSettle();
      expect(
        rig.provider.activeTemperatureAlert!.temperatureLevel,
        TemperatureLevel.extreme,
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(rig.provider.temperatureSyncError, isNotNull);
      firebase.offline = false;
      await rig.provider.syncTemperatureAlerts();
      await tester.pumpAndSettle();
      expect(firebase.events, hasLength(1));
      expect(rig.provider.temperatureSyncError, isNull);
      expect(rig.provider.hasPendingTemperatureSync, isFalse);
    },
  );
  testWidgets('popup is responsive on a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rig = TemperatureRig();
    await tester.pumpWidget(rig.host(home: const HistoryScreen()));
    rig.read(36);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Acknowledge').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Dashboard updates when readings arrive while Settings is selected',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rig = TemperatureRig();
      await tester.pumpWidget(rig.host(home: const DashboardScreen()));
      tester
          .widget<LettuceGuardBottomNav>(find.byType(LettuceGuardBottomNav))
          .onTap(3);
      await tester.pump();
      rig.confirm(32);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Acknowledge'));
      await tester.pumpAndSettle();
      tester
          .widget<LettuceGuardBottomNav>(find.byType(LettuceGuardBottomNav))
          .onTap(0);
      await tester.pump();
      expect(
        find.text('DEMO • CRITICAL HEAT ALERT').hitTestable(),
        findsOneWidget,
      );
      expect(rig.provider.unresolvedAlertsCount, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );
}
