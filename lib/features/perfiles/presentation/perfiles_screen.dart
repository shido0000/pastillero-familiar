// Lista de perfiles. Tocar un perfil lo activa y abre sus medicamentos.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ajustes/data/ajustes_controller.dart';
import '../data/perfil_repository.dart';

class PerfilesScreen extends ConsumerWidget {
  const PerfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfilesAsync = ref.watch(perfilesStreamProvider);
    final ajustes = ref.watch(ajustesProvider).valueOrNull ?? const AjustesState();

    return Scaffold(
      appBar: AppBar(
        title: const Text('¿Quién va a usar la app?'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Ajustes',
            onPressed: () => context.go('/ajustes'),
          ),
        ],
      ),
      body: perfilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar: ' + e.toString())),
        empty: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Crea el primer perfil para empezar.\nPor ejemplo: "Papá" o "Abuela".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
        data: (perfiles) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: perfiles.length,
          itemBuilder: (context, i) {
            final perfil = perfiles[i];
            final activo = perfil.id == ajustes.perfilActivoId;
            return Card(
              elevation: activo ? 4 : 1,
              child: ListTile(
                leading: perfil.fotoPath != null
                    ? CircleAvatar(
                        backgroundImage: FileImage(File(perfil.fotoPath!)),
                        radius: 28,
                      )
                    : CircleAvatar(
                        radius: 28,
                        child: Text(perfil.nombre.isEmpty
                            ? '?'
                            : perfil.nombre[0].toUpperCase()),
                      ),
                title: Text(perfil.nombre,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                subtitle: perfil.edad != null ? Text('${perfil.edad} años') : null,
                trailing: activo
                    ? Icon(Icons.check_circle_rounded,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () async {
                  await ref.read(ajustesProvider.notifier).setPerfilActivo(perfil.id);
                  if (context.mounted) context.go('/medicamentos');
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo perfil'),
        onPressed: () => context.go('/perfil/nuevo'),
      ),
    );
  }
}
