import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/privacy_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../models/patient_profile.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuración del perfil, el almacenamiento y la privacidad.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editPseudonym(
    BuildContext context,
    WidgetRef ref,
    PatientProfile profile,
  ) async {
    final controller = TextEditingController(text: profile.pseudonym);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre o seudónimo'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Seudónimo',
              counterText: '',
            ),
            validator: Validators.pseudonym,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;

    try {
      await ref.read(profileProvider.notifier).saveProfile(pseudonym: result);
      if (!context.mounted) return;
      showSuccessSnack(context, 'Seudónimo actualizado.');
    } catch (error) {
      if (!context.mounted) return;
      showErrorSnack(context, 'No se pudo actualizar el perfil.');
      debugPrint('Error actualizando seudónimo: $error');
    }
  }

  Future<void> _editDepartment(
    BuildContext context,
    WidgetRef ref,
    PatientProfile profile,
  ) async {
    final controller = TextEditingController(text: profile.departmentName);
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Departamento de psicología'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Nombre del departamento',
              counterText: '',
            ),
            validator: Validators.departmentName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;

    try {
      await ref
          .read(profileProvider.notifier)
          .saveProfile(departmentName: result);
      if (!context.mounted) return;
      showSuccessSnack(context, 'Departamento actualizado.');
    } catch (error) {
      if (!context.mounted) return;
      showErrorSnack(context, 'No se pudo actualizar el departamento.');
      debugPrint('Error actualizando departamento: $error');
    }
  }

  Future<void> _clearLocalData(
    BuildContext context,
    WidgetRef ref,
    String patientId,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Borrar todos los datos de este dispositivo?',
      message: 'Se eliminarán tu perfil, tus registros y tus emociones personalizadas guardados localmente. Esta acción no se puede deshacer.',
      confirmLabel: 'Borrar todo',
    );
    if (!confirmed) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('psico.records.$patientId');
      await prefs.remove('psico.profile.$patientId');
      await prefs.remove('psico.customEmotions.$patientId');
      ref.invalidate(profileProvider);
      ref.invalidate(recordsProvider);
      ref.invalidate(catalogProvider);
      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      showSuccessSnack(context, 'Datos locales eliminados.');
    } catch (error) {
      if (!context.mounted) return;
      showErrorSnack(context, 'No se pudieron borrar los datos locales.');
      debugPrint('Error borrando datos locales: $error');
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Cerrar sesión?',
      message: 'Tus datos seguirán guardados en tu cuenta. Podrás volver a entrar con tu correo y contraseña.',
      confirmLabel: 'Cerrar sesión',
      destructive: false,
    );
    if (!confirmed) return;

    try {
      await ref.read(authServiceProvider).signOut();
      ref.invalidate(profileProvider);
      ref.invalidate(recordsProvider);
      ref.invalidate(catalogProvider);
    } catch (error) {
      if (!context.mounted) return;
      showErrorSnack(
        context,
        'No se pudo cerrar la sesión. Inténtalo de nuevo.',
      );
      debugPrint('Error cerrando sesión: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final session = ref.watch(appSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const SectionHeader(title: 'Tu perfil'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.seed,
                  ),
                  title: const Text('Nombre o seudónimo'),
                  subtitle: Text(profile?.pseudonym ?? 'Sin configurar'),
                  trailing: const Icon(Icons.edit_outlined, size: 19),
                  onTap: profile == null
                      ? null
                      : () => _editPseudonym(context, ref, profile),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.apartment_rounded,
                    color: AppTheme.seed,
                  ),
                  title: const Text('Departamento de psicología'),
                  subtitle: Text(
                    profile?.departmentName ?? AppConfig.defaultDepartmentName,
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 19),
                  onTap: profile == null
                      ? null
                      : () => _editDepartment(context, ref, profile),
                ),
              ],
            ),
          ),
          if (session.isFirebaseEnabled) ...[
            const SizedBox(height: 20),
            const SectionHeader(title: 'Cuenta'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppTheme.seed,
                    ),
                    title: const Text('Correo electrónico'),
                    subtitle: Text(session.email ?? 'Cuenta de Firebase'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.logout_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () => _signOut(context, ref),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const SectionHeader(title: 'Almacenamiento'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: session.isFirebaseEnabled
                            ? AppTheme.seed.withValues(alpha: 0.12)
                            : AppTheme.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        session.isFirebaseEnabled
                            ? Icons.cloud_done_rounded
                            : Icons.phone_android_rounded,
                        color: session.isFirebaseEnabled
                            ? AppTheme.seed
                            : AppTheme.warning,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.firebaseStatus.shortLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            session.isFirebaseEnabled
                                ? 'Proyecto: ${session.firebaseStatus.projectId}'
                                : 'Los datos se guardan solo en este dispositivo.',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!session.isFirebaseEnabled) ...[
                  const SizedBox(height: 12),
                  InfoNote(
                    icon: Icons.info_outline_rounded,
                    text:
                        session.firebaseStatus.message ??
                        'Firebase no está configurado en esta compilación.',
                  ),
                  if (AppConfig.missingFirebaseVariables.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Variables pendientes: ${AppConfig.missingFirebaseVariables.join(', ')}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (!session.isFirebaseEnabled && profile != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _clearLocalData(context, ref, profile.patientId),
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Borrar todos mis datos locales'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const SectionHeader(title: 'Privacidad y seguridad'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppTheme.seed,
                  ),
                  title: const Text('Información de privacidad'),
                  subtitle: const Text('Qué datos se guardan y para qué'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showTextDialog(
                    context,
                    title: 'Privacidad y protección de datos',
                    body: '$privacyDetails\n\n$privacyVersionLabel',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.seed,
                  ),
                  title: const Text('Cómo protegemos tus datos'),
                  subtitle: const Text('Aislamiento, autenticación y cifrado'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showTextDialog(
                    context,
                    title: 'Medidas de seguridad',
                    body:
                        '• Cada paciente accede solo a sus propios registros.\n'
                        '• La sesión se gestiona con Firebase Authentication.\n'
                        '• Las reglas de Firestore bloquean el acceso a datos de otros usuarios.\n'
                        '• La comunicación con Firebase viaja cifrada (HTTPS/TLS).\n'
                        '• El correo electrónico se guarda en Firebase Authentication solo para acceder; no se incluye en los registros emocionales.\n'
                        '• Los PDF se generan en el dispositivo y solo se comparten cuando tú lo decides.\n\n'
                        'Si detectas un problema de seguridad, comunícalo a tu departamento de psicología.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: AppTheme.seed,
                  ),
                  title: const Text('Licencias de código abierto'),
                  subtitle: const Text('Bibliotecas utilizadas por la app'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppConfig.appName,
                    applicationVersion: AppConfig.appVersion,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Acerca de'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const AppLogo(size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            AppConfig.appName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Versión ${AppConfig.appVersion}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '${AppTheme.privacyReminder}\n\n'
                  'Esta aplicación no sustituye la atención psicológica profesional. En caso de urgencia, contacta con los servicios sanitarios o de emergencia.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
