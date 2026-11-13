import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/services/insights_service.dart';
import '../../core/utils/date_utils.dart';
import '../../models/emotional_record.dart';

/// Datos necesarios para construir el informe diario.
class DailyReportData {
  const DailyReportData({
    required this.departmentName,
    required this.patientPseudonym,
    required this.date,
    required this.records,
    required this.generatedAt,
  });

  final String departmentName;
  final String patientPseudonym;
  final DateTime date;
  final List<EmotionalRecord> records;
  final DateTime generatedAt;

  List<EmotionalRecord> get sortedRecords {
    final copy = [...records];
    copy.sort((a, b) {
      final aTime = a.eventTime ?? formatTime(a.createdAt);
      final bTime = b.eventTime ?? formatTime(b.createdAt);
      final byTime = aTime.compareTo(bTime);
      if (byTime != 0) return byTime;
      return a.createdAt.compareTo(b.createdAt);
    });
    return copy;
  }
}

/// Datos necesarios para construir el informe semanal.
class WeeklyReportData {
  const WeeklyReportData({
    required this.departmentName,
    required this.patientPseudonym,
    required this.weekStart,
    required this.weekEnd,
    required this.records,
    required this.generatedAt,
  });

  final String departmentName;
  final String patientPseudonym;

  /// Lunes de la semana incluida.
  final DateTime weekStart;

  /// Domingo de la semana incluida.
  final DateTime weekEnd;

  final List<EmotionalRecord> records;
  final DateTime generatedAt;

  DateRange get range =>
      DateRange(start: dateOnly(weekStart), end: dateOnly(weekEnd));

  /// Agregados de la semana: registros, días, intensidad y emociones.
  PeriodStats get stats => periodStats(records, range);

  /// Registros de la semana ordenados por día y hora.
  List<EmotionalRecord> get sortedRecords {
    final copy = [...recordsInRange(records, range)];
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
}

/// Genera los informes PDF diarios y semanales que el paciente puede compartir.
///
/// El diseño usa A4, tipografía integrada con soporte para acentos y un
/// `MultiPage` que permite que los textos largos fluyan sin recortarse.
class PdfReportService {
  const PdfReportService();

  static const PdfColor _text = PdfColor.fromInt(0xFF26332E);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5C6B64);
  static const PdfColor _line = PdfColor.fromInt(0xFFDCD5CB);
  static const PdfColor _soft = PdfColor.fromInt(0xFFF3EFE8);

  /// Paleta serena para los gráficos del informe semanal.
  static const List<PdfColor> _palette = [
    PdfColor.fromInt(0xFF5F8575),
    PdfColor.fromInt(0xFF8C6E5D),
    PdfColor.fromInt(0xFF9A8C6E),
    PdfColor.fromInt(0xFF6D7F8C),
    PdfColor.fromInt(0xFFA0786F),
    PdfColor.fromInt(0xFF7E8C6D),
    PdfColor.fromInt(0xFF8A7C9B),
  ];

  static Future<pw.ThemeData>? _themeFuture;

