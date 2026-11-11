import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Botón de micrófono que se coloca dentro de un campo de texto.
///
/// El mismo botón inicia y detiene el dictado. Cuando está escuchando se
/// muestra relleno para que se vea de un vistazo qué campo está activo.
class DictationMicButton extends StatelessWidget {
  const DictationMicButton({
    super.key,
    required this.listening,
    required this.onPressed,
    this.enabled = true,
  });

  final bool listening;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final label = listening ? 'Detener dictado' : 'Dictar por voz';
    final foreground = listening ? Colors.white : AppTheme.seed;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        button: true,
        label: label,
        child: Tooltip(
          message: label,
          child: Material(
            color: listening
                ? AppTheme.seed
                : AppTheme.seed.withValues(alpha: 0.10),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onPressed : null,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  listening ? Icons.stop_rounded : Icons.mic_none_rounded,
                  size: 20,
                  color: enabled
                      ? foreground
                      : foreground.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
