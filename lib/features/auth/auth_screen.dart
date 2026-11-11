import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/privacy_text.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';

/// Pantalla de acceso con correo y contraseña.
///
/// Permite iniciar sesión, crear una cuenta y recuperar la contraseña.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isRegister = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      final auth = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isRegister) {
        await auth.register(email: email, password: password);
      } else {
        await auth.signIn(email: email, password: password);
      }

      // AppRoot cambia de pantalla al recibir el nuevo estado de sesión.
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = authErrorMessage(error);
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (Validators.email(email) != null) {
      setState(() {
        _error = 'Escribe primero tu correo para recuperar la contraseña.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (!mounted) return;
      setState(() => _loading = false);
      showSuccessSnack(
        context,
        'Te hemos enviado un correo para restablecer la contraseña.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = authErrorMessage(error);
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isRegister = !_isRegister;
      _error = null;
      _confirmController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _isRegister ? 'Crear tu cuenta' : 'Iniciar sesión';
    final subtitle = _isRegister
        ? 'Usa un correo y una contraseña. El correo solo sirve para acceder.'
        : 'Accede con el correo y la contraseña de tu cuenta.';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 76)),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 26),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              hintText: 'nombre@ejemplo.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: Validators.email,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: _isRegister
                                ? const [AutofillHints.newPassword]
                                : const [AutofillHints.password],
                            textInputAction: _isRegister
                                ? TextInputAction.next
                                : TextInputAction.done,
                            onFieldSubmitted: _isRegister
                                ? null
                                : (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                tooltip: _obscurePassword
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                              ),
                            ),
                            validator: Validators.password,
                          ),
                          if (_isRegister) ...[
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _confirmController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'Repite la contraseña',
                                prefixIcon: Icon(Icons.lock_reset_rounded),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden.';
                                }
                                return null;
                              },
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            InfoNote(
                              icon: Icons.error_outline_rounded,
                              color: Theme.of(context).colorScheme.error,
                              text: _error!,
                            ),
                          ],
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_isRegister ? 'Crear cuenta' : 'Entrar'),
                          ),
                          if (!_isRegister)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading ? null : _resetPassword,
                                child: const Text('¿Olvidaste tu contraseña?'),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : _toggleMode,
                      child: Text(
                        _isRegister
                            ? 'Ya tengo cuenta. Iniciar sesión'
                            : 'No tengo cuenta. Crear una',
                      ),
                    ),
                    TextButton(
                      onPressed: () => showTextDialog(
                        context,
                        title: 'Privacidad y protección de datos',
                        body:
                            '$privacySummary\n\n$privacyDetails\n\n$privacyVersionLabel',
                      ),
                      child: const Text('Información de privacidad'),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'El correo electrónico se usa solo para acceder. '
                      'Tus registros emocionales quedan asociados a tu cuenta '
                      'y no se comparten.',
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
          ),
        ),
      ),
    );
  }
}
