import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../gallery/domain/gallery_models.dart';
import '../../application/editor_controller.dart';
import '../../application/editor_providers.dart';
import '../../application/editor_state.dart';
import '../widgets/composition_canvas.dart';
import '../widgets/layer_tools.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({required this.selection, super.key});

  final PhotoSelection selection;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (mounted) {
      ref.read(editorControllerProvider.notifier).load(widget.selection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorControllerProvider);
    final project = state.project;

    return Scaffold(
      appBar: AppBar(title: Text(project?.name ?? 'Nueva composición')),
      body: switch (state.status) {
        EditorStatus.initial || EditorStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        EditorStatus.failure => _EditorError(onRetry: _load),
        EditorStatus.ready => _EditorContent(
          state: state,
          controller: ref.read(editorControllerProvider.notifier),
        ),
      },
    );
  }
}

class _EditorContent extends StatelessWidget {
  const _EditorContent({required this.state, required this.controller});

  final EditorState state;
  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    final project = state.project!;
    final selectedLayer = state.selectedLayer;
    final layerNumber = selectedLayer == null
        ? 0
        : project.orderedLayers.indexWhere(
                (layer) => layer.id == selectedLayer.id,
              ) +
              1;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CompositionCanvas(
                  project: project,
                  images: state.images,
                  selectedLayerId: state.selectedLayerId,
                  onSelect: controller.selectAt,
                  onTransformStart: controller.beginTransform,
                  onTransformUpdate: (delta, scale, rotation) {
                    controller.updateTransform(
                      normalizedDelta: delta,
                      scale: scale,
                      rotation: rotation,
                    );
                  },
                  onTransformEnd: controller.endTransform,
                ),
              ),
            ),
          ),
          LayerTools(
            layer: selectedLayer,
            layerNumber: layerNumber,
            layers: project.orderedLayers.reversed.toList(growable: false),
            selectedLayerId: state.selectedLayerId,
            canUndo: state.canUndo,
            canRedo: state.canRedo,
            onOpacityChanged: controller.setSelectedOpacity,
            onOpacityChangeStart: (_) => controller.beginOpacityChange(),
            onOpacityChangeEnd: (_) => controller.endOpacityChange(),
            onDuplicate: controller.duplicateSelected,
            onDelete: controller.deleteSelected,
            onSelectLayer: controller.selectLayer,
            onReorderLayer: controller.reorderLayer,
            onToggleVisibility: controller.toggleLayerVisibility,
            onToggleLock: controller.toggleLayerLock,
            onBringToFront: controller.bringSelectedToFront,
            onSendToBack: controller.sendSelectedToBack,
            onCrop: controller.cropSelected,
            onUndo: controller.undo,
            onRedo: controller.redo,
          ),
        ],
      ),
    );
  }
}

class _EditorError extends StatelessWidget {
  const _EditorError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No pudimos abrir las imágenes',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Vuelve a la galería para comprobar la selección o inténtalo de nuevo.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
