import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lettuceguard/models/chart_parameter.dart';
import 'package:lettuceguard/models/sensor_model.dart';
import 'package:lettuceguard/screens/history_screen.dart';
import 'package:lettuceguard/widgets/chart_widget.dart';
import 'history_test_helpers.dart';

void main() {
  for (final param in ChartParameter.values) {
    testWidgets(
      '${param.chipLabel} drives chart, title, and primary log value',
      (tester) async {
        final record = SensorData.fromJson(readingJson());
        final provider = HistoryFixture([record]);
        await tester.pumpWidget(historyHost(provider, const HistoryScreen()));
        await selectParameter(tester, param.name);
        expect(find.text(param.chartTitle), findsOneWidget);
        expect(
          find.text('Recent Activity Log • ${param.title}'),
          findsOneWidget,
        );
        final primary = tester.widget<Text>(
          find.byKey(const ValueKey('activity-reading-0')),
        );
        final expected = {
          ChartParameter.ph: 'pH: 6.06',
          ChartParameter.waterTemp: 'Water Temperature: 20.6°C',
          ChartParameter.airTemp: 'Air Temperature: 23.6°C',
          ChartParameter.humidity: 'Humidity: 64%',
          ChartParameter.waterLevel: 'Water Level: 90%',
          ChartParameter.tds: 'TDS: 723 ppm',
        };
        expect(primary.data, expected[param]);
        expect(
          tester
              .widget<ChartWidget>(find.byType(ChartWidget))
              .selectedParameter,
          param,
        );
        expect(
          tester
              .widget<FilterChip>(
                find.byKey(ValueKey('parameter-${param.name}')),
              )
              .selected,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'repeated switching and asynchronous history updates rebuild the log',
    (tester) async {
      final provider = HistoryFixture([SensorData.fromJson(readingJson())]);
      await tester.pumpWidget(historyHost(provider, const HistoryScreen()));
      for (final name in [
        'waterTemp',
        'tds',
        'airTemp',
        'humidity',
        'ph',
        'waterLevel',
        'tds',
      ]) {
        await selectParameter(tester, name);
        expect(
          tester
              .widget<ChartWidget>(find.byType(ChartWidget))
              .selectedParameter
              .name,
          name,
        );
      }
      provider.replace([SensorData.fromJson(readingJson(tds: 811))]);
      await tester.pump();
      expect(find.text('TDS: 811 ppm'), findsOneWidget);
      expect(find.text('pH: 6.06'), findsNothing);
      expect(find.textContaining('Demo history'), findsOneWidget);
    },
  );

  testWidgets('empty history remains friendly for all parameters', (
    tester,
  ) async {
    final provider = HistoryFixture([]);
    await tester.pumpWidget(historyHost(provider, const HistoryScreen()));
    for (final param in ChartParameter.values) {
      await selectParameter(tester, param.name);
      expect(find.text('No historical records available.'), findsOneWidget);
      expect(
        find.text('No activity yet. Historical readings will appear here.'),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'missing, negative, and flagged TDS show unavailable and no chart zero',
    (tester) async {
      final missing = readingJson()..remove('tds');
      final invalid = readingJson(tds: -1);
      final flagged = readingJson(tds: 0)
        ..['sensorErrors'] = {'tdsError': true};
      final provider = HistoryFixture(
        [missing, invalid, flagged].map(SensorData.fromJson).toList(),
      );
      await tester.pumpWidget(historyHost(provider, const HistoryScreen()));
      await selectParameter(tester, 'tds');
      expect(find.text('TDS: Unavailable'), findsNWidgets(3));
      expect(find.text('TDS: 0 ppm'), findsNothing);
      expect(
        find.text('No valid TDS (Nutrients) measurements available.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'valid TDS plots, inspection matches value and timestamp, newest is first',
    (tester) async {
      final old = DateTime(2026, 11, 23, 8, 9);
      final recent = old.add(const Duration(minutes: 1));
      final provider = HistoryFixture([
        SensorData.fromJson(readingJson(tds: 715, time: old)),
        SensorData.fromJson(readingJson(tds: 720, time: recent)),
      ]);
      await tester.pumpWidget(historyHost(provider, const HistoryScreen()));
      await selectParameter(tester, 'tds');
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('activity-reading-0')))
            .data,
        'TDS: 720 ppm',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('activity-reading-1')))
            .data,
        'TDS: 715 ppm',
      );
      final plot = find.byKey(const ValueKey('history-chart-plot'));
      await tester.ensureVisible(plot);
      await tester.tapAt(tester.getTopRight(plot) + const Offset(-2, 80));
      await tester.pump();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('chart-inspection')))
            .data,
        '${historyTimestamp(recent)} • TDS: 720 ppm',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mobile layout distinguishes 15 visible entries from 20 loaded', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = HistoryFixture(
      List.generate(
        20,
        (i) => SensorData.fromJson(
          readingJson(time: DateTime(2026, 11, 23, 8, i)),
        ),
      ),
    );
    await tester.pumpWidget(historyHost(provider, const HistoryScreen()));
    await selectParameter(tester, 'tds');
    expect(
      find.textContaining('Showing 15 of 20 loaded entries'),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNWidgets(15));
    expect(tester.takeException(), isNull);
  });
}
