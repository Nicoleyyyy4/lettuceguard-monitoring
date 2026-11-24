import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../models/temperature_level.dart';
import '../models/chart_parameter.dart' show historyTimestamp;
import '../providers/sensor_provider.dart';
import '../utils/routes.dart';
import 'temperature_alert_banner.dart';

/// One foreground-only presenter above all application routes.
class TemperatureAlertHost extends StatefulWidget {
  const TemperatureAlertHost({
    super.key,
    required this.provider,
    required this.navigatorKey,
    required this.child,
    this.onViewAlerts,
  });
  final SensorProvider provider;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  final VoidCallback? onViewAlerts;
  @override
  State<TemperatureAlertHost> createState() => _TemperatureAlertHostState();
}

class _TemperatureAlertHostState extends State<TemperatureAlertHost>
    with WidgetsBindingObserver {
  DialogRoute<void>? _route;
  bool _scheduled = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  final Set<String> _shown = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    widget.provider.addListener(_schedule);
    _schedule();
  }

  @override
  void didUpdateWidget(TemperatureAlertHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      oldWidget.provider.removeListener(_schedule);
      widget.provider.addListener(_schedule);
    }
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _schedule();
  }

  void _schedule() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final provider = widget.provider;
      final event = provider.activeTemperatureAlert;
      final navigator = widget.navigatorKey.currentState;
      if (_route != null) {
        if (_lifecycle != AppLifecycleState.resumed ||
            event == null ||
            (event.temperatureLevel?.priority ?? 0) <
                TemperatureLevel.critical.priority ||
            event.isAcknowledged) {
          if (_route!.isActive) navigator?.removeRoute(_route!);
          _route = null;
        } else if (event.presentedPriority < event.peakPriority) {
          _shown.add(event.popupToken);
          provider.markTemperaturePopupPresented(event.id, event.peakPriority);
        }
        return;
      }
      if (_lifecycle != AppLifecycleState.resumed ||
          navigator == null ||
          event == null ||
          !provider.temperatureReadyForPopup ||
          !event.needsPopup ||
          _shown.contains(event.popupToken)) {
        return;
      }
      _shown.add(event.popupToken);
      provider.markTemperaturePopupPresented(event.id, event.peakPriority);
      final route = DialogRoute<void>(
        context: navigator.overlay!.context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: _TemperatureDialog(
            provider: provider,
            acknowledge: (alert) {
              provider.acknowledgeTemperatureAlert(
                alert.id,
                priority: alert.peakPriority,
              );
              _close();
            },
            viewAlerts: () {
              _close();
              if (widget.onViewAlerts != null) {
                widget.onViewAlerts!();
              } else {
                navigator.pushNamed(LettuceGuardRoutes.alerts);
              }
            },
          ),
        ),
      );
      _route = route;
      navigator.push(route).whenComplete(() {
        if (_route == route) _route = null;
      });
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _close() {
    final route = _route;
    _route = null;
    if (route?.isActive == true) {
      widget.navigatorKey.currentState?.removeRoute(route!);
    }
  }

  @override
  void dispose() {
    widget.provider.removeListener(_schedule);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TemperatureDialog extends StatelessWidget {
  const _TemperatureDialog({
    required this.provider,
    required this.acknowledge,
    required this.viewAlerts,
  });
  final SensorProvider provider;
  final ValueChanged<AlertModel> acknowledge;
  final VoidCallback viewAlerts;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: provider,
    builder: (context, _) {
      final event = provider.activeTemperatureAlert;
      if (event == null) return const SizedBox.shrink();
      final color = temperatureAlertColor(event.temperatureLevel!);
      final sensorLabel = event.isWaterTemperatureAlert ? 'Water' : 'Air';
      return AlertDialog(
        key: const ValueKey('temperature-alert-dialog'),
        backgroundColor: Colors.white,
        icon: Icon(Icons.warning_amber_rounded, color: color, size: 36),
        title: Text(
          '${event.isDemo ? 'DEMO • ' : ''}${event.title}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event $sensorLabel Temperature: ${event.measuredTemperature!.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                event.isWaterTemperatureAlert
                    ? event.message
                    : event.temperatureLevel!.action,
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Sensor reading: ${historyTimestamp(event.readingTimestamp!)}',
                style: const TextStyle(color: Colors.black54),
              ),
              if (!event.isWaterTemperatureAlert &&
                  provider.temperatureDataProblem != null)
                Text(
                  '${provider.temperatureDataProblem} Recovery is unconfirmed.',
                  style: TextStyle(color: color),
                ),
              if (provider.temperatureSyncError != null)
                Text(
                  provider.temperatureSyncError!,
                  style: TextStyle(color: color),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: viewAlerts, child: const Text('View Alerts')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => acknowledge(event),
            child: const Text('Acknowledge'),
          ),
        ],
      );
    },
  );
}
