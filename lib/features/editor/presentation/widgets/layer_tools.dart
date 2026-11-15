import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/image_layer.dart';

class LayerTools extends StatelessWidget {
  const LayerTools({
    required this.layer,
    required this.layerNumber,
    required this.onOpacityChanged,
    required this.onDuplicate,
    required this.onDelete,
    super.key,
  });

  final ImageLayer? layer;
  final int layerNumber;
  final ValueChanged<double> onOpacityChanged;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: layer == null
              ? const _EmptyTools()
              : _buildSelectedTools(context),
        ),
      ),
    );
  }

  Widget _buildSelectedTools(BuildContext context) {
    final selectedLayer = layer!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Capa $layerNumber',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              key: const Key('duplicate-layer'),
              onPressed: selectedLayer.locked ? null : onDuplicate,
              tooltip: 'Duplicar capa',
              icon: const Icon(Icons.content_copy_outlined),
            ),
            IconButton(
              key: const Key('delete-layer'),
              onPressed: selectedLayer.locked ? null : onDelete,
              tooltip: 'Eliminar capa',
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.opacity, size: 20),
            Expanded(
              child: Slider(
                key: const Key('opacity-slider'),
                value: selectedLayer.opacity,
                onChanged: selectedLayer.locked ? null : onOpacityChanged,
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${(selectedLayer.opacity * 100).round()}%',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyTools extends StatelessWidget {
  const _EmptyTools();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            'Selecciona una imagen en el lienzo',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Arrastra para mover. Pellizca para escalar y gira con dos dedos.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
