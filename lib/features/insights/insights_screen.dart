import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/services/insights_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../models/record_filter.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import 'widgets/insights_widgets.dart';

/// Estadísticas personales: frecuencia de emociones, intensidad semanal y
/// calendario de registros.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  bool get _canGoNext {
    final now = DateTime.now();
    return _month.year < now.year ||
        (_month.year == now.year && _month.month < now.month);
  }

  void _previousMonth() {
    setState(() {
      _month = DateTime(_month.year, _month.month - 1, 1);
    });
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _month = DateTime(_month.year, _month.month + 1, 1);
    });
  }

  void _openDay(DateTime day) {
    ref
        .read(recordFilterProvider.notifier)
        .apply(RecordFilter(from: dateOnly(day), to: dateOnly(day)));
    AppNavigation.openDiary(context);
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsProvider);
    final catalog = ref.watch(catalogProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Tu evolución')),
      body: recordsAsync.when(
        loading: () => const LoadingView(message: 'Calculando tu evolución...'),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'No se pudieron calcular las estadísticas',
          message: 'Comprueba tu conexión e inténtalo de nuevo. Si el problema continúa, revisa la configuración.',
          actionLabel: 'Reintentar',
          onAction: () => ref.read(recordsProvider.notifier).reload(),
        ),
        data: (records) {
          if (records.isEmpty) {
            return EmptyState(
              icon: Icons.insights_rounded,
              title: 'Todavía no hay datos para mostrar',
              message: 'Cuando escribas tu primer registro podrás ver aquí tus emociones más frecuentes, la intensidad por semana y un calendario de tus días.',
              actionLabel: 'Crear un registro',
              onAction: () => AppNavigation.openRecordForm(context),
            );
          }

          final frequencies = emotionFrequency(records);
          final weekly = weeklyIntensitySeries(records);
          final counts = dailyRecordCounts(records);
          final average = averageIntensity(records);

          return RefreshIndicator(
            onRefresh: () => ref.read(recordsProvider.notifier).reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const InfoNote(
                  icon: Icons.auto_graph_rounded,
                  text:
                      'Estas cifras describen lo que has registrado. '
                      'No son una valoración ni un diagnóstico.',
                ),
                const SizedBox(height: 16),
                InsightStatsRow(
                  items: [
                    InsightStatData(
                      value: '${records.length}',
                      label: 'Registros',
                    ),
                    InsightStatData(
                      value: '${daysRecorded(records)}',
                      label: 'Días con registro',
                    ),
                    InsightStatData(
                      value: average == null ? '—' : formatIntensity(average),
                      unit: average == null ? null : '/10',
                      label: 'Intensidad media',
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const SectionHeader(
                  title: 'Mapa de calor',
                  subtitle: 'Toca un día para ver sus registros.',
                ),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
                  child: HeatmapCalendar(
                    month: _month,
                    counts: counts,
                    onPreviousMonth: _previousMonth,
                    onNextMonth: _canGoNext ? _nextMonth : null,
                    onDayTap: _openDay,
                  ),
                ),
                const SizedBox(height: 26),
                const SectionHeader(
                  title: 'Emociones más frecuentes',
                  subtitle: 'Desde tu primer registro.',
                ),
                AppCard(
                  child: EmotionFrequencyList(
                    items: frequencies,
                    catalog: catalog,
                  ),
                ),
                const SizedBox(height: 26),
                const SectionHeader(
                  title: 'Intensidad media por semana',
                  subtitle: 'Últimas 8 semanas. Solo cuenta las intensidades que indicaste.',
                ),
                AppCard(child: WeeklyIntensityChart(points: weekly)),
                const SizedBox(height: 22),
                const InfoNote(
                  text: AppTheme.privacyReminder,
                  icon: Icons.favorite_outline_rounded,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
