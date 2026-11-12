// Historial semanal/mensual con % de adherencia y exportación a PDF.
// En Fase 2, aquí (y solo aquí) irá el banner de AdMob.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/pdf_report.dart';
import '../../ajustes/data/ajustes_controller.dart';
import '../../perfiles/data/perfil_repository.dart';
import 'historial_controller.dart';

class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  ModoHistorial _modo = ModoHistorial.semana;
  bool _exportando = false;

  @override
  Widget build(BuildContext context) {
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

    final resumenAsync = ref.watch(resumenHistorialProvider((perfilId, _modo)));
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Historial de $nombrePerfil')),
      body: resumenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: ' + e.toString())),
        data: (resumen) {
          final adherencia = resumen.adherencia;
          final colorAdherencia = adherencia == null
              ? tema.colorScheme.outline
              : adherencia >= 0.8
                  ? Colors.green.shade700
                  : adherencia >= 0.5
                      ? Colors.orange.shade700
                      : tema.colorScheme.error;

          return Column(
            children: [
              // Selector de periodo
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<ModoHistorial>(
                  segments: const [
                    ButtonSegment(
                        value: ModoHistorial.semana, label: Text('Últimos 7 días')),
                    ButtonSegment(
                        value: ModoHistorial.mes, label: Text('Este mes')),
                  ],
                  selected: {_modo},
                  onSelectionChanged: (s) => setState(() => _modo = s.first),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Tarjeta grande de adherencia
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text(
                              adherencia == null
                                  ? '—'
                                  : '${(adherencia * 100).toStringAsFixed(0)}%',
                              style: tema.textTheme.displayLarge?.copyWith(
                                  color: colorAdherencia,
                                  fontWeight: FontWeight.bold),
                            ),
                            const Text('de adherencia',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(height: 12),
                            Text(
                              '${resumen.totalTomadas} cumplidas · '
                              '${resumen.totalOmitidas} omitidas · '
                              '${resumen.totalVencidas} sin marcar',
                              style: tema.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Detalle por día
                    ...resumen.dias.reversed.map((dia) {
                      final total = dia.slots.length;
                      return ListTile(
                        leading: Icon(
                          total == 0
                              ? Icons.event_busy_rounded
                              : Icons.event_note_rounded,
                          color: tema.colorScheme.primary,
                        ),
                        title: Text(_formatoDiaCorto(dia.fecha)),
                        subtitle: total == 0
                            ? const Text('Sin tomas programadas')
                            : Text('${dia.tomadas + dia.omitidas} de $total gestionadas · '
                                '${dia.tomadas} cumplidas · ${dia.omitidas + dia.vencidasPendientes} sin marcar'),
                      );
                    }),

                    // Espacio reservado para el banner de AdMob (Fase 2).
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: _exportando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white))
            : const Icon(Icons.picture_as_pdf_rounded),
        label: const Text('Exportar PDF'),
        onPressed: resumenAsync.value == null || _exportando
            ? null
            : () async {
                setState(() => _exportando = true);
                try {
                  await generarYCompartirReporte(
                    resumen: resumenAsync.value!,
                    nombrePerfil: nombrePerfil,
                  );
                } finally {
                  if (mounted) setState(() => _exportando = false);
                }
              },
      ),
    );
  }

  String _formatoDiaCorto(DateTime f) {
    const dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dias[f.weekday - 1]} ${f.day} ${meses[f.month - 1]}';
  }
}
