// Utilidades para calcular horarios de toma.

/// Convierte "cada X horas desde la primera toma" en minutos del día.
/// Ej.: cada 8 h desde 08:00 -> [480, 960, 0] (08:00, 16:00 y la toma de
/// medianoche, que pertenece al patrón diario aunque caiga "al día siguiente").
List<int> calcularMinutosCadaXHoras(int intervaloHoras, int minutosPrimeraToma) {
  final resultado = <int>[];
  var m = minutosPrimeraToma;
  while (m < 24 * 60) {
    resultado.add(m);
    m += intervaloHoras * 60;
  }
  // Si la última toma del ciclo cae después de medianoche, se registra
  // envuelta (mod 24 h) como parte del patrón diario, sin duplicar horarios.
  // Ej.: cada 6 h desde 08:00 -> [480, 840, 1200, 120] (08, 14, 20, 02).
  final wrap = m - 24 * 60;
  if (wrap >= 0 && !resultado.contains(wrap)) {
    resultado.add(wrap);
  }
  return resultado;
}
