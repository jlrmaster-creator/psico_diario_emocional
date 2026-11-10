import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/emotion_style.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/emotion_group.dart';
import '../../../models/emotional_record.dart';
import '../../../widgets/emotion_widgets.dart';

/// Tarjeta resumen de un registro emocional.
class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.record,
    required this.catalog,
    this.showDate = false,
    this.onTap,
  });

  final EmotionalRecord record;
  final EmotionCatalog? catalog;
  final bool showDate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = record.eventTime ?? formatTime(record.createdAt);
    final maxIntensity = record.maxIntensity;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (showDate) ...[
                      const SizedBox(width: 8),
                      Text(
                        '· ${formatShortDate(record.eventDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (maxIntensity != null)
                      _IntensityBadge(value: maxIntensity),
                  ],
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: record.emotions
                      .map(
                        (emotion) => EmotionChip(
                          label: emotion.name,
                          color: _colorFor(emotion.groupId),
                          intensity: emotion.intensity,
                          compact: true,
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 10),
                Text(
                  record.situation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (record.thought.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    record.thought,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _colorFor(String groupId) {
    final group = catalog?.groupById(groupId);
    return group == null
        ? AppTheme.seed
        : EmotionStyle.colorFromHex(group.colorHex);
  }
}

class _IntensityBadge extends StatelessWidget {
  const _IntensityBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.seed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed_rounded, size: 13, color: AppTheme.seed),
          const SizedBox(width: 4),
          Text(
            '$value/10',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.seed,
            ),
          ),
        ],
      ),
    );
  }
}
