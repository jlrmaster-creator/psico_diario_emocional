import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../state/providers.dart';
import '../../widgets/common_widgets.dart';
import '../diary/widgets/record_card.dart';

/// Pantalla principal del diario emocional.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final session = ref.watch(appSessionProvider);
    final catalogAsync = ref.watch(catalogProvider);
    final recentAsync = ref.watch(recentRecordsProvider);
    final recordsAsync = ref.watch(recordsProvider);

    final profile = profileAsync.value;
    final catalog = catalogAsync.value;
    final pseudonym = profile?.pseudonym ?? 'Paciente';
    final department = profile?.departmentName ?? 'Departamento de Psicología';

    final today = dateOnly(DateTime.now());
    final todayCount =
        recordsAsync.value
            ?.where((record) => isSameDay(record.eventDate, today))
            .length ??
        0;
    final totalCount = recordsAsync.value?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(recordsProvider.notifier).reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Row(
                children: [
                  const AppLogo(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          department,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Diario Emocional',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => AppNavigation.openSettings(context),
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Configuración',
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.surface,
                      side: const BorderSide(color: AppTheme.outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _GreetingCard(
                pseudonym: pseudonym,
                todayCount: todayCount,
                totalCount: totalCount,
              ),
              if (!session.isFirebaseEnabled) ...[
                const SizedBox(height: 14),
                LocalModeBanner(
                  onTap: () => AppNavigation.openSettings(context),
                ),
              ],
              const SizedBox(height: 24),
              const SectionHeader(
                title: '¿Qué quieres hacer?',
                subtitle: 'Elige cómo quieres cuidar tu espacio emocional hoy.',
              ),
              _QuickActionsGrid(
                onEmotions: () => AppNavigation.openEmotions(context),
                onNewRecord: () => AppNavigation.openRecordForm(context),
                onDiary: () => AppNavigation.openDiary(context),
                onReports: () => AppNavigation.openReports(context),
                onInsights: () => AppNavigation.openInsights(context),
                onSummary: () => AppNavigation.openSummary(context),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Tus últimos registros',
                actionLabel: totalCount > 0 ? 'Ver historial' : null,
                onAction: () => AppNavigation.openDiary(context),
              ),
              recentAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: LoadingView(message: 'Cargando tus registros...'),
                ),
                error: (error, _) => InfoNote(
                  icon: Icons.error_outline_rounded,
                  color: const Color(0xFFB3564C),
                  text: 'No se pudieron cargar los registros. Desliza hacia abajo para volver a intentarlo.',
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return AppCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.seed,
                            size: 28,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Todavía no has escrito ningún registro.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Cuando quieras, empieza describiendo una situación y lo que sentiste.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () =>
                                AppNavigation.openRecordForm(context),
                            icon: const Icon(Icons.edit_note_rounded),
                            label: const Text('Escribir el primero'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final record in records)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RecordCard(
                            record: record,
                            catalog: catalog,
                            showDate: true,
                            onTap: () =>
                                AppNavigation.openRecordDetail(context, record),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              const InfoNote(
                text: AppTheme.privacyReminder,
                icon: Icons.favorite_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({
    required this.pseudonym,
    required this.todayCount,
    required this.totalCount,
  });

  final String pseudonym;
  final int todayCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.seed.withValues(alpha: 0.16),
            const Color(0xFFDCE8E1).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.seed.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, $pseudonym',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatLongDate(DateTime.now()),
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStat(
                icon: Icons.today_rounded,
                label: todayCount == 1
                    ? '1 registro hoy'
                    : '$todayCount registros hoy',
              ),
              _MiniStat(
                icon: Icons.menu_book_rounded,
                label: totalCount == 1
                    ? '1 registro en total'
                    : '$totalCount registros en total',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.seed),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onEmotions,
    required this.onNewRecord,
    required this.onDiary,
    required this.onReports,
    required this.onInsights,
    required this.onSummary,
  });

  final VoidCallback onEmotions;
  final VoidCallback onNewRecord;
  final VoidCallback onDiary;
  final VoidCallback onReports;
  final VoidCallback onInsights;
  final VoidCallback onSummary;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.explore_rounded,
        title: '¿Qué estoy sintiendo?',
        subtitle: 'Explora las emociones',
        color: AppTheme.seed,
        onTap: onEmotions,
      ),
      _QuickAction(
        icon: Icons.edit_note_rounded,
        title: 'Nuevo registro',
        subtitle: 'Escribe lo que ha pasado',
        color: const Color(0xFF6B8CAE),
        onTap: onNewRecord,
      ),
      _QuickAction(
        icon: Icons.menu_book_rounded,
        title: 'Historial',
        subtitle: 'Revisa tu diario',
        color: const Color(0xFF8C6E5D),
        onTap: onDiary,
      ),
      _QuickAction(
        icon: Icons.picture_as_pdf_rounded,
        title: 'Informes PDF',
        subtitle: 'Comparte un día',
        color: const Color(0xFF7D74A8),
        onTap: onReports,
      ),
      _QuickAction(
        icon: Icons.insights_rounded,
        title: 'Estadísticas',
        subtitle: 'Emociones y semanas',
        color: const Color(0xFF4F7C8A),
        onTap: onInsights,
      ),
      _QuickAction(
        icon: Icons.summarize_rounded,
        title: 'Resumen',
        subtitle: 'Qué ha cambiado',
        color: const Color(0xFFB08968),
        onTap: onSummary,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: actions,
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
