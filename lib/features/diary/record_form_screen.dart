import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/emotion_style.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/validators.dart';
import '../../models/emotion.dart';
import '../../models/emotional_record.dart';
import '../../models/selected_emotion.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import '../emotions/emotion_picker_sheet.dart';

/// Formulario para crear o editar un registro emocional.
class RecordFormScreen extends ConsumerStatefulWidget {
  const RecordFormScreen({
    super.key,
    this.record,
    this.initialEmotion,
    this.focusFreeText = false,
  });

  final EmotionalRecord? record;
  final Emotion? initialEmotion;
  final bool focusFreeText;

  @override
  ConsumerState<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends ConsumerState<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _situationController = TextEditingController();
  final _thoughtController = TextEditingController();
  final _behaviorController = TextEditingController();
  final _freeTextController = TextEditingController();
  final _freeTextFocus = FocusNode();

  late DateTime _eventDate;
  String? _eventTime;
  late List<SelectedEmotion> _selected;
  String? _emotionError;
  bool _saving = false;

  bool get _isEditing => widget.record != null;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    _eventDate = dateOnly(record?.eventDate ?? DateTime.now());
    _eventTime = record?.eventTime;
    _titleController.text = record?.displayTitle ?? '';
    _situationController.text = record?.situation ?? '';
    _thoughtController.text = record?.thought ?? '';
    _behaviorController.text = record?.behavior ?? '';
    _freeTextController.text = record?.freeText ?? '';

    _selected = [...?record?.emotions];

    if (widget.initialEmotion != null && _selected.isEmpty) {
      final catalog = ref.read(catalogProvider).value;
      final emotion = widget.initialEmotion!;
      _selected = [
        SelectedEmotion(
          emotionId: emotion.id,
          name: emotion.name,
          groupId: emotion.groupId,
          groupName: catalog?.groupById(emotion.groupId)?.name ?? 'Sin grupo',
        ),
      ];
    }

