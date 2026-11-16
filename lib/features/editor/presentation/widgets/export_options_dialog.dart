import 'package:flutter/material.dart';

import '../../domain/export_format.dart';

enum ExportAction { save, share }

class ExportRequest {
  const ExportRequest({
    required this.action,
    required this.format,
    required this.quality,
  });

  final ExportAction action;
  final ExportFormat format;
  final int quality;
}

class ExportOptionsDialog extends StatefulWidget {
  const ExportOptionsDialog({super.key});

  @override
  State<ExportOptionsDialog> createState() => _ExportOptionsDialogState();
}

class _ExportOptionsDialogState extends State<ExportOptionsDialog> {
  ExportFormat _format = ExportFormat.png;
  double _quality = 90;

  @override
  Widget build(BuildContext context) {
    final isJpg = _format == ExportFormat.jpg;
    return AlertDialog(
      title: const Text('Exportar composición'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<ExportFormat>(
            key: const Key('export-format'),
            segments: const [
              ButtonSegment(value: ExportFormat.png, label: Text('PNG')),
              ButtonSegment(value: ExportFormat.jpg, label: Text('JPG')),
            ],
            selected: {_format},
            onSelectionChanged: (selection) {
              setState(() => _format = selection.first);
            },
          ),
          const SizedBox(height: 16),
          Text(
            isJpg
                ? 'Calidad JPG: ${_quality.round()}%'
                : 'PNG conserva la calidad y transparencia.',
          ),
          Slider(
            key: const Key('export-quality'),
            value: _quality,
            min: 30,
            max: 100,
            divisions: 70,
            onChanged: isJpg
                ? (quality) => setState(() => _quality = quality)
                : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        OutlinedButton.icon(
          key: const Key('share-export'),
          onPressed: () => _submit(ExportAction.share),
          icon: const Icon(Icons.share_outlined),
          label: const Text('Compartir'),
        ),
        FilledButton.icon(
          key: const Key('save-export'),
          onPressed: () => _submit(ExportAction.save),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  void _submit(ExportAction action) {
    Navigator.pop(
      context,
      ExportRequest(action: action, format: _format, quality: _quality.round()),
    );
  }
}
