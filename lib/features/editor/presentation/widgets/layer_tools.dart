import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/image_layer.dart';
import '../../domain/layer_crop.dart';

class LayerTools extends StatelessWidget {
  const LayerTools({
    required this.layer,
    required this.layerNumber,
    required this.layers,
    required this.selectedLayerId,
    required this.canUndo,
    required this.canRedo,
    required this.onOpacityChanged,
    required this.onOpacityChangeStart,
    required this.onOpacityChangeEnd,
    required this.onDuplicate,
    required this.onDelete,
    required this.onSelectLayer,
    required this.onReorderLayer,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.onBringToFront,
    required this.onSendToBack,
    required this.onCrop,
    required this.onUndo,
    required this.onRedo,
    super.key,
  });

  final ImageLayer? layer;
  final int layerNumber;
  final List<ImageLayer> layers;
  final String? selectedLayerId;
  final bool canUndo;
  final bool canRedo;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<double> onOpacityChangeStart;
  final ValueChanged<double> onOpacityChangeEnd;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final ValueChanged<String> onSelectLayer;
  final void Function(String layerId, int newTopIndex) onReorderLayer;
  final ValueChanged<String> onToggleVisibility;
  final ValueChanged<String> onToggleLock;
  final VoidCallback onBringToFront;
  final VoidCallback onSendToBack;
  final ValueChanged<LayerCrop> onCrop;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Capas',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('undo'),
                    onPressed: canUndo ? onUndo : null,
                    tooltip: 'Deshacer',
                    icon: const Icon(Icons.undo),
                  ),
                  IconButton(
                    key: const Key('redo'),
                    onPressed: canRedo ? onRedo : null,
                    tooltip: 'Rehacer',
                    icon: const Icon(Icons.redo),
                  ),
                ],
              ),
              if (layers.isEmpty)
                const _EmptyTools()
              else
                SizedBox(
                  height: (layers.length * 48.0).clamp(48.0, 144.0),
                  child: ReorderableListView.builder(
                    key: const Key('layer-list'),
                    buildDefaultDragHandles: false,
                    itemCount: layers.length,
                    onReorderItem: (oldIndex, newIndex) {
                      onReorderLayer(layers[oldIndex].id, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final currentLayer = layers[index];
                      return _LayerRow(
                        key: ValueKey(currentLayer.id),
                        layer: currentLayer,
                        index: index,
                        layerNumber: layers.length - index,
                        selected: currentLayer.id == selectedLayerId,
                        onSelect: () => onSelectLayer(currentLayer.id),
                        onToggleVisibility: () =>
                            onToggleVisibility(currentLayer.id),
                        onToggleLock: () => onToggleLock(currentLayer.id),
                      );
                    },
                  ),
                ),
              if (layer == null)
                const _SelectionHint()
              else
                _buildSelectedTools(context),
            ],
          ),
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
              key: const Key('send-layer-back'),
              onPressed: selectedLayer.locked ? null : onSendToBack,
              tooltip: 'Enviar al fondo',
              icon: const Icon(Icons.flip_to_back_outlined),
            ),
            IconButton(
              key: const Key('bring-layer-front'),
              onPressed: selectedLayer.locked ? null : onBringToFront,
              tooltip: 'Traer al frente',
              icon: const Icon(Icons.flip_to_front_outlined),
            ),
            IconButton(
              key: const Key('crop-layer'),
              onPressed: selectedLayer.locked
                  ? null
                  : () => _editCrop(context, selectedLayer),
              tooltip: 'Recortar',
              icon: const Icon(Icons.crop),
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
                onChangeStart: selectedLayer.locked
                    ? null
                    : onOpacityChangeStart,
                onChangeEnd: selectedLayer.locked ? null : onOpacityChangeEnd,
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

  Future<void> _editCrop(BuildContext context, ImageLayer selectedLayer) async {
    final crop = await showDialog<LayerCrop>(
      context: context,
      builder: (context) => _CropDialog(initialCrop: selectedLayer.crop),
    );
    if (crop != null) onCrop(crop);
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.layer,
    required this.index,
    required this.layerNumber,
    required this.selected,
    required this.onSelect,
    required this.onToggleVisibility,
    required this.onToggleLock,
    super.key,
  });

  final ImageLayer layer;
  final int index;
  final int layerNumber;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('layer-row-${layer.id}'),
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.transparent,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onSelect,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Capa $layerNumber',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              key: Key('visibility-${layer.id}'),
              onPressed: onToggleVisibility,
              tooltip: layer.visible ? 'Ocultar capa' : 'Mostrar capa',
              icon: Icon(
                layer.visible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            IconButton(
              key: Key('lock-${layer.id}'),
              onPressed: onToggleLock,
              tooltip: layer.locked ? 'Desbloquear capa' : 'Bloquear capa',
              icon: Icon(
                layer.locked ? Icons.lock_outline : Icons.lock_open_outlined,
              ),
            ),
            ReorderableDragStartListener(
              index: index,
              enabled: !layer.locked,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionHint extends StatelessWidget {
  const _SelectionHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Selecciona una imagen en el lienzo o en la lista de capas.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _EmptyTools extends StatelessWidget {
  const _EmptyTools();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text('Esta composición todavía no tiene capas.'),
    );
  }
}

class _CropDialog extends StatefulWidget {
  const _CropDialog({required this.initialCrop});

  final LayerCrop initialCrop;

  @override
  State<_CropDialog> createState() => _CropDialogState();
}

class _CropDialogState extends State<_CropDialog> {
  late LayerCrop _crop = widget.initialCrop;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recortar capa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cropSlider(
              'Izquierda',
              'crop-left',
              _crop.left,
              0.9 - _crop.right,
              (value) => _crop.copyWith(left: value),
            ),
            _cropSlider(
              'Arriba',
              'crop-top',
              _crop.top,
              0.9 - _crop.bottom,
              (value) => _crop.copyWith(top: value),
            ),
            _cropSlider(
              'Derecha',
              'crop-right',
              _crop.right,
              0.9 - _crop.left,
              (value) => _crop.copyWith(right: value),
            ),
            _cropSlider(
              'Abajo',
              'crop-bottom',
              _crop.bottom,
              0.9 - _crop.top,
              (value) => _crop.copyWith(bottom: value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('reset-crop'),
          onPressed: () => setState(() => _crop = const LayerCrop()),
          child: const Text('Restablecer'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('apply-crop'),
          onPressed: () => Navigator.pop(context, _crop),
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  Widget _cropSlider(
    String label,
    String key,
    double value,
    double max,
    LayerCrop Function(double) update,
  ) {
    return Row(
      children: [
        SizedBox(width: 72, child: Text(label)),
        Expanded(
          child: Slider(
            key: Key(key),
            value: value,
            max: max,
            onChanged: (value) => setState(() => _crop = update(value)),
          ),
        ),
        SizedBox(width: 40, child: Text('${(value * 100).round()}%')),
      ],
    );
  }
}
