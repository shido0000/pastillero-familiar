// Servicio de notificaciones locales. Funciona con la app cerrada.
// Acciones "Tomado"/"Omitir" desde la propia notificación.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';

/// Función de nivel superior: el sistema la invoca en un isolate aparte
/// cuando el usuario toca una acción con la app cerrada.
@pragma('vm:entry-point')
Future<void> alResponderEnSegundoPlano(NotificationResponse respuesta) async {
  await _procesarAccion(respuesta);
}

/// Procesa "Tomado"/"Omitir": escribe el estado directamente en SQLite.
/// En segundo plano creamos nuestra propia conexión a la base de datos.
Future<void> _procesarAccion(NotificationResponse respuesta) async {
  if (respuesta.payload == null) return;
  final accion = respuesta.actionId; // 'tomado' | 'omitir' | null (toque simple)
  if (accion == null) return; // toque simple: solo abre la app, no decide

  final data = jsonDecode(respuesta.payload!) as Map<String, dynamic>;
  final medicamentoId = data['medicamentoId'] as int;
  final fechaProgramada = DateTime.parse(data['fecha'] as String);
  final estado = accion == 'tomado' ? EstadoToma.tomada : EstadoToma.omitida;

  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  await db.into(db.tomas).insertOnConflictUpdate(
        TomasCompanion.insert(
          medicamentoId: medicamentoId,
          fechaProgramada: fechaProgramada,
          estado: estado,
          respondidaEn: Value(DateTime.now()),
        ),
      );
  await db.close();
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> inicializar() async {
    // 1. Zona horaria del dispositivo (clave para programar a la hora local).
    tzdata.initializeTimeZones();
    final zona = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zona));

    // 2. Inicialización por plataforma.
    const ajustesAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ajustesIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: ajustesAndroid, iOS: ajustesIOS),
      onDidReceiveNotificationResponse: _alResponderEnPrimerPlano,
      onDidReceiveBackgroundNotificationResponse: alResponderEnSegundoPlano,
    );

    // 3. Permisos (Android 13+ exige POST_NOTIFICATIONS en tiempo de ejecución).
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Android 12+: permiso de alarma exacta. Si el usuario lo rechaza,
  /// las notificaciones caen a modo inexacto (pueden atrasar unos minutos).
  Future<void> pedirPermisoAlarmaExacta() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  /// Programa un recordatorio a una fecha/hora concreta.
  Future<void> programarRecordatorio({
    required int id,
    required String titulo,
    required String cuerpo,
    required DateTime fecha,
    required String payload,
  }) async {
    if (fecha.isBefore(DateTime.now())) return; // ya pasó: no programar

    final android = AndroidNotificationDetails(
      'recordatorios',
      'Recordatorios de medicación',
      channelDescription: 'Avisos a la hora de cada toma',
      importance: Importance.max,
      priority: Priority.high,
      actions: const [
        AndroidNotificationAction('tomado', 'Tomado'),
        AndroidNotificationAction('omitir', 'Omitir'),
      ],
    );
    const ios = DarwinNotificationDetails(categoryIdentifier: 'recordatorio');

    final detalles = NotificationDetails(android: android, iOS: ios);
    final fechaTz = tz.TZDateTime.from(fecha, tz.local);

    try {
      // Alarma exacta (ideal para medicación).
      await _plugin.zonedSchedule(
        id, titulo, cuerpo, fechaTz, detalles,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (_) {
      // Sin permiso de alarma exacta: caída a modo inexacto (la app sigue útil).
      await _plugin.zonedSchedule(
        id, titulo, cuerpo, fechaTz, detalles,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  Future<void> cancelarTodas() => _plugin.cancelAll();

  void _alResponderEnPrimerPlano(NotificationResponse respuesta) {
    // Con la app abierta también registramos la acción elegida.
    _procesarAccion(respuesta);
  }
}

// Provider global del servicio (se sobreescribe en main.dart).
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('Se inicializa en main() con overrideWithValue');
});
