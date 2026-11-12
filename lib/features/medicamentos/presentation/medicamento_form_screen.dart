// Formulario de medicamento: nombre, dosis, frecuencia, horarios,
// duración del tratamiento y notas.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/programador_recordatorios.dart';
import '../../../core/utils/horarios_utils.dart';
import '../../ajustes/data/ajustes_controller.dart';
import '../data/medicamento_repository.dart';

class MedicamentoFormScreen extends ConsumerStatefulWidget {
  const MedicamentoFormScreen({super.key});

  @override
  ConsumerState<MedicamentoFormScreen> createState() => _MedicamentoFormScreenState();
}

class _MedicamentoFormScreenState extends ConsumerState<MedicamentoFormScreen> {
  final _nombreController = TextEditingController();
  final _dosisController = TextEditingController();
  final _notasController = TextEditingController();

  TipoFrecuencia _frecuencia = TipoFrecuencia.vecesAlDia;
  int _intervaloHoras = 8;
  int _minutosPrimeraToma = 8 * 60; // 08:00
  int _vecesPorDia = 2;
  List<int> _minutosElegidos = [8 * 60, 20 * 60];
  bool _indefinido = false;
  int _diasDuracion = 30;

  @override
  void dispose() {
    _nombreController.dispose();
    _dosisController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _elegirHora({required bool esPrimeraToma, int? indice}) async {
    final horaInicial = TimeOfDay.now();
    final elegida = await showTimePicker(
      context: context,
      initialTime: horaInicial,
      helpText: 'Elige la hora',
    );
    if (elegida == null) return;
    final minutos = elegida.hour * 60 + elegida.minute;
    setState(() {
      if (esPrimeraToma) {
        _minutosPrimeraToma = minutos;
      } else if (indice != null) {
        _minutosElegidos[indice] = minutos;
      }
    });
  }

  String _formatoHora(int minutos) {
    final h = (minutos ~/ 60).toString().padLeft(2, '0');
    final m = (minutos % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final dosis = _dosisController.text.trim();
    if (nombre.isEmpty || dosis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Completa el nombre y la dosis del medicamento')));
      return;
    }
    final perfilId = ref.read(ajustesProvider).valueOrNull?.perfilActivoId;
    if (perfilId == null) {
      if (mounted) context.go('/perfiles');
      return;
    }

    final minutos = _frecuencia == TipoFrecuencia.cadaXHoras
        ? calcularMinutosCadaXHoras(_intervaloHoras, _minutosPrimeraToma)
        : List<int>.from(_minutosElegidos)..sort();

    await ref.read(medicamentoRepositoryProvider).crearMedicamento(
          perfilId: perfilId,
          nombre: nombre,
          dosis: dosis,
          tipoFrecuencia: _frecuencia,
          intervaloHoras:
              _frecuencia == TipoFrecuencia.cadaXHoras ? _intervaloHoras : null,
          vecesPorDia: _frecuencia == TipoFrecuencia.vecesAlDia ? _vecesPorDia : null,
          minutosDelDia: minutos,
          fechaInicio: DateTime.now(),
          fechaFin:
              _indefinido ? null : DateTime.now().add(Duration(days: _diasDuracion)),
          notas: _notasController.text.trim().isEmpty
              ? null
              : _notasController.text.trim(),
        );

    // Reprogramamos los recordatorios para incluir el nuevo medicamento.
    await ProgramadorRecordatorios(
      ref.read(databaseProvider),
      ref.read(notificationServiceProvider),
    ).reprogramarTodo();

    if (mounted) context.go('/medicamentos');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo medicamento')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _nombreController,
            decoration: const InputDecoration(
                labelText: 'Nombre del medicamento', hintText: 'Ej.: Losartán'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dosisController,
            decoration: const InputDecoration(
                labelText: 'Dosis', hintText: 'Ej.: 1 comprimido de 50 mg'),
          ),
          const SizedBox(height: 24),
          const Text('¿Cada cuánto se toma?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SegmentedButton<TipoFrecuencia>(
            segments: const [
              ButtonSegment(
                  value: TipoFrecuencia.vecesAlDia,
                  label: Text('Veces al día'),
                  icon: Icon(Icons.today_rounded)),
              ButtonSegment(
                  value: TipoFrecuencia.cadaXHoras,
                  label: Text('Cada X horas'),
                  icon: Icon(Icons.schedule_rounded)),
            ],
            selected: {_frecuencia},
            onSelectionChanged: (s) => setState(() => _frecuencia = s.first),
          ),
          const SizedBox(height: 16),
          if (_frecuencia == TipoFrecuencia.cadaXHoras) ...[
            DropdownButtonFormField<int>(
              initialValue: _intervaloHoras,
              decoration: const InputDecoration(labelText: 'Intervalo'),
              items: const [4, 6, 8, 12, 24]
                  .map((h) => DropdownMenuItem(value: h, child: Text('Cada $h horas')))
                  .toList(),
              onChanged: (v) => setState(() => _intervaloHoras = v ?? 8),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.alarm_rounded),
              title: Text('Primera toma: ${_formatoHora(_minutosPrimeraToma)}'),
              onTap: () => _elegirHora(esPrimeraToma: true),
            ),
          ] else ...[
            DropdownButtonFormField<int>(
              initialValue: _vecesPorDia,
              decoration: const InputDecoration(labelText: 'Tomas por día'),
              items: List.generate(6, (i) => i + 1)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n al día')))
                  .toList(),
              onChanged: (v) => setState(() {
                _vecesPorDia = v ?? 2;
                // Ajustamos la lista de horarios al nuevo número de tomas.
                while (_minutosElegidos.length < _vecesPorDia) {
                  _minutosElegidos.add(8 * 60 + _minutosElegidos.length * 6 * 60);
                }
                _minutosElegidos = _minutosElegidos.sublist(0, _vecesPorDia);
              }),
            ),
            const SizedBox(height: 8),
            ...List.generate(_vecesPorDia, (i) {
              final etiqueta = i == 0 ? 'Toma 1 (mañana)' : 'Toma ${i + 1}';
              return ListTile(
                leading: const Icon(Icons.alarm_rounded),
                title: Text('$etiqueta: ${_formatoHora(_minutosElegidos[i])}'),
                onTap: () => _elegirHora(esPrimeraToma: false, indice: i),
              );
            }),
          ],
          const SizedBox(height: 24),
          const Text('Duración del tratamiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          SwitchListTile(
            title: const Text('Tratamiento indefinido'),
            value: _indefinido,
            onChanged: (v) => setState(() => _indefinido = v),
          ),
          if (!_indefinido)
            DropdownButtonFormField<int>(
              initialValue: _diasDuracion,
              decoration: const InputDecoration(labelText: 'Duración'),
              items: const [7, 10, 14, 30, 60, 90, 180, 365]
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d días')))
                  .toList(),
              onChanged: (v) => setState(() => _diasDuracion = v ?? 30),
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _notasController,
            decoration: const InputDecoration(
                labelText: 'Notas (opcional)', hintText: 'Ej.: tomar con comida'),
            maxLines: 2,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: const Text('Guardar medicamento'),
            onPressed: _guardar,
          ),
        ],
      ),
    );
  }
}
