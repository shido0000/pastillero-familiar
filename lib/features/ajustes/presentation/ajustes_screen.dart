// Ajustes: apariencia, accesibilidad y gestión. Todo persistido localmente.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/ajustes_controller.dart';

class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustesAsync = ref.watch(ajustesProvider);
    final ajustes = ajustesAsync.valueOrNull ?? const AjustesState();
    final controller = ref.read(ajustesProvider.notifier);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Apariencia ──────────────────────────────────────────
          Text('Apariencia', style: tema.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ModoTema>(
            segments: const [
              ButtonSegment(value: ModoTema.sistema, label: Text('Automático')),
              ButtonSegment(value: ModoTema.claro, label: Text('Claro')),
              ButtonSegment(value: ModoTema.oscuro, label: Text('Oscuro')),
            ],
            selected: {ajustes.modoTema},
            onSelectionChanged: (s) => controller.setModoTema(s.first),
          ),
          const SizedBox(height: 16),

          // ── Accesibilidad (pensado para adultos mayores) ────────
          Text('Accesibilidad', style: tema.textTheme.titleMedium),
          SwitchListTile(
            title: const Text('Texto grande', style: TextStyle(fontSize: 18)),
            subtitle: const Text('Aumenta el tamaño de todas las letras'),
            value: ajustes.textoGrande,
            onChanged: controller.setTextoGrande,
          ),
          SwitchListTile(
            title: const Text('Alto contraste', style: TextStyle(fontSize: 18)),
            subtitle: const Text('Colores más intensos y fáciles de ver'),
            value: ajustes.altoContraste,
            onChanged: controller.setAltoContraste,
          ),
          const Divider(height: 32),

          // ── Gestión ─────────────────────────────────────────────
          Text('Gestión', style: tema.textTheme.titleMedium),
          ListTile(
            leading: const Icon(Icons.family_restroom_rounded, size: 32),
            title: const Text('Perfiles', style: TextStyle(fontSize: 18)),
            subtitle: const Text('Cambiar o crear perfiles de pacientes'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('/perfiles'),
          ),
          ListTile(
            leading: const Icon(Icons.medication_rounded, size: 32),
            title: const Text('Medicamentos', style: TextStyle(fontSize: 18)),
            subtitle: const Text('Ver, terminar o eliminar tratamientos'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('/medicamentos'),
          ),
          const Divider(height: 32),

          // ── Acerca de ───────────────────────────────────────────
          Text('Acerca de', style: tema.textTheme.titleMedium),
          const ListTile(
            leading: Icon(Icons.offline_bolt_rounded, size: 32),
            title: Text('Funciona sin internet', style: TextStyle(fontSize: 18)),
            subtitle: Text('Tus datos se guardan solo en este dispositivo'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded, size: 32),
            title: Text('Pastillero Familiar v1.0.0', style: TextStyle(fontSize: 18)),
            // Fase 2: aquí irá "Mejorar a Pro" con las compras in-app.
          ),
        ],
      ),
    );
  }
}
