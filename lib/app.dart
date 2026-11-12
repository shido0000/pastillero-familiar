// Raíz de la app: aplica tema, modo oscuro y escala de texto según ajustes.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/ajustes/data/ajustes_controller.dart';

class PastilleroApp extends ConsumerWidget {
  const PastilleroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesProvider).valueOrNull ?? const AjustesState();
    final router = ref.watch(appRouterProvider);

    final themeMode = switch (ajustes.modoTema) {
      ModoTema.sistema => ThemeMode.system,
      ModoTema.claro => ThemeMode.light,
      ModoTema.oscuro => ThemeMode.dark,
    };

    return MaterialApp.router(
      title: 'Pastillero Familiar',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Español neutro en toda la app.
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.claro(altoContraste: ajustes.altoContraste),
      darkTheme: AppTheme.oscuro(altoContraste: ajustes.altoContraste),
      themeMode: themeMode,
      // Texto grande accesible: escala global 1.25x.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: ajustes.textoGrande ? const TextScaler.linear(1.25) : null,
        ),
        child: child!,
      ),
    );
  }
}
