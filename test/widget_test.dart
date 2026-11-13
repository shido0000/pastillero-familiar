// Prueba de humo de la configuración base del proyecto.
// (El widget test completo requiere mockear path_provider; los tests
// de lógica viven en motor_tomas_test.dart.)
import 'package:flutter_test/flutter_test.dart';
import 'package:pastillero_familiar/core/config.dart';

void main() {
  test('la versión gratuita limita los perfiles a 2', () {
    expect(kMaxPerfilesGratis, 2);
  });
}
