// Repositorio de perfiles: CRUD con borrado en cascada manual
// y validación del límite de la versión gratuita.
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config.dart';
import '../../../core/database/app_database.dart';

/// Superado el límite de perfiles de la versión gratuita.
class LimitePerfilesException implements Exception {
  final int maximo;
  LimitePerfilesException(this.maximo);
}

class PerfilRepository {
  PerfilRepository(this._db);
  final AppDatabase _db;

  Stream<List<Perfil>> observarTodos() {
    return (_db.select(_db.perfiles)
          ..orderBy([(p) => OrderingTerm.asc(p.nombre)]))
        .watch();
  }

  Future<Perfil> crearPerfil({
    required String nombre,
    required bool esPro,
    int? edad,
    String? fotoPath,
  }) async {
    // Límite de 2 perfiles en la versión gratuita (validado aquí, no en la UI).
    if (!esPro) {
      final total = (await _db.select(_db.perfiles).get()).length;
      if (total >= kMaxPerfilesGratis) {
        throw LimitePerfilesException(kMaxPerfilesGratis);
      }
    }
    final id = await _db.into(_db.perfiles).insert(
          PerfilesCompanion.insert(
            nombre: nombre,
            edad: Value(edad),
            fotoPath: Value(fotoPath),
          ),
        );
    return Perfil(
      id: id,
      nombre: nombre,
      fotoPath: fotoPath,
      edad: edad,
      creadoEn: DateTime.now(),
    );
  }

  Future<void> actualizarPerfil(Perfil perfil) {
    return (_db.update(_db.perfiles)..where((p) => p.id.equals(perfil.id))).write(
      PerfilesCompanion(
        nombre: Value(perfil.nombre),
        edad: Value(perfil.edad),
        fotoPath: Value(perfil.fotoPath),
      ),
    );
  }

  /// Borrado en cascada manual: tomas -> horarios -> medicamentos -> perfil.
  Future<void> eliminarPerfil(int perfilId) {
    return _db.transaction(() async {
      final meds = await (_db.select(_db.medicamentos)
            ..where((m) => m.perfilId.equals(perfilId)))
          .get();
      for (final med in meds) {
        await (_db.delete(_db.tomas)..where((t) => t.medicamentoId.equals(med.id))).go();
        await (_db.delete(_db.horarios)..where((h) => h.medicamentoId.equals(med.id))).go();
      }
      await (_db.delete(_db.medicamentos)..where((m) => m.perfilId.equals(perfilId))).go();
      await (_db.delete(_db.perfiles)..where((p) => p.id.equals(perfilId))).go();
    });
  }
}

final perfilRepositoryProvider =
    Provider<PerfilRepository>((ref) => PerfilRepository(ref.watch(databaseProvider)));

/// Stream reactivo de todos los perfiles.
final perfilesStreamProvider = StreamProvider<List<Perfil>>(
    (ref) => ref.watch(perfilRepositoryProvider).observarTodos());
