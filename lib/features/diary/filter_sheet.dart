import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/emotion_style.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/emotion_group.dart';
import '../../../models/record_filter.dart';
import '../../../widgets/common_widgets.dart';

/// Abre el panel de filtros del historial.
Future<RecordFilter?> showRecordFilterSheet(
  BuildContext context, {
  required RecordFilter current,
  required EmotionCatalog catalog,
}) {
  return showModalBottomSheet<RecordFilter>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => RecordFilterSheet(current: current, catalog: catalog),
  );
}

class RecordFilterSheet extends StatefulWidget {
  const RecordFilterSheet({
    super.key,
    required this.current,
    required this.catalog,
  });

  final RecordFilter current;
  final EmotionCatalog catalog;

  @override
  State<RecordFilterSheet> createState() => _RecordFilterSheetState();
}

class _RecordFilterSheetState extends State<RecordFilterSheet> {
  late DateTime? _from = widget.current.from;
  late DateTime? _to = widget.current.to;
  late String? _groupId = widget.current.groupId;
  late String? _emotionId = widget.current.emotionId;

  List<EmotionOption> get _emotionOptions {
    final emotions = _groupId == null
        ? widget.catalog.allEmotions
        : widget.catalog.groupById(_groupId)?.emotions ?? const [];
    final sorted = [...emotions]..sort((a, b) => a.name.compareTo(b.name));
    return sorted
        .map((emotion) => EmotionOption(id: emotion.id, name: emotion.name))
        .toList(growable: false);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initialStart = _from ?? now.subtract(const Duration(days: 7));
    final initialEnd = _to ?? now;
    final range = await showDateRangePicker(
      context: context,
      locale: const Locale('es'),
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd.isBefore(initialStart) ? initialStart : initialEnd,
      ),
      helpText: 'Selecciona un intervalo',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (range == null) return;
    setState(() {
      _from = dateOnly(range.start);
      _to = dateOnly(range.end);
    });
  }

  void _setQuickRange(int? days) {
    final now = dateOnly(DateTime.now());
    setState(() {
      if (days == null) {
        _from = null;
        _to = null;
      } else {
        _from = now.subtract(Duration(days: days - 1));
        _to = now;
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      RecordFilter(
        from: _from,
        to: _to,
        groupId: _groupId,
        emotionId: _emotionId,
      ),
    );
  }

  void _clear() {
    setState(() {
      _from = null;
      _to = null;
      _groupId = null;
      _emotionId = null;
    });
  }

  bool _matchesRange(int days) {
    final today = dateOnly(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    return _from != null &&
        _to != null &&
        isSameDay(_from!, start) &&
        isSameDay(_to!, today);
  }

  @override
  Widget build(BuildContext context) {
    final hasRange = _from != null || _to != null;

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtrar el historial',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  const SectionHeader(title: 'Fechas'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Hoy'),
                        selected: _matchesRange(1),
                        onSelected: (_) => _setQuickRange(1),
                      ),
                      ChoiceChip(
                        label: const Text('Últimos 7 días'),
                        selected: _matchesRange(7),
                        onSelected: (_) => _setQuickRange(7),
                      ),
                      ChoiceChip(
                        label: const Text('Últimos 30 días'),
                        selected: _matchesRange(30),
                        onSelected: (_) => _setQuickRange(30),
                      ),
                      ChoiceChip(
                        label: const Text('Todas las fechas'),
                        selected: !hasRange,
                        onSelected: (_) => _setQuickRange(null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.calendar_month_rounded, size: 20),
                    label: Text(
                      hasRange
                          ? '${formatShortDate(_from ?? _to!)} - ${formatShortDate(_to ?? _from!)}'
                          : 'Elegir un día o intervalo',
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Grupo emocional'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _groupId == null,
                        onSelected: (_) => setState(() {
                          _groupId = null;
                          _emotionId = null;
                        }),
                      ),
                      for (final group in widget.catalog.groups)
                        ChoiceChip(
                          label: Text(group.name),
                          selected: _groupId == group.id,
                          selectedColor: EmotionStyle.softBackground(
                            EmotionStyle.colorFromHex(group.colorHex),
                          ),
                          onSelected: (_) => setState(() {
                            _groupId = _groupId == group.id ? null : group.id;
                            _emotionId = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionHeader(title: 'Emoción concreta'),
                  DropdownButtonFormField<String>(
                    key: ValueKey('emotion-filter-${_groupId ?? 'all'}'),
                    initialValue: _emotionId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mood_rounded),
                      hintText: 'Todas las emociones',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todas las emociones'),
                      ),
                      for (final option in _emotionOptions)
                        DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(option.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _emotionId = value),
                  ),
                  const SizedBox(height: 20),
                  const InfoNote(
                    icon: Icons.filter_alt_outlined,
                    text: 'Puedes combinar fecha, grupo y emoción. Los filtros solo afectan a lo que ves en el historial; no modifican tus registros.',
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                border: Border(top: BorderSide(color: AppTheme.outline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _apply,
                      icon: const Icon(Icons.check_rounded, size: 19),
                      label: const Text('Aplicar filtros'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmotionOption {
  const EmotionOption({required this.id, required this.name});

  final String id;
  final String name;
}
