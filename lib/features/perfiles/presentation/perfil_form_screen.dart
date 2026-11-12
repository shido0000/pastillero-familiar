// Formulario para crear un perfil: nombre, edad opcional y foto opcional.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/perfil_repository.dart';

class PerfilFormScreen extends ConsumerStatefulWidget {
  const PerfilFormScreen({super.key});

  @override
  ConsumerState<PerfilFormScreen> createState() => _PerfilFormScreenState();
}

class _PerfilFormScreenState extends ConsumerState<PerfilFormScreen> {
  final _nombreController = TextEditingController();
  final _edadController = TextEditingController();
  String? _fotoPath;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _edadController.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final foto = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512, // suficiente para un avatar, ahorra espacio
      imageQuality: 80,
    );
    if (foto == null) return;
    // Copiamos la foto a un directorio propio de la app (la caché se puede borrar).
    final dir = await getApplicationDocumentsDirectory();
    final destino =
        p.join(dir.path, 'perfil_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await File(foto.path).copy(destino);
    setState(() => _fotoPath = destino);
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Escribe el nombre del perfil')));
      return;
    }
    setState(() => _guardando = true);
    try {
      // esPro: false en el MVP. En Fase 2 se lee del estado de la compra.
      await ref.read(perfilRepositoryProvider).crearPerfil(
            nombre: nombre,
            esPro: false,
            edad: int.tryParse(_edadController.text.trim()),
            fotoPath: _fotoPath,
          );
      if (mounted) context.go('/perfiles');
    } on LimitePerfilesException {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Límite alcanzado'),
            content: const Text(
                'La versión gratuita permite hasta 2 perfiles. '
                'Con la versión Pro podrás crear los que necesites.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _elegirFoto,
              child: CircleAvatar(
                radius: 48,
                backgroundImage:
                    _fotoPath != null ? FileImage(File(_fotoPath!)) : null,
                child: _fotoPath == null
                    ? const Icon(Icons.add_a_photo_rounded, size: 40)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nombreController,
            decoration: const InputDecoration(
                labelText: 'Nombre', hintText: 'Ej.: Abuela, Papá, Yo'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _edadController,
            decoration: const InputDecoration(labelText: 'Edad (opcional)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    height: 24, width: 24, child: CircularProgressIndicator())
                : const Text('Guardar perfil'),
          ),
        ],
      ),
    );
  }
}
