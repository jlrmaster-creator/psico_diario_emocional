import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../models/emotion.dart';
import '../../../state/providers.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/dialogs.dart';

/// Diálogo para crear una emoción propia.
Future<Emotion?> showCustomEmotionDialog(
  BuildContext context, {
  String? initialGroupId,
}) {
  return showDialog<Emotion>(
    context: context,
    builder: (_) => CustomEmotionDialog(initialGroupId: initialGroupId),
  );
}

class CustomEmotionDialog extends ConsumerStatefulWidget {
  const CustomEmotionDialog({super.key, this.initialGroupId});

  final String? initialGroupId;

  @override
  ConsumerState<CustomEmotionDialog> createState() =>
      _CustomEmotionDialogState();
}

class _CustomEmotionDialogState extends ConsumerState<CustomEmotionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _groupId;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final catalog = ref.read(catalogProvider).value;
    final groupId =
        _groupId ??
        (catalog == null || catalog.groups.isEmpty
            ? null
            : catalog.groups.first.id);
    if (groupId == null) return;

    setState(() => _saving = true);
    try {
      final emotion = await ref
          .read(catalogProvider.notifier)
          .addCustomEmotion(
            name: _nameController.text,
            groupId: groupId,
            description: _descriptionController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(emotion);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnack(
        context,
        'No se pudo crear la emoción. Inténtalo de nuevo.',
      );
      debugPrint('Error creando emoción personalizada: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);
    final catalog = catalogAsync.value;

    if (catalog == null) {
      return const AlertDialog(
        content: SizedBox(
          height: 120,
          child: LoadingView(message: 'Cargando grupos...'),
        ),
      );
    }

    if (catalog.groups.isEmpty) {
      return AlertDialog(
        title: const Text('Añadir una emoción'),
        content: const Text(
          'El catálogo de grupos no está disponible en este momento. '
          'Cierra este diálogo e inténtalo de nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      );
    }

    _groupId ??= widget.initialGroupId ?? catalog.groups.first.id;

    return AlertDialog(
      title: const Text('Añadir una emoción'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Puedes añadir una palabra que describa mejor lo que sientes. Se guardará en tu catálogo personal.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la emoción',
                  hintText: 'Ej.: Nostalgia',
                  counterText: '',
                ),
                validator: Validators.emotionName,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _groupId,
                decoration: const InputDecoration(
                  labelText: 'Grupo emocional',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: catalog.groups
                    .map(
                      (group) => DropdownMenuItem(
                        value: group.id,
                        child: Text(group.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => setState(() => _groupId = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLength: 160,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: '¿Qué significa para ti?',
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
