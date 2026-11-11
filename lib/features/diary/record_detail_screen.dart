import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/emotion_style.dart';
import '../../core/utils/date_utils.dart';
import '../../models/emotional_record.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';

/// Vista completa de un registro del diario.
class RecordDetailScreen extends ConsumerWidget {
  const RecordDetailScreen({super.key, required this.record});

  final EmotionalRecord record;

  EmotionalRecord _currentRecord(WidgetRef ref) {
    final records = ref.watch(recordsProvider).value;
    if (records == null) return record;
    for (final item in records) {
      if (item.id == record.id) return item;
    }
    return record;
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    EmotionalRecord current,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Eliminar este registro?',
      message: 'Se borrarán la situación, las emociones, los pensamientos y la conducta de este registro. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar registro',
    );
    if (!confirmed) return;

    try {
      await ref.read(recordsProvider.notifier).deleteRecord(current.id);
      if (!context.mounted) return;
      showSuccessSnack(context, 'Registro eliminado.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      showErrorSnack(
        context,
        'No se pudo eliminar el registro. Inténtalo de nuevo.',
      );
      debugPrint('Error eliminando registro: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = _currentRecord(ref);
    final catalog = ref.watch(catalogProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        actions: [
          IconButton(
            onPressed: () async {
              await AppNavigation.openRecordForm(context, record: current);
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar registro',
          ),
          IconButton(
            onPressed: () => _delete(context, ref, current),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Eliminar registro',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          AppCard(
            color: AppTheme.seed.withValues(alpha: 0.07),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.displayTitle,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.event_rounded,
                      color: AppTheme.seed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formatLongDate(current.eventDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Hora del registro: ${current.eventTime ?? formatTime(current.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: current.emotions
                      .map((emotion) {
                        final group = catalog?.groupById(emotion.groupId);
                        final color = group == null
                            ? AppTheme.seed
                            : EmotionStyle.colorFromHex(group.colorHex);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${emotion.name} · ${emotion.groupName}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            icon: Icons.title_rounded,
            title: 'Título',
            subtitle: 'Resumen del registro',
            content: current.displayTitle,
          ),
          const SizedBox(height: 12),
          _DetailSection(
            icon: Icons.place_outlined,
            title: 'Situación',
            subtitle: '¿Qué ha ocurrido?',
            content: current.situation,
          ),
          const SizedBox(height: 12),
          _EmotionsDetail(record: current),
          const SizedBox(height: 12),
          _DetailSection(
            icon: Icons.psychology_outlined,
            title: 'Pensamiento',
            subtitle: '¿Qué has pensado en ese momento?',
            content: current.thought,
          ),
          const SizedBox(height: 12),
          _DetailSection(
            icon: Icons.directions_run_rounded,
            title: 'Conducta',
            subtitle: '¿Cómo has reaccionado?',
            content: current.behavior,
          ),
          if (current.freeText != null &&
              current.freeText!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _DetailSection(
              icon: Icons.format_quote_rounded,
              title: 'Con tus propias palabras',
              subtitle: 'Descripción libre',
              content: current.freeText!,
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Creado el ${formatNumericDate(current.createdAt)} a las ${formatTime(current.createdAt)}'
            '${current.updatedAt.difference(current.createdAt).inMinutes.abs() >= 1 ? ' · Editado el ${formatNumericDate(current.updatedAt)} a las ${formatTime(current.updatedAt)}' : ''}',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const InfoNote(
            icon: Icons.lock_outline_rounded,
            text: 'Este registro es tuyo. Solo tú puedes verlo desde tu sesión y decides si lo compartes.',
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String content;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.seed),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content.trim().isEmpty ? '-' : content.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionsDetail extends StatelessWidget {
  const _EmotionsDetail({required this.record});

  final EmotionalRecord record;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.mood_rounded, size: 18, color: AppTheme.seed),
              SizedBox(width: 8),
              Text(
                'Emociones',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final emotion in record.emotions)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          emotion.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        emotion.intensity == null
                            ? 'Sin intensidad'
                            : '${emotion.intensity}/10',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    emotion.groupName,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (emotion.intensity != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: emotion.intensity! / 10,
                        minHeight: 7,
                        backgroundColor: AppTheme.surfaceMuted,
                        color: AppTheme.seed,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
