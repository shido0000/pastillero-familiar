import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/programador_recordatorios.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Base de datos local, 100% offline.
  final db = AppDatabase();

  // 2. Notificaciones locales.
  final notificaciones = NotificationService();
  await notificaciones.inicializar();

  // 3. Reprogramación al arrancar: recupera recordatorios perdidos
  //    (reinicio del teléfono, app cerrada varios días, cambio de hora).
  final programador = ProgramadorRecordatorios(db, notificaciones);
  await programador.reprogramarTodo();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(notificaciones),
      ],
      child: const PastilleroApp(),
    ),
  );
}
