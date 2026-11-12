// Proveedores del historial: modo (semana/mes) + resumen calculado.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/historial_repository.dart';

enum ModoHistorial { semana, mes }

final resumenHistorialProvider =
    FutureProvider.autoDispose.family<ResumenHistorial, (int, ModoHistorial)>(
        (ref, parametros) {
  final (perfilId, modo) = parametros;
  final repo = ref.watch(historialRepositoryProvider);
  final ahora = DateTime.now();

  final inicio = switch (modo) {
    ModoHistorial.semana => ahora.subtract(const Duration(days: 6)),
    ModoHistorial.mes => DateTime(ahora.year, ahora.month, 1),
  };

  return repo.resumen(perfilId: perfilId, inicio: inicio, fin: ahora);
});
