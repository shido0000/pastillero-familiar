# Pastillero Familiar

App móvil (Flutter) de recordatorios de medicamentos para toda la familia.
100% offline: sin cuentas, sin backend obligatorio.

## Funcionalidades (MVP)

- Onboarding simple y perfiles de pacientes (máx. 2 en la versión gratuita)
- Medicamentos con frecuencia, horarios, duración del tratamiento y notas
- Notificaciones locales con acciones "Tomado" / "Omitir" desde la notificación
- Pantalla "Hoy" con el estado de cada toma (pendiente / tomada / omitida)
- Historial semanal y mensual con % de adherencia
- Reporte PDF exportable para llevar al médico
- Modo oscuro, texto grande y alto contraste para adultos mayores

## APK automática con GitHub Actions

Cada push a `main` compila la APK (`.github/workflows/build.yml`).
Descárgala en la pestaña **Actions → Build APK → Artifacts**.

## Compilación local

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter build apk --release
```

Las carpetas `android/` e `ios/` se generan con:
`flutter create . --platforms android,ios --org com.jonyperez`
