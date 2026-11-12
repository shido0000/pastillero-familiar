// Pruebas del corazón de la app: cálculo de tomas del día.
import 'package:flutter_test/flutter_test.dart';
import 'package:pastillero_familiar/core/database/app_database.dart';
import 'package:pastillero_familiar/core/utils/horarios_utils.dart';
import 'package:pastillero_familiar/features/tomas/domain/motor_tomas.dart';

void main() {
  // Fechas fijas: 2026-11-09 fue lunes.
  final lunes = DateTime(2026, 11, 9);
  final martes = DateTime(2026, 11, 10);

  Medicamento med({
    TipoFrecuencia tipo = TipoFrecuencia.vecesAlDia,
    int? intervaloHoras,
    int? vecesPorDia,
    DateTime? inicio,
    DateTime? fin,
  }) =>
      Medicamento(
        id: 1,
        perfilId: 1,
        nombre: 'Losartán',
        dosis: '50 mg',
        tipoFrecuencia: tipo,
        intervaloHoras: intervaloHoras,
        vecesPorDia: vecesPorDia,
        fechaInicio: inicio ?? DateTime(2026, 11, 1),
        fechaFin: fin,
        notas: null,
        activo: true,
      );

  Horario horario(int minutos, {int diasSemana = 127}) => Horario(
      id: 1, medicamentoId: 1, minutosDelDia: minutos, diasSemana: diasSemana);

  Toma registro(DateTime fecha, EstadoToma estado) => Toma(
        id: 99,
        medicamentoId: 1,
        fechaProgramada: fecha,
        estado: estado,
        respondidaEn: fecha.add(const Duration(minutes: 5)),
      );

  group('calcularMinutosCadaXHoras', () {
    test('cada 8 h desde las 08:00 da tres tomas incluida la de medianoche', () {
      expect(calcularMinutosCadaXHoras(8, 8 * 60), [480, 960, 0]);
    });

    test('cada 12 h desde las 09:30 da dos tomas', () {
      expect(calcularMinutosCadaXHoras(12, 9 * 60 + 30), [570, 1290]);
    });
  });

  group('calcularSlotsDelDia', () {
    test('vecesAlDia genera los slots ordenados por hora', () {
      final slots = calcularSlotsDelDia(
        medicamentos: [med(vecesPorDia: 2)],
        horariosPorMedicamento: {1: [horario(20 * 60), horario(8 * 60)]},
        registros: [],
        dia: lunes,
      );
      expect(slots.length, 2);
      expect(slots.first.fechaProgramada.hour, 8);
      expect(slots.last.fechaProgramada.hour, 20);
    });

    test('respetar el bitmask de días de la semana', () {
      // bit 0 = lunes -> solo aplica los lunes.
      final slotsLunes = calcularSlotsDelDia(
        medicamentos: [med()],
        horariosPorMedicamento: {1: [horario(480, diasSemana: 1)]},
        registros: [],
        dia: lunes,
      );
      final slotsMartes = calcularSlotsDelDia(
        medicamentos: [med()],
        horariosPorMedicamento: {1: [horario(480, diasSemana: 1)]},
        registros: [],
        dia: martes,
      );
      expect(slotsLunes.length, 1);
      expect(slotsMartes.isEmpty, isTrue);
    });

    test('excluye tomas anteriores al inicio del tratamiento', () {
      final slots = calcularSlotsDelDia(
        medicamentos: [med(inicio: DateTime(2026, 11, 15))],
        horariosPorMedicamento: {1: [horario(480)]},
        registros: [],
        dia: lunes, // 9 de noviembre: antes del inicio
      );
      expect(slots.isEmpty, isTrue);
    });

    test('excluye tomas posteriores al fin del tratamiento', () {
      final slots = calcularSlotsDelDia(
        medicamentos: [med(fin: DateTime(2026, 11, 8))],
        horariosPorMedicamento: {1: [horario(480)]},
        registros: [],
        dia: lunes, // 9 de noviembre: después del fin
      );
      expect(slots.isEmpty, isTrue);
    });

    test('cruza correctamente los registros tomada/omitida', () {
      final slot8 = DateTime(2026, 11, 9, 8, 0);
      final slot20 = DateTime(2026, 11, 9, 20, 0);
      final slots = calcularSlotsDelDia(
        medicamentos: [med(vecesPorDia: 2)],
        horariosPorMedicamento: {1: [horario(480), horario(1200)]},
        registros: [
          registro(slot8, EstadoToma.tomada),
          registro(slot20, EstadoToma.omitida),
        ],
        dia: lunes,
      );
      expect(slots[0].estado, EstadoToma.tomada);
      expect(slots[1].estado, EstadoToma.omitida);
      expect(slots[0].estaPendiente, isFalse);
    });

    test('un horario sin registro queda pendiente', () {
      final slots = calcularSlotsDelDia(
        medicamentos: [med()],
        horariosPorMedicamento: {1: [horario(480)]},
        registros: [],
        dia: lunes,
      );
      expect(slots.single.estaPendiente, isTrue);
      expect(slots.single.estado, isNull);
    });
  });
}
