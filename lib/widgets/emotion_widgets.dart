import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/emotion_style.dart';
import '../models/emotion.dart';
import '../models/emotion_group.dart';

/// Icono circular de un grupo emocional.
class EmotionAvatar extends StatelessWidget {
  const EmotionAvatar({
    super.key,
    required this.group,
    this.size = 44,
    this.iconSize,
  });

  final EmotionGroup group;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final color = EmotionStyle.colorFromHex(group.colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: EmotionStyle.softBackground(color),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        EmotionStyle.iconFor(group.icon),
        color: color,
        size: iconSize ?? size * 0.5,
      ),
    );
  }
}

/// Chip de una emoción con su color de grupo e intensidad opcional.
class EmotionChip extends StatelessWidget {
  const EmotionChip({
    super.key,
    required this.label,
    required this.color,
    this.intensity,
    this.onDeleted,
    this.compact = false,
  });

  final String label;
  final Color color;
  final int? intensity;
  final VoidCallback? onDeleted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = intensity == null ? label : '$label · $intensity/10';
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 10,
        compact ? 5 : 7,
        onDeleted != null ? 4 : (compact ? 8 : 10),
        compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: EmotionStyle.softBackground(color),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: 2),
            InkWell(
              onTap: onDeleted,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Icon(
                  Icons.close_rounded,
                  size: compact ? 15 : 17,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fila seleccionable de una emoción dentro del catálogo o del selector.
class EmotionListTile extends StatelessWidget {
  const EmotionListTile({
    super.key,
    required this.emotion,
    required this.group,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final Emotion emotion;
  final EmotionGroup group;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final color = EmotionStyle.colorFromHex(group.colorHex);
    return Material(
      color: selected ? EmotionStyle.softBackground(color) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            emotion.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (emotion.isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Propia',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (emotion.description != null &&
                        emotion.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        emotion.description!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  (selected
                      ? Icon(Icons.check_circle_rounded, color: color, size: 22)
                      : const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppTheme.textSecondary,
                          size: 22,
                        )),
            ],
          ),
        ),
      ),
    );
  }
}
