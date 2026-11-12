// Proveedores de la pantalla "Hoy": combinan medicamentos, horarios
// y registros de tomas en una lista viva de slots del día.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../medicamentos/data/medicamento_repository.dart';
import '../data/toma_repository.dart';
import '../domain/motor_tomas.dart';

/// Slots de HOY para un perfil. Se recalcula en vivo cuando cambia
/// cualquier medicamento, horario o registro de toma.
final slotsHoyProvider = StreamProvider.family<List<SlotToma>, int>((ref, perfilId) {
  final medRepo = ref.watch(medicamentoRepositoryProvider);
  final tomaRepo = ref.watch(tomaRepositoryProvider);

  final ahora = DateTime.now();
  final dia = DateTime(ahora.year, ahora.month, ahora.day);

  Stream<List<SlotToma>> combinar() async* {
    await for (final meds in medRepo.observarPorPerfil(perfilId)) {
      // Horarios de lectura puntual: se refrescan cuando cambian los medicamentos.
      final horarios = <int, List<Horario>>{};
      for (final med in meds) {
        horarios[med.id] = await medRepo.horariosDe(med.id);
      }
      await for (final registros in tomaRepo.observarDelDia(perfilId, dia)) {
        yield calcularSlotsDelDia(
          medicamentos: meds,
          horariosPorMedicamento: horarios,
          registros: registros,
          dia: dia,
        );
      }
    }
  }

  return combinar();
});
