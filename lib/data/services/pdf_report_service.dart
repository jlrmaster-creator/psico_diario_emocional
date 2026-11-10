import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

/// Genera el informe PDF diario que el paciente puede compartir.
///
/// El diseño usa A4, tipografía integrada con soporte para acentos y un
/// `MultiPage` que permite que los textos largos fluyan sin recortarse.
class PdfReportService {
  const PdfReportService();

  static const PdfColor _text = PdfColor.fromInt(0xFF26332E);
  static const PdfColor _muted = PdfColor.fromInt(0xFF5C6B64);
  static const PdfColor _line = PdfColor.fromInt(0xFFDCD5CB);
  static const PdfColor _soft = PdfColor.fromInt(0xFFF3EFE8);

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
}
