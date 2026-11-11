import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/insights_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import 'widgets/insights_widgets.dart';

enum _SummaryMode { week, month }

/// Resumen semanal o mensual con una lectura breve de los cambios.
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  _SummaryMode _mode = _SummaryMode.week;
  DateTime _anchor = dateOnly(DateTime.now());

  DateRange get _range =>
      _mode == _SummaryMode.week ? weekRange(_anchor) : monthRange(_anchor);

  DateRange get _previousRange => _mode == _SummaryMode.week
      ? previousWeekRange(_range)
      : previousMonthRange(_range);

  bool get _canGoNext {
    final currentRange = _mode == _SummaryMode.week
        ? weekRange(DateTime.now())
        : monthRange(DateTime.now());
    return _range.end.isBefore(currentRange.end);
  }

  void _changeMode(_SummaryMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _anchor = dateOnly(DateTime.now());
    });
  }

  void _previous() {
    setState(() {
      _anchor = _mode == _SummaryMode.week
          ? DateTime(
              _range.start.year,
              _range.start.month,
              _range.start.day - 7,
            )
          : DateTime(_range.start.year, _range.start.month - 1, 1);
    });
  }

  void _next() {
    if (!_canGoNext) return;
    setState(() {
      _anchor = _mode == _SummaryMode.week
          ? DateTime(
              _range.start.year,
              _range.start.month,
              _range.start.day + 7,
            )
          : DateTime(_range.start.year, _range.start.month + 1, 1);
    });
  }

  String get _periodLabel => _mode == _SummaryMode.week
      ? formatWeekRange(_range.start, _range.end)
      : formatMonthYear(_range.start);

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsProvider);
    final catalog = ref.watch(catalogProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen')),
      body: recordsAsync.when(
        loading: () => const LoadingView(message: 'Preparando tu resumen...'),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'No se pudo preparar el resumen',
          message: 'Comprueba tu conexión e inténtalo de nuevo. Si el problema continúa, revisa la configuración.',
          actionLabel: 'Reintentar',
          onAction: () => ref.read(recordsProvider.notifier).reload(),
        ),
        data: (records) {
          final current = periodStats(records, _range);
          final previous = periodStats(records, _previousRange);
          final comparison = PeriodComparison(
            current: current,
            previous: previous,
          );
          final highlights = summaryHighlights(
            comparison,
            isMonth: _mode == _SummaryMode.month,
            today: DateTime.now(),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              const InfoNote(
                icon: Icons.notes_rounded,
                text:
                    'Un resumen descriptivo de lo que has registrado. '
                    'Sin rachas ni valoraciones sobre cómo deberías sentirte.',
              ),
              const SizedBox(height: 16),
              Center(
                child: SegmentedButton<_SummaryMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _SummaryMode.week,
                      label: Text('Semana'),
                      icon: Icon(Icons.view_week_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: _SummaryMode.month,
                      label: Text('Mes'),
                      icon: Icon(Icons.calendar_month_outlined, size: 18),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) =>
                      _changeMode(selection.first),
                ),
              ),
              const SizedBox(height: 14),
              PeriodNavigator(
                label: _periodLabel,
                onPrevious: _previous,
                onNext: _canGoNext ? _next : null,
              ),
              const SizedBox(height: 18),
              if (!current.hasRecords)
                _EmptyPeriodCard(
                  isMonth: _mode == _SummaryMode.month,
                  onPrevious: _previous,
                )
              else ...[
                InsightStatsRow(
                  items: [
                    InsightStatData(
                      value: '${current.recordCount}',
                      label: 'Registros',
                    ),
                    InsightStatData(
                      value: '${current.daysRecorded}',
                      label: 'Días con registro',
                    ),
                    InsightStatData(
                      value: current.averageIntensity == null
                          ? '—'
                          : formatIntensity(current.averageIntensity!),
                      unit: current.averageIntensity == null ? null : '/10',
                      label: 'Intensidad media',
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                SectionHeader(
                  title: 'Qué ha cambiado',
                  subtitle:
                      'Comparado con ${_mode == _SummaryMode.week ? 'la semana' : 'el mes'} anterior.',
                ),
                AppCard(
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < highlights.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(height: 14),
                        _HighlightRow(highlight: highlights[index]),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const SectionHeader(
                  title: 'Emociones más presentes',
                  subtitle: 'Hasta tres emociones de este periodo.',
                ),
                AppCard(
                  child: EmotionFrequencyList(
                    items: current.emotions,
                    catalog: catalog,
                    maxItems: 3,
                  ),
                ),
                const SizedBox(height: 22),
                const InfoNote(
                  text:
                      'Puedes leer este resumen antes de tu sesión o compartir '
                      'el informe PDF del día que tú elijas.',
                  icon: Icons.favorite_outline_rounded,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight});

  final SummaryHighlight highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppTheme.seed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(_iconFor(highlight.kind), size: 17, color: AppTheme.seed),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              highlight.text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(SummaryHighlightKind kind) {
    switch (kind) {
      case SummaryHighlightKind.records:
        return Icons.edit_note_rounded;
      case SummaryHighlightKind.days:
        return Icons.calendar_month_rounded;
      case SummaryHighlightKind.intensity:
        return Icons.speed_rounded;
      case SummaryHighlightKind.emotion:
        return Icons.emoji_emotions_outlined;
      case SummaryHighlightKind.group:
        return Icons.category_outlined;
    }
  }
}

class _EmptyPeriodCard extends StatelessWidget {
  const _EmptyPeriodCard({required this.isMonth, required this.onPrevious});

  final bool isMonth;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.event_note_rounded, size: 30, color: AppTheme.seed),
          const SizedBox(height: 10),
          Text(
            'No hay registros en este ${isMonth ? 'mes' : 'periodo'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Puedes volver al periodo anterior o crear un registro cuando quieras.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Ver periodo anterior'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    );
  }
}
