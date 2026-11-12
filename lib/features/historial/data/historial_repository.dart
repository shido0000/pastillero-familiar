// Repositorio del historial: reconstruye los slots de un rango de fechas
// (reutilizando el motor de tomas) y calcula la adherencia.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../tomas/domain/motor_tomas.dart';

/// Resumen de un día del historial.
class DiaHistorial {
  final DateTime fecha;
  final List<SlotToma> slots;
  DiaHistorial({required this.fecha, required this.slots});

  int get tomadas => slots.where((s) => s.estado == EstadoToma.tomada).length;
  int get omitidas => slots.where((s) => s.estado == EstadoToma.omitida).length;
  int get vencidasPendientes =>
      slots.where((s) => s.estaPendiente && s.yaPaso).length;
  int get completadas => tomadas;
}

/// Resumen de un periodo completo (semana o mes).
class ResumenHistorial {
  final List<DiaHistorial> dias;
  final List<Medicamento> medicamentos;
  ResumenHistorial({required this.dias, required this.medicamentos});

  int get totalProgramadas => dias.fold(0, (a, d) => a + d.slots.length);
  int get totalTomadas => dias.fold(0, (a, d) => a + d.tomadas);
  int get totalOmitidas => dias.fold(0, (a, d) => a + d.omitidas);
  int get totalVencidas => dias.fold(0, (a, d) => a + d.vencidasPendientes);

  /// % de adherencia: tomas cumplidas entre las tomas que ya debieron
  /// ocurrir (excluye las que aún están por llegar). Null = sin datos.
  double? get adherencia {
    final base = totalTomadas + totalOmitidas + totalVencidas;
    if (base == 0) return null;
    return totalTomadas / base;
  }
}

class HistorialRepository {
  HistorialRepository(this._db);
  final AppDatabase _db;

  Future<ResumenHistorial> resumen({
    required int perfilId,
    required DateTime inicio,
    required DateTime fin,
  }) async {
    // Medicamentos activos del perfil en el periodo.
    final meds = await (_db.select(_db.medicamentos)
          ..where((m) => m.perfilId.equals(perfilId) & m.activo.equals(true)))
        .get();

    // Registros de tomas del periodo (join con medicamentos para filtrar perfil).
    final registros = await (_db.select(_db.tomas).join([
      innerJoin(_db.medicamentos,
          _db.medicamentos.id.equalsExp(_db.tomas.medicamentoId)),
    ])
          ..where(_db.medicamentos.perfilId.equals(perfilId) &
              _db.tomas.fechaProgramada.isBetweenValues(inicio, fin)))
        .get()
        .then((rows) => rows.map((r) => r.readTable(_db.tomas)).toList());

    // Horarios por medicamento.
    final horariosPorMedicamento = <int, List<Horario>>{};
    for (final med in meds) {
      horariosPorMedicamento[med.id] = await (_db.select(_db.horarios)
            ..where((h) => h.medicamentoId.equals(med.id)))
          .get();
    }

    // Reconstruimos día por día con el mismo motor de la pantalla "Hoy".
    final dias = <DiaHistorial>[];
    var dia = DateTime(inicio.year, inicio.month, inicio.day);
    final finDia = DateTime(fin.year, fin.month, fin.day);
    while (!dia.isAfter(finDia)) {
      final slots = calcularSlotsDelDia(
        medicamentos: meds,
        horariosPorMedicamento: horariosPorMedicamento,
        registros: registros,
        dia: dia,
      );
      dias.add(DiaHistorial(fecha: dia, slots: slots));
      dia = dia.add(const Duration(days: 1));
    }

    return ResumenHistorial(dias: dias, medicamentos: meds);
  }
}

final historialRepositoryProvider = Provider<HistorialRepository>(
    (ref) => HistorialRepository(ref.watch(databaseProvider)));
