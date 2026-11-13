// Base de datos local (Drift sobre SQLite). 100% offline.
// Regenerar el código con:  dart run build_runner build --delete-conflicting-outputs
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Cómo se repite la toma del medicamento.
enum TipoFrecuencia { cadaXHoras, vecesAlDia }

/// Estado decidido de una toma. "Pendiente" no existe en la tabla:
/// una toma sin registro está pendiente por definición.
enum EstadoToma { tomada, omitida }

/// Perfiles de pacientes (abuelo, abuela, hijo en tratamiento, etc.).
class Perfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().withLength(min: 1, max: 60)();
  // Ruta local de la foto opcional (image_picker). Null = sin foto.
  TextColumn get fotoPath => text().nullable()();
  IntColumn get edad => integer().nullable()();
  DateTimeColumn get creadoEn => dateTime().withDefault(currentDateAndTime)();
}

/// Medicamentos asociados a un perfil.
class Medicamentos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get perfilId => integer().references(Perfiles, #id)();
  TextColumn get nombre => text().withLength(min: 1, max: 80)();
  // Texto libre: "500 mg", "1 comprimido", "2 inhalaciones"...
  TextColumn get dosis => text().withLength(min: 1, max: 60)();
  // Nota: intEnum devuelve un ColumnBuilder que debe invocarse ()().
  IntColumn get tipoFrecuencia => intEnum<TipoFrecuencia>()();
  // Cada X horas (ej. cada 8 h). Solo si tipoFrecuencia == cadaXHoras.
  IntColumn get intervaloHoras => integer().nullable()();
  // X veces al día (ej. 3 veces). Solo si tipoFrecuencia == vecesAlDia.
  IntColumn get vecesPorDia => integer().nullable()();
  DateTimeColumn get fechaInicio => dateTime()();
  // Null = tratamiento indefinido.
  DateTimeColumn get fechaFin => dateTime().nullable()();
  TextColumn get notas => text().nullable()();
  // Borrado lógico: los tratamientos terminados no se eliminan (historial/PDF).
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
}

/// Horarios de toma de un medicamento.
/// minutosDelDia (0-1439) en vez de TimeOfDay: inmune a cambios de hora (DST).
/// diasSemana como bitmask: bit 0 = lunes ... bit 6 = domingo. 127 = todos.
class Horarios extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicamentoId => integer().references(Medicamentos, #id)();
  IntColumn get minutosDelDia => integer()();
  IntColumn get diasSemana => integer().withDefault(const Constant(127))();
}

/// Registro de estado de una toma ya decidida.
/// Único compuesto (medicamentoId, fechaProgramada): evita duplicados.
class Tomas extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicamentoId => integer().references(Medicamentos, #id)();
  DateTimeColumn get fechaProgramada => dateTime()();
  IntColumn get estado => intEnum<EstadoToma>()();
  // Momento real en que el usuario respondió (para el reporte PDF).
  DateTimeColumn get respondidaEn => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {medicamentoId, fechaProgramada},
      ];
}

@DriftDatabase(tables: [Perfiles, Medicamentos, Horarios, Tomas])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_abrirConexion());

  // Versión para migraciones futuras: incrementar y escribir en onUpgrade.
  @override
  int get schemaVersion => 1;

  static LazyDatabase _abrirConexion() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final archivo = File(p.join(dir.path, 'pastillero.sqlite'));
      return NativeDatabase.createInBackground(archivo);
    });
  }
}

// Provider global de la base de datos (se sobreescribe en main.dart).
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Se inicializa en main() con overrideWithValue');
});
