// Navegación con go_router. Redirige al onboarding en la primera apertura.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ajustes/data/ajustes_controller.dart';
import '../../features/ajustes/presentation/ajustes_screen.dart';
import '../../features/historial/presentation/historial_screen.dart';
import '../../features/medicamentos/presentation/medicamento_detalle_screen.dart';
import '../../features/medicamentos/presentation/medicamento_form_screen.dart';
import '../../features/medicamentos/presentation/medicamentos_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/perfiles/presentation/perfil_form_screen.dart';
import '../../features/perfiles/presentation/perfiles_screen.dart';
import '../../features/tomas/presentation/hoy_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(ajustesProvider); // reacciona al onboarding

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final ajustes = ref.read(ajustesProvider).valueOrNull;
      if (ajustes == null) return null; // aún cargando
      final enOnboarding = state.matchedLocation == '/onboarding';
      if (!ajustes.onboardingCompleto && !enOnboarding) return '/onboarding';
      if (ajustes.onboardingCompleto && enOnboarding) return '/perfiles';
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/hoy'),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/perfiles', builder: (_, __) => const PerfilesScreen()),
      GoRoute(path: '/perfil/nuevo', builder: (_, __) => const PerfilFormScreen()),
      GoRoute(path: '/hoy', builder: (_, __) => const HoyScreen()),
      GoRoute(path: '/medicamentos', builder: (_, __) => const MedicamentosScreen()),
      GoRoute(path: '/medicamento/nuevo', builder: (_, __) => const MedicamentoFormScreen()),
      GoRoute(
        path: '/medicamento/:id',
        builder: (_, state) => MedicamentoDetalleScreen(
          medicamentoId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/historial', builder: (_, __) => const HistorialScreen()),
      GoRoute(path: '/ajustes', builder: (_, __) => const AjustesScreen()),
    ],
  );
});
