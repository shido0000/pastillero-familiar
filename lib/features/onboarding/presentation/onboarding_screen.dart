// Onboarding: una sola pantalla, texto grande, español neutro.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ajustes/data/ajustes_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.medication_rounded, size: 96, color: tema.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Bienvenido a Pastillero Familiar',
                style: tema.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const _Beneficio(Icons.notifications_active_rounded,
                  'Te recordamos cada toma, incluso con la app cerrada'),
              const _Beneficio(Icons.family_restroom_rounded,
                  'Un pastillero para cada miembro de la familia'),
              const _Beneficio(Icons.picture_as_pdf_rounded,
                  'Lleva tu historial al médico en un reporte PDF'),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () async {
                  await ref.read(ajustesProvider.notifier).setOnboardingCompleto();
                  if (context.mounted) context.go('/perfiles');
                },
                child: const Text('Comenzar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Beneficio extends StatelessWidget {
  const _Beneficio(this.icono, this.texto);
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icono, color: tema.colorScheme.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(child: Text(texto, style: tema.textTheme.titleMedium)),
        ],
      ),
    );
  }
}
