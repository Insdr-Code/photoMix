import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../editor/application/editor_providers.dart';
import '../../../editor/domain/editor_project.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final recentProjects = ref.watch(editorProjectsProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppConstants.appName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Text(
                    'Combina tus fotos.\nCrea algo único.',
                    style: textTheme.headlineLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Superpone imágenes, organiza capas y crea composiciones directamente desde tu dispositivo.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.gallery),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Nueva composición'),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Proyectos recientes',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  recentProjects.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => _RecentProjectsError(
                      message: error.toString(),
                      onRetry: () => ref.invalidate(editorProjectsProvider),
                    ),
                    data: (projects) => projects.isEmpty
                        ? _EmptyRecentProjects(textTheme: textTheme)
                        : Column(
                            children: [
                              for (final project in projects.take(5))
                                _RecentProjectTile(project: project),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  key: const Key('view-all-projects'),
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(AppRoutes.projects),
                                  child: const Text('Ver todos'),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const Key('open-projects'),
                      onPressed: () =>
                          Navigator.of(context).pushNamed(AppRoutes.projects),
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Mis proyectos'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRecentProjects extends StatelessWidget {
  const _EmptyRecentProjects({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no tienes proyectos',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Crea tu primera composición para empezar.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentProjectTile extends StatelessWidget {
  const _RecentProjectTile({required this.project});

  final EditorProject project;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        key: ValueKey('recent-project-${project.id}'),
        onTap: () => Navigator.of(
          context,
        ).pushNamed(AppRoutes.editor, arguments: project.id),
        leading: const Icon(Icons.layers_outlined, color: AppColors.primary),
        title: Text(project.name),
        subtitle: Text('${project.layers.length} capas'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _RecentProjectsError extends StatelessWidget {
  const _RecentProjectsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('No se pudieron cargar los proyectos recientes.'),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
