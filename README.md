# Pastillero Familiar 💊

Recordatorios de medicamentos para toda la familia, **100% offline**.

- Recordatorios confiables, incluso con la app cerrada
- Acción "Tomado" / "Omitir" desde la propia notificación
- Múltiples perfiles (abuelo, abuela, hijo en tratamiento...)
- Historial semanal/mensual con % de adherencia
- Reporte PDF exportable para llevar al médico
- Modo oscuro, texto grande y alto contraste para adultos mayores

## Stack

Flutter 3.x · Riverpod · Drift (SQLite) · flutter_local_notifications · pdf/printing

## Compilar

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter build apk --release
```

La APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

## CI

Cada push a `main` dispara GitHub Actions: ejecuta los tests y compila la APK.
Descárgala en **Actions → Build APK → Artifacts**.

## Notas

- Sin backend obligatorio. La sincronización familiar (Fase 2) usa Firestore
  en su capa gratuita y la app funciona igual sin conexión.
- No subir nunca: `key.properties`, `.keystore`, `google-services.json`.
