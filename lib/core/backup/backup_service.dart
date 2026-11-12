// Copia de seguridad local: exporta toda la base a JSON y la comparte
// como archivo (WhatsApp, correo, Drive...). Funciona sin nube.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/app_database.dart';

class BackupService {
  BackupService(this._db);
  final AppDatabase _db;

  Future<Map<String, dynamic>> exportarJson() async {
    return {
      'version': 1,
      'exportadoEn': DateTime.now().toIso8601String(),
      'perfiles': [
        for (final p in await _db.select(_db.perfiles).get())
          {
            'id': p.id,
            'nombre': p.nombre,
            'fotoPath': p.fotoPath,
            'edad': p.edad,
            'creadoEn': p.creadoEn.toIso8601String(),
          },
      ],
      'medicamentos': [
        for (final m in await _db.select(_db.medicamentos).get())
          {
            'id': m.id,
            'perfilId': m.perfilId,
            'nombre': m.nombre,
            'dosis': m.dosis,
            'tipoFrecuencia': m.tipoFrecuencia.index,
            'intervaloHoras': m.intervaloHoras,
            'vecesPorDia': m.vecesPorDia,
            'fechaInicio': m.fechaInicio.toIso8601String(),
            'fechaFin': m.fechaFin?.toIso8601String(),
            'notas': m.notas,
            'activo': m.activo,
          },
      ],
      'horarios': [
        for (final h in await _db.select(_db.horarios).get())
          {
            'id': h.id,
            'medicamentoId': h.medicamentoId,
            'minutosDelDia': h.minutosDelDia,
            'diasSemana': h.diasSemana,
          },
      ],
      'tomas': [
        for (final t in await _db.select(_db.tomas).get())
          {
            'id': t.id,
            'medicamentoId': t.medicamentoId,
            'fechaProgramada': t.fechaProgramada.toIso8601String(),
            'estado': t.estado.index,
            'respondidaEn': t.respondidaEn?.toIso8601String(),
          },
      ],
    };
  }

  Future<void> compartirBackup() async {
    final dir = await getTemporaryDirectory();
    final archivo = File(dir.path + '/backup_pastillero.json');
    await archivo.writeAsString(jsonEncode(await exportarJson()));
    await Share.shareXFiles([XFile(archivo.path)],
        text: 'Copia de seguridad de Pastillero Familiar');
  }

  /// Restaura un backup/snapshot. Borrado completo previo (transaccional).
  Future<void> restaurarDesdeJson(Map<String, dynamic> data) {
    return _db.transaction(() async {
      await _db.delete(_db.tomas).go();
      await _db.delete(_db.horarios).go();
      await _db.delete(_db.medicamentos).go();
      await _db.delete(_db.perfiles).go();

      for (final p in (data['perfiles'] as List).cast<Map<String, dynamic>>()) {
        await _db.into(_db.perfiles).insert(PerfilesCompanion.insert(
              id: Value(p['id'] as int),
              nombre: p['nombre'] as String,
              fotoPath: Value(p['fotoPath'] as String?),
              edad: Value(p['edad'] as int?),
              creadoEn: Value(DateTime.parse(p['creadoEn'] as String)),
            ));
      }
      for (final m in (data['medicamentos'] as List).cast<Map<String, dynamic>>()) {
        await _db.into(_db.medicamentos).insert(MedicamentosCompanion.insert(
              id: Value(m['id'] as int),
              perfilId: m['perfilId'] as int,
              nombre: m['nombre'] as String,
              dosis: m['dosis'] as String,
              tipoFrecuencia: TipoFrecuencia.values[m['tipoFrecuencia'] as int],
              intervaloHoras: Value(m['intervaloHoras'] as int?),
              vecesPorDia: Value(m['vecesPorDia'] as int?),
              fechaInicio: DateTime.parse(m['fechaInicio'] as String),
              fechaFin: Value(m['fechaFin'] != null
                  ? DateTime.parse(m['fechaFin'] as String)
                  : null),
              notas: Value(m['notas'] as String?),
              activo: Value(m['activo'] as bool),
            ));
      }
      for (final h in (data['horarios'] as List).cast<Map<String, dynamic>>()) {
        await _db.into(_db.horarios).insert(HorariosCompanion.insert(
              id: Value(h['id'] as int),
              medicamentoId: h['medicamentoId'] as int,
              minutosDelDia: h['minutosDelDia'] as int,
              diasSemana: Value(h['diasSemana'] as int),
            ));
      }
      for (final t in (data['tomas'] as List).cast<Map<String, dynamic>>()) {
        await _db.into(_db.tomas).insert(TomasCompanion.insert(
              id: Value(t['id'] as int),
              medicamentoId: t['medicamentoId'] as int,
              fechaProgramada: DateTime.parse(t['fechaProgramada'] as String),
              estado: EstadoToma.values[t['estado'] as int],
              respondidaEn: Value(t['respondidaEn'] != null
                  ? DateTime.parse(t['respondidaEn'] as String)
                  : null),
            ));
      }
    });
  }
}

final backupServiceProvider =
    Provider<BackupService>((ref) => BackupService(ref.watch(databaseProvider)));
