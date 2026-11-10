import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/privacy_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';

/// Alta inicial del paciente: seudónimo, departamento y consentimiento.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pseudonymController = TextEditingController();
  final _departmentController = TextEditingController(
    text: AppConfig.defaultDepartmentName,
  );
  bool _acceptedPrivacy = false;
  bool _saving = false;
  String? _privacyError;

  @override
  void dispose() {
    _pseudonymController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _privacyError = null);

    final formValid = _formKey.currentState?.validate() ?? false;
    if (!_acceptedPrivacy) {
      setState(() {
        _privacyError = 'Debes aceptar la información de privacidad.';
      });
    }
    if (!formValid || !_acceptedPrivacy) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(profileProvider.notifier)
          .create(
            pseudonym: _pseudonymController.text,
            departmentName: _departmentController.text,
          );
      if (!mounted) return;
      showSuccessSnack(context, 'Tu espacio personal está listo.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showErrorSnack(
        context,
        'No se pudo crear el perfil. Revisa los datos e inténtalo de nuevo.',
      );
      debugPrint('Error creando perfil: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            children: [
              const Center(child: AppLogo(size: 76)),
              const SizedBox(height: 22),
              const Text(
                'Tu espacio de emociones',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Un lugar privado para observar lo que sientes entre sesión y sesión.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 26),
              if (!session.isFirebaseEnabled) ...[
                const LocalModeBanner(),
                const SizedBox(height: 20),
              ],
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Cómo quieres que te llamemos?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Puedes usar un seudónimo o un identificador. No necesitas escribir tu nombre real.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pseudonymController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Nombre o seudónimo',
                        hintText: 'Ej.: Luna, Paciente 12, A. M.',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        counterText: '',
                      ),
                      validator: Validators.pseudonym,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _departmentController,
                      textInputAction: TextInputAction.done,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Departamento de psicología',
                        prefixIcon: Icon(Icons.apartment_rounded),
                        counterText: '',
                      ),
                      validator: Validators.departmentName,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppCard(
                color: AppTheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedPrivacy,
                          onChanged: (value) => setState(() {
                            _acceptedPrivacy = value ?? false;
                            if (_acceptedPrivacy) _privacyError = null;
                          }),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _acceptedPrivacy = !_acceptedPrivacy,
                            ),
                            child: const Text(
                              'He leído y acepto la información de privacidad.',
                              style: TextStyle(fontSize: 13.5, height: 1.35),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => showTextDialog(
                          context,
                          title: 'Privacidad y protección de datos',
                          body: '$privacyDetails\n\n$privacyVersionLabel',
                        ),
                        child: const Text('Leer la información completa'),
                      ),
                    ),
                    if (_privacyError != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          _privacyError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(_saving ? 'Preparando tu espacio...' : 'Comenzar'),
              ),
              const SizedBox(height: 16),
              const Text(
                AppTheme.privacyReminder,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
