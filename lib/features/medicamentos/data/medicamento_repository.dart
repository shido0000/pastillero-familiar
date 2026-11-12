// Repositorio de medicamentos: crea el medicamento y sus horarios
// de forma atómica (transacción).
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';

class MedicamentoRepository {
  MedicamentoRepository(this._db);
  final AppDatabase _db;

  Stream<List<Medicamento>> observarPorPerfil(int perfilId) {
    return (_db.select(_db.medicamentos)
          ..where((m) => m.perfilId.equals(perfilId) & m.activo.equals(true))
          ..orderBy([(m) => OrderingTerm.asc(m.nombre)]))
        .watch();
  }

  Future<int> crearMedicamento({
    required int perfilId,
    required String nombre,
    required String dosis,
    required TipoFrecuencia tipoFrecuencia,
    int? intervaloHoras,
    int? vecesPorDia,
    required List<int> minutosDelDia, // calculados en el formulario
    required DateTime fechaInicio,
    DateTime? fechaFin,
    String? notas,
  }) {
    return _db.transaction(() async {
      final id = await _db.into(_db.medicamentos).insert(
            MedicamentosCompanion.insert(
              perfilId: perfilId,
              nombre: nombre,
              dosis: dosis,
              tipoFrecuencia: tipoFrecuencia,
              intervaloHoras: Value(intervaloHoras),
              vecesPorDia: Value(vecesPorDia),
              fechaInicio: fechaInicio,
              fechaFin: Value(fechaFin),
              notas: Value(notas),
            ),
          );
      for (final minutos in minutosDelDia) {
        await _db.into(_db.horarios).insert(
              HorariosCompanion.insert(medicamentoId: id, minutosDelDia: minutos),
            );
      }
      return id;
    });
  }

  /// Horarios de un medicamento (lectura puntual para el motor de tomas).
  Future<List<Horario>> horariosDe(int medicamentoId) {
    return (_db.select(_db.horarios)
          ..where((h) => h.medicamentoId.equals(medicamentoId)))
        .get();
  }

  /// Lee un medicamento por su id (null si no existe).
  Future<Medicamento?> obtenerPorId(int id) {
    return (_db.select(_db.medicamentos)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  /// Fin de tratamiento: se desactiva pero se conserva (historial y PDF).
  Future<void> desactivar(int id) {
    return (_db.update(_db.medicamentos)..where((m) => m.id.equals(id)))
        .write(MedicamentosCompanion(activo: const Value(false)));
  }

  /// Borrado completo (cascada manual).
  Future<void> eliminar(int id) {
    return _db.transaction(() async {
      await (_db.delete(_db.tomas)..where((t) => t.medicamentoId.equals(id))).go();
      await (_db.delete(_db.horarios)..where((h) => h.medicamentoId.equals(id))).go();
      await (_db.delete(_db.medicamentos)..where((m) => m.id.equals(id))).go();
    });
  }
}

final medicamentoRepositoryProvider = Provider<MedicamentoRepository>(
    (ref) => MedicamentoRepository(ref.watch(databaseProvider)));

/// Stream de medicamentos de un perfil, con caché por perfilId.
final medicamentosPorPerfilProvider =
    StreamProvider.family<List<Medicamento>, int>(
        (ref, perfilId) => ref.watch(medicamentoRepositoryProvider).observarPorPerfil(perfilId));
