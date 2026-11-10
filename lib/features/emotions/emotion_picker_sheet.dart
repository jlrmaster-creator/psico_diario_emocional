import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/emotion_style.dart';
import '../../../models/emotion.dart';
import '../../../models/emotion_group.dart';
import '../../../models/selected_emotion.dart';
import '../../../state/providers.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/emotion_widgets.dart';
import 'custom_emotion_dialog.dart';

/// Abre el selector múltiple de emociones.
Future<List<Emotion>?> showEmotionPicker(
  BuildContext context, {
  required List<SelectedEmotion> selected,
}) {
  return showModalBottomSheet<List<Emotion>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => EmotionPickerSheet(selected: selected),
  );
}

class EmotionPickerSheet extends ConsumerStatefulWidget {
  const EmotionPickerSheet({super.key, required this.selected});

  final List<SelectedEmotion> selected;

  @override
  ConsumerState<EmotionPickerSheet> createState() => _EmotionPickerSheetState();
}

class _EmotionPickerSheetState extends ConsumerState<EmotionPickerSheet> {
  final _searchController = TextEditingController();
  final Map<String, Emotion> _extraEmotions = {};
  final Set<String> _selectedIds = {};
  String? _groupId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    for (final emotion in widget.selected) {
      _selectedIds.add(emotion.emotionId);
      _extraEmotions[emotion.emotionId] = Emotion(
        id: emotion.emotionId,
        name: emotion.name,
        groupId: emotion.groupId,
        isCustom: true,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Emotion> _resultEmotions(EmotionCatalog catalog) {
    final byId = <String, Emotion>{
      for (final emotion in catalog.allEmotions) emotion.id: emotion,
      ..._extraEmotions,
    };

    var emotions = byId.values.toList(growable: false);
    if (_groupId != null) {
      emotions = emotions
          .where((emotion) => emotion.groupId == _groupId)
          .toList(growable: false);
    }

    final query = _query.trim();
    if (query.isNotEmpty) {
      emotions = catalog
          .search(query)
          .where((emotion) => _groupId == null || emotion.groupId == _groupId)
          .toList(growable: false);
      // Recupera las emociones propias que coincidan con la búsqueda.
      final catalogIds = emotions.map((emotion) => emotion.id).toSet();
      emotions = [
        ...emotions,
        ...byId.values.where(
          (emotion) =>
              !catalogIds.contains(emotion.id) &&
              (_groupId == null || emotion.groupId == _groupId) &&
              emotion.name.toLowerCase().contains(query.toLowerCase()),
        ),
      ];
    }

    emotions.sort((a, b) => a.name.compareTo(b.name));
    return emotions;
  }

  void _toggle(Emotion emotion) {
    setState(() {
      if (_selectedIds.contains(emotion.id)) {
        _selectedIds.remove(emotion.id);
      } else {
        _selectedIds.add(emotion.id);
        _extraEmotions[emotion.id] = emotion;
      }
    });
  }

  Future<void> _createCustom() async {
    final emotion = await showCustomEmotionDialog(
      context,
      initialGroupId: _groupId,
    );
    if (emotion == null || !mounted) return;
    setState(() {
      _extraEmotions[emotion.id] = emotion;
      _selectedIds.add(emotion.id);
    });
  }

  void _confirm(EmotionCatalog catalog) {
    final byId = <String, Emotion>{
      for (final emotion in catalog.allEmotions) emotion.id: emotion,
      ..._extraEmotions,
    };
    final result = _selectedIds
        .map((id) => byId[id])
        .whereType<Emotion>()
        .toList(growable: false);
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: catalogAsync.when(
          loading: () => const LoadingView(message: 'Cargando emociones...'),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(20),
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'No se pudo cargar el catálogo',
              message: 'Comprueba tu conexión e inténtalo de nuevo. También puedes escribir tu emoción manualmente.',
              actionLabel: 'Reintentar',
              onAction: () => ref.invalidate(catalogProvider),
            ),
          ),
          data: (catalog) => _buildContent(catalog),
        ),
      ),
    );
  }

  Widget _buildContent(EmotionCatalog catalog) {
    final emotions = _resultEmotions(catalog);
    final sections = <_EmotionSection>[];
    for (final group in catalog.groups) {
      final groupEmotions = emotions
          .where((emotion) => emotion.groupId == group.id)
          .toList(growable: false);
      if (groupEmotions.isNotEmpty) {
        sections.add(_EmotionSection(group: group, emotions: groupEmotions));
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Selecciona emociones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
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
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Puedes elegir más de una. Después podrás indicar la intensidad de cada una.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar una emoción...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _GroupFilterChip(
                label: 'Todos',
                selected: _groupId == null,
                color: AppTheme.seed,
                onTap: () => setState(() => _groupId = null),
              ),
              for (final group in catalog.groups)
                _GroupFilterChip(
                  label: group.name,
                  selected: _groupId == group.id,
                  color: EmotionStyle.colorFromHex(group.colorHex),
                  onTap: () => setState(() {
                    _groupId = _groupId == group.id ? null : group.id;
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: sections.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No encontramos esa emoción',
                  message: 'Prueba con otra palabra o crea una emoción propia.',
                  actionLabel: 'Crear emoción propia',
                  onAction: _createCustom,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final color = EmotionStyle.colorFromHex(
                      section.group.colorHex,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                section.group.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (final emotion in section.emotions)
                          EmotionListTile(
                            emotion: emotion,
                            group: section.group,
                            selected: _selectedIds.contains(emotion.id),
                            onTap: () => _toggle(emotion),
                          ),
                      ],
                    );
                  },
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
                child: OutlinedButton.icon(
                  onPressed: _createCustom,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Emoción propia'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => _confirm(catalog),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    _selectedIds.isEmpty
                        ? 'Elige emociones'
                        : 'Añadir (${_selectedIds.length})',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmotionSection {
  const _EmotionSection({required this.group, required this.emotions});

  final EmotionGroup group;
  final List<Emotion> emotions;
}

class _GroupFilterChip extends StatelessWidget {
  const _GroupFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: color.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: selected ? color : AppTheme.textSecondary,
        ),
        side: BorderSide(
          color: selected ? color.withValues(alpha: 0.4) : AppTheme.outline,
        ),
        backgroundColor: AppTheme.surface,
      ),
    );
  }
}
