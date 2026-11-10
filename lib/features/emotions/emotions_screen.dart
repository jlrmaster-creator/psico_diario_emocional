import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/emotion_style.dart';
import '../../models/emotion.dart';
import '../../models/emotion_group.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/emotion_widgets.dart';
import 'custom_emotion_dialog.dart';

/// Catálogo visual "¿Qué estoy sintiendo?".
class EmotionsScreen extends ConsumerStatefulWidget {
  const EmotionsScreen({super.key});

  @override
  ConsumerState<EmotionsScreen> createState() => _EmotionsScreenState();
}

class _EmotionsScreenState extends ConsumerState<EmotionsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createCustom() async {
    final emotion = await showCustomEmotionDialog(context);
    if (emotion == null || !mounted) return;
    await AppNavigation.openRecordForm(context, initialEmotion: emotion);
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('¿Qué estoy sintiendo?')),
      body: catalogAsync.when(
        loading: () => const LoadingView(message: 'Cargando emociones...'),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'No se pudo cargar el catálogo',
          message: 'Comprueba tu conexión e inténtalo de nuevo. Tus registros no se han visto afectados.',
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(catalogProvider),
        ),
        data: (catalog) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const InfoNote(
              icon: Icons.self_improvement_rounded,
              text: 'Explora las emociones con calma. No hay respuestas correctas: elige las palabras que más se acerquen a lo que sientes.',
            ),
            const SizedBox(height: 16),
            TextField(
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
            const SizedBox(height: 18),
            if (_query.trim().isNotEmpty)
              _SearchResults(
                catalog: catalog,
                query: _query,
                onSelect: (emotion) => AppNavigation.openRecordForm(
                  context,
                  initialEmotion: emotion,
                ),
              )
            else ...[
              const SectionHeader(
                title: 'Seis grupos de emociones',
                subtitle: 'Toca un grupo para ver todas sus emociones.',
              ),
              _GroupGrid(
                groups: catalog.groups,
                onTap: (group) =>
                    AppNavigation.openEmotionGroup(context, group),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿No encuentras la palabra?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Puedes añadir una emoción propia a tu catálogo personal o describirlo con tus palabras al crear un registro.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _createCustom,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Añadir una emoción propia'),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => AppNavigation.openRecordForm(
                        context,
                        focusFreeText: true,
                      ),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Escribir libremente cómo me siento'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InfoNote(icon: Icons.info_outline_rounded, text: catalog.notice),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.groups, required this.onTap});

  final List<EmotionGroup> groups;
  final ValueChanged<EmotionGroup> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final group = groups[index];
        final color = EmotionStyle.colorFromHex(group.colorHex);
        return Material(
          color: EmotionStyle.softBackground(color),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => onTap(group),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withValues(alpha: 0.22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      EmotionStyle.iconFor(group.icon),
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    group.emotions.length == 1
                        ? '1 emoción'
                        : '${group.emotions.length} emociones',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.catalog,
    required this.query,
    required this.onSelect,
  });

  final EmotionCatalog catalog;
  final String query;
  final ValueChanged<Emotion> onSelect;

  @override
  Widget build(BuildContext context) {
    final results = catalog
        .search(query)
        .where((emotion) => catalog.groupById(emotion.groupId) != null)
        .toList(growable: false);
    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No encontramos esa emoción',
        message: 'Prueba con otra palabra o añade una emoción propia desde el catálogo.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Resultados',
          subtitle:
              '${results.length} ${results.length == 1 ? 'emoción encontrada' : 'emociones encontradas'}',
        ),
        for (final emotion in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: EmotionListTile(
              emotion: emotion,
              group: catalog.groupById(emotion.groupId)!,
              onTap: () => onSelect(emotion),
            ),
          ),
      ],
    );
  }
}
