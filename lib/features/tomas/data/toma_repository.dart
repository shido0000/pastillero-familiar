// Repositorio de tomas: registra el estado decidido de cada slot.
// "Pendiente" no se guarda: es la ausencia de registro.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

class TomaRepository {
  TomaRepository(this._db);
  final AppDatabase _db;

  /// Observa en vivo los registros del día para un perfil
  /// (join con medicamentos para filtrar por perfil).
  Stream<List<Toma>> observarDelDia(int perfilId, DateTime dia) {
    final inicio = DateTime(dia.year, dia.month, dia.day);
    final fin = inicio.add(const Duration(days: 1));

    final query = _db.select(_db.tomas).join([
      innerJoin(_db.medicamentos,
          _db.medicamentos.id.equalsExp(_db.tomas.medicamentoId)),
    ]);
    query.where(_db.medicamentos.perfilId.equals(perfilId) &
        _db.tomas.fechaProgramada.isBetweenValues(inicio, fin));
    return query
        .watch()
        .map((rows) => rows.map((r) => r.readTable(_db.tomas)).toList());
  }

  /// Marca una toma (tomada u omitida). Si ya existía registro, lo actualiza.
  Future<void> marcar({
    required int medicamentoId,
    required DateTime fechaProgramada,
    required EstadoToma estado,
  }) {
    return _db.into(_db.tomas).insertOnConflictUpdate(
          TomasCompanion.insert(
            medicamentoId: medicamentoId,
            fechaProgramada: fechaProgramada,
            estado: estado,
            respondidaEn: Value(DateTime.now()),
          ),
        );
  }

  /// Deshace una decisión: la toma vuelve a "pendiente".
  Future<void> desmarcar({
    required int medicamentoId,
    required DateTime fechaProgramada,
  }) {
    return (_db.delete(_db.tomas)
          ..where((t) =>
              t.medicamentoId.equals(medicamentoId) &
              t.fechaProgramada.equals(fechaProgramada)))
        .go();
  }
}

final tomaRepositoryProvider =
    Provider<TomaRepository>((ref) => TomaRepository(ref.watch(databaseProvider)));