  /// Carga una tipografía con soporte completo de acentos y símbolos.
  ///
  /// Se usa Noto Sans (licencia OFL, incluida en `assets/fonts/OFL.txt`) en
  /// lugar de las fuentes Helvetica integradas, que no admiten Unicode.
  static Future<pw.ThemeData> _loadTheme() {
    return _themeFuture ??= () async {
      final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
      );
      return pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: regular,
        boldItalic: bold,
      );
    }();
  }

  Future<Uint8List> buildDailyReport(DailyReportData data) async {
    final theme = await _loadTheme();

    final document = pw.Document(
      title: 'Diario emocional - ${formatNumericDate(data.date)}',
      author: data.departmentName,
      subject: 'Registro personal de emociones',
      creator: 'Diario Emocional',
    );

    final records = data.sortedRecords;
    final generatedLabel =
        '${formatReportDate(data.generatedAt)} a las ${formatTime(data.generatedAt)}';

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 40, 42, 46),
        theme: theme,
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            '${data.departmentName}  |  Diario emocional',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Registro personal del paciente. Generado el $generatedLabel.',
                  style: const pw.TextStyle(fontSize: 7.5, color: _muted),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 7.5, color: _muted),
              ),
            ],
          ),
        ),
        build: (context) => [
          _buildHeader(data, records.length),
          pw.SizedBox(height: 18),
          ..._buildRecords(records, data.date),
          pw.SizedBox(height: 16),
          _buildClosingNote(),
        ],
      ),
    );

    return document.save();
  }

  /// Genera un informe con todos los registros de una semana.
  ///
  /// Incluye métricas del periodo, un gráfico de las emociones más frecuentes,
  /// la distribución por grupos, una tabla de estadísticas y la tabla completa
  /// de registros. El documento se genera en el dispositivo.
  Future<Uint8List> buildWeeklyReport(WeeklyReportData data) async {
    final theme = await _loadTheme();
    final records = data.sortedRecords;
    final stats = data.stats;
    final weekLabel = formatWeekRange(data.weekStart, data.weekEnd);

    final document = pw.Document(
      title: 'Diario emocional - Semana $weekLabel',
      author: data.departmentName,
      subject: 'Resumen semanal del registro personal de emociones',
      creator: 'Diario Emocional',
    );

    final generatedLabel =
        '${formatReportDate(data.generatedAt)} a las ${formatTime(data.generatedAt)}';

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 40, 42, 46),
        theme: theme,
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Text(
            '${data.departmentName}  |  Diario emocional  |  Informe semanal',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  'Registro personal del paciente. Generado el $generatedLabel.',
                  style: const pw.TextStyle(fontSize: 7.5, color: _muted),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 7.5, color: _muted),
              ),
            ],
          ),
        ),
        build: (context) => [
          _buildWeeklyHeader(data, records.length),
          pw.SizedBox(height: 16),
          if (records.isEmpty)
            _buildEmptyWeek(data)
          else ...[
            _buildWeeklyMetrics(stats),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              'Emociones más frecuentes',
              'Las emociones que más veces has registrado durante la semana.',
            ),
            pw.SizedBox(height: 8),
            _buildTopEmotionChart(stats),
            pw.SizedBox(height: 18),
            _buildSectionTitle(
              'Distribución por grupo',
              'Peso de cada grupo emocional sobre el total de emociones registradas.',
            ),
            pw.SizedBox(height: 8),
            _buildGroupDistribution(stats),
            pw.SizedBox(height: 18),
            _buildSectionTitle(
              'Estadísticas de las emociones',
              'Frecuencia, porcentaje del total e intensidad media de cada emoción.',
            ),
            pw.SizedBox(height: 8),
            _buildEmotionStatsTable(stats, records),
            pw.SizedBox(height: 20),
            _buildSectionTitle(
              'Registros de la semana',
              'Todos los registros incluidos, ordenados por día y hora.',
            ),
            pw.SizedBox(height: 8),
            _buildWeeklyRecordsTable(records),
          ],
          pw.SizedBox(height: 16),
          _buildClosingNote(),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildWeeklyHeader(WeeklyReportData data, int recordCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            data.departmentName.toUpperCase(),
            style: const pw.TextStyle(
              fontSize: 9,
              letterSpacing: 1.2,
              color: _muted,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Informe semanal',
            style: const pw.TextStyle(
              fontSize: 22,
              color: _text,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Diario emocional',
            style: const pw.TextStyle(fontSize: 10, color: _muted),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _headerField(
                  'Paciente',
                  data.patientPseudonym.isEmpty
                      ? 'Sin identificar'
                      : data.patientPseudonym,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _headerField(
                  'Semana',
                  formatWeekRange(data.weekStart, data.weekEnd),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _headerField(
                  'Fecha del informe',
                  '${formatReportDate(data.generatedAt)} - '
                      '${formatTime(data.generatedAt)}',
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _headerField(
                  'Registros incluidos',
                  '$recordCount ${recordCount == 1 ? 'registro' : 'registros'}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildWeeklyMetrics(PeriodStats stats) {
    final average = stats.averageIntensity;
    final topEmotion = stats.topEmotionName;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _weeklyMetric('Registros', '${stats.recordCount}')),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _weeklyMetric('Días con registro', '${stats.daysRecorded}'),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _weeklyMetric(
            'Intensidad media',
            average == null ? '—' : formatIntensity(average),
            unit: average == null ? null : '/10',
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: _weeklyMetric(
            'Emoción más frecuente',
            topEmotion ?? '—',
            compact: true,
          ),
        ),
      ],
    );
  }

  pw.Widget _weeklyMetric(
    String label,
    String value, {
    String? unit,
    bool compact = false,
  }) {
    return pw.Container(
      constraints: const pw.BoxConstraints(minHeight: 56),
      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _line, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(
              fontSize: 5.8,
              letterSpacing: 0.5,
              color: _muted,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Text(
                  value,
                  maxLines: 2,
                  style: pw.TextStyle(
                    fontSize: compact ? 10 : 17,
                    color: _text,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if (unit != null) ...[
                pw.SizedBox(width: 2),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(
                    unit,
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 13,
            color: _text,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          subtitle,
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ],
    );
  }

  pw.Widget _buildTopEmotionChart(PeriodStats stats) {
    final items = stats.emotions.take(6).toList(growable: false);
    if (items.isEmpty) {
      return _mutedMessage('No hay emociones registradas en esta semana.');
    }

    final maxCount = items.first.count;
    final total = stats.emotions.fold<int>(0, (sum, item) => sum + item.count);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _line, width: 0.5),
      ),
      child: pw.Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) pw.SizedBox(height: 8),
            _buildEmotionBarRow(
              item: items[index],
              maxCount: maxCount,
              total: total,
              color: _palette[index % _palette.length],
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildEmotionBarRow({
    required EmotionFrequency item,
    required int maxCount,
    required int total,
    required PdfColor color,
  }) {
    final remaining = maxCount - item.count;
    final percent = total == 0 ? 0 : (item.count / total * 100).round();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(
          width: 96,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.name,
                maxLines: 1,
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: _text,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                item.groupName,
                maxLines: 1,
                style: const pw.TextStyle(fontSize: 6.5, color: _muted),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: item.count,
                child: pw.Container(
                  height: 8,
                  decoration: pw.BoxDecoration(
                    color: color,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
              ),
              if (remaining > 0)
                pw.Expanded(
                  flex: remaining,
                  child: pw.Container(
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: _soft,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.SizedBox(
          width: 46,
          child: pw.Text(
            '${item.count} ($percent %)',
            textAlign: pw.TextAlign.right,
            style: const pw.TextStyle(fontSize: 7.5, color: _muted),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildGroupDistribution(PeriodStats stats) {
    final groups = _groupCounts(stats.emotions);
    if (groups.isEmpty) {
      return _mutedMessage(
        'No hay grupos emocionales que mostrar en esta semana.',
      );
    }

    final total = groups.fold<int>(0, (sum, group) => sum + group.count);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: _line, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 140,
            height: 130,
            child: pw.Chart(
              grid: pw.PieGrid(),
              datasets: [
                for (var index = 0; index < groups.length; index++)
                  pw.PieDataSet(
                    value: groups[index].count,
                    color: _palette[index % _palette.length],
                    legendPosition: pw.PieLegendPosition.none,
                    innerRadius: 24,
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < groups.length; index++) ...[
                  if (index > 0) pw.SizedBox(height: 6),
                  _buildGroupLegendRow(
                    group: groups[index],
                    total: total,
                    color: _palette[index % _palette.length],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildGroupLegendRow({
    required _EmotionGroupCount group,
    required int total,
    required PdfColor color,
  }) {
    final percent = total == 0 ? 0 : (group.count / total * 100).round();

    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            group.name,
            maxLines: 1,
            style: const pw.TextStyle(fontSize: 8.5, color: _text),
          ),
        ),
        pw.Text(
          '${group.count} ($percent %)',
          style: const pw.TextStyle(fontSize: 7.5, color: _muted),
        ),
      ],
    );
  }

  pw.Widget _buildEmotionStatsTable(
    PeriodStats stats,
    List<EmotionalRecord> records,
  ) {
    if (stats.emotions.isEmpty) {
      return _mutedMessage('No hay emociones registradas en esta semana.');
    }

    final total = stats.emotions.fold<int>(0, (sum, item) => sum + item.count);
    final rows = <List<String>>[];
    for (final emotion in stats.emotions) {
      final average = _averageIntensityForEmotion(records, emotion);
      rows.add([
        emotion.name,
        emotion.groupName,
        '${emotion.count}',
        '${(emotion.count / total * 100).round()} %',
        average == null ? '—' : '${formatIntensity(average)}/10',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: const [
        'Emoción',
        'Grupo',
        'Veces',
        '% del total',
        'Intensidad media',
      ],
      data: rows,
      headerStyle: const pw.TextStyle(
        fontSize: 7.5,
        color: _text,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 7.5, color: _text),
      headerDecoration: const pw.BoxDecoration(color: _soft),
      headerAlignment: pw.Alignment.centerLeft,
      headerAlignments: const {
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      cellAlignments: const {
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      border: const pw.TableBorder(
        top: pw.BorderSide(color: _line, width: 0.5),
        bottom: pw.BorderSide(color: _line, width: 0.5),
        horizontalInside: pw.BorderSide(color: _line, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.4),
        1: pw.FlexColumnWidth(1.8),
        2: pw.FixedColumnWidth(34),
        3: pw.FixedColumnWidth(52),
        4: pw.FixedColumnWidth(62),
      },
    );
  }

  pw.Widget _buildWeeklyRecordsTable(List<EmotionalRecord> records) {
    if (records.isEmpty) {
      return _mutedMessage('No hay registros en esta semana.');
    }

    final rows = <List<String>>[];
    for (final record in records) {
      final day = formatDayMonth(record.eventDate);
      final time = record.eventTime ?? formatTime(record.createdAt);
      final emotions = record.emotions.isEmpty
          ? '—'
          : record.emotions
                .map((emotion) {
                  final intensity = emotion.intensity == null
                      ? ''
                      : ' (${emotion.intensity}/10)';
                  return '${emotion.name}$intensity';
                })
                .join(', ');
      rows.add([
        day,
        time,
        record.displayTitle,
        emotions,
        record.maxIntensity == null ? '—' : '${record.maxIntensity}/10',
      ]);
    }

    return pw.TableHelper.fromTextArray(
      headers: const ['Día', 'Hora', 'Título', 'Emociones', 'Intensidad'],
      data: rows,
      headerStyle: const pw.TextStyle(
        fontSize: 7.5,
        color: _text,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 7.2, color: _text),
      headerDecoration: const pw.BoxDecoration(color: _soft),
      headerAlignment: pw.Alignment.centerLeft,
      headerAlignments: const {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      cellAlignments: const {
        0: pw.Alignment.center,
        1: pw.Alignment.center,
        4: pw.Alignment.center,
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      border: const pw.TableBorder(
        top: pw.BorderSide(color: _line, width: 0.5),
        bottom: pw.BorderSide(color: _line, width: 0.5),
        horizontalInside: pw.BorderSide(color: _line, width: 0.4),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(42),
        1: pw.FixedColumnWidth(32),
        2: pw.FlexColumnWidth(2.1),
        3: pw.FlexColumnWidth(2.7),
        4: pw.FixedColumnWidth(48),
      },
    );
  }

  pw.Widget _buildEmptyWeek(WeeklyReportData data) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        'No hay registros emocionales entre el '
        '${formatReportDate(data.weekStart)} y el '
        '${formatReportDate(data.weekEnd)}.',
        style: const pw.TextStyle(fontSize: 10, color: _muted),
      ),
    );
  }

  pw.Widget _mutedMessage(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        message,
        style: const pw.TextStyle(fontSize: 9, color: _muted),
      ),
    );
  }

  List<_EmotionGroupCount> _groupCounts(List<EmotionFrequency> emotions) {
    final counters = <String, _EmotionGroupCount>{};
    for (final emotion in emotions) {
      final current = counters[emotion.groupId];
      if (current == null) {
        counters[emotion.groupId] = _EmotionGroupCount(
          name: emotion.groupName,
          count: emotion.count,
        );
      } else {
        current.count += emotion.count;
      }
    }

    final result = counters.values.toList(growable: false);
    result.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  double? _averageIntensityForEmotion(
    List<EmotionalRecord> records,
    EmotionFrequency frequency,
  ) {
    var sum = 0;
    var count = 0;
    for (final record in records) {
      for (final emotion in record.emotions) {
        final sameEmotion = frequency.emotionId.isNotEmpty
            ? emotion.emotionId == frequency.emotionId
            : emotion.name == frequency.name &&
                  emotion.groupId == frequency.groupId;
        if (!sameEmotion) continue;
        final intensity = emotion.intensity;
        if (intensity == null) continue;
        sum += intensity;
        count += 1;
      }
    }
    if (count == 0) return null;
    return sum / count;
  }

  pw.Widget _buildHeader(DailyReportData data, int recordCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _line, width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            data.departmentName.toUpperCase(),
            style: const pw.TextStyle(
              fontSize: 9,
              letterSpacing: 1.2,
              color: _muted,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Diario emocional',
            style: const pw.TextStyle(
              fontSize: 22,
              color: _text,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _headerField(
                  'Paciente',
                  data.patientPseudonym.isEmpty
                      ? 'Sin identificar'
                      : data.patientPseudonym,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _headerField(
                  'Fecha de los registros',
                  formatReportDate(data.date),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _headerField('Fecha del informe', generatedDate(data)),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _headerField(
                  'Registros incluidos',
                  '$recordCount ${recordCount == 1 ? 'registro' : 'registros'}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String generatedDate(DailyReportData data) =>
      '${formatReportDate(data.generatedAt)} - ${formatTime(data.generatedAt)}';

  pw.Widget _headerField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(
            fontSize: 6.5,
            letterSpacing: 0.8,
            color: _muted,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(value, style: const pw.TextStyle(fontSize: 10, color: _text)),
      ],
    );
  }

  List<pw.Widget> _buildRecords(List<EmotionalRecord> records, DateTime date) {
    if (records.isEmpty) {
      return [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _soft,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            'No hay registros emocionales para el ${formatReportDate(date)}.',
            style: const pw.TextStyle(fontSize: 10, color: _muted),
          ),
        ),
      ];
    }

    final widgets = <pw.Widget>[];
    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      widgets.addAll(_buildRecord(record, index + 1, records.length));
      if (index < records.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
        widgets.add(pw.Divider(color: _line, thickness: 0.5, height: 16));
      }
    }
    return widgets;
  }

  List<pw.Widget> _buildRecord(EmotionalRecord record, int index, int total) {
    final time = record.eventTime ?? formatTime(record.createdAt);
    final widgets = <pw.Widget>[
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'Registro $index de $total',
            style: const pw.TextStyle(
              fontSize: 8,
              letterSpacing: 0.6,
              color: _muted,
            ),
          ),
          pw.Text(
            'Hora: $time',
            style: const pw.TextStyle(
              fontSize: 9,
              color: _text,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 6),
      _field('Título', record.displayTitle),
      pw.SizedBox(height: 6),
      _field('Situación', record.situation),
      pw.SizedBox(height: 6),
      _emotionsField(record),
      pw.SizedBox(height: 6),
      _field('Pensamiento', record.thought),
      pw.SizedBox(height: 6),
      _field('Conducta', record.behavior),
    ];

    if (record.freeText != null && record.freeText!.trim().isNotEmpty) {
      widgets
        ..add(pw.SizedBox(height: 6))
        ..add(_field('En sus propias palabras', record.freeText!.trim()));
    }

    return widgets;
  }

  pw.Widget _field(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(
            fontSize: 6.5,
            letterSpacing: 0.8,
            color: _muted,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value.trim().isEmpty ? '-' : value.trim(),
          style: const pw.TextStyle(
            fontSize: 9.5,
            color: _text,
            lineSpacing: 2,
          ),
        ),
      ],
    );
  }

  pw.Widget _emotionsField(EmotionalRecord record) {
    final children = <pw.Widget>[
      pw.Text(
        'EMOCIONES',
        style: const pw.TextStyle(
          fontSize: 6.5,
          letterSpacing: 0.8,
          color: _muted,
        ),
      ),
      pw.SizedBox(height: 3),
    ];

    if (record.emotions.isEmpty) {
      children.add(
        pw.Text('-', style: const pw.TextStyle(fontSize: 9.5, color: _text)),
      );
    } else {
      for (final emotion in record.emotions) {
        final intensity = emotion.intensity == null
            ? 'sin intensidad indicada'
            : 'intensidad ${emotion.intensity}/10';
        children.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              '• ${emotion.name} (${emotion.groupName}) - $intensity',
              style: const pw.TextStyle(fontSize: 9.5, color: _text),
            ),
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _buildClosingNote() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line, width: 0.6),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        'Este documento contiene información personal y sensible. '
        'Ha sido generado por el propio paciente desde Diario Emocional y no '
        'constituye un diagnóstico ni una valoración clínica. Compártelo '
        'únicamente con las personas que elijas.',
        style: const pw.TextStyle(
          fontSize: 7.5,
          color: _muted,
          lineSpacing: 1.5,
        ),
      ),
    );
  }

  static String dailyReportFileName(DateTime date) {
    final formatted = DateFormat('yyyy-MM-dd').format(date);
    return 'diario_emocional_$formatted.pdf';
  }

  static String weeklyReportFileName(DateTime weekStart) {
    final formatted = DateFormat('yyyy-MM-dd').format(weekStart);
    return 'diario_emocional_semana_$formatted.pdf';
  }
}

class _EmotionGroupCount {
  _EmotionGroupCount({required this.name, required this.count});

  final String name;
  int count;
}