    if (widget.focusFreeText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _freeTextFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _situationController.dispose();
    _thoughtController.dispose();
    _behaviorController.dispose();
    _freeTextController.dispose();
    _freeTextFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('es'),
      initialDate: _eventDate,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Fecha del acontecimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) return;
    setState(() => _eventDate = dateOnly(picked));
  }

  Future<void> _pickTime() async {
    final initial =
        combineDateAndTime(_eventDate, _eventTime) ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Hora del acontecimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) return;
    setState(() {
      _eventTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _openEmotionPicker() async {
    final picked = await showEmotionPicker(context, selected: _selected);
    if (picked == null) return;

    final catalog = ref.read(catalogProvider).value;
    final existing = {
      for (final emotion in _selected) emotion.emotionId: emotion,
    };
    final merged = picked
        .map((emotion) {
          final previous = existing[emotion.id];
          if (previous != null) return previous;
          return SelectedEmotion(
            emotionId: emotion.id,
            name: emotion.name,
            groupId: emotion.groupId,
            groupName: catalog?.groupById(emotion.groupId)?.name ?? 'Sin grupo',
          );
        })
        .toList(growable: false);

    setState(() {
      _selected = merged;
      if (_selected.isNotEmpty) _emotionError = null;
    });
  }

  void _removeEmotion(String id) {
    setState(() {
      _selected = _selected
          .where((emotion) => emotion.emotionId != id)
          .toList(growable: false);
    });
  }

  void _setIntensity(String id, int value) {
    setState(() {
      _selected = _selected
          .map(
            (emotion) => emotion.emotionId == id
                ? emotion.copyWith(intensity: value)
                : emotion,
          )
          .toList(growable: false);
    });
  }

  void _toggleIntensity(String id, bool enabled) {
    setState(() {
      _selected = _selected
          .map(
            (emotion) => emotion.emotionId == id
                ? (enabled
                      ? emotion.copyWith(intensity: emotion.intensity ?? 5)
                      : emotion.copyWith(clearIntensity: true))
                : emotion,
          )
          .toList(growable: false);
    });
  }

  bool get _hasContent {
    return _titleController.text.trim().isNotEmpty ||
        _situationController.text.trim().isNotEmpty ||
        _thoughtController.text.trim().isNotEmpty ||
        _behaviorController.text.trim().isNotEmpty ||
        _freeTextController.text.trim().isNotEmpty ||
        _selected.isNotEmpty;
  }

  Future<void> _cancel() async {
    if (_hasContent) {
      final discard = await showConfirmDialog(
        context,
        title: '¿Descartar el registro?',
        message: 'Si sales ahora, los cambios que hayas escrito y no hayas guardado se perderán.',
        confirmLabel: 'Descartar',
        cancelLabel: 'Seguir escribiendo',
      );
      if (!discard) return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _emotionError = _selected.isEmpty
          ? 'Selecciona al menos una emoción.'
          : null;
    });
    if (!valid || _selected.isEmpty) return;

    setState(() => _saving = true);
    try {
      final session = ref.read(appSessionProvider);
      final existing = widget.record;
      final record = buildRecord(
        patientId: session.patientId,
        eventDate: _eventDate,
        createdAt: existing?.createdAt ?? DateTime.now(),
        title: _titleController.text,
        situation: _situationController.text,
        emotions: _selected,
        thought: _thoughtController.text,
        behavior: _behaviorController.text,
        freeText: _freeTextController.text,
        eventTime: _eventTime,
        id: existing?.id,
      );

      await ref.read(recordsProvider.notifier).saveRecord(record);
      if (!mounted) return;
      showSuccessSnack(
        context,
        _isEditing ? 'Registro actualizado.' : 'Registro guardado.',
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = error is AppException
          ? error.message
          : 'No se pudo guardar el registro. Inténtalo de nuevo.';
      showErrorSnack(context, message);
      debugPrint('Error guardando registro: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar registro' : 'Nuevo registro'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            InfoNote(
              icon: Icons.edit_note_rounded,
              text: _isEditing
                  ? 'Puedes cambiar cualquier parte del registro. Los campos con * son obligatorios.'
                  : 'Escribe con calma y con tus propias palabras. Los campos con * son obligatorios.',
            ),
            const SizedBox(height: 16),
            _FormSection(
              title: 'Fecha y hora',
              subtitle: '¿Cuándo ocurrió?',
              child: Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      icon: Icons.calendar_month_rounded,
                      label: formatShortDate(_eventDate),
                      caption: 'Fecha',
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PickerField(
                      icon: Icons.schedule_rounded,
                      label: _eventTime ?? 'Sin hora',
                      caption: 'Hora (opcional)',
                      onTap: _pickTime,
                      onClear: _eventTime == null
                          ? null
                          : () => setState(() => _eventTime = null),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Título *',
              subtitle: 'Un resumen breve para reconocerlo en el historial.',
              child: TextFormField(
                controller: _titleController,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Ej.: Conversación con mi amiga',
                ),
                validator: (value) => Validators.requiredText(
                  value,
                  fieldName: 'El título',
                  maxLength: 80,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Situación *',
              subtitle: '¿Qué ha ocurrido? Describe el contexto.',
              child: TextFormField(
                controller: _situationController,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Ej.: Una conversación con una amiga, una noticia, un recuerdo...',
                  alignLabelWithHint: true,
                ),
                validator: (value) => Validators.requiredText(
                  value,
                  fieldName: 'La situación',
                  maxLength: 2000,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Emociones *',
              subtitle: 'Puedes elegir varias, incluso del mismo grupo. Después puedes indicar la intensidad de cada una.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selected.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _emotionError == null
                              ? AppTheme.outline
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      child: const Text(
                        'Todavía no has seleccionado ninguna emoción.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  else
                    for (final emotion in _selected)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SelectedEmotionCard(
                          emotion: emotion,
                          color: EmotionStyle.colorFromHex(
                            catalog?.groupById(emotion.groupId)?.colorHex ??
                                '#5F8575',
                          ),
                          onRemove: () => _removeEmotion(emotion.emotionId),
                          onToggleIntensity: (enabled) =>
                              _toggleIntensity(emotion.emotionId, enabled),
                          onIntensityChanged: (value) =>
                              _setIntensity(emotion.emotionId, value),
                        ),
                      ),
                  if (_emotionError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _emotionError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _openEmotionPicker,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      _selected.isEmpty
                          ? 'Seleccionar emociones'
                          : 'Cambiar selección',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Pensamiento *',
              subtitle: '¿Qué has pensado en ese momento?',
              child: TextFormField(
                controller: _thoughtController,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Ej.: "Seguro que piensa que no le importo", "No voy a poder con esto"...',
                  alignLabelWithHint: true,
                ),
                validator: (value) => Validators.requiredText(
                  value,
                  fieldName: 'El pensamiento',
                  maxLength: 2000,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Conducta *',
              subtitle: '¿Cómo has reaccionado? ¿Qué has hecho?',
              child: TextFormField(
                controller: _behaviorController,
                minLines: 3,
                maxLines: 6,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Ej.: Me he callado, he salido de la habitación, he llamado a alguien...',
                  alignLabelWithHint: true,
                ),
                validator: (value) => Validators.requiredText(
                  value,
                  fieldName: 'La conducta',
                  maxLength: 2000,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _FormSection(
              title: 'Con tus propias palabras',
              subtitle: 'Opcional. Si quieres, describe cómo te sientes sin usar las opciones anteriores.',
              child: TextFormField(
                controller: _freeTextController,
                focusNode: _freeTextFocus,
                minLines: 2,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Ej.: "Como si llevara una mochila muy pesada"...',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const InfoNote(
              icon: Icons.lightbulb_outline_rounded,
              text: 'No hay una forma correcta de sentirse. Este registro es para ti: no se interpreta ni se evalúa automáticamente.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            border: Border(top: BorderSide(color: AppTheme.outline)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(_saving ? 'Guardando...' : 'Guardar registro'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.seed),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  tooltip: 'Quitar hora',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedEmotionCard extends StatelessWidget {
  const _SelectedEmotionCard({
    required this.emotion,
    required this.color,
    required this.onRemove,
    required this.onToggleIntensity,
    required this.onIntensityChanged,
  });

  final SelectedEmotion emotion;
  final Color color;
  final VoidCallback onRemove;
  final ValueChanged<bool> onToggleIntensity;
  final ValueChanged<int> onIntensityChanged;

  @override
  Widget build(BuildContext context) {
    final hasIntensity = emotion.intensity != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
      decoration: BoxDecoration(
        color: EmotionStyle.softBackground(color),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emotion.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      emotion.groupName,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Quitar emoción',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Row(
            children: [
              const Text(
                'Indicar intensidad',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Switch.adaptive(
                value: hasIntensity,
                onChanged: onToggleIntensity,
                activeTrackColor: color,
              ),
            ],
          ),
          if (hasIntensity)
            Row(
              children: [
                const Text(
                  '0',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                Expanded(
                  child: Slider(
                    value: (emotion.intensity ?? 5).toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '${emotion.intensity}/10',
                    activeColor: color,
                    onChanged: (value) => onIntensityChanged(value.round()),
                  ),
                ),
                const Text(
                  '10',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${emotion.intensity}/10',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
