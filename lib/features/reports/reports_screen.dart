import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../core/services/insights_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/services/pdf_report_service.dart';
import '../../models/emotional_record.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import 'pdf_preview_screen.dart';

enum _ReportMode { day, week }

/// Pantalla de generación y compartición de los informes PDF.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _ReportMode _mode = _ReportMode.day;
  DateTime _anchor = dateOnly(DateTime.now());
  bool _busy = false;

  bool get _isWeek => _mode == _ReportMode.week;

  DateTime get _today => dateOnly(DateTime.now());

  DateRange get _week => weekRange(_anchor);

  String get _periodLabel => _isWeek
      ? formatWeekRange(_week.start, _week.end)
      : formatLongDate(_anchor);

  String get _fileName => _isWeek
      ? PdfReportService.weeklyReportFileName(_week.start)
      : PdfReportService.dailyReportFileName(_anchor);

  String get _previewTitle =>
      _isWeek ? 'Informe semanal' : 'Informe del ${formatShortDate(_anchor)}';

  bool get _canGoNext => _isWeek
      ? _week.end.isBefore(weekRange(_today).end)
      : _anchor.isBefore(_today);

  List<EmotionalRecord> _recordsFor(List<EmotionalRecord> all) {
    final filtered = _isWeek
        ? recordsInRange(all, _week)
        : recordsForDate(all, _anchor);
    final copy = [...filtered];
    copy.sort((a, b) {
      final byDate = dateOnly(a.eventDate).compareTo(dateOnly(b.eventDate));
      if (byDate != 0) return byDate;
      final aTime = a.eventTime ?? formatTime(a.createdAt);
      final bTime = b.eventTime ?? formatTime(b.createdAt);
      final byTime = aTime.compareTo(bTime);
      if (byTime != 0) return byTime;
      return a.createdAt.compareTo(b.createdAt);
    });
    return copy;
  }

  Future<Uint8List?> _generate(
    List<EmotionalRecord> records,
    String department,
    String pseudonym,
  ) async {
    try {
      final service = ref.read(pdfReportServiceProvider);
      if (_isWeek) {
        return await service.buildWeeklyReport(
          WeeklyReportData(
            departmentName: department,
            patientPseudonym: pseudonym,
            weekStart: _week.start,
            weekEnd: _week.end,
            records: records,
            generatedAt: DateTime.now(),
          ),
        );
      }
      return await service.buildDailyReport(
        DailyReportData(
          departmentName: department,
          patientPseudonym: pseudonym,
          date: _anchor,
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
    final fileName = _fileName;
    final title = _previewTitle;
    setState(() => _busy = true);
    final bytes = await _generate(records, department, pseudonym);
    if (!mounted) return;
    setState(() => _busy = false);
    if (bytes == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            PdfPreviewScreen(bytes: bytes, fileName: fileName, title: title),
      ),
    );
  }

  Future<void> _sharePdf(
    List<EmotionalRecord> records,
    String department,
    String pseudonym,
  ) async {
    final fileName = _fileName;
    final subject = _isWeek
        ? 'Diario emocional - Semana ${formatWeekRange(_week.start, _week.end)}'
        : 'Diario emocional - ${formatReportDate(_anchor)}';
    final body = _isWeek
        ? 'Comparto el informe semanal de mi diario emocional correspondiente '
              'a la semana del ${formatWeekRange(_week.start, _week.end)}.'
        : 'Comparto el informe de mi diario emocional correspondiente al '
              '${formatReportDate(_anchor)}.';

    setState(() => _busy = true);
    final bytes = await _generate(records, department, pseudonym);
    if (!mounted) return;
    setState(() => _busy = false);
    if (bytes == null) return;

    try {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
        subject: subject,
        body: body,
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
    final baseName = _isWeek
        ? 'diario_emocional_semana_${DateFormat('yyyy-MM-dd').format(_week.start)}'
        : 'diario_emocional_${DateFormat('yyyy-MM-dd').format(_anchor)}';

    setState(() => _busy = true);
    final bytes = await _generate(records, department, pseudonym);
    if (!mounted) return;
    setState(() => _busy = false);
    if (bytes == null) return;

    try {
      final savedPath = await FileSaver.instance.saveFile(
        name: baseName,
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

  void _changeMode(_ReportMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _anchor = dateOnly(DateTime.now());
    });
  }

  void _changePeriod(int direction) {
    if (direction > 0 && !_canGoNext) return;
    setState(() {
      if (_isWeek) {
        _anchor = DateTime(
          _week.start.year,
          _week.start.month,
          _week.start.day + (7 * direction),
        );
      } else {
        _anchor = dateOnly(_anchor.add(Duration(days: direction)));
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: _anchor,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: _isWeek ? 'Semana del informe' : 'Fecha del informe',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) return;
    setState(() => _anchor = dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsProvider);
    final profile = ref.watch(profileProvider).value;
    final department = profile?.departmentName ?? 'Departamento de Psicología';
    final pseudonym = profile?.pseudonym ?? 'Paciente';

    final periodRecords = recordsAsync.value == null
        ? const <EmotionalRecord>[]
        : _recordsFor(recordsAsync.value!);
    final canGenerate = periodRecords.isNotEmpty && !_busy;

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
            InfoNote(
              icon: Icons.picture_as_pdf_rounded,
              text: _isWeek
                  ? 'Elige una semana para crear un informe con todos sus registros, '
                        'gráficos y estadísticas de las emociones. Después podrás verlo, '
                        'guardarlo o compartirlo tú mismo.'
                  : 'Elige un día para crear un informe con todos sus registros. '
                        'Después podrás verlo, guardarlo o compartirlo tú mismo.',
            ),
            const SizedBox(height: 16),
            Center(
              child: SegmentedButton<_ReportMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _ReportMode.day,
                    label: Text('Día'),
                    icon: Icon(Icons.today_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: _ReportMode.week,
                    label: Text('Semana'),
                    icon: Icon(Icons.view_week_outlined, size: 18),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) => _changeMode(selection.first),
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _changePeriod(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                        tooltip: _isWeek ? 'Semana anterior' : 'Día anterior',
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                Text(
                                  _isWeek
                                      ? 'Semana del informe'
                                      : 'Fecha del informe',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _periodLabel,
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
                        onPressed: _canGoNext ? () => _changePeriod(1) : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                        tooltip: _isWeek ? 'Semana siguiente' : 'Día siguiente',
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
                              periodRecords.isEmpty
                                  ? _isWeek
                                        ? 'Sin registros esta semana'
                                        : 'Sin registros este día'
                                  : periodRecords.length == 1
                                  ? '1 registro incluido'
                                  : '${periodRecords.length} registros incluidos',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              periodRecords.isEmpty
                                  ? 'Prueba con otro periodo o crea un registro primero.'
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
            if (periodRecords.isNotEmpty) ...[
              SectionHeader(
                title: _isWeek ? 'Registros de la semana' : 'Registros del día',
                subtitle: 'Se incluirán todos en el PDF, en orden cronológico.',
              ),
              for (final record in periodRecords)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReportRecordRow(record: record, showDate: _isWeek),
                ),
              const SizedBox(height: 14),
            ],
            FilledButton.icon(
              onPressed: canGenerate
                  ? () => _viewPdf(periodRecords, department, pseudonym)
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
                  ? () => _sharePdf(periodRecords, department, pseudonym)
                  : null,
              icon: const Icon(Icons.share_outlined),
              label: const Text('Compartir PDF'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: canGenerate
                  ? () => _savePdf(periodRecords, department, pseudonym)
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
  const _ReportRecordRow({required this.record, this.showDate = false});

  final EmotionalRecord record;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final time = record.eventTime ?? formatTime(record.createdAt);
    final badge = showDate
        ? '${formatDayMonth(record.eventDate)} · $time'
        : time;

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
              badge,
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
