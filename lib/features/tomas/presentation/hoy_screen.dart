// Pantalla principal "Hoy": lista de tomas del día con estados y
// botones grandes para adultos mayores.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../ajustes/data/ajustes_controller.dart';
import '../../perfiles/data/perfil_repository.dart';
import '../data/toma_repository.dart';
import '../domain/motor_tomas.dart';
import 'hoy_controller.dart';

class HoyScreen extends ConsumerWidget {
  const HoyScreen({super.key});

  Future<void> _marcar(WidgetRef ref, SlotToma slot, EstadoToma estado) async {
    await ref.read(tomaRepositoryProvider).marcar(
          medicamentoId: slot.medicamento.id,
          fechaProgramada: slot.fechaProgramada,
          estado: estado,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilId = ref.watch(ajustesProvider).valueOrNull?.perfilActivoId;
    if (perfilId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/perfiles'));
      return const SizedBox.shrink();
    }

    final perfiles = ref.watch(perfilesStreamProvider).valueOrNull ?? const [];
    String nombrePerfil = 'Perfil';
    for (final p in perfiles) {
      if (p.id == perfilId) nombrePerfil = p.nombre;
    }

    final slotsAsync = ref.watch(slotsHoyProvider(perfilId));
    final tema = Theme.of(context);
    final fechaHoy = DateTime.now();
    final fechaTexto = MaterialLocalizations.of(context).formatFullDate(fechaHoy);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pastillero de $nombrePerfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Historial',
            onPressed: () => context.go('/historial'),
          ),
          IconButton(
            icon: const Icon(Icons.family_restroom_rounded),
            tooltip: 'Cambiar perfil',
            onPressed: () => context.go('/perfiles'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Ajustes',
            onPressed: () => context.go('/ajustes'),
          ),
        ],
      ),
      body: slotsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ' + e.toString())),
        data: (slots) {
          if (slots.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No hay tomas programadas para hoy.\n'
                  'Agrega un medicamento para empezar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }

          final tomadas = slots.where((s) => s.estado == EstadoToma.tomada).length;

          return Column(
            children: [
              // Encabezado: fecha y progreso del día.
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fechaTexto,
                        style: tema.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('$tomadas de ${slots.length} tomas completadas',
                        style: tema.textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: tomadas / slots.length,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: slots.length,
                  itemBuilder: (context, i) {
                    final slot = slots[i];
                    final pendienteYVencida = slot.estaPendiente && slot.yaPaso;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color:
                          pendienteYVencida ? tema.colorScheme.errorContainer : null,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _hora(slot.fechaProgramada),
                                  style: tema.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(slot.medicamento.nombre,
                                          style: tema.textTheme.titleLarge
                                              ?.copyWith(fontWeight: FontWeight.w600)),
                                      Text(slot.medicamento.dosis,
                                          style: tema.textTheme.bodyLarge),
                                    ],
                                  ),
                                ),
                                _ChipEstado(slot: slot),
                              ],
                            ),
                            if (slot.medicamento.notas != null) ...[
                              const SizedBox(height: 8),
                              Text('Notas: ${slot.medicamento.notas!}',
                                  style: tema.textTheme.bodyMedium),
                            ],
                            const SizedBox(height: 12),
                            if (slot.estaPendiente)
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      icon: const Icon(Icons.check_rounded, size: 28),
                                      label: const Text('Tomado',
                                          style: TextStyle(fontSize: 18)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: tema.colorScheme.primary,
                                        minimumSize: const Size(0, 56),
                                      ),
                                      onPressed: () =>
                                          _marcar(ref, slot, EstadoToma.tomada),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.close_rounded, size: 28),
                                      label: const Text('Omitir',
                                          style: TextStyle(fontSize: 18)),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 56),
                                      ),
                                      onPressed: () =>
                                          _marcar(ref, slot, EstadoToma.omitida),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Center(
                                child: TextButton(
                                  onPressed: () => ref
                                      .read(tomaRepositoryProvider)
                                      .desmarcar(
                                        medicamentoId: slot.medicamento.id,
                                        fechaProgramada: slot.fechaProgramada,
                                      ),
                                  child: const Text('Deshacer'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Medicamento'),
        onPressed: () => context.go('/medicamento/nuevo'),
      ),
    );
  }

  String _hora(DateTime f) =>
      '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
}

class _ChipEstado extends StatelessWidget {
  const _ChipEstado({required this.slot});
  final SlotToma slot;

  @override
  Widget build(BuildContext context) {
    final estado = slot.estado;
    if (estado == null) {
      final vencida = slot.yaPaso;
      return Chip(
        avatar: Icon(vencida ? Icons.warning_rounded : Icons.schedule_rounded,
            size: 18),
        label: Text(vencida ? 'Vencida' : 'Pendiente'),
        backgroundColor: vencida
            ? Theme.of(context).colorScheme.error.withValues(alpha: 0.2)
            : null,
      );
    }
    return Chip(
      avatar: Icon(
        estado == EstadoToma.tomada
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded,
        size: 18,
      ),
      label: Text(estado == EstadoToma.tomada ? 'Tomada' : 'Omitida'),
    );
  }
}
