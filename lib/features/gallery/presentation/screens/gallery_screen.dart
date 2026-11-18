import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/gallery_controller.dart';
import '../../application/gallery_providers.dart';
import '../../application/gallery_state.dart';

import '../widgets/gallery_image_tile.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen>
    with WidgetsBindingObserver {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(galleryControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final status = ref.read(galleryControllerProvider).status;
      if (status == GalleryStatus.permissionDenied) {
        ref.read(galleryControllerProvider.notifier).load();
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(galleryControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _continue() async {
    final selection = await ref
        .read(galleryControllerProvider.notifier)
        .createSelection();
    if (!mounted || selection == null) return;
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.editor, arguments: selection);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GalleryState>(galleryControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && message != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    });

    final state = ref.watch(galleryControllerProvider);
    final controller = ref.read(galleryControllerProvider.notifier);
    final canImport = state.status == GalleryStatus.ready && !state.isBusy;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.background == null ? 'Elige un fondo' : 'Añade imágenes',
        ),
        actions: [
          if (state.isImporting)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: canImport ? controller.importFiles : null,
              tooltip: 'Importar desde archivos',
              icon: const Icon(Icons.upload_file_outlined),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: switch (state.status) {
        GalleryStatus.initial || GalleryStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        GalleryStatus.permissionDenied => _PermissionMessage(
          onRequest: controller.load,
          onOpenSettings: controller.openSettings,
        ),
        GalleryStatus.failure => _ErrorMessage(onRetry: controller.load),
        GalleryStatus.ready => _GalleryContent(
          state: state,
          controller: controller,
          scrollController: _scrollController,
        ),
      },
      bottomNavigationBar:
          state.status == GalleryStatus.ready && state.background != null
          ? _SelectionBar(
              state: state,
              onChangeBackground: controller.changeBackground,
              onClearImports: controller.clearImportedFiles,
              onContinue: _continue,
            )
          : null,
    );
  }
}

class _GalleryContent extends StatelessWidget {
  const _GalleryContent({
    required this.state,
    required this.controller,
    required this.scrollController,
  });

  final GalleryState state;
  final GalleryController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final availableImages = state.availableImages;
    if (state.albums.isEmpty && availableImages.isEmpty) {
      return const _EmptyMessage(
        icon: Icons.photo_library_outlined,
        title: 'No encontramos fotografías',
        message: 'Agrega imágenes a tu galería e inténtalo de nuevo.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _AlbumButton(state: state, controller: controller),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              state.background == null
                  ? 'Selecciona la fotografía principal de tu composición.'
                  : 'Toca otras fotos para añadirlas como capas.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
        Expanded(
          child: availableImages.isEmpty
              ? const _EmptyMessage(
                  icon: Icons.photo_outlined,
                  title: 'Álbum vacío',
                  message: 'Selecciona otro álbum para ver sus fotografías.',
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 600 ? 5 : 3;
                    return GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount:
                          availableImages.length +
                          (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= availableImages.length) {
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        final image = availableImages[index];
                        final selectionIndex = state.additionalImages
                            .indexWhere((selected) => selected.id == image.id);
                        return GalleryImageTile(
                          key: Key('gallery-image-${image.id}'),
                          image: image,
                          filePath: state.importedFilePaths.contains(image.id)
                              ? image.id
                              : null,
                          isBackground: state.background?.id == image.id,
                          selectionIndex: selectionIndex < 0
                              ? null
                              : selectionIndex + 1,
                          onTap: () => controller.selectImage(image),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AlbumButton extends StatelessWidget {
  const _AlbumButton({required this.state, required this.controller});

  final GalleryState state;
  final GalleryController controller;

  Future<void> _showAlbums(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.albums.length,
              itemBuilder: (context, index) {
                final album = state.albums[index];
                return ListTile(
                  selected: album.id == state.selectedAlbumId,
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(album.name),
                  trailing: Text('${album.imageCount}'),
                  onTap: () {
                    Navigator.of(context).pop();
                    controller.selectAlbum(album);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final album = state.selectedAlbum;
    if (album == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showAlbums(context),
        icon: const Icon(Icons.photo_library_outlined),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${album.name} · ${album.imageCount}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.state,
    required this.onChangeBackground,
    required this.onClearImports,
    required this.onContinue,
  });

  final GalleryState state;
  final VoidCallback onChangeBackground;
  final VoidCallback onClearImports;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final importedCount = state.importedFilePaths.length;
    final layerCount = state.additionalImages.length;

    return Material(
      color: AppColors.surface,
      elevation: 12,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                layerCount == 1
                    ? 'Fondo seleccionado · 1 capa'
                    : 'Fondo seleccionado · $layerCount capas',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (importedCount > 0)
                TextButton.icon(
                  onPressed: state.isBusy ? null : onClearImports,
                  icon: const Icon(Icons.clear, size: 18),
                  label: Text(
                    importedCount == 1
                        ? 'Quitar 1 archivo importado'
                        : 'Quitar $importedCount archivos importados',
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: state.isBusy ? null : onChangeBackground,
                      child: const Text('Cambiar fondo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: state.canContinue ? onContinue : null,
                      child: state.isSaving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionMessage extends StatelessWidget {
  const _PermissionMessage({
    required this.onRequest,
    required this.onOpenSettings,
  });

  final Future<void> Function() onRequest;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return _EmptyMessage(
      icon: Icons.photo_library_outlined,
      title: 'Acceso a tus fotos',
      message:
          'PhotoMix necesita acceso a tu galería para que puedas elegir fotografías.',
      content: Column(
        children: [
          FilledButton(
            onPressed: onRequest,
            child: const Text('Permitir acceso'),
          ),
          TextButton(
            onPressed: onOpenSettings,
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _EmptyMessage(
      icon: Icons.error_outline,
      title: 'No pudimos abrir la galería',
      message: 'Revisa los permisos del dispositivo e inténtalo de nuevo.',
      content: FilledButton(
        onPressed: onRetry,
        child: const Text('Reintentar'),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.content,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (content != null) ...[const SizedBox(height: 24), content!],
          ],
        ),
      ),
    );
  }
}
