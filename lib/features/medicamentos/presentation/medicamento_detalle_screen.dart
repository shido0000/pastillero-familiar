// Detalle de un medicamento: información completa y acciones de fin
// de tratamiento o borrado, siempre con confirmación.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/programador_recordatorios.dart';
import '../data/medicamento_repository.dart';
import '../domain/descripciones.dart';

/// Carga el medicamento y sus horarios.
final detalleMedicamentoProvider =
    FutureProvider.autoDispose.family<(Medicamento, List<Horario>), int>((ref, id) async {
  final repo = ref.watch(medicamentoRepositoryProvider);
  final med = await repo.obtenerPorId(id);
  if (med == null) throw StateError('Medicamento no encontrado');
  return (med, await repo.horariosDe(id));
});

class MedicamentoDetalleScreen extends ConsumerWidget {
  const MedicamentoDetalleScreen({super.key, required this.medicamentoId});
  final int medicamentoId;

  String _hora(int minutos) =>
      '${(minutos ~/ 60).toString().padLeft(2, '0')}:${(minutos % 60).toString().padLeft(2, '0')}';

  Future<void> _reprogramarNotificaciones(WidgetRef ref) async {
    await ProgramadorRecordatorios(
      ref.read(databaseProvider),
      ref.read(notificationServiceProvider),
    ).reprogramarTodo();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(detalleMedicamentoProvider(medicamentoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del medicamento')),
      body: detalleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ' + e.toString())),
        data: (detalle) {
          final med = detalle.$1;
          final horarios = detalle.$2;
          final tema = Theme.of(context);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Icon(Icons.medication_rounded,
                      size: 48, color: tema.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.nombre,
                            style: tema.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(med.dosis, style: tema.textTheme.titleMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.repeat_rounded),
                title: Text(describirFrecuencia(med),
                    style: const TextStyle(fontSize: 18)),
              ),
              ListTile(
                leading: const Icon(Icons.event_available_rounded),
                title:
                    Text(describirDuracion(med), style: const TextStyle(fontSize: 18)),
              ),
              ListTile(
                leading: const Icon(Icons.alarm_rounded),
                title: Text(
                  'Horas de toma: ${horarios.map((h) => _hora(h.minutosDelDia)).join(' · ')}',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              if (med.notas != null && med.notas!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.sticky_note_2_rounded),
                  title: Text(med.notas!, style: const TextStyle(fontSize: 18)),
                ),
              const SizedBox(height: 32),

              // Terminar tratamiento: conserva el historial para el PDF.
              OutlinedButton.icon(
                icon: const Icon(Icons.event_busy_rounded),
                label: const Text('Terminar tratamiento'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: () async {
                  final confirmar = await _confirmar(
                      context, '¿Terminar el tratamiento de ${med.nombre}? Se conservará en el historial.');
                  if (confirmar != true) return;
                  await ref.read(medicamentoRepositoryProvider).desactivar(med.id);
                  await _reprogramarNotificaciones(ref);
                  if (context.mounted) context.go('/medicamentos');
                },
              ),
              const SizedBox(height: 12),

              // Eliminar: borra también el historial (irreversible).
              OutlinedButton.icon(
                icon: Icon(Icons.delete_forever_rounded, color: tema.colorScheme.error),
                label: Text('Eliminar con su historial',
                    style:
                        TextStyle(color: tema.colorScheme.error, fontSize: 18)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
                onPressed: () async {
                  final confirmar = await _confirmar(
                      context,
                      '¿Eliminar ${med.nombre} y TODO su historial? Esta acción no se puede deshacer.',
                      peligroso: true);
                  if (confirmar != true) return;
                  await ref.read(medicamentoRepositoryProvider).eliminar(med.id);
                  await _reprogramarNotificaciones(ref);
                  if (context.mounted) context.go('/medicamentos');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _confirmar(BuildContext context, String mensaje,
      {bool peligroso = false}) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: peligroso
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error)
                : null,
            child: const Text('Sí, continuar'),
          ),
        ],
      ),
    );
    return resultado ?? false;
  }
}
