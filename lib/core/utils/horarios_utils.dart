// Utilidades para calcular horarios de toma.

/// Convierte "cada X horas desde la primera toma" en minutos del día.
/// Ej.: cada 8 h desde 08:00 -> [480, 960, 0] (08:00, 16:00, 00:00).
List<int> calcularMinutosCadaXHoras(int intervaloHoras, int minutosPrimeraToma) {
  final resultado = <int>[];
  var m = minutosPrimeraToma;
  while (m < 24 * 60) {
    resultado.add(m);
    m += intervaloHoras * 60;
  }
  return resultado;
}
