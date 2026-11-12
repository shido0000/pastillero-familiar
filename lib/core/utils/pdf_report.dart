// Generador de reporte PDF, 100% offline (paquete pdf) y compartible
// con cualquier app (WhatsApp, correo, guardar en archivos) vía printing.
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../features/historial/data/historial_repository.dart';

// Nombres en español sin depender de intl.
const _dias = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

String _formatoDia(DateTime f) =>
    _dias[f.weekday - 1] + ' ' + f.day.toString() + ' de ' + _meses[f.month - 1] + ' de ' + f.year.toString();

Future<void> generarYCompartirReporte({
  required ResumenHistorial resumen,
  required String nombrePerfil,
}) async {
  final pdf = pw.Document();

  final adherencia = resumen.adherencia;
  final adherenciaTexto = adherencia == null
      ? 'Sin tomas registradas aún'
      : (adherencia * 100).toStringAsFixed(0) + ' %';

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        // Encabezado
        pw.Text('Reporte de adherencia a la medicación',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Paciente: ' + nombrePerfil, style: const pw.TextStyle(fontSize: 14)),
        pw.Text('Periodo: ' + _formatoDia(resumen.dias.first.fecha) +
            ' al ' + _formatoDia(resumen.dias.last.fecha)),
        pw.SizedBox(height: 16),

        // Resumen general
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Resumen del periodo',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 6),
              pw.Text('Adherencia: ' + adherenciaTexto),
              pw.Text('Tomas programadas: ' + resumen.totalProgramadas.toString()),
              pw.Text('Tomas cumplidas: ' + resumen.totalTomadas.toString()),
              pw.Text('Tomas omitidas: ' + resumen.totalOmitidas.toString()),
              pw.Text('Tomas sin marcar: ' + resumen.totalVencidas.toString()),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Detalle día por día
        pw.Text('Detalle por día',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Día', 'Programadas', 'Cumplidas', 'Omitidas'],
          data: [
            for (final d in resumen.dias)
              [
                _formatoDia(d.fecha),
                d.slots.length.toString(),
                d.tomadas.toString(),
                (d.omitidas + d.vencidasPendientes).toString(),
              ],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
        ),
        pw.SizedBox(height: 16),

        // Medicamentos activos
        if (resumen.medicamentos.isNotEmpty) ...[
          pw.Text('Medicamentos actuales',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Medicamento', 'Dosis', 'Notas'],
            data: [
              for (final m in resumen.medicamentos)
                [m.nombre, m.dosis, m.notas ?? ''],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green900),
          ),
        ],
        pw.SizedBox(height: 24),
        pw.Text('Generado con Pastillero Familiar',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ],
    ),
  );

  // Abre el diálogo nativo de compartir/guardar (correo, WhatsApp, PDF...).
  await Printing.sharePdf(
    bytes: await pdf.save(),
    filename: 'reporte_' + nombrePerfil.toLowerCase().replaceAll(' ', '_') + '.pdf',
  );
}
