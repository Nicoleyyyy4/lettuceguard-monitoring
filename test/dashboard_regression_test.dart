import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lettuceguard/providers/sensor_provider.dart';
import 'package:lettuceguard/screens/dashboard_screen.dart';
import 'package:lettuceguard/screens/settings_screen.dart';
import 'package:lettuceguard/widgets/bottom_nav.dart';
import 'history_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    // Auth creates event subscriptions when instantiated; these tests don't log in.
    for (final stream in ['auth-state', 'id-token']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            MethodChannel('plugins.flutter.io/firebase_auth/$stream/[DEFAULT]'),
            (_) async => null,
          );
    }
  });

  testWidgets(
    'dashboard, alerts, history, and settings navigation remain usable',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = SensorProvider(initialEsp32Url: '');
      await tester.pumpWidget(historyHost(provider, const DashboardScreen()));
      expect(find.text('LettuceGuard'), findsOneWidget);
      expect(find.text('TDS (Nutrient)'), findsOneWidget);
      final nav = tester.widget<LettuceGuardBottomNav>(
        find.byType(LettuceGuardBottomNav),
      );
      nav.onTap(1);
      await tester.pump();
      expect(
        find.text('Historical Parameter Trends').hitTestable(),
        findsOneWidget,
      );
      nav.onTap(2);
      await tester.pump();
      expect(
        find.text('All Hardware Sensors Operational').hitTestable(),
        findsOneWidget,
      );
      nav.onTap(3);
      await tester.pump();
      expect(
        find.text('System Configuration & Diagnostics').hitTestable(),
        findsOneWidget,
      );
      provider.toggleThemeMode();
      await tester.pump();
      expect(provider.isDarkMode, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('settings demo switch clears simulated history for production', (
    tester,
  ) async {
    final provider = SensorProvider(
      initialEsp32Url: '',
      firebaseService: fixtureService(null),
    );
    await tester.pumpWidget(historyHost(provider, const SettingsScreen()));
    final toggle = find.widgetWithText(
      SwitchListTile,
      'Hardware Simulation / Demo Mode',
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(provider.isDemoMode, isFalse);
    expect(provider.history, isEmpty);
    expect(provider.currentData.hasValidTds, isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(provider.isDemoMode, isTrue);
    expect(provider.history, isNotEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'production dashboard waits for device data without retaining mock values',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = SensorProvider(
        initialEsp32Url: '',
        firebaseService: fixtureService(null),
        initialDemoMode: false,
      );
      await tester.pumpWidget(historyHost(provider, const DashboardScreen()));
      await tester.pump();
      expect(
        find
            .text(
              'Waiting for live ESP32 readings. Check the device connection.',
            )
            .hitTestable(),
        findsOneWidget,
      );
      expect(find.text('NaN'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
