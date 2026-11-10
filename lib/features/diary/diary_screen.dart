import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/emotion_style.dart';
import '../../core/utils/date_utils.dart';
import '../../models/emotion_group.dart';
import '../../models/emotional_record.dart';
import '../../models/record_filter.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import 'filter_sheet.dart';
import 'widgets/record_card.dart';

/// Historial cronológico del diario emocional.
class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  Future<void> _openFilters(BuildContext context, WidgetRef ref) async {
    final catalog = ref.read(catalogProvider).value;
    if (catalog == null) return;
    final current = ref.read(recordFilterProvider);
    final result = await showRecordFilterSheet(
      context,
      current: current,
      catalog: catalog,
    );
    if (result == null) return;
    ref.read(recordFilterProvider.notifier).apply(result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(filteredRecordsProvider);
    final allAsync = ref.watch(recordsProvider);
    final catalog = ref.watch(catalogProvider).value;
    final filter = ref.watch(recordFilterProvider);

    final filteredCount = recordsAsync.value?.length ?? 0;
    final totalCount = allAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi diario emocional'),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () => _openFilters(context, ref),
                icon: const Icon(Icons.filter_alt_outlined),
                tooltip: 'Filtrar registros',
              ),
              if (filter.isActive)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.seed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppNavigation.openRecordForm(context),
        backgroundColor: AppTheme.seed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo registro'),
      ),
      body: recordsAsync.when(
        loading: () => const LoadingView(message: 'Cargando tu diario...'),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'No se pudo cargar el diario',
          message: 'Comprueba tu conexión e inténtalo de nuevo. Si el problema continúa, revisa la configuración.',
          actionLabel: 'Reintentar',
          onAction: () => ref.read(recordsProvider.notifier).reload(),
        ),
        data: (records) {
          return RefreshIndicator(
            onRefresh: () => ref.read(recordsProvider.notifier).reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                _DiarySummary(
                  total: totalCount,
                  filtered: filteredCount,
                  filter: filter,
                  catalog: catalog,
                  onClear: () =>
                      ref.read(recordFilterProvider.notifier).clear(),
                  onRemoveDates: () => ref
                      .read(recordFilterProvider.notifier)
                      .apply(filter.copyWith(clearDates: true)),
                  onRemoveGroup: () => ref
                      .read(recordFilterProvider.notifier)
                      .apply(
                        filter.copyWith(clearGroup: true, clearEmotion: true),
                      ),
                  onRemoveEmotion: () => ref
                      .read(recordFilterProvider.notifier)
                      .apply(filter.copyWith(clearEmotion: true)),
                  onFilter: () => _openFilters(context, ref),
                ),
                const SizedBox(height: 16),
                if (records.isEmpty)
                  _EmptyDiary(
                    hasFilter: filter.isActive,
                    onClear: () =>
                        ref.read(recordFilterProvider.notifier).clear(),
                    onNew: () => AppNavigation.openRecordForm(context),
                  )
                else
                  ..._buildGroupedRecords(context, records, catalog),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedRecords(
    BuildContext context,
    List<EmotionalRecord> records,
    EmotionCatalog? catalog,
  ) {
    final grouped = <DateTime, List<EmotionalRecord>>{};
    for (final record in records) {
      final day = dateOnly(record.eventDate);
      grouped.putIfAbsent(day, () => []).add(record);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      final day = entry.key;
      final dayRecords = entry.value;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  friendlyDateLabel(day),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatLongDate(day),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                dayRecords.length == 1
                    ? '1 registro'
                    : '${dayRecords.length} registros',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
      for (final record in dayRecords) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RecordCard(
              record: record,
              catalog: catalog,
              onTap: () => AppNavigation.openRecordDetail(context, record),
            ),
          ),
        );
      }
      widgets.add(const SizedBox(height: 8));
    }
    return widgets;
  }
}

class _DiarySummary extends StatelessWidget {
  const _DiarySummary({
    required this.total,
    required this.filtered,
    required this.filter,
    required this.catalog,
    required this.onClear,
    required this.onRemoveDates,
    required this.onRemoveGroup,
    required this.onRemoveEmotion,
    required this.onFilter,
  });

  final int total;
  final int filtered;
  final RecordFilter filter;
  final EmotionCatalog? catalog;
  final VoidCallback onClear;
  final VoidCallback onRemoveDates;
  final VoidCallback onRemoveGroup;
  final VoidCallback onRemoveEmotion;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filter.from != null || filter.to != null) {
      final from = filter.from;
      final to = filter.to;
      final label = from != null && to != null
          ? '${formatShortDate(from)} - ${formatShortDate(to)}'
          : from != null
          ? 'Desde ${formatShortDate(from)}'
          : 'Hasta ${formatShortDate(to!)}';
      chips.add(
        _FilterPill(
          icon: Icons.calendar_month_rounded,
          label: label,
          onRemove: onRemoveDates,
        ),
      );
    }

    if (filter.groupId != null) {
      final group = catalog?.groupById(filter.groupId);
      chips.add(
        _FilterPill(
          icon: Icons.category_outlined,
          label: group?.name ?? 'Grupo',
          color: group == null
              ? AppTheme.seed
              : EmotionStyle.colorFromHex(group.colorHex),
          onRemove: onRemoveGroup,
        ),
      );
    }

    if (filter.emotionId != null) {
      final emotion = catalog?.emotionById(filter.emotionId);
      chips.add(
        _FilterPill(
          icon: Icons.mood_rounded,
          label: emotion?.name ?? 'Emoción',
          onRemove: onRemoveEmotion,
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                color: AppTheme.seed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filter.isActive
                      ? '$filtered de $total registros'
                      : total == 1
                      ? '1 registro en tu diario'
                      : '$total registros en tu diario',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!filter.isActive && total > 0)
                TextButton.icon(
                  onPressed: onFilter,
                  icon: const Icon(Icons.filter_alt_outlined, size: 17),
                  label: const Text('Filtrar'),
                ),
            ],
          ),
          if (filter.isActive) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: chips),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: onClear,
                  child: const Text('Quitar filtros'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onFilter,
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: const Text('Cambiar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.onRemove,
    this.color = AppTheme.seed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onRemove;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.close_rounded, size: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary({
    required this.hasFilter,
    required this.onClear,
    required this.onNew,
  });

  final bool hasFilter;
  final VoidCallback onClear;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    if (hasFilter) {
      return EmptyState(
        icon: Icons.filter_alt_off_rounded,
        title: 'No hay registros con estos filtros',
        message:
            'Prueba a cambiar las fechas, el grupo o la emoción seleccionada.',
        actionLabel: 'Quitar filtros',
        onAction: onClear,
      );
    }

    return EmptyState(
      icon: Icons.edit_note_rounded,
      title: 'Tu diario está esperando',
      message: 'Cada registro es una pequeña observación de lo que vives. Puedes empezar cuando quieras.',
      actionLabel: 'Crear mi primer registro',
      onAction: onNew,
    );
  }
}
