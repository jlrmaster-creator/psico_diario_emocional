import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'state/providers.dart';
import 'widgets/common_widgets.dart';

/// Raíz de la aplicación.
class PsicoApp extends StatelessWidget {
  const PsicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppRoot(),
    );
  }
}

/// Decide entre inicio de sesión, alta y pantalla principal.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtimeAsync = ref.watch(firebaseRuntimeProvider);

    return runtimeAsync.when(
      loading: () => const _SplashScreen(),
      error: (error, _) => _StartupError(
        message: 'No se pudo inicializar el almacenamiento. Comprueba la conexión y vuelve a intentarlo.',
        onRetry: () => ref.invalidate(firebaseRuntimeProvider),
      ),
      data: (runtime) {
        if (runtime.mode == FirebaseMode.error) {
          return _StartupError(
            message:
                runtime.message ??
                'No se pudo conectar con Firebase. Revisa la configuración.',
            onRetry: () => ref.invalidate(firebaseRuntimeProvider),
          );
        }

        if (runtime.mode == FirebaseMode.firebase) {
          final authAsync = ref.watch(authStateProvider);

          return authAsync.when(
            loading: () => const _SplashScreen(),
            error: (error, _) => _StartupError(
              message: 'No se pudo comprobar la sesión. Comprueba la conexión y vuelve a intentarlo.',
              onRetry: () => ref.invalidate(authStateProvider),
            ),
            data: (user) {
              if (user == null) return const AuthScreen();
              return const _ProfileGate();
            },
          );
        }

        return const _ProfileGate();
      },
    );
  }
}

/// Carga el perfil del paciente y decide entre alta y pantalla principal.
class _ProfileGate extends ConsumerWidget {
  const _ProfileGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const _SplashScreen(),
      error: (error, _) => _StartupError(
        message: 'No se pudo cargar tu espacio. Comprueba la conexión y vuelve a intentarlo.',
        onRetry: () => ref.read(profileProvider.notifier).reload(),
      ),
      data: (profile) {
        if (profile == null) return const OnboardingScreen();
        return const HomeScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(size: 78),
            SizedBox(height: 18),
            Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'No se pudo cargar tu espacio',
          message: message ?? 'Comprueba la conexión y vuelve a intentarlo. Si el problema continúa, cierra y abre la aplicación.',
          actionLabel: 'Reintentar',
          onAction: onRetry,
        ),
      ),
    );
  }
}
