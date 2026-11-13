// Lista de medicamentos del perfil activo.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ajustes/data/ajustes_controller.dart';
import '../data/medicamento_repository.dart';

class MedicamentosScreen extends ConsumerWidget {
  const MedicamentosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilId = ref.watch(ajustesProvider).valueOrNull?.perfilActivoId;

    if (perfilId == null) {
      // Sin perfil activo: volver a la selección.
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/perfiles'));
      return const SizedBox.shrink();
    }

    final medsAsync = ref.watch(medicamentosPorPerfilProvider(perfilId));

    return Scaffold(
      appBar: AppBar(title: const Text('Medicamentos')),
      body: medsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ' + e.toString())),
        data: (meds) {
          // Estado vacío: aún no hay medicamentos.
          if (meds.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aún no hay medicamentos.\nToca "Agregar" para crear el primero.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meds.length,
            itemBuilder: (context, i) {
              final med = meds[i];
              return Card(
                child: ListTile(
                  leading: Icon(Icons.medication_rounded,
                      size: 40, color: Theme.of(context).colorScheme.primary),
                  title: Text(med.nombre,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  subtitle: Text(med.dosis),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/medicamento/${med.id}'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: const Text('Agregar'),
        onPressed: () => context.go('/medicamento/nuevo'),
      ),
    );
  }
}
