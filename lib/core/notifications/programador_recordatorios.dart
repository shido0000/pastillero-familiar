// Reprogramador: calcula los slots de los próximos 7 días y programa
// una notificación por cada uno. Se ejecuta al abrir la app y tras
// crear o modificar medicamentos — así el teléfono "recupera" lo que
// se perdió si estuvo apagado.
import 'dart:convert';

import '../../features/tomas/domain/motor_tomas.dart';
import '../database/app_database.dart';
import 'notification_service.dart';

class ProgramadorRecordatorios {
  ProgramadorRecordatorios(this._db, this._notificaciones);

  static const int _diasPorDelante = 7;

  final AppDatabase _db;
  final NotificationService _notificaciones;

  Future<void> reprogramarTodo() async {
    await _notificaciones.cancelarTodas();
    final ahora = DateTime.now();

    final perfiles = await _db.select(_db.perfiles).get();
    for (final perfil in perfiles) {
      final meds = await (_db.select(_db.medicamentos)
            ..where((m) => m.perfilId.equals(perfil.id) & m.activo.equals(true)))
          .get();

      for (final med in meds) {
        final horarios = await (_db.select(_db.horarios)
              ..where((h) => h.medicamentoId.equals(med.id)))
            .get();

        for (var d = 0; d < _diasPorDelante; d++) {
          final dia =
              DateTime(ahora.year, ahora.month, ahora.day).add(Duration(days: d));
          final slots = calcularSlotsDelDia(
            medicamentos: [med],
            horariosPorMedicamento: {med.id: horarios},
            registros: const [],
            dia: dia,
          );

          for (final slot in slots) {
            if (slot.fechaProgramada.isBefore(ahora)) continue;
            await _notificaciones.programarRecordatorio(
              id: idNotificacion(med.id, slot.fechaProgramada),
              titulo: 'Hora de: ' + med.nombre,
              cuerpo: med.dosis + ' — ' + perfil.nombre,
              fecha: slot.fechaProgramada,
              payload: jsonEncode({
                'medicamentoId': med.id,
                'fecha': slot.fechaProgramada.toIso8601String(),
              }),
            );
          }
        }
      }
    }
  }

  /// ID determinista y estable por (medicamento, minuto): permite
  /// reprogramar sin duplicar la misma toma.
  int idNotificacion(int medicamentoId, DateTime fecha) =>
      (medicamentoId * 100000000 + fecha.millisecondsSinceEpoch ~/ 60000) %
      2147483647;
}
