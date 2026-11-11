import 'package:flutter/material.dart';

import '../../../core/services/insights_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/emotion_style.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/emotion_group.dart';

/// Dato breve para las filas de resumen.
class InsightStatData {
  const InsightStatData({required this.value, required this.label, this.unit});

  final String value;
  final String label;
  final String? unit;
}

/// Tres cifras principales en una fila adaptable.
class InsightStatsRow extends StatelessWidget {
  const InsightStatsRow({super.key, required this.items});

  final List<InsightStatData> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(child: _StatCard(data: items[index])),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final InsightStatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              if (data.unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  data.unit!,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              height: 1.25,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de emociones con una barra proporcional a su frecuencia.
class EmotionFrequencyList extends StatelessWidget {
  const EmotionFrequencyList({
    super.key,
    required this.items,
    this.catalog,
    this.maxItems = 6,
    this.showGroup = true,
  });

  final List<EmotionFrequency> items;
  final EmotionCatalog? catalog;
  final int maxItems;
  final bool showGroup;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(maxItems).toList(growable: false);
    if (visible.isEmpty) {
      return const Text(
        'Todavía no hay emociones registradas en este periodo.',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      );
    }

    final maxCount = visible
        .map((item) => item.count)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var index = 0; index < visible.length; index++) ...[
          if (index > 0) const SizedBox(height: 14),
          _EmotionBar(
            item: visible[index],
            maxCount: maxCount,
            color: EmotionStyle.colorFromHex(
              catalog?.groupById(visible[index].groupId)?.colorHex ?? '#5F8575',
            ),
            showGroup: showGroup,
          ),
        ],
      ],
    );
  }
}

class _EmotionBar extends StatelessWidget {
  const _EmotionBar({
    required this.item,
    required this.maxCount,
    required this.color,
    required this.showGroup,
  });

  final EmotionFrequency item;
  final int maxCount;
  final Color color;
  final bool showGroup;

  @override
  Widget build(BuildContext context) {
    final value = maxCount == 0 ? 0.0 : item.count / maxCount;

    return Semantics(
      label: '${item.name}: ${item.count} ${item.count == 1 ? 'vez' : 'veces'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.count}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          if (showGroup) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                item.groupName,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: AppTheme.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barras verticales con la intensidad media de las últimas semanas.
class WeeklyIntensityChart extends StatelessWidget {
  const WeeklyIntensityChart({super.key, required this.points});

  final List<WeeklyIntensity> points;

  @override
  Widget build(BuildContext context) {
    final hasIntensity = points.any((point) => point.average != null);
    if (!hasIntensity) {
      return const Text(
        'Aún no hay intensidades indicadas en estas semanas. '
        'Puedes añadirlas al crear o editar un registro.',
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          color: AppTheme.textSecondary,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 148,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points)
                Expanded(child: _WeekBar(point: point)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final point in points)
              Expanded(
                child: Text(
                  formatDayMonth(point.weekStart),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({required this.point});

  final WeeklyIntensity point;

  @override
  Widget build(BuildContext context) {
    final average = point.average;
    final height = average == null
        ? 3.0
        : 4 + (average.clamp(0, 10) / 10) * 110;
    final color = average == null ? AppTheme.outline : AppTheme.seed;

    return Semantics(
      label:
          'Semana del ${formatReportDate(point.weekStart)}: '
          '${average == null ? 'sin intensidad' : '${formatIntensity(average)} de media'}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            average == null ? '—' : formatIntensity(average),
            maxLines: 1,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Calendario mensual con un color más intenso según el número de registros.
class HeatmapCalendar extends StatelessWidget {
  const HeatmapCalendar({
    super.key,
    required this.month,
    required this.counts,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<DateTime, int> counts;
  final VoidCallback onPreviousMonth;

  /// `null` desactiva el botón de mes siguiente.
  final VoidCallback? onNextMonth;

  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final days = monthGridDays(month);

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Mes anterior',
            ),
            Expanded(
              child: Text(
                formatMonthYear(month),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Mes siguiente',
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            for (final label in const ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            if (day == null) return const SizedBox.shrink();
            return _HeatDay(
              day: day,
              count: counts[day] ?? 0,
              onTap: () => onDayTap(day),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Menos',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 5),
            for (var count = 1; count <= 4; count++) ...[
              _HeatLegendBox(count: count),
              const SizedBox(width: 3),
            ],
            const SizedBox(width: 2),
            const Text(
              'Más',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeatDay extends StatelessWidget {
  const _HeatDay({required this.day, required this.count, required this.onTap});

  final DateTime day;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _heatColor(count);
    final textColor = count >= 3 ? Colors.white : AppTheme.textPrimary;

    return Semantics(
      label:
          '${formatReportDate(day)}: '
          '${count == 0 ? 'sin registros' : '$count ${count == 1 ? 'registro' : 'registros'}'}',
      button: true,
      excludeSemantics: true,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: count > 0 ? FontWeight.w700 : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatLegendBox extends StatelessWidget {
  const _HeatLegendBox({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _heatColor(count),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

Color _heatColor(int count) {
  if (count <= 0) return AppTheme.surfaceMuted;
  final alpha = count >= 4 ? 0.82 : 0.16 + (count * 0.16);
  return AppTheme.seed.withValues(alpha: alpha);
}

/// Selector de periodo con flechas para el resumen.
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;

  /// `null` desactiva el botón de periodo siguiente.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Periodo anterior',
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Periodo siguiente',
          ),
        ],
      ),
    );
  }
}
