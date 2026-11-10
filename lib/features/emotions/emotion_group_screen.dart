import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/emotion_style.dart';
import '../../models/emotion.dart';
import '../../models/emotion_group.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/emotion_widgets.dart';
import 'custom_emotion_dialog.dart';

/// Emociones de un grupo concreto.
class EmotionGroupScreen extends ConsumerWidget {
  const EmotionGroupScreen({super.key, required this.group});

  final EmotionGroup group;

  Future<void> _deleteCustom(
    BuildContext context,
    WidgetRef ref,
    Emotion emotion,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Eliminar “${emotion.name}”?',
      message: 'Se quitará de tu catálogo personal. Los registros que ya la usan conservarán su nombre y su intensidad.',
      confirmLabel: 'Eliminar emoción',
    );
    if (!confirmed) return;

    try {
      await ref.read(catalogProvider.notifier).deleteCustomEmotion(emotion.id);
      if (!context.mounted) return;
      showSuccessSnack(context, 'Emoción eliminada del catálogo.');
    } catch (error) {
      if (!context.mounted) return;
      showErrorSnack(
        context,
        'No se pudo eliminar la emoción. Inténtalo de nuevo.',
      );
      debugPrint('Error eliminando emoción propia: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final currentGroup = catalog?.groupById(group.id) ?? group;
    final color = EmotionStyle.colorFromHex(currentGroup.colorHex);

    return Scaffold(
      appBar: AppBar(title: Text(currentGroup.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: EmotionStyle.softBackground(color),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmotionAvatar(group: currentGroup, size: 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentGroup.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentGroup.description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Emociones de este grupo',
            subtitle: 'Toca una emoción para registrarla.',
            actionLabel: 'Añadir',
            onAction: () async {
              final emotion = await showCustomEmotionDialog(
                context,
                initialGroupId: currentGroup.id,
              );
              if (emotion == null || !context.mounted) return;
              showSuccessSnack(
                context,
                '“${emotion.name}” se ha añadido a tu catálogo.',
              );
            },
          ),
          for (final emotion in currentGroup.emotions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: EmotionListTile(
                emotion: emotion,
                group: currentGroup,
                onTap: () => AppNavigation.openRecordForm(
                  context,
                  initialEmotion: emotion,
                ),
                trailing: emotion.isCustom
                    ? IconButton(
                        onPressed: () => _deleteCustom(context, ref, emotion),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        tooltip: 'Eliminar emoción propia',
                      )
                    : null,
              ),
            ),
          const SizedBox(height: 14),
          const InfoNote(
            icon: Icons.touch_app_rounded,
            text: 'Puedes seleccionar más de una emoción en el formulario de registro, aunque pertenezcan a grupos distintos.',
          ),
        ],
      ),
    );
  }
}
