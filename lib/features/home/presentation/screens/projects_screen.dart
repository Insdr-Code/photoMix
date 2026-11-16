import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../editor/application/editor_providers.dart';
import '../../../editor/domain/editor_project.dart';
import '../../../editor/presentation/screens/editor_screen.dart';
import '../../../gallery/application/gallery_providers.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(editorProjectsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mis proyectos')),
      body: projects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ProjectsError(
          message: error.toString(),
          onRetry: () => ref.invalidate(editorProjectsProvider),
        ),
        data: (items) {
          if (items.isEmpty) return const _NoProjects();
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(editorProjectsProvider);
              await ref.read(editorProjectsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final project = items[index];
                return _ProjectTile(
                  project: project,
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EditorScreen(projectId: project.id),
                    ),
                  ),
                  onDelete: () => _confirmDelete(context, ref, project),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EditorProject project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text('¿Quieres eliminar "${project.name}" y sus imágenes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm-delete-project'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(editorProjectRepositoryProvider).delete(project.id);
      ref.invalidate(editorProjectsProvider);
      try {
        await ref
            .read(imageFileStorageProvider)
            .deleteProjectImages(project.id);
      } catch (error, stackTrace) {
        debugPrint('No se pudieron eliminar los recursos del proyecto: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Proyecto eliminado, pero no se pudieron limpiar sus imágenes: '
                '$error',
              ),
            ),
          );
        }
        return;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Proyecto eliminado.')));
      }
    } catch (error, stackTrace) {
      debugPrint('Error al eliminar proyecto: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar el proyecto: $error')),
        );
      }
    }
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.onOpen,
    required this.onDelete,
  });

  final EditorProject project;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final updatedAt = project.updatedAt;
    final date =
        '${updatedAt.year}-'
        '${updatedAt.month.toString().padLeft(2, '0')}-'
        '${updatedAt.day.toString().padLeft(2, '0')}';
    return Card(
      child: ListTile(
        key: ValueKey('project-${project.id}'),
        onTap: onOpen,
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.layers_outlined, color: Colors.white),
        ),
        title: Text(project.name),
        subtitle: Text('${project.layers.length} capas · Actualizado $date'),
        trailing: IconButton(
          key: Key('delete-project-${project.id}'),
          onPressed: onDelete,
          tooltip: 'Eliminar proyecto',
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _NoProjects extends StatelessWidget {
  const _NoProjects();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes proyectos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Crea una composición para verla aquí.'),
          ],
        ),
      ),
    );
  }
}

class _ProjectsError extends StatelessWidget {
  const _ProjectsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('No se pudieron cargar los proyectos.'),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
