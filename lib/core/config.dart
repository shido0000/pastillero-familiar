// Configuración global de la app.

// Límite de perfiles de la versión gratuita. Se valida en el repositorio,
// no en la UI, para que no se pueda saltar desde la interfaz.
const int kMaxPerfilesGratis = 2;

// AdMob (Fase 2): dejar en false hasta configurar los App IDs reales en
// AndroidManifest.xml e Info.plist; si no, el SDK de anuncios puede fallar.
const bool kAdMobHabilitado = false;
