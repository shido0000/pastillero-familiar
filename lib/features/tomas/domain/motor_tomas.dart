// Motor de tomas: calcula los slots del día a partir de los horarios.
// Las tomas pendientes NO se guardan en la base de datos: se derivan aquí.
// Solo lo decidido (tomada/omitida) vive en la tabla Tomas.
import '../../../core/database/app_database.dart';

/// Una toma concreta de un día: slot calculado + registro de estado si existe.
class SlotToma {
  final Medicamento medicamento;
  final DateTime fechaProgramada;
  final Toma? registro; // null = pendiente

  const SlotToma({
    required this.medicamento,
    required this.fechaProgramada,
    this.registro,
  });

  EstadoToma? get estado => registro?.estado;
  bool get estaPendiente => registro == null;
  bool get yaPaso => DateTime.now().isAfter(fechaProgramada);
}

/// diasSemana es un bitmask: bit 0 = lunes ... bit 6 = domingo. 127 = todos.
bool _horarioAplicaElDia(int diasSemana, DateTime dia) {
  final bit = 1 << (dia.weekday - 1);
  return (diasSemana & bit) != 0;
}

/// Clave única lógica de una toma (medicamento + minuto del día).
String _clave(int medicamentoId, DateTime fecha) {
  final minutos = fecha.hour * 60 + fecha.minute;
  return '${medicamentoId}@${fecha.year}-${fecha.month}-${fecha.day}-$minutos';
}

/// Calcula todos los slots del día, ordenados por hora,
/// cruzando los slots con los registros de estado existentes.
List<SlotToma> calcularSlotsDelDia({
  required List<Medicamento> medicamentos,
  required Map<int, List<Horario>> horariosPorMedicamento,
  required List<Toma> registros,
  required DateTime dia,
}) {
  final inicioDia = DateTime(dia.year, dia.month, dia.day);

  final registrosPorClave = <String, Toma>{};
  for (final t in registros) {
    registrosPorClave[_clave(t.medicamentoId, t.fechaProgramada)] = t;
  }

  final slots = <SlotToma>[];
  for (final med in medicamentos) {
    for (final horario in horariosPorMedicamento[med.id] ?? const <Horario>[]) {
      if (!_horarioAplicaElDia(horario.diasSemana, dia)) continue;

      final fecha = inicioDia.add(Duration(minutes: horario.minutosDelDia));

      // Vigencia del tratamiento (fecha de inicio y fin).
      final inicioMed = DateTime(
          med.fechaInicio.year, med.fechaInicio.month, med.fechaInicio.day);
      if (fecha.isBefore(inicioMed)) continue;
      final fin = med.fechaFin;
      if (fin != null &&
          fecha.isAfter(DateTime(fin.year, fin.month, fin.day, 23, 59, 59))) {
        continue;
      }

      slots.add(SlotToma(
        medicamento: med,
        fechaProgramada: fecha,
        registro: registrosPorClave[_clave(med.id, fecha)],
      ));
    }
  }
  slots.sort((a, b) => a.fechaProgramada.compareTo(b.fechaProgramada));
  return slots;
}
