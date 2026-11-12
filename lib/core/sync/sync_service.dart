// Sincronización familiar OPCIONAL (solo Pro).
// Estrategia simple y robusta: snapshot completo de la base local hacia
// un documento de Firestore, con marca de tiempo. Gana el snapshot más
// reciente (last-write-wins). Si no hay internet o Firebase no está
// configurado, la app funciona exactamente igual.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backup/backup_service.dart';
import '../database/app_database.dart';

class SyncService {
  SyncService(this._db, this._backup);
  final AppDatabase _db;
  final BackupService _backup;

  final _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subEscucha;
  Timer? _debouncePush;
  DateTime? _ultimoPush;
  String? _codigo;

  /// Crea un código familiar de 6 caracteres y activa la sync.
  Future<String> crearFamilia() async {
    // Sin caracteres confundibles (0/O, 1/I/L).
    const caracteres = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final ahora = DateTime.now().microsecondsSinceEpoch;
    final codigo = String.fromCharCodes(List.generate(
        6, (i) => caracteres.codeUnitAt((ahora >> (i * 3)) % caracteres.length)));
    await _guardarYConectar(codigo);
    return codigo;
  }

  /// Se conecta a la familia de un familiar (recibe el código por WhatsApp).
  Future<void> conectarConFamilia(String codigo) =>
      _guardarYConectar(codigo.trim().toUpperCase());

  Future<void> _guardarYConectar(String codigo) async {
    _codigo = codigo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codigoFamilia', codigo);

    // 1. Escucha: si otro dispositivo sube algo más nuevo, lo aplicamos.
    _subEscucha?.cancel();
    _subEscucha = _firestore.collection('familias').doc(codigo).snapshots().listen((doc) async {
      final remoto = doc.data();
      if (remoto == null) return;
      final fechaRemota = DateTime.tryParse(remoto['actualizadoEn'] as String? ?? '');
      // Ignoramos ecos de nuestro propio push.
      if (fechaRemota == null ||
          (_ultimoPush != null && !fechaRemota.isAfter(_ultimoPush!))) {
        return;
      }
      await _backup.restaurarDesdeJson(remoto['datos'] as Map<String, dynamic>);
    });

    // 2. Primer push y push automático ante cualquier cambio local.
    await _subirSnapshot();
    _iniciarPushAutomatico();
  }

  /// Cualquier cambio local (toma marcada, medicamento nuevo...) dispara
  /// un push con 3 s de debounce para no saturar la cuota gratuita.
  void _iniciarPushAutomatico() {
    _db.select(_db.tomas).watch().listen((_) {
      _debouncePush?.cancel();
      _debouncePush = Timer(const Duration(seconds: 3), () {
        if (_codigo != null) _subirSnapshot();
      });
    });
  }

  Future<void> _subirSnapshot() async {
    if (_codigo == null) return;
    _ultimoPush = DateTime.now();
    await _firestore.collection('familias').doc(_codigo).set({
      'datos': await _backup.exportarJson(),
      'actualizadoEn': DateTime.now().toIso8601String(),
    });
  }

  /// Recupera el código guardado al arrancar (si el usuario ya activó sync).
  Future<void> restaurarConexionAlArrancar() async {
    final prefs = await SharedPreferences.getInstance();
    final codigo = prefs.getString('codigoFamilia');
    if (codigo != null) await _guardarYConectar(codigo);
  }

  Future<void> desconectar() async {
    await _subEscucha?.cancel();
    _debouncePush?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('codigoFamilia');
    _codigo = null;
  }
}

final syncServiceProvider = Provider<SyncService>(
    (ref) => SyncService(ref.watch(databaseProvider), ref.watch(backupServiceProvider)));
