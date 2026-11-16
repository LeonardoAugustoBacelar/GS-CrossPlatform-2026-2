import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/preferences_provider.dart';
import '../../core/utils/formatters.dart';
import '../alerts/domain/territory_alert.dart';
import '../settings/application/settings_controller.dart';

/// Notificações locais para alertas **críticos**. Cada alerta notifica uma
/// vez só. A notificação informa; a decisão continua sendo humana.
class AlertNotifier {
  AlertNotifier(this._prefs, this._isEnabled, {this.onOpenAlert});

  final SharedPreferences _prefs;
  final bool Function() _isEnabled;

  /// Chamado ao tocar na notificação, com o id do alerta.
  void Function(String alertId)? onOpenAlert;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _sentKey = 'notifications.sent';
  static const _channel = AndroidNotificationDetails(
    'alertas_criticos',
    'Alertas críticos',
    channelDescription: 'Alertas de nível crítico do território',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> _init() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = response.payload;
        if (id != null) onOpenAlert?.call(id);
      },
    );
    _initialized = true;
  }

  /// Pede permissão ao sistema. Retorna se as notificações foram liberadas.
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  Future<void> notifyCritical(List<TerritoryAlert> alerts) async {
    if (!_isEnabled()) return;
    final sent = {...?_prefs.getStringList(_sentKey)};
    final pending = alerts.where(
      (a) => a.severity == AlertSeverity.high && !sent.contains(a.id),
    );
    if (pending.isEmpty) return;
    await _init();
    for (final alert in pending) {
      await _plugin.show(
        id: alert.id.hashCode & 0x7fffffff,
        title: 'Alerta crítico: ${alert.title}',
        body:
            '${alert.summary} Confiança '
            '${alert.confidenceLevel.label.toLowerCase()} '
            '(${Fmt.percent(alert.confidence)}). A decisão é sua.',
        notificationDetails: const NotificationDetails(
          android: _channel,
          iOS: DarwinNotificationDetails(),
        ),
        payload: alert.id,
      );
      sent.add(alert.id);
    }
    await _prefs.setStringList(_sentKey, sent.toList());
  }
}

final alertNotifierProvider = Provider<AlertNotifier>(
  (ref) => AlertNotifier(
    ref.watch(sharedPreferencesProvider),
    () => ref.read(settingsProvider).notificationsEnabled,
  ),
);
