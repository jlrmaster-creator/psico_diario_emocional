import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/services/pdf_report_service.dart';
import '../../models/emotional_record.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import 'pdf_preview_screen.dart';

/// Pantalla de generación y compartición del informe diario.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _date = dateOnly(DateTime.now());
  bool _busy = false;

  Future<Uint8List?> _generate(
    List<EmotionalRecord> records,
    String department,
    String pseudonym,
  ) async {
    try {
      return await ref
          .read(pdfReportServiceProvider)
          .buildDailyReport(
            DailyReportData(
              departmentName: department,
              patientPseudonym: pseudonym,
              date: _date,
              records: records,
              generatedAt: DateTime.now(),
            ),
          );
    } catch (error) {
      if (!mounted) return null;
      showErrorSnack(context, 'No se pudo generar el PDF. Inténtalo de nuevo.');
      debugPrint('Error generando PDF: $error');
      return null;
    }
  }

  Future<void> _viewPdf(
    List<EmotionalRecord> records,
    String department,
    String pseudonym,
  ) async {
    setState(() => _busy = true);
    final bytes = await _generate(records, department, pseudonym);
    if (!mounted) return;
    setState(() => _busy = false);
    if (bytes == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfPreviewScreen(
          bytes: bytes,
          fileName: PdfReportService.dailyReportFileName(_date),
          title: 'Informe del ${formatShortDate(_date)}',
        ),
      ),
    );
  }

  Future<void> _sharePdf(
    List<EmotionalRecord> records,
    String department,
    String pseudonym,
  ) async {
    setState(() => _busy = true);
    final bytes = await _generate(records, department, pseudonym);
    if (!mounted) return;
    setState(() => _busy = false);
    if (bytes == null) return;

    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: PdfReportService.dailyReportFileName(_date),
        subject: 'Diario emocional - ${formatReportDate(_date)}',
        body:
            'Comparto el informe de mi diario emocional correspondiente al ${formatReportDate(_date)}.',
      );
    } catch (error) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'No se pudo abrir el menú de compartir. Inténtalo de nuevo.',
      );
      debugPrint('Error compartiendo PDF: $error');
    }
  }

  Future<void> _savePdf(
    List<EmotionalRecord> records,
    String department,
    String pseudonym,
  ) async {
    setState(() => _busy = true);
    final bytes = await _generate(records, department, pseudonym);
    if (!mounted) return;
    setState(() => _busy = false);
    if (bytes == null) return;

    try {
      final savedPath = await FileSaver.instance.saveFile(
        name: 'diario_emocional_${DateFormat('yyyy-MM-dd').format(_date)}',
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      if (!mounted) return;
      showSuccessSnack(
        context,
        savedPath.isEmpty
            ? 'PDF guardado en el dispositivo.'
            : 'PDF guardado: $savedPath',
      );
    } catch (error) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'No se pudo guardar el PDF. Puedes usar “Compartir” y elegir Guardar en archivos.',
      );
      debugPrint('Error guardando PDF: $error');
    }
  }

  void _changeDate(int days) {
    final candidate = dateOnly(_date.add(Duration(days: days)));
    if (candidate.isAfter(dateOnly(DateTime.now()))) return;
    setState(() => _date = candidate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha del informe',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) return;
    setState(() => _date = dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsProvider);
    final profile = ref.watch(profileProvider).value;
    final department = profile?.departmentName ?? 'Departamento de Psicología';
    final pseudonym = profile?.pseudonym ?? 'Paciente';

    final dayRecords = recordsAsync.value == null
        ? const <EmotionalRecord>[]
        : recordsForDate(recordsAsync.value!, _date);
    final canGenerate = dayRecords.isNotEmpty && !_busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Informes PDF')),
      body: recordsAsync.when(
        loading: () => const LoadingView(message: 'Cargando registros...'),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'No se pudieron cargar los registros',
          message: 'Comprueba tu conexión e inténtalo de nuevo antes de generar el informe.',
          actionLabel: 'Reintentar',
          onAction: () => ref.read(recordsProvider.notifier).reload(),
        ),
        data: (_) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const InfoNote(
              icon: Icons.picture_as_pdf_rounded,
              text: 'Elige un día para crear un informe con todos sus registros. Después podrás verlo, guardarlo o compartirlo tú mismo.',
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _changeDate(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: 'Día anterior',
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                const Text(
                                  'Fecha del informe',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatLongDate(_date),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _date.isBefore(dateOnly(DateTime.now()))
                            ? () => _changeDate(1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: 'Día siguiente',
                      ),
                    ],
                  ),
                  const Divider(height: 22),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.seed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppTheme.seed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayRecords.isEmpty
                                  ? 'Sin registros este día'
                                  : dayRecords.length == 1
                                  ? '1 registro incluido'
                                  : '${dayRecords.length} registros incluidos',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dayRecords.isEmpty
                                  ? 'Prueba con otra fecha o crea un registro primero.'
                                  : 'Paciente: $pseudonym',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (dayRecords.isNotEmpty) ...[
              const SectionHeader(
                title: 'Registros del día',
                subtitle: 'Se incluirán todos en el PDF, en orden cronológico.',
              ),
              for (final record in dayRecords)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReportRecordRow(record: record),
                ),
              const SizedBox(height: 14),
            ],
            FilledButton.icon(
              onPressed: canGenerate
                  ? () => _viewPdf(dayRecords, department, pseudonym)
                  : null,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.visibility_outlined),
              label: Text(_busy ? 'Generando...' : 'Ver informe PDF'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: canGenerate
                  ? () => _sharePdf(dayRecords, department, pseudonym)
                  : null,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir PDF'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: canGenerate
                  ? () => _savePdf(dayRecords, department, pseudonym)
                  : null,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Guardar PDF en el dispositivo'),
            ),
            const SizedBox(height: 16),
            const InfoNote(
              icon: Icons.lock_outline_rounded,
              text: 'El informe incluye un seudónimo, no tu nombre real. Se genera en tu dispositivo y solo se comparte si tú eliges hacerlo.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRecordRow extends StatelessWidget {
  const _ReportRecordRow({required this.record});

  final EmotionalRecord record;

  @override
  Widget build(BuildContext context) {
    final time = record.eventTime ?? formatTime(record.createdAt);
    return AppCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              record.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
