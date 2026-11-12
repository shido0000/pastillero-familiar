// Textos descriptivos de un medicamento, en español neutro.
import '../../../core/database/app_database.dart';

String describirFrecuencia(Medicamento med) => switch (med.tipoFrecuencia) {
      TipoFrecuencia.cadaXHoras => 'Cada ${med.intervaloHoras} horas',
      TipoFrecuencia.vecesAlDia => '${med.vecesPorDia} vez/veces al día',
    };

String describirDuracion(Medicamento med) {
  if (med.fechaFin == null) return 'Tratamiento indefinido';
  final dias = med.fechaFin!.difference(med.fechaInicio).inDays;
  return 'Tratamiento de $dias días';
}
